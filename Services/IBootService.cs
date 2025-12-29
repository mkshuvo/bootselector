using System.Collections.Generic;
using System.Threading.Tasks;
using bootselector.Models;

namespace bootselector.Services;

/// <summary>
/// Interface for platform-specific boot management operations
/// </summary>
public interface IBootService
{
    /// <summary>
    /// Get all available boot entFRefresries
    /// </summary>
    Task<List<BootEntry>> GetBootEntriesAsync();
    
    /// <summary>
    /// Set the next boot entry and optionally restart
    /// </summary>
    /// <param name="entry">The boot entry to boot into</param>
    /// <param name="restart">Whether to restart immediately</param>
    /// <returns>Result message</returns>
    Task<(bool Success, string Message)> SetNextBootAsync(BootEntry entry, bool restart = true);
    
    /// <summary>
    /// Check if the service is available on this platform
    /// </summary>
    bool IsAvailable { get; }
    
    /// <summary>
    /// Get the platform name
    /// </summary>
    string PlatformName { get; }
}
