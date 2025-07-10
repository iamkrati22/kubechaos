# Demo Real App Failures Script - Shows how Chaos Monkey can cause actual failures on real application pods
# This script demonstrates chaos testing on the nginx deployment

Write-Host "Chaos Monkey - Real Application Failure Demonstration" -ForegroundColor Yellow
Write-Host "=====================================================" -ForegroundColor Yellow

# Function to check if pods are failing
function Check-PodFailures {
    param($namespace, $labelSelector)
    
    Write-Host "Checking for pod failures in $namespace with labels: $labelSelector..." -ForegroundColor Cyan
    
    # Check for failed pods
    $failedPods = kubectl get pods -n $namespace -l $labelSelector -o json | ConvertFrom-Json | Where-Object { $_.status.phase -eq "Failed" }
    if ($failedPods) {
        Write-Host "FAILED PODS:" -ForegroundColor Red
        foreach ($pod in $failedPods) {
            Write-Host "  - $($pod.metadata.name)" -ForegroundColor Red
        }
    }
    
    # Check for restarted containers
    $restartedPods = kubectl get pods -n $namespace -l $labelSelector -o json | ConvertFrom-Json | Where-Object { 
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
    }
    
    # Check for CrashLoopBackOff
    $crashLoopPods = kubectl get pods -n $namespace -l $labelSelector -o json | ConvertFrom-Json | Where-Object { 
        $_.status.containerStatuses | Where-Object { $_.state.waiting.reason -eq "CrashLoopBackOff" }
    }
    if ($crashLoopPods) {
        Write-Host "CRASH LOOP PODS:" -ForegroundColor Red
        foreach ($pod in $crashLoopPods) {
            Write-Host "  - $($pod.metadata.name)" -ForegroundColor Red
        }
    }
}

# Function to monitor pods during stress
function Monitor-RealAppPods {
    param($namespace, $labelSelector, $duration = 60)
    
    Write-Host "Monitoring real app pods for $duration seconds..." -ForegroundColor Cyan
    
    $startTime = Get-Date
    $endTime = $startTime.AddSeconds($duration)
    
    while ((Get-Date) -lt $endTime) {
        $pods = kubectl get pods -n $namespace -l $labelSelector -o json | ConvertFrom-Json
        
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

# Show current nginx deployment status
Write-Host "Current nginx deployment status:" -ForegroundColor Green
kubectl get pods -l app=nginx

# Test 1: CPU Stress on Real Nginx Pods
Write-Host "`nTest 1: CPU Stress on Real Nginx Pods" -ForegroundColor Green
Write-Host "This should cause CPU pressure on nginx containers..." -ForegroundColor Gray

# Apply CPU stress to nginx pods
Write-Host "Applying CPU stress to nginx pods..." -ForegroundColor Cyan
Start-Job -ScriptBlock {
    go run main.go test_pods.go chaos_types.go -chaos-type=in-pod-cpu-stress -intensity=7 -duration=60s -labels="app=nginx"
}

# Monitor for 70 seconds
Write-Host "Monitoring nginx pods for failures..." -ForegroundColor Cyan
Start-Sleep -Seconds 70

# Check results
Check-PodFailures -namespace "default" -labelSelector "app=nginx"

# Test 2: Memory Stress on Real Nginx Pods
Write-Host "`nTest 2: Memory Stress on Real Nginx Pods" -ForegroundColor Green
Write-Host "This should cause memory pressure on nginx containers..." -ForegroundColor Gray

# Apply memory stress to nginx pods
Write-Host "Applying memory stress to nginx pods..." -ForegroundColor Cyan
Start-Job -ScriptBlock {
    go run main.go test_pods.go chaos_types.go -chaos-type=in-pod-memory-stress -intensity=6 -duration=45s -labels="app=nginx"
}

# Monitor for 50 seconds
Write-Host "Monitoring nginx pods for failures..." -ForegroundColor Cyan
Start-Sleep -Seconds 50

# Check results
Check-PodFailures -namespace "default" -labelSelector "app=nginx"

# Test 3: Process Killing on Real Nginx Pods
Write-Host "`nTest 3: Process Killing on Real Nginx Pods" -ForegroundColor Green
Write-Host "This should kill random processes in nginx containers..." -ForegroundColor Gray

# Apply process killing to nginx pods
Write-Host "Applying process killing to nginx pods..." -ForegroundColor Cyan
Start-Job -ScriptBlock {
    go run main.go test_pods.go chaos_types.go -chaos-type=kill-process -intensity=3 -duration=30s -labels="app=nginx"
}

# Monitor for 40 seconds
Write-Host "Monitoring nginx pods for failures..." -ForegroundColor Cyan
Start-Sleep -Seconds 40

# Check results
Check-PodFailures -namespace "default" -labelSelector "app=nginx"

# Test 4: Mixed Stress on Real Nginx Pods
Write-Host "`nTest 4: Mixed Stress on Real Nginx Pods" -ForegroundColor Green
Write-Host "Combining CPU and memory stress for maximum impact..." -ForegroundColor Gray

# Apply mixed stress to nginx pods
Write-Host "Applying mixed stress to nginx pods..." -ForegroundColor Cyan
Start-Job -ScriptBlock {
    go run main.go test_pods.go chaos_types.go -chaos-type=in-pod-mixed-stress -intensity=5 -duration=40s -labels="app=nginx"
}

# Monitor for 50 seconds
Write-Host "Monitoring nginx pods for failures..." -ForegroundColor Cyan
Start-Sleep -Seconds 50

# Check results
Check-PodFailures -namespace "default" -labelSelector "app=nginx"

# Test 5: Cron-based Chaos on Real Nginx Pods
Write-Host "`nTest 5: Cron-based Chaos on Real Nginx Pods" -ForegroundColor Green
Write-Host "Running chaos every 30 seconds for 2 minutes..." -ForegroundColor Gray

# Start cron-based chaos
Write-Host "Starting cron-based chaos..." -ForegroundColor Cyan
$cronJob = Start-Job -ScriptBlock {
    go run main.go test_pods.go chaos_types.go -cron="*/30 * * * * *" -chaos-type=in-pod-cpu-stress -intensity=4 -labels="app=nginx"
}

# Monitor for 2 minutes
Write-Host "Monitoring nginx pods during cron chaos..." -ForegroundColor Cyan
Start-Sleep -Seconds 120

# Stop the cron job
Stop-Job $cronJob
Remove-Job $cronJob

# Check results
Check-PodFailures -namespace "default" -labelSelector "app=nginx"

# Final Summary
Write-Host "`nREAL APP FAILURE DEMONSTRATION SUMMARY" -ForegroundColor Yellow
Write-Host "=========================================" -ForegroundColor Yellow

Write-Host "`nFinal nginx deployment status:" -ForegroundColor Cyan
kubectl get pods -l app=nginx

Write-Host "`nNginx pod details:" -ForegroundColor Cyan
kubectl describe pods -l app=nginx | Select-String -Pattern "Events:|Restart Count:|Last State:|Reason:"

Write-Host "`nFAILURE SCENARIOS DEMONSTRATED ON REAL APP:" -ForegroundColor Yellow
Write-Host "1. CPU stress on nginx containers" -ForegroundColor Gray
Write-Host "2. Memory stress on nginx containers" -ForegroundColor Gray
Write-Host "3. Process killing in nginx containers" -ForegroundColor Gray
Write-Host "4. Mixed resource stress on nginx containers" -ForegroundColor Gray
Write-Host "5. Cron-based periodic chaos on nginx containers" -ForegroundColor Gray

Write-Host "`nReal application chaos testing completed!" -ForegroundColor Green

Write-Host "`nTIPS FOR REAL APP CHAOS TESTING:" -ForegroundColor Yellow
Write-Host "- Start with low intensity (1-3) for real apps" -ForegroundColor Gray
Write-Host "- Use shorter durations (15-30s) initially" -ForegroundColor Gray
Write-Host "- Monitor application health during chaos" -ForegroundColor Gray
Write-Host "- Have rollback plan ready (kubectl rollout restart)" -ForegroundColor Gray
Write-Host "- Test on non-critical services first" -ForegroundColor Gray 