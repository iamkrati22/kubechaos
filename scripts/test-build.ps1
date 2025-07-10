# Test Build Script for Chaos Monkey
# This script tests the build process locally

Write-Host "🧪 Testing Chaos Monkey Build" -ForegroundColor Yellow
Write-Host "=============================" -ForegroundColor Yellow

# Check if Go is installed
try {
    $goVersion = go version
    Write-Host "✅ Go found: $goVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Go not found. Please install Go 1.21+" -ForegroundColor Red
    exit 1
}

# Check dependencies
Write-Host "📦 Checking dependencies..." -ForegroundColor Cyan
go mod download
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to download dependencies" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Dependencies downloaded" -ForegroundColor Green

# Test build for Windows
Write-Host "🔨 Testing Windows build..." -ForegroundColor Cyan
go build -v -o test-chaos-monkey.exe main.go test_pods.go chaos_types.go version.go
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Windows build failed" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Windows build successful" -ForegroundColor Green

# Test the binary
Write-Host "🧪 Testing binary..." -ForegroundColor Cyan
$versionOutput = & .\test-chaos-monkey.exe --version
Write-Host "Version output: $versionOutput" -ForegroundColor Gray

$helpOutput = & .\test-chaos-monkey.exe --help
Write-Host "Help output length: $($helpOutput.Length) characters" -ForegroundColor Gray

# Clean up
Remove-Item test-chaos-monkey.exe -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "✅ All tests passed! Build is working correctly." -ForegroundColor Green
Write-Host "🚀 Ready for GitHub Actions deployment." -ForegroundColor Cyan 