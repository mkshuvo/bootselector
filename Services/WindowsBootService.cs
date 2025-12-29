using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Threading.Tasks;
using System.Runtime.InteropServices;
using System.Text.RegularExpressions;
using bootselector.Models;

namespace bootselector.Services;

/// <summary>
/// Windows implementation using bcdedit for firmware boot entries
/// </summary>
public partial class WindowsBootService : IBootService
{
    public bool IsAvailable => RuntimeInformation.IsOSPlatform(OSPlatform.Windows);
    public string PlatformName => "Windows (bcdedit)";

    [GeneratedRegex(@"identifier\s+\{(.+?)\}", RegexOptions.Compiled | RegexOptions.IgnoreCase)]
    private static partial Regex IdentifierRegex();

    [GeneratedRegex(@"description\s+(.+)", RegexOptions.Compiled | RegexOptions.IgnoreCase)]
    private static partial Regex DescriptionRegex();

    public async Task<List<BootEntry>> GetBootEntriesAsync()
    {
        var entries = new List<BootEntry>();
        
        try
        {
            // Run bcdedit to get firmware boot entries
            var process = new Process
            {
                StartInfo = new ProcessStartInfo
                {
                    FileName = "bcdedit",
                    Arguments = "/enum firmware",
                    RedirectStandardOutput = true,
                    RedirectStandardError = true,
                    UseShellExecute = false,
                    CreateNoWindow = true,
                    Verb = "runas" // Request admin
                }
            };
            
            process.Start();
            var output = await process.StandardOutput.ReadToEndAsync();
            await process.WaitForExitAsync();
            
            // Parse entries - bcdedit outputs blocks separated by blank lines
            var blocks = output.Split(new[] { "\r\n\r\n", "\n\n" }, StringSplitOptions.RemoveEmptyEntries);
            
            foreach (var block in blocks)
            {
                var idMatch = IdentifierRegex().Match(block);
                var descMatch = DescriptionRegex().Match(block);
                
                if (idMatch.Success && descMatch.Success)
                {
                    var id = idMatch.Groups[1].Value;
                    var name = descMatch.Groups[1].Value.Trim();
                    
                    // Skip the boot manager itself
                    if (id.Equals("fwbootmgr", StringComparison.OrdinalIgnoreCase))
                        continue;
                    
                    entries.Add(new BootEntry
                    {
                        Id = $"{{{id}}}",
                        Name = name,
                        IsCurrent = false // Windows doesn't easily expose this
                    });
                }
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error getting boot entries: {ex.Message}");
        }
        
        return entries;
    }

    public async Task<(bool Success, string Message)> SetNextBootAsync(BootEntry entry, bool restart = true)
    {
        try
        {
            // Set boot sequence for next boot only
            var setProcess = new Process
            {
                StartInfo = new ProcessStartInfo
                {
                    FileName = "bcdedit",
                    Arguments = $"/set {{fwbootmgr}} bootsequence {entry.Id}",
                    RedirectStandardOutput = true,
                    RedirectStandardError = true,
                    UseShellExecute = false,
                    CreateNoWindow = true
                }
            };
            
            setProcess.Start();
            var error = await setProcess.StandardError.ReadToEndAsync();
            var output = await setProcess.StandardOutput.ReadToEndAsync();
            await setProcess.WaitForExitAsync();
            
            if (setProcess.ExitCode != 0)
            {
                return (false, $"Failed to set boot sequence: {error}");
            }
            
            if (restart)
            {
                // Restart the system
                var restartProcess = new Process
                {
                    StartInfo = new ProcessStartInfo
                    {
                        FileName = "shutdown",
                        Arguments = "/r /t 0",
                        UseShellExecute = false,
                        CreateNoWindow = true
                    }
                };
                restartProcess.Start();
            }
            
            return (true, $"Successfully set next boot to: {entry.Name}");
        }
        catch (Exception ex)
        {
            return (false, $"Error: {ex.Message}");
        }
    }
}
