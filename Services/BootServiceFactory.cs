using System;
using System.Runtime.InteropServices;

namespace bootselector.Services;

/// <summary>
/// Factory to get the appropriate boot service for the current platform
/// </summary>
public static class BootServiceFactory
{
    public static IBootService GetBootService()
    {
        if (RuntimeInformation.IsOSPlatform(OSPlatform.Linux))
        {
            return new LinuxBootService();
        }
        else if (RuntimeInformation.IsOSPlatform(OSPlatform.Windows))
        {
            return new WindowsBootService();
        }
        else
        {
            throw new PlatformNotSupportedException(
                "Boot selection is only supported on Linux and Windows.");
        }
    }
}
