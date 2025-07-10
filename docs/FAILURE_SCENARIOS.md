# 🎭 Chaos Monkey - Failure Scenarios

This document explains how the Chaos Monkey tool can cause **actual failures** in Kubernetes pods, not just stress testing.

## 🚨 **WARNING: DESTRUCTIVE OPERATIONS**

The following chaos types can cause **real failures** including:
- Pod crashes and restarts
- Out of Memory (OOM) kills
- Application instability
- Data corruption
- Service unavailability

**Use with extreme caution in production environments!**

---

## 🔥 **Failure Types**

### 1. **Out of Memory (OOM) Kills** 💀
**Chaos Type:** `in-pod-memory-stress`
**How it fails:** Exhausts all available memory, triggering Kubernetes OOM killer

```bash
# High intensity memory stress (most likely to cause OOM)
go run main.go test_pods.go chaos_types.go -chaos-type=in-pod-memory-stress -intensity=10 -duration=60s
```

**What happens:**
- Pod consumes all available memory
- Kubernetes OOM killer terminates the pod
- Container exits with `Exit Code 137`
- Pod status becomes `Failed`

**Failure Indicators:**
```bash
kubectl describe pod <pod-name> | grep -i "oom\|killed\|exit code"
```

### 2. **Process Killing Chaos** 💀
**Chaos Type:** `kill-process`
**How it fails:** Kills random processes inside the container

```bash
# Kill random processes (causes crashes)
go run main.go test_pods.go chaos_types.go -chaos-type=kill-process -intensity=5 -duration=30s
```

**What happens:**
- Random processes are killed with `kill -9`
- Application processes may be terminated
- Container restarts due to process crashes
- Service becomes unavailable

**Failure Indicators:**
```bash
kubectl get pods -o wide  # Look for CrashLoopBackOff
kubectl logs <pod-name>   # Check for crash logs
```

### 3. **Memory Corruption Chaos** 💥
**Chaos Type:** `corrupt-memory`
**How it fails:** Attempts to corrupt memory directly

```bash
# Corrupt memory (most aggressive)
go run main.go test_pods.go chaos_types.go -chaos-type=corrupt-memory -intensity=3 -duration=20s
```

**What happens:**
- Writes random data to memory locations
- Can cause application crashes
- May corrupt application data
- Unpredictable behavior

**Failure Indicators:**
```bash
kubectl describe pod <pod-name> | grep -i "crash\|error\|failed"
```

### 4. **Extreme CPU Stress** 🔥
**Chaos Type:** `in-pod-cpu-stress`
**How it fails:** Exhausts CPU resources, causing timeouts

```bash
# Extreme CPU stress
go run main.go test_pods.go chaos_types.go -chaos-type=in-pod-cpu-stress -intensity=10 -duration=120s
```

**What happens:**
- Application becomes extremely slow
- Health checks timeout
- Pod marked as `NotReady`
- Service unresponsive

### 5. **Mixed Resource Stress** 💥
**Chaos Type:** `in-pod-mixed-stress`
**How it fails:** Combines CPU, memory, and I/O stress

```bash
# Combined stress attack
go run main.go test_pods.go chaos_types.go -chaos-type=in-pod-mixed-stress -intensity=8 -duration=60s
```

**What happens:**
- Multiple resource types stressed simultaneously
- Maximum impact on application stability
- Higher chance of failures
- Complex failure scenarios

---

## 📊 **Failure Monitoring**

### **Built-in Health Monitoring**
The chaos monkey includes health monitoring that detects:

```go
// Failure detection in MonitorPodHealth function
- Pod status changes to "Failed"
- Container restart counts
- Container readiness status
- OOM kill events
- Scheduling failures
```

### **Manual Failure Detection**
```bash
# Check for failed pods
kubectl get pods -o wide | grep Failed

# Check for restarted containers
kubectl get pods -o json | jq '.items[] | select(.status.containerStatuses[].restartCount > 0)'

# Check for OOM kills
kubectl describe pods | grep -i "oom\|killed"

# Check for crash loops
kubectl get pods | grep CrashLoopBackOff
```

---

## 🎯 **Failure Scenarios by Intensity**

### **Low Intensity (1-3)**
- Mild resource pressure
- Temporary slowdowns
- Rare failures

### **Medium Intensity (4-7)**
- Significant resource pressure
- Occasional crashes
- Service degradation

### **High Intensity (8-10)**
- Extreme resource pressure
- Frequent failures
- OOM kills likely
- Application instability

---

## 🧪 **Testing Failure Scenarios**

### **PowerShell Test Script**
```powershell
# Run comprehensive failure tests
.\test_failures.ps1
```

### **Bash Test Script**
```bash
# Run failure demonstration
./demo_failures.sh
```

### **Manual Testing**
```bash
# 1. Create test pods
go run main.go test_pods.go chaos_types.go -create -count=3

# 2. Apply extreme stress
go run main.go test_pods.go chaos_types.go -chaos-type=in-pod-memory-stress -intensity=10 -duration=60s

# 3. Monitor for failures
kubectl get pods -w
```

---

## ⚠️ **Safety Guidelines**

### **Before Running Destructive Chaos**
1. **Backup critical data**
2. **Test in non-production first**
3. **Have rollback plan ready**
4. **Monitor closely during execution**
5. **Set reasonable time limits**

### **Safe Testing Commands**
```bash
# Start with low intensity
go run main.go test_pods.go chaos_types.go -chaos-type=in-pod-cpu-stress -intensity=3 -duration=30s

# Use dry-run first
go run main.go test_pods.go chaos_types.go -chaos-type=pod-delete -dry-run

# Test on isolated namespace
go run main.go test_pods.go chaos_types.go -namespace=chaos-test -chaos-type=in-pod-memory-stress
```

---

## 🔧 **Recovery Procedures**

### **If Pods Crash**
```bash
# Check pod status
kubectl get pods

# View crash logs
kubectl logs <pod-name> --previous

# Restart deployment if needed
kubectl rollout restart deployment/<deployment-name>
```

### **If OOM Kills Occur**
```bash
# Check memory limits
kubectl describe pod <pod-name> | grep -A 5 "Limits"

# Increase memory limits if needed
kubectl patch deployment <deployment-name> -p '{"spec":{"template":{"spec":{"containers":[{"name":"<container-name>","resources":{"limits":{"memory":"1Gi"}}}]}}}}'
```

### **If Services Become Unresponsive**
```bash
# Check service endpoints
kubectl get endpoints <service-name>

# Restart services
kubectl delete pod -l app=<app-label>
```

---

## 📈 **Failure Metrics**

### **Key Metrics to Monitor**
- **Pod restart count**
- **Container crash frequency**
- **OOM kill events**
- **Service response times**
- **Resource utilization**

### **Alerting on Failures**
```bash
# Monitor for failed pods
kubectl get pods --field-selector=status.phase=Failed

# Monitor for restarted containers
kubectl get pods -o json | jq '.items[] | select(.status.containerStatuses[].restartCount > 5)'
```

---

## 🎭 **Advanced Failure Techniques**

### **Combination Attacks**
```bash
# Sequential chaos types
go run main.go test_pods.go chaos_types.go -chaos-type=in-pod-cpu-stress -duration=30s
go run main.go test_pods.go chaos_types.go -chaos-type=in-pod-memory-stress -duration=30s
go run main.go test_pods.go chaos_types.go -chaos-type=kill-process -duration=30s
```

### **Cron-based Chaos**
```bash
# Run chaos every 5 minutes
go run main.go test_pods.go chaos_types.go -cron="*/5 * * * *" -chaos-type=in-pod-mixed-stress -intensity=7
```

### **Targeted Chaos**
```bash
# Target specific pods by labels
go run main.go test_pods.go chaos_types.go -labels="app=critical-service" -chaos-type=in-pod-memory-stress
```

---

## 🚨 **Emergency Stop**

If chaos gets out of control:

```bash
# Stop all chaos jobs
kubectl delete job -l chaos-type=stress

# Clean up test pods
go run main.go test_pods.go chaos_types.go -cleanup

# Restart critical deployments
kubectl rollout restart deployment/<critical-deployment>
```

---

## 📚 **Additional Resources**

- [Kubernetes Pod Lifecycle](https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/)
- [OOM Killer Documentation](https://kubernetes.io/docs/tasks/administer-cluster/out-of-resource/)
- [Container Resource Management](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)

---

**Remember: The goal is to test resilience, not destroy production systems!** 🎭 