namespace bootselector.Models;

/// <summary>
/// Represents a boot entry from the EFI/UEFI boot manager
/// </summary>
public class BootEntry
{
    /// <summary>
    /// The boot entry ID (e.g., "0000", "0001", "0002")
    /// </summary>
    public string Id { get; set; } = string.Empty;
    
    /// <summary>
    /// The display name of the boot entry (e.g., "Windows Boot Manager", "ubuntu")
    /// </summary>
    public string Name { get; set; } = string.Empty;
    
    /// <summary>
    /// Whether this is the currently active boot entry
    /// </summary>
    public bool IsCurrent { get; set; }
    
    /// <summary>
    /// Display string for the UI
    /// </summary>
    public string DisplayName => IsCurrent ? $"► {Name} (Current)" : Name;
    
    public override string ToString() => DisplayName;
}
