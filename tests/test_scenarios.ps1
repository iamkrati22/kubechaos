# Chaos Monkey Test Suite
# This script tests all functionality of the chaos monkey tool

param(
    [string]$Namespace = "chaos-test",
    [switch]$CleanupOnly
)

Write-Host "🎭 Chaos Monkey Test Suite" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan

# Function to run a test
function Test-Scenario {
    param(
        [string]$Name,
        [string]$Command,
        [string]$ExpectedOutput = "",
        [string]$Description = ""
    )
    
    Write-Host "`n🧪 Testing: $Name" -ForegroundColor Yellow
    if ($Description) {
        Write-Host "   $Description" -ForegroundColor Gray
    }
    Write-Host "   Command: $Command" -ForegroundColor Gray
    
    try {
        $result = Invoke-Expression $Command 2>&1
        $success = $LASTEXITCODE -eq 0
        
        if ($success) {
            Write-Host "   ✅ PASSED" -ForegroundColor Green
            if ($result) {
                Write-Host "   Output: $result" -ForegroundColor White
            }
        } else {
            Write-Host "   ❌ FAILED (Exit code: $LASTEXITCODE)" -ForegroundColor Red
            Write-Host "   Error: $result" -ForegroundColor Red
        }
        
        return $success
    }
    catch {
        Write-Host "   ❌ FAILED (Exception)" -ForegroundColor Red
        Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Function to check if namespace exists
function Test-NamespaceExists {
    param([string]$Namespace)
    
    $ns = kubectl get namespace $Namespace --no-headers 2>$null
    return $LASTEXITCODE -eq 0
}

# Function to create test namespace
function New-TestNamespace {
    param([string]$Namespace)
    
    if (-not (Test-NamespaceExists -Namespace $Namespace)) {
        Write-Host "📦 Creating test namespace: $Namespace" -ForegroundColor Blue
        kubectl create namespace $Namespace
    } else {
        Write-Host "📦 Test namespace already exists: $Namespace" -ForegroundColor Blue
    }
}

# Function to create test deployments
function New-TestDeployments {
    param([string]$Namespace)
    
    Write-Host "🚀 Creating test deployments..." -ForegroundColor Blue
    
    # Create nginx deployment
    kubectl create deployment nginx --image=nginx:alpine -n $Namespace 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   ✅ Created nginx deployment" -ForegroundColor Green
    }
    
    # Create redis deployment
    kubectl create deployment redis --image=redis:alpine -n $Namespace 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   ✅ Created redis deployment" -ForegroundColor Green
    }
    
    # Create postgres deployment
    kubectl create deployment postgres --image=postgres:alpine -n $Namespace 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   ✅ Created postgres deployment" -ForegroundColor Green
    }
    
    # Wait for pods to be ready
    Write-Host "⏳ Waiting for pods to be ready..." -ForegroundColor Blue
    Start-Sleep -Seconds 10
}

# Function to cleanup test resources
function Remove-TestResources {
    param([string]$Namespace)
    
    Write-Host "🧹 Cleaning up test resources..." -ForegroundColor Blue
    
    # Delete namespace (this will delete all resources in it)
    kubectl delete namespace $Namespace --ignore-not-found=true
    Write-Host "   ✅ Deleted namespace: $Namespace" -ForegroundColor Green
}

# Main test execution
if ($CleanupOnly) {
    Write-Host "🧹 Cleanup mode - removing test resources only" -ForegroundColor Yellow
    Remove-TestResources -Namespace $Namespace
    exit 0
}

# Setup test environment
New-TestNamespace -Namespace $Namespace
New-TestDeployments -Namespace $Namespace

# Test Results tracking
$testResults = @()
$totalTests = 0
$passedTests = 0

# Test 1: Help command
$totalTests++
$result = Test-Scenario -Name "Help Command" -Command "go run main.go test_pods.go -help" -Description "Test help command displays correctly"
if ($result) { $passedTests++ }
$testResults += @{Name="Help Command"; Result=$result}

# Test 2: Dry run mode
$totalTests++
$result = Test-Scenario -Name "Dry Run Mode" -Command "go run main.go test_pods.go -namespace=$Namespace -dry-run" -Description "Test dry-run shows what would be deleted without actually deleting"
if ($result) { $passedTests++ }
$testResults += @{Name="Dry Run Mode"; Result=$result}

# Test 3: Create test pods
$totalTests++
$result = Test-Scenario -Name "Create Test Pods" -Command "go run main.go test_pods.go -namespace=$Namespace -create -count=2" -Description "Test creating test pods"
if ($result) { $passedTests++ }
$testResults += @{Name="Create Test Pods"; Result=$result}

# Test 4: Delete single pod
$totalTests++
$result = Test-Scenario -Name "Delete Single Pod" -Command "go run main.go test_pods.go -namespace=$Namespace -delete-count=1" -Description "Test deleting a single random pod"
if ($result) { $passedTests++ }
$testResults += @{Name="Delete Single Pod"; Result=$result}

# Test 5: Delete multiple pods
$totalTests++
$result = Test-Scenario -Name "Delete Multiple Pods" -Command "go run main.go test_pods.go -namespace=$Namespace -delete-count=2" -Description "Test deleting multiple random pods"
if ($result) { $passedTests++ }
$testResults += @{Name="Delete Multiple Pods"; Result=$result}

# Test 6: Label filtering
$totalTests++
$result = Test-Scenario -Name "Label Filtering" -Command "go run main.go test_pods.go -namespace=$Namespace -labels='app=nginx' -dry-run" -Description "Test filtering pods by labels"
if ($result) { $passedTests++ }
$testResults += @{Name="Label Filtering"; Result=$result}

# Test 7: Cleanup test pods
$totalTests++
$result = Test-Scenario -Name "Cleanup Test Pods" -Command "go run main.go test_pods.go -namespace=$Namespace -cleanup" -Description "Test cleaning up test pods created by chaos monkey"
if ($result) { $passedTests++ }
$testResults += @{Name="Cleanup Test Pods"; Result=$result}

# Test 8: Invalid namespace
$totalTests++
$result = Test-Scenario -Name "Invalid Namespace" -Command "go run main.go test_pods.go -namespace=non-existent-namespace" -Description "Test behavior with non-existent namespace"
if ($result) { $passedTests++ }
$testResults += @{Name="Invalid Namespace"; Result=$result}

# Test 9: No pods scenario
$totalTests++
$result = Test-Scenario -Name "No Pods Scenario" -Command "go run main.go test_pods.go -namespace=$Namespace -labels='app=nonexistent' -dry-run" -Description "Test behavior when no pods match criteria"
if ($result) { $passedTests++ }
$testResults += @{Name="No Pods Scenario"; Result=$result}

# Test 10: Create and delete in one run
$totalTests++
$result = Test-Scenario -Name "Create and Delete" -Command "go run main.go test_pods.go -namespace=$Namespace -create -count=3 -delete-count=1" -Description "Test creating pods and then deleting one in the same run"
if ($result) { $passedTests++ }
$testResults += @{Name="Create and Delete"; Result=$result}

# Print test summary
Write-Host "`n📊 Test Summary" -ForegroundColor Cyan
Write-Host "===============" -ForegroundColor Cyan
Write-Host "Total Tests: $totalTests" -ForegroundColor White
Write-Host "Passed: $passedTests" -ForegroundColor Green
Write-Host "Failed: $($totalTests - $passedTests)" -ForegroundColor Red
Write-Host "Success Rate: $([math]::Round(($passedTests / $totalTests) * 100, 2))%" -ForegroundColor Cyan

# Print detailed results
Write-Host "`n📋 Detailed Results:" -ForegroundColor Cyan
foreach ($test in $testResults) {
    $status = if ($test.Result) { "✅ PASS" } else { "❌ FAIL" }
    $color = if ($test.Result) { "Green" } else { "Red" }
    Write-Host "   $status $($test.Name)" -ForegroundColor $color
}

# Cleanup
Write-Host "`n🧹 Cleaning up test environment..." -ForegroundColor Yellow
Remove-TestResources -Namespace $Namespace

Write-Host "`n🎉 Test suite completed!" -ForegroundColor Cyan 