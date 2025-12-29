# ⚡ Boot Selector

A cross-platform boot entry selector for EFI/UEFI systems. Easily switch between operating systems on your next restart.

## Features

- 🖥️ **Cross-platform** - Works on Linux and Windows
- 🎨 **Modern UI** - Beautiful dark theme with Avalonia UI
- 🔄 **One-click reboot** - Select OS and restart immediately
- 🔒 **Secure** - Uses system privilege elevation (pkexec/sudo on Linux, UAC on Windows)
- 📦 **Self-contained** - No .NET runtime installation required

## Quick Install (Linux)

### One-liner install:

```bash
curl -fsSL https://raw.githubusercontent.com/mkshuvo/bootselector/main/install.sh | sudo bash
```

### Or specify a version:

```bash
VERSION=1.0.0 curl -fsSL https://raw.githubusercontent.com/mkshuvo/bootselector/main/install.sh | sudo bash
```

### Uninstall:

```bash
curl -fsSL https://raw.githubusercontent.com/mkshuvo/bootselector/main/install.sh | sudo bash -s -- --uninstall
```

## Manual Installation

### Fedora/RHEL/CentOS

```bash
# Download the RPM
wget https://github.com/mkshuvo/bootselector/raw/main/latest-release/bootselector-1.0.0-1.fc43.x86_64.rpm

# Install
sudo rpm -i bootselector-1.0.0-1.fc43.x86_64.rpm
```

### Portable (Any Linux)

```bash
# Download and extract
wget https://github.com/mkshuvo/bootselector/raw/main/latest-release/bootselector-1.0.0-linux-x64.tar.gz
tar xzf bootselector-1.0.0-linux-x64.tar.gz
cd bootselector-1.0.0-linux-x64

# Install
./install.sh
```

## Download Links

| Platform                    | Download                                                                                                                                     |
| --------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- |
| **Fedora/RHEL** (RPM)       | [bootselector-1.0.0-1.fc43.x86_64.rpm](https://github.com/mkshuvo/bootselector/raw/main/latest-release/bootselector-1.0.0-1.fc43.x86_64.rpm) |
| **Linux Portable** (tar.gz) | [bootselector-1.0.0-linux-x64.tar.gz](https://github.com/mkshuvo/bootselector/raw/main/latest-release/bootselector-1.0.0-linux-x64.tar.gz)   |

## Usage

1. Launch **Boot Selector** from your applications menu or run `bootselector`
2. Select the desired boot entry from the dropdown
3. Click **"Set Next Boot"** to set it for next restart only
4. Or click **"Restart to Selected Boot"** to set and restart immediately
5. Authenticate when prompted (sudo/admin password)

## Building from Source

### Prerequisites

- .NET 10 SDK
- For RPM packages: `rpm-build`
- For DEB packages: `dpkg-deb` (Debian/Ubuntu systems)

### Build

```bash
# Clone the repository
git clone https://github.com/mkshuvo/bootselector.git
cd bootselector

# Build and run
dotnet build
dotnet run

# Create packages
./build-packages.sh
```

## How It Works

### Linux

Uses `efibootmgr` to interact with EFI/UEFI boot variables:

```bash
efibootmgr --bootnext XXXX && reboot
```

### Windows

Uses `bcdedit` to set the firmware boot sequence:

```cmd
bcdedit /set {fwbootmgr} bootsequence {XXXX}
shutdown /r /t 0
```

## Requirements

- **Linux**: EFI/UEFI system with `efibootmgr` installed
- **Windows**: EFI/UEFI system, run as Administrator

## License

MIT License - see [LICENSE](LICENSE) file

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Author

Created by [@mkshuvo](https://github.com/mkshuvo)
