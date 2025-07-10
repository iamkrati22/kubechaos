# Test Failures Script - Demonstrates how Chaos Monkey can cause actual failures
# This script shows different ways the application can fail under stress

Write-Host "Testing Chaos Monkey Failure Scenarios" -ForegroundColor Yellow
Write-Host "================================================" -ForegroundColor Yellow

# Function to check pod status
function Test-PodHealth {
    param($namespace, $podName)
    
    $pod = kubectl get pod $podName -n $namespace -o json | ConvertFrom-Json
    if ($pod.status.phase -eq "Failed") {
        Write-Host "POD FAILED: $podName" -ForegroundColor Red
        return $false
    }
    
    foreach ($container in $pod.status.containerStatuses) {
        if ($container.restartCount -gt 0) {
            Write-Host "CONTAINER RESTARTED: $($container.name) restarted $($container.restartCount) times" -ForegroundColor Yellow
        }
        if (-not $container.ready) {
            Write-Host "CONTAINER NOT READY: $($container.name)" -ForegroundColor Yellow
        }
    }
    
    return $true
}

# Function to monitor pods during stress
function Monitor-PodsDuringStress {
    param($namespace, $duration = 60)
    
    Write-Host "Monitoring pods for $duration seconds..." -ForegroundColor Cyan
    
    $startTime = Get-Date
    $endTime = $startTime.AddSeconds($duration)
    
    while ((Get-Date) -lt $endTime) {
        $pods = kubectl get pods -n $namespace -o json | ConvertFrom-Json
        
        foreach ($pod in $pods.items) {
            if ($pod.status.phase -eq "Failed") {
                Write-Host "POD FAILED: $($pod.metadata.name)" -ForegroundColor Red
            }
            
            foreach ($container in $pod.status.containerStatuses) {
                if ($container.restartCount -gt 0) {
                    Write-Host "RESTART: $($pod.metadata.name) - $($container.name) restarted $($container.restartCount) times" -ForegroundColor Yellow
                }
            }
        }
        
        Start-Sleep -Seconds 5
    }
}

# Test 1: Extreme Memory Stress (Likely to cause OOM)
Write-Host "`nTest 1: Extreme Memory Stress (OOM Test)" -ForegroundColor Green
Write-Host "This should cause Out of Memory kills..." -ForegroundColor Gray

# Create test pods
Write-Host "Creating test pods..." -ForegroundColor Cyan
go run main.go test_pods.go chaos_types.go -create -count=3 -namespace=default

# Apply extreme memory stress
Write-Host "Applying extreme memory stress..." -ForegroundColor Cyan
Start-Job -ScriptBlock {
    go run main.go test_pods.go chaos_types.go -chaos-type=in-pod-memory-stress -intensity=10 -duration=60s -namespace=default
}

# Monitor for failures
Monitor-PodsDuringStress -namespace "default" -duration 70

Write-Host "`nMemory Stress Test Results:" -ForegroundColor Yellow
kubectl get pods -n default
kubectl describe pods -n default | Select-String -Pattern "OOM|Killed|Exit Code"

# Test 2: Process Killing (Likely to cause crashes)
Write-Host "`nTest 2: Process Killing Chaos" -ForegroundColor Green
Write-Host "This should kill random processes and cause crashes..." -ForegroundColor Gray

# Create fresh test pods
Write-Host "Creating fresh test pods..." -ForegroundColor Cyan
go run main.go test_pods.go chaos_types.go -create -count=2 -namespace=default

# Apply process killing chaos
Write-Host "Applying process killing chaos..." -ForegroundColor Cyan
Start-Job -ScriptBlock {
    go run main.go test_pods.go chaos_types.go -chaos-type=kill-process -intensity=5 -duration=30s -namespace=default
}

# Monitor for failures
Monitor-PodsDuringStress -namespace "default" -duration 40

Write-Host "`nProcess Killing Test Results:" -ForegroundColor Yellow
kubectl get pods -n default
kubectl logs -n default -l app=test-pod --tail=20

# Test 3: Memory Corruption (Most aggressive)
Write-Host "`nTest 3: Memory Corruption Chaos" -ForegroundColor Green
Write-Host "This is the most aggressive test - may cause crashes..." -ForegroundColor Gray

# Create fresh test pods
Write-Host "Creating fresh test pods..." -ForegroundColor Cyan
go run main.go test_pods.go chaos_types.go -create -count=1 -namespace=default

# Apply memory corruption chaos
Write-Host "Applying memory corruption chaos..." -ForegroundColor Cyan
Start-Job -ScriptBlock {
    go run main.go test_pods.go chaos_types.go -chaos-type=corrupt-memory -intensity=3 -duration=20s -namespace=default
}

# Monitor for failures
Monitor-PodsDuringStress -namespace "default" -duration 30

Write-Host "`nMemory Corruption Test Results:" -ForegroundColor Yellow
kubectl get pods -n default
kubectl describe pods -n default | Select-String -Pattern "CrashLoopBackOff|Error|Failed"

# Test 4: Network Chaos (if available)
Write-Host "`nTest 4: Network Latency Chaos" -ForegroundColor Green
Write-Host "This should cause network timeouts..." -ForegroundColor Gray

# Create fresh test pods
Write-Host "Creating fresh test pods..." -ForegroundColor Cyan
go run main.go test_pods.go chaos_types.go -create -count=2 -namespace=default

# Apply network chaos
Write-Host "Applying network latency chaos..." -ForegroundColor Cyan
Start-Job -ScriptBlock {
    go run main.go test_pods.go chaos_types.go -chaos-type=network-latency -intensity=7 -duration=45s -namespace=default
}

# Monitor for failures
Monitor-PodsDuringStress -namespace "default" -duration 50

# Summary
Write-Host "`nFAILURE TEST SUMMARY" -ForegroundColor Yellow
Write-Host "=====================" -ForegroundColor Yellow

Write-Host "`nChecking for failures across all tests:" -ForegroundColor Cyan

# Check for failed pods
$failedPods = kubectl get pods -n default -o json | ConvertFrom-Json | Where-Object { $_.status.phase -eq "Failed" }
if ($failedPods) {
    Write-Host "FAILED PODS FOUND:" -ForegroundColor Red
    foreach ($pod in $failedPods) {
        Write-Host "  - $($pod.metadata.name)" -ForegroundColor Red
    }
} else {
    Write-Host "✅ No failed pods found" -ForegroundColor Green
}

# Check for restarted containers
$restartedPods = kubectl get pods -n default -o json | ConvertFrom-Json | Where-Object { 
    $_.status.containerStatuses | Where-Object { $_.restartCount -gt 0 }
}
if ($restartedPods) {
    Write-Host "PODS WITH RESTARTS:" -ForegroundColor Yellow
    foreach ($pod in $restartedPods) {
        foreach ($container in $pod.status.containerStatuses) {
            if ($container.restartCount -gt 0) {
                Write-Host "  - $($pod.metadata.name): $($container.name) restarted $($container.restartCount) times" -ForegroundColor Yellow
            }
        }
    }
} else {
    Write-Host "✅ No container restarts found" -ForegroundColor Green
}

# Check for CrashLoopBackOff
$crashLoopPods = kubectl get pods -n default -o json | ConvertFrom-Json | Where-Object { 
    $_.status.containerStatuses | Where-Object { $_.state.waiting.reason -eq "CrashLoopBackOff" }
}
if ($crashLoopPods) {
    Write-Host "CRASH LOOP PODS:" -ForegroundColor Red
    foreach ($pod in $crashLoopPods) {
        Write-Host "  - $($pod.metadata.name)" -ForegroundColor Red
    }
} else {
    Write-Host "✅ No crash loop pods found" -ForegroundColor Green
}

Write-Host "`nFAILURE SCENARIOS DEMONSTRATED:" -ForegroundColor Yellow
Write-Host "1. Out of Memory (OOM) kills - Pods terminated by Kubernetes" -ForegroundColor Gray
Write-Host "2. Process crashes - Random processes killed, containers restart" -ForegroundColor Gray
Write-Host "3. Memory corruption - Application crashes or becomes unstable" -ForegroundColor Gray
Write-Host "4. Network timeouts - Services become unresponsive" -ForegroundColor Gray

Write-Host "`nCleaning up test pods..." -ForegroundColor Cyan
go run main.go test_pods.go chaos_types.go -cleanup -namespace=default

Write-Host "`nFailure testing completed!" -ForegroundColor Green 