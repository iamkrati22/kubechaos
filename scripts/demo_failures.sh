#!/bin/bash

# Demo Failures Script - Shows how Chaos Monkey can cause actual failures
# This script demonstrates the most aggressive failure scenarios

echo "🧪 Chaos Monkey - Failure Demonstration"
echo "======================================"

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to check if pods are failing
check_pod_failures() {
    local namespace=$1
    echo -e "${CYAN}🔍 Checking for pod failures in $namespace...${NC}"
    
    # Check for failed pods
    failed_pods=$(kubectl get pods -n $namespace -o json | jq -r '.items[] | select(.status.phase == "Failed") | .metadata.name')
    if [ ! -z "$failed_pods" ]; then
        echo -e "${RED}💥 FAILED PODS:${NC}"
        echo "$failed_pods" | while read pod; do
            echo -e "  - ${RED}$pod${NC}"
        done
    fi
    
    # Check for restarted containers
    restarted=$(kubectl get pods -n $namespace -o json | jq -r '.items[] | select(.status.containerStatuses[].restartCount > 0) | .metadata.name')
    if [ ! -z "$restarted" ]; then
        echo -e "${YELLOW}🔄 PODS WITH RESTARTS:${NC}"
        echo "$restarted" | while read pod; do
            echo -e "  - ${YELLOW}$pod${NC}"
        done
    fi
    
    # Check for CrashLoopBackOff
    crash_loop=$(kubectl get pods -n $namespace -o json | jq -r '.items[] | select(.status.containerStatuses[].state.waiting.reason == "CrashLoopBackOff") | .metadata.name')
    if [ ! -z "$crash_loop" ]; then
        echo -e "${RED}💥 CRASH LOOP PODS:${NC}"
        echo "$crash_loop" | while read pod; do
            echo -e "  - ${RED}$pod${NC}"
        done
    fi
}

# Test 1: Extreme Memory Stress (Most likely to cause OOM)
echo -e "\n${GREEN}🧪 Test 1: Extreme Memory Stress (OOM Killer)${NC}"
echo "This should cause Out of Memory kills..."

# Create test pods
echo -e "${CYAN}Creating test pods...${NC}"
go run main.go test_pods.go chaos_types.go -create -count=3 -namespace=default

# Apply extreme memory stress
echo -e "${CYAN}Applying extreme memory stress (intensity 10)...${NC}"
go run main.go test_pods.go chaos_types.go -chaos-type=in-pod-memory-stress -intensity=10 -duration=60s -namespace=default &
CHAOS_PID=$!

# Monitor for 70 seconds
echo -e "${CYAN}Monitoring for failures...${NC}"
sleep 70

# Check results
check_pod_failures "default"

# Test 2: Process Killing (Likely to cause crashes)
echo -e "\n${GREEN}🧪 Test 2: Process Killing Chaos${NC}"
echo "This should kill random processes and cause crashes..."

# Create fresh test pods
echo -e "${CYAN}Creating fresh test pods...${NC}"
go run main.go test_pods.go chaos_types.go -create -count=2 -namespace=default

# Apply process killing chaos
echo -e "${CYAN}Applying process killing chaos...${NC}"
go run main.go test_pods.go chaos_types.go -chaos-type=kill-process -intensity=5 -duration=30s -namespace=default &
CHAOS_PID=$!

# Monitor for 40 seconds
echo -e "${CYAN}Monitoring for failures...${NC}"
sleep 40

# Check results
check_pod_failures "default"

# Test 3: Memory Corruption (Most aggressive)
echo -e "\n${GREEN}🧪 Test 3: Memory Corruption Chaos${NC}"
echo "This is the most aggressive test - may cause crashes..."

# Create fresh test pods
echo -e "${CYAN}Creating fresh test pods...${NC}"
go run main.go test_pods.go chaos_types.go -create -count=1 -namespace=default

# Apply memory corruption chaos
echo -e "${CYAN}Applying memory corruption chaos...${NC}"
go run main.go test_pods.go chaos_types.go -chaos-type=corrupt-memory -intensity=3 -duration=20s -namespace=default &
CHAOS_PID=$!

# Monitor for 30 seconds
echo -e "${CYAN}Monitoring for failures...${NC}"
sleep 30

# Check results
check_pod_failures "default"

# Test 4: Mixed Stress (Combination attack)
echo -e "\n${GREEN}🧪 Test 4: Mixed Stress Attack${NC}"
echo "Combining CPU and memory stress for maximum impact..."

# Create fresh test pods
echo -e "${CYAN}Creating fresh test pods...${NC}"
go run main.go test_pods.go chaos_types.go -create -count=2 -namespace=default

# Apply mixed stress chaos
echo -e "${CYAN}Applying mixed stress chaos...${NC}"
go run main.go test_pods.go chaos_types.go -chaos-type=in-pod-mixed-stress -intensity=8 -duration=45s -namespace=default &
CHAOS_PID=$!

# Monitor for 50 seconds
echo -e "${CYAN}Monitoring for failures...${NC}"
sleep 50

# Check results
check_pod_failures "default"

# Final Summary
echo -e "\n${YELLOW}📋 FAILURE DEMONSTRATION SUMMARY${NC}"
echo "======================================"

echo -e "\n${CYAN}🔍 Final status check:${NC}"
kubectl get pods -n default

echo -e "\n${YELLOW}🎯 FAILURE SCENARIOS DEMONSTRATED:${NC}"
echo "1. ${RED}Out of Memory (OOM) kills${NC} - Pods terminated by Kubernetes"
echo "2. ${YELLOW}Process crashes${NC} - Random processes killed, containers restart"
echo "3. ${RED}Memory corruption${NC} - Application crashes or becomes unstable"
echo "4. ${YELLOW}Mixed resource stress${NC} - Combined CPU and memory pressure"

echo -e "\n${CYAN}🧹 Cleaning up test pods...${NC}"
go run main.go test_pods.go chaos_types.go -cleanup -namespace=default

echo -e "\n${GREEN}✅ Failure demonstration completed!${NC}"

echo -e "\n${YELLOW}💡 TIPS FOR CAUSING MORE FAILURES:${NC}"
echo "- Increase intensity to 10 for maximum stress"
echo "- Use longer durations (2m, 5m) for sustained pressure"
echo "- Combine multiple chaos types in sequence"
echo "- Target pods with limited resources"
echo "- Run on nodes with high resource utilization" 