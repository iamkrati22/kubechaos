# Demo Failures Script - Shows how Chaos Monkey can cause actual failures
# This script demonstrates the most aggressive failure scenarios

Write-Host "🧪 Chaos Monkey - Failure Demonstration" -ForegroundColor Yellow
Write-Host "======================================" -ForegroundColor Yellow

# Function to check if pods are failing
function Check-PodFailures {
    param($namespace)
    
    Write-Host "🔍 Checking for pod failures in $namespace..." -ForegroundColor Cyan
    
    # Check for failed pods
    $failedPods = kubectl get pods -n $namespace -o json | ConvertFrom-Json | Where-Object { $_.status.phase -eq "Failed" }
    if ($failedPods) {
        Write-Host "💥 FAILED PODS:" -ForegroundColor Red
        foreach ($pod in $failedPods) {
            Write-Host "  - $($pod.metadata.name)" -ForegroundColor Red
        }
    }
    
    # Check for restarted containers
    $restartedPods = kubectl get pods -n $namespace -o json | ConvertFrom-Json | Where-Object { 
        $_.status.containerStatuses | Where-Object { $_.restartCount -gt 0 }
    }
    if ($restartedPods) {
        Write-Host "🔄 PODS WITH RESTARTS:" -ForegroundColor Yellow
        foreach ($pod in $restartedPods) {
            foreach ($container in $pod.status.containerStatuses) {
                if ($container.restartCount -gt 0) {
                    Write-Host "  - $($pod.metadata.name): $($container.name) restarted $($container.restartCount) times" -ForegroundColor Yellow
                }
            }
        }
    }
    
    # Check for CrashLoopBackOff
    $crashLoopPods = kubectl get pods -n $namespace -o json | ConvertFrom-Json | Where-Object { 
        $_.status.containerStatuses | Where-Object { $_.state.waiting.reason -eq "CrashLoopBackOff" }
    }
    if ($crashLoopPods) {
        Write-Host "💥 CRASH LOOP PODS:" -ForegroundColor Red
        foreach ($pod in $crashLoopPods) {
            Write-Host "  - $($pod.metadata.name)" -ForegroundColor Red
        }
    }
}

# Test 1: Extreme Memory Stress (Most likely to cause OOM)
Write-Host "`n🧪 Test 1: Extreme Memory Stress (OOM Killer)" -ForegroundColor Green
Write-Host "This should cause Out of Memory kills..." -ForegroundColor Gray

# Create test pods
Write-Host "Creating test pods..." -ForegroundColor Cyan
go run main.go test_pods.go chaos_types.go -create -count=3 -namespace=default

# Apply extreme memory stress
Write-Host "Applying extreme memory stress (intensity 10)..." -ForegroundColor Cyan
Start-Job -ScriptBlock {
    go run main.go test_pods.go chaos_types.go -chaos-type=in-pod-memory-stress -intensity=10 -duration=60s -namespace=default
}

# Monitor for 70 seconds
Write-Host "Monitoring for failures..." -ForegroundColor Cyan
Start-Sleep -Seconds 70

# Check results
Check-PodFailures -namespace "default"

# Test 2: Process Killing (Likely to cause crashes)
Write-Host "`n🧪 Test 2: Process Killing Chaos" -ForegroundColor Green
Write-Host "This should kill random processes and cause crashes..." -ForegroundColor Gray

# Create fresh test pods
Write-Host "Creating fresh test pods..." -ForegroundColor Cyan
go run main.go test_pods.go chaos_types.go -create -count=2 -namespace=default

# Apply process killing chaos
Write-Host "Applying process killing chaos..." -ForegroundColor Cyan
Start-Job -ScriptBlock {
    go run main.go test_pods.go chaos_types.go -chaos-type=kill-process -intensity=5 -duration=30s -namespace=default
}

# Monitor for 40 seconds
Write-Host "Monitoring for failures..." -ForegroundColor Cyan
Start-Sleep -Seconds 40

# Check results
Check-PodFailures -namespace "default"

# Test 3: Memory Corruption (Most aggressive)
Write-Host "`n🧪 Test 3: Memory Corruption Chaos" -ForegroundColor Green
Write-Host "This is the most aggressive test - may cause crashes..." -ForegroundColor Gray

# Create fresh test pods
Write-Host "Creating fresh test pods..." -ForegroundColor Cyan
go run main.go test_pods.go chaos_types.go -create -count=1 -namespace=default

# Apply memory corruption chaos
Write-Host "Applying memory corruption chaos..." -ForegroundColor Cyan
Start-Job -ScriptBlock {
    go run main.go test_pods.go chaos_types.go -chaos-type=corrupt-memory -intensity=3 -duration=20s -namespace=default
}

# Monitor for 30 seconds
Write-Host "Monitoring for failures..." -ForegroundColor Cyan
Start-Sleep -Seconds 30

# Check results
Check-PodFailures -namespace "default"

# Test 4: Mixed Stress (Combination attack)
Write-Host "`n🧪 Test 4: Mixed Stress Attack" -ForegroundColor Green
Write-Host "Combining CPU and memory stress for maximum impact..." -ForegroundColor Gray

# Create fresh test pods
Write-Host "Creating fresh test pods..." -ForegroundColor Cyan
go run main.go test_pods.go chaos_types.go -create -count=2 -namespace=default

# Apply mixed stress chaos
Write-Host "Applying mixed stress chaos..." -ForegroundColor Cyan
Start-Job -ScriptBlock {
    go run main.go test_pods.go chaos_types.go -chaos-type=in-pod-mixed-stress -intensity=8 -duration=45s -namespace=default
}

# Monitor for 50 seconds
Write-Host "Monitoring for failures..." -ForegroundColor Cyan
Start-Sleep -Seconds 50

# Check results
Check-PodFailures -namespace "default"

# Final Summary
Write-Host "`n📋 FAILURE DEMONSTRATION SUMMARY" -ForegroundColor Yellow
Write-Host "======================================" -ForegroundColor Yellow

Write-Host "`n🔍 Final status check:" -ForegroundColor Cyan
kubectl get pods -n default

Write-Host "`n🎯 FAILURE SCENARIOS DEMONSTRATED:" -ForegroundColor Yellow
Write-Host "1. Out of Memory (OOM) kills - Pods terminated by Kubernetes" -ForegroundColor Gray
Write-Host "2. Process crashes - Random processes killed, containers restart" -ForegroundColor Gray
Write-Host "3. Memory corruption - Application crashes or becomes unstable" -ForegroundColor Gray
Write-Host "4. Mixed resource stress - Combined CPU and memory pressure" -ForegroundColor Gray

Write-Host "`n🧹 Cleaning up test pods..." -ForegroundColor Cyan
go run main.go test_pods.go chaos_types.go -cleanup -namespace=default

Write-Host "`n✅ Failure demonstration completed!" -ForegroundColor Green

Write-Host "`n💡 TIPS FOR CAUSING MORE FAILURES:" -ForegroundColor Yellow
Write-Host "- Increase intensity to 10 for maximum stress" -ForegroundColor Gray
Write-Host "- Use longer durations (2m, 5m) for sustained pressure" -ForegroundColor Gray
Write-Host "- Combine multiple chaos types in sequence" -ForegroundColor Gray
Write-Host "- Target pods with limited resources" -ForegroundColor Gray
Write-Host "- Run on nodes with high resource utilization" -ForegroundColor Gray 