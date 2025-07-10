# Chaos Monkey Test Runner
# Simple script to run the test suite from the main directory

param(
    [string]$Namespace = "chaos-test",
    [switch]$CleanupOnly,
    [switch]$Help
)

if ($Help) {
    Write-Host "🎭 Chaos Monkey Test Runner" -ForegroundColor Cyan
    Write-Host "Usage:" -ForegroundColor White
    Write-Host "  .\run_tests.ps1                    # Run all tests with default namespace"
    Write-Host "  .\run_tests.ps1 -Namespace my-test # Run tests with custom namespace"
    Write-Host "  .\run_tests.ps1 -CleanupOnly       # Cleanup test resources only"
    Write-Host "  .\run_tests.ps1 -Help              # Show this help"
    exit 0
}

Write-Host "🎭 Starting Chaos Monkey Test Suite..." -ForegroundColor Cyan

# Check if we're in the right directory
if (-not (Test-Path "main.go")) {
    Write-Host "❌ Error: main.go not found. Please run this script from the kubechaos directory." -ForegroundColor Red
    exit 1
}

# Check if tests directory exists
if (-not (Test-Path "tests\test_scenarios.ps1")) {
    Write-Host "❌ Error: Test scenarios not found. Please ensure tests directory exists." -ForegroundColor Red
    exit 1
}

# Run the test suite
Write-Host "🚀 Executing test scenarios..." -ForegroundColor Green
& ".\tests\test_scenarios.ps1" -Namespace $Namespace -CleanupOnly:$CleanupOnly

Write-Host "`n🎉 Test runner completed!" -ForegroundColor Cyan 