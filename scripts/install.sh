#!/bin/bash

# Installation script for Chaos Monkey
# This script installs the chaos monkey tool globally

set -e

echo "🎭 Installing Chaos Monkey..."
echo "============================"

# Detect OS and architecture
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

# Map architecture names
case $ARCH in
    x86_64) ARCH="amd64" ;;
    aarch64) ARCH="arm64" ;;
    armv7l) ARCH="arm" ;;
esac

# Determine binary name
if [[ "$OS" == "darwin" ]]; then
    OS="darwin"
elif [[ "$OS" == "linux" ]]; then
    OS="linux"
else
    echo "❌ Unsupported OS: $OS"
    exit 1
fi

BINARY_NAME="chaos-monkey-$OS-$ARCH"
INSTALL_DIR="/usr/local/bin"

echo "Detected OS: $OS, Architecture: $ARCH"
echo "Binary: $BINARY_NAME"

# Check if binary exists
if [[ ! -f "dist/$BINARY_NAME" ]]; then
    echo "❌ Binary not found: dist/$BINARY_NAME"
    echo "Please run './build.sh' first to build the binaries"
    exit 1
fi

# Create installation directory if it doesn't exist
sudo mkdir -p $INSTALL_DIR

# Copy binary to installation directory
echo "Installing to $INSTALL_DIR..."
sudo cp "dist/$BINARY_NAME" "$INSTALL_DIR/chaos-monkey"
sudo chmod +x "$INSTALL_DIR/chaos-monkey"

# Create symlink for easier access
if [[ -L "/usr/bin/chaos-monkey" ]]; then
    sudo rm "/usr/bin/chaos-monkey"
fi
sudo ln -sf "$INSTALL_DIR/chaos-monkey" "/usr/bin/chaos-monkey"

echo "✅ Chaos Monkey installed successfully!"
echo ""
echo "Usage examples:"
echo "  chaos-monkey --help"
echo "  chaos-monkey -chaos-type=in-pod-cpu-stress -labels='app=nginx'"
echo "  chaos-monkey -cron='*/5 * * * *' -chaos-type=kill-process"
echo ""
echo "Documentation: https://github.com/your-repo/chaos-monkey" 