#!/bin/bash
# Boot Selector Installer
# Usage: curl -fsSL https://raw.githubusercontent.com/mkshuvo/bootselector/master/install.sh | sudo bash
#
# This script downloads and installs Boot Selector from GitHub

set -e

# Configuration
REPO="mkshuvo/bootselector"
APP_NAME="bootselector"
INSTALL_DIR="/opt/$APP_NAME"
VERSION="${VERSION:-1.0.0}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_banner() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════╗"
    echo "║       ⚡ Boot Selector Installer      ║"
    echo "╚══════════════════════════════════════╝"
    echo -e "${NC}"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[!]${NC} $1"
}

error() {
    echo -e "${RED}[✗]${NC} $1"
    exit 1
}

# Check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        error "Please run as root or with sudo"
    fi
}

# Detect OS and package manager
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        OS_LIKE=$ID_LIKE
    else
        error "Cannot detect OS. /etc/os-release not found."
    fi
    
    # Detect architecture
    ARCH=$(uname -m)
    case $ARCH in
        x86_64)
            ARCH="linux-x64"
            ;;
        aarch64)
            ARCH="linux-arm64"
            ;;
        *)
            error "Unsupported architecture: $ARCH"
            ;;
    esac
    
    info "Detected OS: $OS ($ARCH)"
}

# Check dependencies
check_dependencies() {
    info "Checking dependencies..."
    
    # Check for efibootmgr
    if ! command -v efibootmgr &> /dev/null; then
        warn "efibootmgr not found. Installing..."
        
        if command -v dnf &> /dev/null; then
            dnf install -y efibootmgr
        elif command -v apt-get &> /dev/null; then
            apt-get update && apt-get install -y efibootmgr
        elif command -v pacman &> /dev/null; then
            pacman -S --noconfirm efibootmgr
        elif command -v zypper &> /dev/null; then
            zypper install -y efibootmgr
        else
            warn "Could not install efibootmgr automatically. Please install it manually."
        fi
    fi
    
    success "Dependencies OK"
}

# Download and install
install_app() {
    local TEMP_DIR=$(mktemp -d)
    
    # Download from latest-release folder in repo
    local DOWNLOAD_URL="https://github.com/$REPO/raw/master/latest-release/$APP_NAME-$VERSION-$ARCH.tar.gz"
    
    info "Downloading from: $DOWNLOAD_URL"
    
    # Download
    if ! curl -fsSL "$DOWNLOAD_URL" -o "$TEMP_DIR/$APP_NAME.tar.gz"; then
        error "Download failed. Check if the release exists at $DOWNLOAD_URL"
    fi
    
    success "Downloaded successfully"
    
    # Extract
    info "Extracting..."
    tar xzf "$TEMP_DIR/$APP_NAME.tar.gz" -C "$TEMP_DIR"
    
    # Find the extracted directory
    EXTRACTED_DIR=$(find "$TEMP_DIR" -maxdepth 1 -type d -name "$APP_NAME*" | head -1)
    if [ -z "$EXTRACTED_DIR" ] || [ "$EXTRACTED_DIR" = "$TEMP_DIR" ]; then
        EXTRACTED_DIR="$TEMP_DIR"
    fi
    
    # Remove old installation
    if [ -d "$INSTALL_DIR" ]; then
        warn "Removing previous installation..."
        rm -rf "$INSTALL_DIR"
    fi
    
    # Install
    info "Installing to $INSTALL_DIR..."
    mkdir -p "$INSTALL_DIR"
    
    # Copy all files from extracted directory
    if [ -d "$EXTRACTED_DIR" ] && [ "$EXTRACTED_DIR" != "$TEMP_DIR" ]; then
        cp -r "$EXTRACTED_DIR"/* "$INSTALL_DIR/"
    else
        # Files might be directly in temp dir
        cp -r "$TEMP_DIR"/*.dll "$TEMP_DIR"/*.so "$TEMP_DIR"/*.json "$TEMP_DIR"/$APP_NAME "$TEMP_DIR"/*.png "$INSTALL_DIR/" 2>/dev/null || true
    fi
    
    # Make executable
    chmod +x "$INSTALL_DIR/$APP_NAME"
    
    # Create symlink
    ln -sf "$INSTALL_DIR/$APP_NAME" /usr/local/bin/$APP_NAME
    
    success "Installed to $INSTALL_DIR"
    
    # Cleanup
    rm -rf "$TEMP_DIR"
}

# Create desktop entry
create_desktop_entry() {
    info "Creating desktop entry..."
    
    mkdir -p /usr/share/applications
    mkdir -p /usr/share/icons/hicolor/256x256/apps
    
    # Copy icon if exists
    if [ -f "$INSTALL_DIR/icon.png" ]; then
        cp "$INSTALL_DIR/icon.png" /usr/share/icons/hicolor/256x256/apps/$APP_NAME.png
    fi
    
    # Create desktop entry
    cat > /usr/share/applications/$APP_NAME.desktop << EOF
[Desktop Entry]
Name=Boot Selector
Comment=Select which OS to boot on next restart
Exec=$INSTALL_DIR/$APP_NAME
Icon=$APP_NAME
Terminal=false
Type=Application
Categories=System;Settings;
Keywords=boot;efi;uefi;grub;reboot;
StartupWMClass=$APP_NAME
EOF
    
    # Update desktop database
    update-desktop-database /usr/share/applications 2>/dev/null || true
    gtk-update-icon-cache /usr/share/icons/hicolor 2>/dev/null || true
    
    success "Desktop entry created"
}

# Uninstall function
uninstall() {
    info "Uninstalling Boot Selector..."
    
    rm -rf "$INSTALL_DIR"
    rm -f /usr/local/bin/$APP_NAME
    rm -f /usr/share/applications/$APP_NAME.desktop
    rm -f /usr/share/icons/hicolor/256x256/apps/$APP_NAME.png
    
    update-desktop-database /usr/share/applications 2>/dev/null || true
    
    success "Boot Selector has been uninstalled"
    exit 0
}

# Main
main() {
    print_banner
    
    # Check for uninstall flag
    if [ "$1" = "--uninstall" ] || [ "$1" = "-u" ]; then
        check_root
        uninstall
    fi
    
    check_root
    detect_os
    check_dependencies
    install_app
    create_desktop_entry
    
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║    ✓ Installation Complete!          ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════╝${NC}"
    echo ""
    echo "  Run 'bootselector' or find it in your applications menu."
    echo ""
    echo "  To uninstall, run:"
    echo "    curl -fsSL https://raw.githubusercontent.com/$REPO/master/install.sh | sudo bash -s -- --uninstall"
    echo ""
}

main "$@"
