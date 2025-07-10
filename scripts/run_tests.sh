#!/bin/bash

# Chaos Monkey Test Runner (Bash Version)
# Simple script to run the test suite from the main directory

NAMESPACE=${1:-"chaos-test"}
CLEANUP_ONLY=${2:-false}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Show help
show_help() {
    echo -e "${CYAN}🎭 Chaos Monkey Test Runner${NC}"
    echo -e "${WHITE}Usage:${NC}"
    echo -e "  ./run_tests.sh                    # Run all tests with default namespace"
    echo -e "  ./run_tests.sh my-test            # Run tests with custom namespace"
    echo -e "  ./run_tests.sh my-test true       # Cleanup test resources only"
    echo -e "  ./run_tests.sh help               # Show this help"
    exit 0
}

# Check for help
if [ "$1" = "help" ]; then
    show_help
fi

echo -e "${CYAN}🎭 Starting Chaos Monkey Test Suite...${NC}"

# Check if we're in the right directory
if [ ! -f "main.go" ]; then
    echo -e "${RED}❌ Error: main.go not found. Please run this script from the kubechaos directory.${NC}"
    exit 1
fi

# Check if tests directory exists
if [ ! -f "tests/test_scenarios.sh" ]; then
    echo -e "${RED}❌ Error: Test scenarios not found. Please ensure tests directory exists.${NC}"
    exit 1
fi

# Make test script executable
chmod +x "tests/test_scenarios.sh"

# Run the test suite
echo -e "${GREEN}🚀 Executing test scenarios...${NC}"
./tests/test_scenarios.sh "$NAMESPACE" "$CLEANUP_ONLY"

echo -e "\n${CYAN}🎉 Test runner completed!${NC}" 