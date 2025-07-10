# Chaos Monkey Test Suite

This directory contains comprehensive tests for the Chaos Monkey tool that randomly deletes pods in Kubernetes clusters.

## Overview

The test suite validates all functionality of the chaos monkey tool including:
- CLI argument parsing
- Dry-run mode
- Multiple pod deletion
- Label filtering
- Test pod creation
- Cleanup functionality
- Error handling

## Test Files

### `test_scenarios.ps1` (PowerShell)
- Windows-compatible test script
- Colored output with detailed results
- Comprehensive error handling

### `test_scenarios.sh` (Bash)
- Cross-platform bash script
- Compatible with Linux/macOS/Windows (with WSL)
- Similar functionality to PowerShell version

## Running Tests

### PowerShell (Windows)
```powershell
# Run all tests
.\tests\test_scenarios.ps1

# Run with custom namespace
.\tests\test_scenarios.ps1 -Namespace "my-test-namespace"

# Cleanup only
.\tests\test_scenarios.ps1 -CleanupOnly
```

### Bash (Linux/macOS/WSL)
```bash
# Make executable
chmod +x tests/test_scenarios.sh

# Run all tests
./tests/test_scenarios.sh

# Run with custom namespace
./tests/test_scenarios.sh "my-test-namespace"

# Cleanup only
./tests/test_scenarios.sh "my-test-namespace" "true"
```

## Test Scenarios

### 1. Help Command
- **Purpose**: Verify help command displays correctly
- **Command**: `go run main.go test_pods.go -help`
- **Expected**: Help text with all available flags

### 2. Dry Run Mode
- **Purpose**: Test dry-run shows what would be deleted without actually deleting
- **Command**: `go run main.go test_pods.go -namespace=chaos-test -dry-run`
- **Expected**: List of pods that would be deleted

### 3. Create Test Pods
- **Purpose**: Test creating test pods functionality
- **Command**: `go run main.go test_pods.go -namespace=chaos-test -create -count=2`
- **Expected**: 2 test pods created successfully

### 4. Delete Single Pod
- **Purpose**: Test deleting a single random pod
- **Command**: `go run main.go test_pods.go -namespace=chaos-test -delete-count=1`
- **Expected**: One pod deleted successfully

### 5. Delete Multiple Pods
- **Purpose**: Test deleting multiple random pods
- **Command**: `go run main.go test_pods.go -namespace=chaos-test -delete-count=2`
- **Expected**: Two pods deleted successfully

### 6. Label Filtering
- **Purpose**: Test filtering pods by labels
- **Command**: `go run main.go test_pods.go -namespace=chaos-test -labels='app=nginx' -dry-run`
- **Expected**: Only nginx pods listed for deletion

### 7. Cleanup Test Pods
- **Purpose**: Test cleaning up test pods created by chaos monkey
- **Command**: `go run main.go test_pods.go -namespace=chaos-test -cleanup`
- **Expected**: All test pods with `created=chaos-monkey` label deleted

### 8. Invalid Namespace
- **Purpose**: Test behavior with non-existent namespace
- **Command**: `go run main.go test_pods.go -namespace=non-existent-namespace`
- **Expected**: Appropriate error message

### 9. No Pods Scenario
- **Purpose**: Test behavior when no pods match criteria
- **Command**: `go run main.go test_pods.go -namespace=chaos-test -labels='app=nonexistent' -dry-run`
- **Expected**: Message indicating no pods found

### 10. Create and Delete
- **Purpose**: Test creating pods and then deleting one in the same run
- **Command**: `go run main.go test_pods.go -namespace=chaos-test -create -count=3 -delete-count=1`
- **Expected**: 3 pods created, 1 pod deleted

## Test Environment Setup

The test suite automatically:

1. **Creates Test Namespace**: Creates a dedicated namespace for testing
2. **Deploys Test Applications**: Creates nginx, redis, and postgres deployments
3. **Waits for Readiness**: Ensures pods are ready before testing
4. **Cleans Up**: Removes all test resources after completion

## Prerequisites

- Kubernetes cluster (minikube, kind, or cloud cluster)
- `kubectl` configured and working
- Go 1.21+ installed
- PowerShell (for .ps1 script) or Bash (for .sh script)

## Troubleshooting

### Common Issues

1. **Permission Denied** (Bash script)
   ```bash
   chmod +x tests/test_scenarios.sh
   ```

2. **Execution Policy** (PowerShell)
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

3. **Namespace Already Exists**
   - The script handles this automatically
   - Use cleanup mode to remove existing namespace

4. **Pods Not Ready**
   - The script waits 10 seconds for pods to be ready
   - Increase wait time in script if needed

### Manual Cleanup

If tests fail and leave resources behind:

```bash
# Delete test namespace
kubectl delete namespace chaos-test --ignore-not-found=true

# Or use cleanup mode
./tests/test_scenarios.sh "chaos-test" "true"
```

## Expected Output

Successful test run should show:
- ✅ All tests passing
- 📊 Test summary with success rate
- 🧹 Cleanup completed
- 🎉 Test suite completed

## Contributing

When adding new features to the chaos monkey tool:

1. Add corresponding test scenarios
2. Update this README with new test descriptions
3. Ensure both PowerShell and Bash scripts are updated
4. Test on different platforms if possible 