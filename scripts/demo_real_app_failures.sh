#!/bin/bash

# Demo Real App Failures Script - Shows how Chaos Monkey can cause actual failures on real application pods
# This script demonstrates chaos testing on the nginx deployment

echo "Chaos Monkey - Real Application Failure Demonstration"
echo "===================================================="

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to check if pods are failing
check_pod_failures() {
    local namespace=$1
    local label_selector=$2
    
    echo -e "${CYAN}Checking for pod failures in $namespace with labels: $label_selector...${NC}"
    
    # Check for failed pods
    failed_pods=$(kubectl get pods -n $namespace -l $label_selector -o json | jq -r '.items[] | select(.status.phase == "Failed") | .metadata.name')
    if [ ! -z "$failed_pods" ]; then
        echo -e "${RED}FAILED PODS:${NC}"
        echo "$failed_pods" | while read pod; do
            echo -e "  - ${RED}$pod${NC}"
        done
    fi
    
    # Check for restarted containers
    restarted=$(kubectl get pods -n $namespace -l $label_selector -o json | jq -r '.items[] | select(.status.containerStatuses[].restartCount > 0) | .metadata.name')
    if [ ! -z "$restarted" ]; then
        echo -e "${YELLOW}PODS WITH RESTARTS:${NC}"
        echo "$restarted" | while read pod; do
            echo -e "  - ${YELLOW}$pod${NC}"
        done
    fi
    
    # Check for CrashLoopBackOff
    crash_loop=$(kubectl get pods -n $namespace -l $label_selector -o json | jq -r '.items[] | select(.status.containerStatuses[].state.waiting.reason == "CrashLoopBackOff") | .metadata.name')
    if [ ! -z "$crash_loop" ]; then
        echo -e "${RED}CRASH LOOP PODS:${NC}"
        echo "$crash_loop" | while read pod; do
            echo -e "  - ${RED}$pod${NC}"
        done
    fi
}

# Function to monitor pods during stress
monitor_real_app_pods() {
    local namespace=$1
    local label_selector=$2
    local duration=${3:-60}
    
    echo -e "${CYAN}Monitoring real app pods for $duration seconds...${NC}"
    
    local start_time=$(date +%s)
    local end_time=$((start_time + duration))
    
    while [ $(date +%s) -lt $end_time ]; do
        pods=$(kubectl get pods -n $namespace -l $label_selector -o json | jq -r '.items[] | .metadata.name')
        
        for pod in $pods; do
            status=$(kubectl get pod $pod -n $namespace -o json | jq -r '.status.phase')
            if [ "$status" = "Failed" ]; then
                echo -e "${RED}POD FAILED: $pod${NC}"
            fi
            
            restart_count=$(kubectl get pod $pod -n $namespace -o json | jq -r '.status.containerStatuses[0].restartCount')
            if [ "$restart_count" -gt 0 ]; then
                echo -e "${YELLOW}RESTART: $pod restarted $restart_count times${NC}"
            fi
        done
        
        sleep 5
    done
}

# Show current nginx deployment status
echo -e "\n${GREEN}Current nginx deployment status:${NC}"
kubectl get pods -l app=nginx

# Test 1: CPU Stress on Real Nginx Pods
echo -e "\n${GREEN}Test 1: CPU Stress on Real Nginx Pods${NC}"
echo "This should cause CPU pressure on nginx containers..."

# Apply CPU stress to nginx pods
echo -e "${CYAN}Applying CPU stress to nginx pods...${NC}"
go run main.go test_pods.go chaos_types.go -chaos-type=in-pod-cpu-stress -intensity=7 -duration=60s -labels="app=nginx" &
CHAOS_PID=$!

# Monitor for 70 seconds
echo -e "${CYAN}Monitoring nginx pods for failures...${NC}"
sleep 70

# Check results
check_pod_failures "default" "app=nginx"

# Test 2: Memory Stress on Real Nginx Pods
echo -e "\n${GREEN}Test 2: Memory Stress on Real Nginx Pods${NC}"
echo "This should cause memory pressure on nginx containers..."

# Apply memory stress to nginx pods
echo -e "${CYAN}Applying memory stress to nginx pods...${NC}"
go run main.go test_pods.go chaos_types.go -chaos-type=in-pod-memory-stress -intensity=6 -duration=45s -labels="app=nginx" &
CHAOS_PID=$!

# Monitor for 50 seconds
echo -e "${CYAN}Monitoring nginx pods for failures...${NC}"
sleep 50

# Check results
check_pod_failures "default" "app=nginx"

# Test 3: Process Killing on Real Nginx Pods
echo -e "\n${GREEN}Test 3: Process Killing on Real Nginx Pods${NC}"
echo "This should kill random processes in nginx containers..."

# Apply process killing to nginx pods
echo -e "${CYAN}Applying process killing to nginx pods...${NC}"
go run main.go test_pods.go chaos_types.go -chaos-type=kill-process -intensity=3 -duration=30s -labels="app=nginx" &
CHAOS_PID=$!

# Monitor for 40 seconds
echo -e "${CYAN}Monitoring nginx pods for failures...${NC}"
sleep 40

# Check results
check_pod_failures "default" "app=nginx"

# Test 4: Mixed Stress on Real Nginx Pods
echo -e "\n${GREEN}Test 4: Mixed Stress on Real Nginx Pods${NC}"
echo "Combining CPU and memory stress for maximum impact..."

# Apply mixed stress to nginx pods
echo -e "${CYAN}Applying mixed stress to nginx pods...${NC}"
go run main.go test_pods.go chaos_types.go -chaos-type=in-pod-mixed-stress -intensity=5 -duration=40s -labels="app=nginx" &
CHAOS_PID=$!

# Monitor for 50 seconds
echo -e "${CYAN}Monitoring nginx pods for failures...${NC}"
sleep 50

# Check results
check_pod_failures "default" "app=nginx"

# Test 5: Cron-based Chaos on Real Nginx Pods
echo -e "\n${GREEN}Test 5: Cron-based Chaos on Real Nginx Pods${NC}"
echo "Running chaos every 30 seconds for 2 minutes..."

# Start cron-based chaos
echo -e "${CYAN}Starting cron-based chaos...${NC}"
go run main.go test_pods.go chaos_types.go -cron="*/30 * * * * *" -chaos-type=in-pod-cpu-stress -intensity=4 -labels="app=nginx" &
CRON_PID=$!

# Monitor for 2 minutes
echo -e "${CYAN}Monitoring nginx pods during cron chaos...${NC}"
sleep 120

# Stop the cron job
kill $CRON_PID 2>/dev/null

# Check results
check_pod_failures "default" "app=nginx"

# Final Summary
echo -e "\n${YELLOW}REAL APP FAILURE DEMONSTRATION SUMMARY${NC}"
echo "========================================="

echo -e "\n${CYAN}Final nginx deployment status:${NC}"
kubectl get pods -l app=nginx

echo -e "\n${CYAN}Nginx pod details:${NC}"
kubectl describe pods -l app=nginx | grep -E "Events:|Restart Count:|Last State:|Reason:"

echo -e "\n${YELLOW}FAILURE SCENARIOS DEMONSTRATED ON REAL APP:${NC}"
echo "1. CPU stress on nginx containers" | sed 's/^/  /'
echo "2. Memory stress on nginx containers" | sed 's/^/  /'
echo "3. Process killing in nginx containers" | sed 's/^/  /'
echo "4. Mixed resource stress on nginx containers" | sed 's/^/  /'
echo "5. Cron-based periodic chaos on nginx containers" | sed 's/^/  /'

echo -e "\n${GREEN}Real application chaos testing completed!${NC}"

echo -e "\n${YELLOW}TIPS FOR REAL APP CHAOS TESTING:${NC}"
echo "- Start with low intensity (1-3) for real apps" | sed 's/^/  /'
echo "- Use shorter durations (15-30s) initially" | sed 's/^/  /'
echo "- Monitor application health during chaos" | sed 's/^/  /'
echo "- Have rollback plan ready (kubectl rollout restart)" | sed 's/^/  /'
echo "- Test on non-critical services first" | sed 's/^/  /' 