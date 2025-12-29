using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Threading.Tasks;
using System.Runtime.InteropServices;
using System.Text.RegularExpressions;
using bootselector.Models;

namespace bootselector.Services;

/// <summary>
/// Linux implementation using efibootmgr
/// </summary>
public partial class LinuxBootService : IBootService
{
    public bool IsAvailable => RuntimeInformation.IsOSPlatform(OSPlatform.Linux);
    public string PlatformName => "Linux (efibootmgr)";

    [GeneratedRegex(@"Boot([0-9A-Fa-f]{4})\*?\s+(.+?)(?:\t|$)", RegexOptions.Compiled)]
    private static partial Regex BootEntryRegex();

    [GeneratedRegex(@"BootCurrent:\s*([0-9A-Fa-f]{4})", RegexOptions.Compiled)]
    private static partial Regex BootCurrentRegex();

    public async Task<List<BootEntry>> GetBootEntriesAsync()
    {
        var entries = new List<BootEntry>();
        
        try
        {
            // Run efibootmgr to get boot entries
            var process = new Process
            {
                StartInfo = new ProcessStartInfo
                {
                    FileName = "efibootmgr",
                    RedirectStandardOutput = true,
                    RedirectStandardError = true,
                    UseShellExecute = false,
                    CreateNoWindow = true
                }
            };
            
            process.Start();
            var output = await process.StandardOutput.ReadToEndAsync();
            await process.WaitForExitAsync();
            
            // Parse current boot entry
            string currentBootId = "";
            var currentMatch = BootCurrentRegex().Match(output);
            if (currentMatch.Success)
            {
                currentBootId = currentMatch.Groups[1].Value;
            }
            
            // Parse boot entries
            var matches = BootEntryRegex().Matches(output);
            foreach (Match match in matches)
            {
                var id = match.Groups[1].Value;
                var name = match.Groups[2].Value.Trim();
                
                entries.Add(new BootEntry
                {
                    Id = id,
                    Name = name,
                    IsCurrent = id.Equals(currentBootId, StringComparison.OrdinalIgnoreCase)
                });
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
            // Build the command - uses pkexec for graphical sudo prompt
            var command = restart 
                ? $"efibootmgr --bootnext {entry.Id} && reboot"
                : $"efibootmgr --bootnext {entry.Id}";
            
            var process = new Process
            {
                StartInfo = new ProcessStartInfo
                {
                    FileName = "pkexec",
                    Arguments = $"sh -c \"{command}\"",
                    RedirectStandardOutput = true,
                    RedirectStandardError = true,
                    UseShellExecute = false,
                    CreateNoWindow = true
                }
            };
            
            process.Start();
            var error = await process.StandardError.ReadToEndAsync();
            var output = await process.StandardOutput.ReadToEndAsync();
            await process.WaitForExitAsync();
            
            if (process.ExitCode == 0)
            {
                return (true, $"Successfully set next boot to: {entry.Name}");
            }
            else
            {
                return (false, $"Failed: {error}");
            }
        }
        catch (Exception ex)
        {
            return (false, $"Error: {ex.Message}");
        }
    }
}
