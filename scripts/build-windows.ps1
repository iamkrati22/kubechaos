# Windows Build Script for Chaos Monkey
# This script builds and creates checksums for Windows

Write-Host "🔨 Building Chaos Monkey for Windows..." -ForegroundColor Yellow

# Build the binary
Write-Host "Building binary..." -ForegroundColor Cyan
go build -v -o chaos-monkey-windows-amd64.exe main.go test_pods.go chaos_types.go version.go

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Build failed!" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Build completed successfully" -ForegroundColor Green

# List the created file
Write-Host "Created files:" -ForegroundColor Cyan
Get-ChildItem chaos-monkey-windows-amd64.exe | Format-Table Name, Length

# Create checksum
Write-Host "Creating checksum..." -ForegroundColor Cyan
try {
    $hash = Get-FileHash -Path "chaos-monkey-windows-amd64.exe" -Algorithm SHA256
    $hash.Hash | Out-File -FilePath "checksums.txt" -Encoding ASCII
    Write-Host "✅ Checksum created: $($hash.Hash)" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to create checksum: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Windows build and checksum completed successfully!" -ForegroundColor Green 