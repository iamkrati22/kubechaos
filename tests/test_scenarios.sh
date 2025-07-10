#!/bin/bash

# Chaos Monkey Test Suite (Bash Version)
# This script tests all functionality of the chaos monkey tool

NAMESPACE=${1:-"chaos-test"}
CLEANUP_ONLY=${2:-false}

echo "🎭 Chaos Monkey Test Suite"
echo "================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
NC='\033[0m' # No Color

# Function to run a test
test_scenario() {
    local name="$1"
    local command="$2"
    local description="$3"
    
    echo -e "\n🧪 Testing: $name"
    if [ -n "$description" ]; then
        echo -e "   $description"
    fi
    echo -e "   Command: $command"
    
    if eval "$command" > /tmp/chaos_test_output 2>&1; then
        echo -e "   ${GREEN}✅ PASSED${NC}"
        if [ -s /tmp/chaos_test_output ]; then
            echo -e "   Output: $(cat /tmp/chaos_test_output)"
        fi
        return 0
    else
        echo -e "   ${RED}❌ FAILED (Exit code: $?)${NC}"
        echo -e "   Error: $(cat /tmp/chaos_test_output)"
        return 1
    fi
}

# Function to check if namespace exists
namespace_exists() {
    kubectl get namespace "$1" --no-headers >/dev/null 2>&1
}

# Function to create test namespace
create_test_namespace() {
    if ! namespace_exists "$1"; then
        echo -e "📦 Creating test namespace: $1"
        kubectl create namespace "$1"
    else
        echo -e "📦 Test namespace already exists: $1"
    fi
}

# Function to create test deployments
create_test_deployments() {
    echo -e "🚀 Creating test deployments..."
    
    # Create nginx deployment
    if kubectl create deployment nginx --image=nginx:alpine -n "$1" >/dev/null 2>&1; then
        echo -e "   ${GREEN}✅ Created nginx deployment${NC}"
    fi
    
    # Create redis deployment
    if kubectl create deployment redis --image=redis:alpine -n "$1" >/dev/null 2>&1; then
        echo -e "   ${GREEN}✅ Created redis deployment${NC}"
    fi
    
    # Create postgres deployment
    if kubectl create deployment postgres --image=postgres:alpine -n "$1" >/dev/null 2>&1; then
        echo -e "   ${GREEN}✅ Created postgres deployment${NC}"
    fi
    
    # Wait for pods to be ready
    echo -e "⏳ Waiting for pods to be ready..."
    sleep 10
}

# Function to cleanup test resources
cleanup_test_resources() {
    echo -e "🧹 Cleaning up test resources..."
    
    # Delete namespace (this will delete all resources in it)
    kubectl delete namespace "$1" --ignore-not-found=true >/dev/null 2>&1
    echo -e "   ${GREEN}✅ Deleted namespace: $1${NC}"
}

# Main test execution
if [ "$CLEANUP_ONLY" = "true" ]; then
    echo -e "${YELLOW}🧹 Cleanup mode - removing test resources only${NC}"
    cleanup_test_resources "$NAMESPACE"
    exit 0
fi

# Setup test environment
create_test_namespace "$NAMESPACE"
create_test_deployments "$NAMESPACE"

# Test Results tracking
declare -a test_results
total_tests=0
passed_tests=0

# Test 1: Help command
((total_tests++))
if test_scenario "Help Command" "go run main.go test_pods.go -help" "Test help command displays correctly"; then
    ((passed_tests++))
    test_results+=("Help Command: PASS")
else
    test_results+=("Help Command: FAIL")
fi

# Test 2: Dry run mode
((total_tests++))
if test_scenario "Dry Run Mode" "go run main.go test_pods.go -namespace=$NAMESPACE -dry-run" "Test dry-run shows what would be deleted without actually deleting"; then
    ((passed_tests++))
    test_results+=("Dry Run Mode: PASS")
else
    test_results+=("Dry Run Mode: FAIL")
fi

# Test 3: Create test pods
((total_tests++))
if test_scenario "Create Test Pods" "go run main.go test_pods.go -namespace=$NAMESPACE -create -count=2" "Test creating test pods"; then
    ((passed_tests++))
    test_results+=("Create Test Pods: PASS")
else
    test_results+=("Create Test Pods: FAIL")
fi

# Test 4: Delete single pod
((total_tests++))
if test_scenario "Delete Single Pod" "go run main.go test_pods.go -namespace=$NAMESPACE -delete-count=1" "Test deleting a single random pod"; then
    ((passed_tests++))
    test_results+=("Delete Single Pod: PASS")
else
    test_results+=("Delete Single Pod: FAIL")
fi

# Test 5: Delete multiple pods
((total_tests++))
if test_scenario "Delete Multiple Pods" "go run main.go test_pods.go -namespace=$NAMESPACE -delete-count=2" "Test deleting multiple random pods"; then
    ((passed_tests++))
    test_results+=("Delete Multiple Pods: PASS")
else
    test_results+=("Delete Multiple Pods: FAIL")
fi

# Test 6: Label filtering
((total_tests++))
if test_scenario "Label Filtering" "go run main.go test_pods.go -namespace=$NAMESPACE -labels='app=nginx' -dry-run" "Test filtering pods by labels"; then
    ((passed_tests++))
    test_results+=("Label Filtering: PASS")
else
    test_results+=("Label Filtering: FAIL")
fi

# Test 7: Cleanup test pods
((total_tests++))
if test_scenario "Cleanup Test Pods" "go run main.go test_pods.go -namespace=$NAMESPACE -cleanup" "Test cleaning up test pods created by chaos monkey"; then
    ((passed_tests++))
    test_results+=("Cleanup Test Pods: PASS")
else
    test_results+=("Cleanup Test Pods: FAIL")
fi

# Test 8: Invalid namespace
((total_tests++))
if test_scenario "Invalid Namespace" "go run main.go test_pods.go -namespace=non-existent-namespace" "Test behavior with non-existent namespace"; then
    ((passed_tests++))
    test_results+=("Invalid Namespace: PASS")
else
    test_results+=("Invalid Namespace: FAIL")
fi

# Test 9: No pods scenario
((total_tests++))
if test_scenario "No Pods Scenario" "go run main.go test_pods.go -namespace=$NAMESPACE -labels='app=nonexistent' -dry-run" "Test behavior when no pods match criteria"; then
    ((passed_tests++))
    test_results+=("No Pods Scenario: PASS")
else
    test_results+=("No Pods Scenario: FAIL")
fi

# Test 10: Create and delete in one run
((total_tests++))
if test_scenario "Create and Delete" "go run main.go test_pods.go -namespace=$NAMESPACE -create -count=3 -delete-count=1" "Test creating pods and then deleting one in the same run"; then
    ((passed_tests++))
    test_results+=("Create and Delete: PASS")
else
    test_results+=("Create and Delete: FAIL")
fi

# Print test summary
echo -e "\n📊 Test Summary"
echo -e "==============="
echo -e "Total Tests: $total_tests"
echo -e "Passed: ${GREEN}$passed_tests${NC}"
echo -e "Failed: ${RED}$((total_tests - passed_tests))${NC}"
echo -e "Success Rate: ${CYAN}$(echo "scale=2; $passed_tests * 100 / $total_tests" | bc -l)%${NC}"

# Print detailed results
echo -e "\n📋 Detailed Results:"
for result in "${test_results[@]}"; do
    if [[ $result == *": PASS" ]]; then
        echo -e "   ${GREEN}✅ $result${NC}"
    else
        echo -e "   ${RED}❌ $result${NC}"
    fi
done

# Cleanup
echo -e "\n🧹 Cleaning up test environment..."
cleanup_test_resources "$NAMESPACE"

echo -e "\n🎉 Test suite completed!"

# Clean up temp file
rm -f /tmp/chaos_test_output 