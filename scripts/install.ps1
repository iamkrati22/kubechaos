# Installation script for Chaos Monkey (Windows)
# This script installs the chaos monkey tool globally on Windows

Write-Host "🎭 Installing Chaos Monkey..." -ForegroundColor Yellow
Write-Host "============================" -ForegroundColor Yellow

# Detect architecture
$ARCH = if ([Environment]::Is64BitOperatingSystem) { "amd64" } else { "386" }
$BINARY_NAME = "chaos-monkey-windows-$ARCH.exe"

Write-Host "Detected Architecture: $ARCH" -ForegroundColor Cyan
Write-Host "Binary: $BINARY_NAME" -ForegroundColor Cyan

# Check if binary exists
if (-not (Test-Path "dist\$BINARY_NAME")) {
    Write-Host "❌ Binary not found: dist\$BINARY_NAME" -ForegroundColor Red
    Write-Host "Please run './build.sh' first to build the binaries" -ForegroundColor Red
    exit 1
}

# Create installation directory
$INSTALL_DIR = "$env:ProgramFiles\ChaosMonkey"
if (-not (Test-Path $INSTALL_DIR)) {
    New-Item -ItemType Directory -Path $INSTALL_DIR -Force | Out-Null
}

# Copy binary to installation directory
Write-Host "Installing to $INSTALL_DIR..." -ForegroundColor Cyan
Copy-Item "dist\$BINARY_NAME" "$INSTALL_DIR\chaos-monkey.exe" -Force

# Add to PATH
$PATH_DIR = "$env:USERPROFILE\AppData\Local\Microsoft\WinGet\Packages"
if (-not (Test-Path $PATH_DIR)) {
    New-Item -ItemType Directory -Path $PATH_DIR -Force | Out-Null
}

# Create a batch file for easy access
$BATCH_FILE = "$PATH_DIR\chaos-monkey.bat"
@"
@echo off
"$INSTALL_DIR\chaos-monkey.exe" %*
"@ | Out-File -FilePath $BATCH_FILE -Encoding ASCII

# Add to PATH if not already there
$CurrentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
if ($CurrentPath -notlike "*$PATH_DIR*") {
    [Environment]::SetEnvironmentVariable("PATH", "$CurrentPath;$PATH_DIR", "User")
    Write-Host "Added to PATH. Please restart your terminal for changes to take effect." -ForegroundColor Yellow
}

Write-Host "✅ Chaos Monkey installed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Usage examples:" -ForegroundColor Cyan
Write-Host "  chaos-monkey --help" -ForegroundColor Gray
Write-Host "  chaos-monkey -chaos-type=in-pod-cpu-stress -labels='app=nginx'" -ForegroundColor Gray
Write-Host "  chaos-monkey -cron='*/5 * * * *' -chaos-type=kill-process" -ForegroundColor Gray
Write-Host ""
Write-Host "Documentation: https://github.com/your-repo/chaos-monkey" -ForegroundColor Cyan 