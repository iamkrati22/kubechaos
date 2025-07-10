# Create Release Package Script for Chaos Monkey
# This script builds binaries and creates release packages

Write-Host "ðŸŽ­ Creating Chaos Monkey Release Package" -ForegroundColor Yellow
Write-Host "=======================================" -ForegroundColor Yellow

# Create directories
$BUILD_DIR = "../dist"
$RELEASE_DIR = "../releases"

if (-not (Test-Path $BUILD_DIR)) {
    New-Item -ItemType Directory -Path $BUILD_DIR -Force | Out-Null
}

if (-not (Test-Path $RELEASE_DIR)) {
    New-Item -ItemType Directory -Path $RELEASE_DIR -Force | Out-Null
}

Write-Host "Building binaries for all platforms..." -ForegroundColor Cyan

# Build for Windows
Write-Host "Building for Windows..." -ForegroundColor Green
$env:GOOS = "windows"
$env:GOARCH = "amd64"
go build -o "$BUILD_DIR\chaos-monkey-windows-amd64.exe" ../main.go ../test_pods.go ../chaos_types.go ../version.go

$env:GOOS = "windows"
$env:GOARCH = "386"
go build -o "$BUILD_DIR\chaos-monkey-windows-386.exe" ../main.go ../test_pods.go ../chaos_types.go ../version.go

# Build for Linux
Write-Host "Building for Linux..." -ForegroundColor Green
$env:GOOS = "linux"
$env:GOARCH = "amd64"
go build -o "$BUILD_DIR\chaos-monkey-linux-amd64" ../main.go ../test_pods.go ../chaos_types.go ../version.go

$env:GOOS = "linux"
$env:GOARCH = "386"
go build -o "$BUILD_DIR\chaos-monkey-linux-386" ../main.go ../test_pods.go ../chaos_types.go ../version.go

$env:GOOS = "linux"
$env:GOARCH = "arm64"
go build -o "$BUILD_DIR\chaos-monkey-linux-arm64" ../main.go ../test_pods.go ../chaos_types.go ../version.go

# Build for macOS
Write-Host "Building for macOS..." -ForegroundColor Green
$env:GOOS = "darwin"
$env:GOARCH = "amd64"
go build -o "$BUILD_DIR\chaos-monkey-darwin-amd64" ../main.go ../test_pods.go ../chaos_types.go ../version.go

$env:GOOS = "darwin"
$env:GOARCH = "arm64"
go build -o "$BUILD_DIR\chaos-monkey-darwin-arm64" ../main.go ../test_pods.go ../chaos_types.go ../version.go

# Create checksums
Write-Host "Creating checksums..." -ForegroundColor Cyan
Get-ChildItem $BUILD_DIR -Name "chaos-monkey-*" | ForEach-Object {
    $file = Join-Path $BUILD_DIR $_
    $hash = Get-FileHash -Path $file -Algorithm SHA256
    $hash.Hash | Out-File -FilePath "$file.sha256" -Encoding ASCII
}

# Create release packages
Write-Host "Creating release packages..." -ForegroundColor Cyan

# Windows packages
Compress-Archive -Path "$BUILD_DIR\chaos-monkey-windows-amd64.exe" -DestinationPath "$RELEASE_DIR\chaos-monkey-windows-amd64.zip" -Force
Compress-Archive -Path "$BUILD_DIR\chaos-monkey-windows-386.exe" -DestinationPath "$RELEASE_DIR\chaos-monkey-windows-386.zip" -Force

# Linux packages
tar -czf "$RELEASE_DIR\chaos-monkey-linux-amd64.tar.gz" -C $BUILD_DIR chaos-monkey-linux-amd64
tar -czf "$RELEASE_DIR\chaos-monkey-linux-386.tar.gz" -C $BUILD_DIR chaos-monkey-linux-386
tar -czf "$RELEASE_DIR\chaos-monkey-linux-arm64.tar.gz" -C $BUILD_DIR chaos-monkey-linux-arm64

# macOS packages
tar -czf "$RELEASE_DIR\chaos-monkey-darwin-amd64.tar.gz" -C $BUILD_DIR chaos-monkey-darwin-amd64
tar -czf "$RELEASE_DIR\chaos-monkey-darwin-arm64.tar.gz" -C $BUILD_DIR chaos-monkey-darwin-arm64

# Create installation scripts
Write-Host "Creating installation scripts..." -ForegroundColor Cyan

# Windows installation script
$windowsScript = @'
# Chaos Monkey Installation Script for Windows
Write-Host "Installing Chaos Monkey..." -ForegroundColor Yellow

# Download and extract
$INSTALL_DIR = "$env:USERPROFILE\AppData\Local\ChaosMonkey"
if (-not (Test-Path $INSTALL_DIR)) {
    New-Item -ItemType Directory -Path $INSTALL_DIR -Force | Out-Null
}

# Copy binary
Copy-Item "chaos-monkey-windows-amd64.exe" "$INSTALL_DIR\chaos-monkey.exe"

# Add to PATH
$PATH_DIR = "$env:USERPROFILE\AppData\Local\Microsoft\WinGet\Packages"
if (-not (Test-Path $PATH_DIR)) {
    New-Item -ItemType Directory -Path $PATH_DIR -Force | Out-Null
}

# Create batch file
$batchContent = @"
@echo off
"$INSTALL_DIR\chaos-monkey.exe" %*
"@
$batchContent | Out-File -FilePath "$PATH_DIR\chaos-monkey.bat" -Encoding ASCII

Write-Host "Chaos Monkey installed successfully!" -ForegroundColor Green
Write-Host "Usage: chaos-monkey --help" -ForegroundColor Cyan
'@

$windowsScript | Out-File -FilePath "$RELEASE_DIR\install-windows.ps1" -Encoding UTF8

# Linux/macOS installation script
$unixScript = @'
#!/bin/bash
# Chaos Monkey Installation Script for Linux/macOS

echo "Installing Chaos Monkey..."

# Detect OS and architecture
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

case $ARCH in
    x86_64) ARCH="amd64" ;;
    aarch64) ARCH="arm64" ;;
    armv7l) ARCH="arm" ;;
esac

if [[ "$OS" == "darwin" ]]; then
    OS="darwin"
elif [[ "$OS" == "linux" ]]; then
    OS="linux"
else
    echo "Unsupported OS: $OS"
    exit 1
fi

BINARY_NAME="chaos-monkey-$OS-$ARCH"
INSTALL_DIR="/usr/local/bin"

echo "Installing to $INSTALL_DIR..."
sudo cp "$BINARY_NAME" "$INSTALL_DIR/chaos-monkey"
sudo chmod +x "$INSTALL_DIR/chaos-monkey"

echo "Chaos Monkey installed successfully!"
echo "Usage: chaos-monkey --help"
'@

$unixScript | Out-File -FilePath "$RELEASE_DIR\install-unix.sh" -Encoding ASCII

Write-Host "âœ… Release package created successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Release files:" -ForegroundColor Yellow
Get-ChildItem $RELEASE_DIR | ForEach-Object {
    Write-Host "  - $($_.Name)" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Build files:" -ForegroundColor Yellow
Get-ChildItem $BUILD_DIR | ForEach-Object {
    Write-Host "  - $($_.Name)" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Create GitHub repository" -ForegroundColor Gray
Write-Host "2. Push code to repository" -ForegroundColor Gray
Write-Host "3. Create release with these files" -ForegroundColor Gray
Write-Host "4. Update README with download links" -ForegroundColor Gray 
