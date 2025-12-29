#!/bin/bash
# Build script for creating Linux packages (self-contained)
# This script bundles .NET runtime so users don't need to install it

set -e

APP_NAME="bootselector"
VERSION="1.0.0"
MAINTAINER="Boot Selector Team <contact@example.com>"
DESCRIPTION="Cross-platform boot entry selector for EFI/UEFI systems"
RUNTIME="linux-x64"  # Change to linux-arm64 for ARM

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "🔧 Building self-contained application for $RUNTIME..."
echo ""

# Clean previous builds
rm -rf bin/Release
rm -rf publish
rm -rf packages
mkdir -p packages

# Publish self-contained app
dotnet publish -c Release -r $RUNTIME --self-contained true -p:PublishTrimmed=true -o publish/$RUNTIME

# Convert SVG to PNG for Linux desktop integration
echo "📷 Converting icon to PNG..."
convert -background none Assets/icon.svg -resize 256x256 publish/$RUNTIME/icon.png 2>/dev/null || cp Assets/icon.svg publish/$RUNTIME/

echo ""
echo "========================================"
echo "📦 Creating portable .tar.gz package..."
echo "========================================"

# Create portable tarball
TARBALL_NAME="${APP_NAME}-${VERSION}-${RUNTIME}"
mkdir -p "packages/$TARBALL_NAME"
cp -r publish/$RUNTIME/* "packages/$TARBALL_NAME/"

# Add install script
cat > "packages/$TARBALL_NAME/install.sh" << 'EOF'
#!/bin/bash
set -e
INSTALL_DIR="/opt/bootselector"
echo "Installing Boot Selector to $INSTALL_DIR..."
sudo mkdir -p "$INSTALL_DIR"
sudo cp -r ./* "$INSTALL_DIR/"
sudo chmod +x "$INSTALL_DIR/bootselector"
sudo ln -sf "$INSTALL_DIR/bootselector" /usr/local/bin/bootselector

# Desktop entry
sudo mkdir -p /usr/share/applications
sudo tee /usr/share/applications/bootselector.desktop > /dev/null << 'DESKTOP'
[Desktop Entry]
Name=Boot Selector
Comment=Select which OS to boot on next restart
Exec=/opt/bootselector/bootselector
Icon=/opt/bootselector/icon.png
Terminal=false
Type=Application
Categories=System;Settings;
DESKTOP

echo "✅ Installation complete! Run 'bootselector' or find it in your applications menu."
EOF
chmod +x "packages/$TARBALL_NAME/install.sh"

# Create tarball
cd packages
tar czf "${TARBALL_NAME}.tar.gz" "$TARBALL_NAME"
rm -rf "$TARBALL_NAME"
cd "$SCRIPT_DIR"

echo "✅ Created: packages/${TARBALL_NAME}.tar.gz"

# Check if rpmbuild is available for RPM creation
if command -v rpmbuild &> /dev/null; then
    echo ""
    echo "========================================"
    echo "📦 Creating .rpm package..."
    echo "========================================"

    # Create RPM build structure
    RPM_ROOT="packages/rpm-build"
    rm -rf "$RPM_ROOT"
    mkdir -p "$RPM_ROOT"/{BUILD,RPMS,SOURCES,SPECS,SRPMS}

    # Create tarball for RPM
    TARBALL_DIR="$RPM_ROOT/SOURCES/$APP_NAME-$VERSION"
    mkdir -p "$TARBALL_DIR"
    cp -r publish/$RUNTIME/* "$TARBALL_DIR/"
    cd "$RPM_ROOT/SOURCES"
    tar czf "$APP_NAME-$VERSION.tar.gz" "$APP_NAME-$VERSION"
    rm -rf "$APP_NAME-$VERSION"
    cd "$SCRIPT_DIR"

    # Create spec file
    cat > "$RPM_ROOT/SPECS/$APP_NAME.spec" << EOF
Name:           $APP_NAME
Version:        $VERSION
Release:        1%{?dist}
Summary:        $DESCRIPTION

License:        MIT
URL:            https://github.com/example/bootselector
Source0:        %{name}-%{version}.tar.gz

AutoReqProv:    no
%define debug_package %{nil}
Requires:       efibootmgr

%description
Boot Selector allows you to choose which operating system
to boot on the next restart. It works with EFI/UEFI systems
and supports both Linux (efibootmgr) and Windows (bcdedit).

%prep
%setup -q

%install
mkdir -p %{buildroot}/opt/%{name}
mkdir -p %{buildroot}/usr/bin
mkdir -p %{buildroot}/usr/share/applications
mkdir -p %{buildroot}/usr/share/icons/hicolor/256x256/apps

cp -r * %{buildroot}/opt/%{name}/

# Create launcher script
cat > %{buildroot}/usr/bin/%{name} << 'LAUNCHER'
#!/bin/bash
exec /opt/bootselector/bootselector "\$@"
LAUNCHER
chmod +x %{buildroot}/usr/bin/%{name}

# Desktop entry
cat > %{buildroot}/usr/share/applications/%{name}.desktop << 'DESKTOP'
[Desktop Entry]
Name=Boot Selector
Comment=Select which OS to boot on next restart
Exec=/opt/bootselector/bootselector
Icon=bootselector
Terminal=false
Type=Application
Categories=System;Settings;
Keywords=boot;efi;uefi;grub;reboot;
StartupWMClass=bootselector
DESKTOP

# Icon
if [ -f %{buildroot}/opt/%{name}/icon.png ]; then
    cp %{buildroot}/opt/%{name}/icon.png %{buildroot}/usr/share/icons/hicolor/256x256/apps/%{name}.png
fi

%files
/opt/%{name}
/usr/bin/%{name}
/usr/share/applications/%{name}.desktop
%attr(644, root, root) /usr/share/icons/hicolor/256x256/apps/%{name}.png

%post
chmod +x /opt/%{name}/%{name}
update-desktop-database /usr/share/applications 2>/dev/null || true
gtk-update-icon-cache /usr/share/icons/hicolor 2>/dev/null || true

%changelog
* $(date "+%a %b %d %Y") Boot Selector Team - $VERSION-1
- Initial release
EOF

    # Build RPM
    rpmbuild --define "_topdir $SCRIPT_DIR/$RPM_ROOT" -bb "$RPM_ROOT/SPECS/$APP_NAME.spec"

    # Move RPM to packages directory
    find "$RPM_ROOT/RPMS" -name "*.rpm" -exec mv {} packages/ \;

    # Cleanup
    rm -rf "$RPM_ROOT"
    
    echo "✅ RPM package created!"
else
    echo ""
    echo "⚠️  rpmbuild not found. Skipping RPM creation."
    echo "   Install with: sudo dnf install rpm-build"
fi

# Check if dpkg-deb is available for DEB creation
if command -v dpkg-deb &> /dev/null; then
    echo ""
    echo "========================================"
    echo "📦 Creating .deb package..."
    echo "========================================"

    # Create .deb package structure
    DEB_ROOT="packages/deb-build"
    rm -rf "$DEB_ROOT"
    mkdir -p "$DEB_ROOT/DEBIAN"
    mkdir -p "$DEB_ROOT/opt/$APP_NAME"
    mkdir -p "$DEB_ROOT/usr/share/applications"
    mkdir -p "$DEB_ROOT/usr/share/icons/hicolor/256x256/apps"
    mkdir -p "$DEB_ROOT/usr/bin"

    # Copy application files
    cp -r publish/$RUNTIME/* "$DEB_ROOT/opt/$APP_NAME/"

    # Create desktop entry
    cat > "$DEB_ROOT/usr/share/applications/$APP_NAME.desktop" << EOF
[Desktop Entry]
Name=Boot Selector
Comment=Select which OS to boot on next restart
Exec=/opt/$APP_NAME/$APP_NAME
Icon=$APP_NAME
Terminal=false
Type=Application
Categories=System;Settings;
Keywords=boot;efi;uefi;grub;reboot;
StartupWMClass=$APP_NAME
EOF

    # Copy icon
    if [ -f "publish/$RUNTIME/icon.png" ]; then
        cp publish/$RUNTIME/icon.png "$DEB_ROOT/usr/share/icons/hicolor/256x256/apps/$APP_NAME.png"
    fi

    # Create symlink script
    cat > "$DEB_ROOT/usr/bin/$APP_NAME" << EOF
#!/bin/bash
exec /opt/$APP_NAME/$APP_NAME "\$@"
EOF
    chmod +x "$DEB_ROOT/usr/bin/$APP_NAME"

    # Calculate installed size (in KB)
    INSTALLED_SIZE=$(du -sk "$DEB_ROOT" | cut -f1)

    # Create control file
    cat > "$DEB_ROOT/DEBIAN/control" << EOF
Package: $APP_NAME
Version: $VERSION
Section: utils
Priority: optional
Architecture: amd64
Installed-Size: $INSTALLED_SIZE
Depends: efibootmgr
Maintainer: $MAINTAINER
Description: $DESCRIPTION
 Boot Selector allows you to choose which operating system
 to boot on the next restart. It works with EFI/UEFI systems
 and supports both Linux (efibootmgr) and Windows (bcdedit).
EOF

    # Create postinst script
    cat > "$DEB_ROOT/DEBIAN/postinst" << 'EOF'
#!/bin/bash
set -e
chmod +x /opt/bootselector/bootselector
update-desktop-database /usr/share/applications 2>/dev/null || true
gtk-update-icon-cache /usr/share/icons/hicolor 2>/dev/null || true
exit 0
EOF
    chmod 755 "$DEB_ROOT/DEBIAN/postinst"

    # Build .deb package
    dpkg-deb --build --root-owner-group "$DEB_ROOT" "packages/${APP_NAME}_${VERSION}_amd64.deb"

    # Cleanup
    rm -rf "$DEB_ROOT"
    
    echo "✅ DEB package created!"
else
    echo ""
    echo "⚠️  dpkg-deb not found. Skipping DEB creation."
    echo "   This is expected on non-Debian systems."
fi

echo ""
echo "========================================"
echo "✅ Build complete!"
echo "========================================"
echo ""
echo "📁 Packages created in 'packages' directory:"
ls -lh packages/ 2>/dev/null
echo ""
echo "📌 Installation options:"
echo "   Portable:      tar xzf packages/${APP_NAME}-${VERSION}-${RUNTIME}.tar.gz && cd ${APP_NAME}-${VERSION}-${RUNTIME} && ./install.sh"
if [ -f "packages/${APP_NAME}-${VERSION}"*.rpm ]; then
    echo "   Fedora/RHEL:   sudo rpm -i packages/${APP_NAME}-${VERSION}*.rpm"
fi
if [ -f "packages/${APP_NAME}_${VERSION}_amd64.deb" ]; then
    echo "   Debian/Ubuntu: sudo dpkg -i packages/${APP_NAME}_${VERSION}_amd64.deb"
fi
