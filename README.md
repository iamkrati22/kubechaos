# KubeChaos

A powerful **CLI tool** for Kubernetes chaos engineering that tests application resilience through various failure scenarios.

[![Go Version](https://img.shields.io/badge/Go-1.21+-blue.svg)](https://golang.org)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20Linux%20%7C%20macOS-lightgrey.svg)]()

## Features

- **Multiple Chaos Types**: CPU stress, memory stress, process killing, memory corruption
- **In-Pod Chaos**: Execute chaos directly inside target pods
- **Cron Scheduling**: Periodic chaos triggers with custom schedules
- **Label Filtering**: Target specific pods by labels
- **Dry-Run Mode**: Preview what would happen without execution
- **Health Monitoring**: Real-time pod health monitoring during chaos
- **Cross-Platform CLI**: Windows, Linux, and macOS support
- **Docker Support**: Run as a container
- **CLI Tool**: Full command-line interface with help and version commands

## Installation Methods

### **Method 1: Direct Download (Recommended)**

#### **Windows**
```powershell
# Download the latest release
Invoke-WebRequest -Uri "https://github.com/iamkrati22/kubechaos/releases/latest/download/kubechaos-windows-amd64.exe" -OutFile "kubechaos.exe"

# Add to PATH (optional)
Move-Item kubechaos.exe "$env:USERPROFILE\AppData\Local\Microsoft\WinGet\Packages\"
```

#### **Linux/macOS**
```bash
# Download the latest release
curl -L -o kubechaos https://github.com/iamkrati22/kubechaos/releases/latest/download/kubechaos-linux-amd64
chmod +x kubechaos

# Move to PATH (optional)
sudo mv kubechaos /usr/local/bin/
```

### **Method 2: Build from Source**

#### **Prerequisites**
- Go 1.21+ installed
- Git installed
- Kubernetes cluster access

#### **Build Steps**
```bash
# Clone the repository
git clone https://github.com/iamkrati22/kubechaos.git
cd kubechaos

# Build for your platform
go build -o kubechaos main.go test_pods.go chaos_types.go version.go

# For Windows
go build -o kubechaos.exe main.go test_pods.go chaos_types.go version.go
```

### **Method 3: Docker**

```bash
# Build Docker image
docker build -t kubechaos docker/

# Run kubechaos in Docker
docker run -v ~/.kube:/home/chaos/.kube:ro kubechaos --help

# Run specific chaos type
docker run -v ~/.kube:/home/chaos/.kube:ro kubechaos -chaos-type=in-pod-cpu-stress -labels="app=nginx"

# Use docker-compose
docker-compose -f docker/docker-compose.yml --profile cpu-stress up
```

### **Method 4: Go Install**

```bash
# Install directly via Go
go install github.com/iamkrati22/kubechaos@latest
```

## CLI Usage

### **Basic Commands**

```bash
# Show help
kubechaos --help

# Show version
kubechaos --version

# List available chaos types
kubechaos --help | grep chaos-type
```

### **Chaos Types Available**

| Chaos Type | Description | Example |
|------------|-------------|---------|
| `pod-delete` | Delete random pods | `kubechaos -chaos-type=pod-delete` |
| `in-pod-cpu-stress` | CPU stress inside pods | `kubechaos -chaos-type=in-pod-cpu-stress` |
| `in-pod-memory-stress` | Memory stress inside pods | `kubechaos -chaos-type=in-pod-memory-stress` |
| `in-pod-mixed-stress` | Combined CPU and memory stress | `kubechaos -chaos-type=in-pod-mixed-stress` |
| `kill-process` | Kill random processes in pods | `kubechaos -chaos-type=kill-process` |
| `corrupt-memory` | Attempt memory corruption | `kubechaos -chaos-type=corrupt-memory` |

### **Command Line Options**

| Flag | Description | Default | Example |
|------|-------------|---------|---------|
| `-namespace` | Target namespace | `default` | `-namespace=production` |
| `-labels` | Label selector | `""` | `-labels="app=nginx"` |
| `-chaos-type` | Type of chaos | `pod-delete` | `-chaos-type=in-pod-cpu-stress` |
| `-intensity` | Chaos intensity (1-10) | `5` | `-intensity=7` |
| `-duration` | Chaos duration | `30s` | `-duration=60s` |
| `-cron` | Cron schedule | `""` | `-cron="*/5 * * * *"` |
| `-probability` | Trigger probability (0.0-1.0) | `0.5` | `-probability=0.3` |
| `-dry-run` | Preview only | `false` | `-dry-run` |
| `-create` | Create test pods | `false` | `-create` |
| `-count` | Number of test pods | `3` | `-count=5` |
| `-cleanup` | Clean up test pods | `false` | `-cleanup` |
| `-help` | Show help | `false` | `--help` |
| `-version` | Show version | `false` | `--version` |

## Usage Examples

### **1. Basic Chaos Testing**

```bash
# CPU stress on nginx pods
kubechaos -chaos-type=in-pod-cpu-stress -labels="app=nginx" -intensity=5 -duration=30s

# Memory stress on database pods
kubechaos -chaos-type=in-pod-memory-stress -labels="app=postgres" -intensity=7 -duration=60s

# Kill random processes
kubechaos -chaos-type=kill-process -labels="app=web" -intensity=3 -duration=20s
```

### **2. Cron-based Chaos**

```bash
# Run chaos every 5 minutes
kubechaos -cron="*/5 * * * *" -chaos-type=in-pod-cpu-stress -labels="app=nginx"

# Run chaos every 30 seconds with 30% probability
kubechaos -cron="*/30 * * * * *" -chaos-type=kill-process -probability=0.3 -labels="app=web"

# Run chaos every hour in production
kubechaos -cron="0 * * * *" -chaos-type=in-pod-mixed-stress -labels="app=web" -namespace=production
```

### **3. Advanced Usage**

```bash
# Dry-run mode (preview only)
kubechaos -chaos-type=pod-delete -dry-run -labels="app=nginx"

# Target specific namespace
kubechaos -namespace=production -chaos-type=in-pod-mixed-stress -labels="app=api"

# Multiple labels
kubechaos -labels="app=web,env=prod,version=v2" -chaos-type=in-pod-memory-stress

# High intensity chaos
kubechaos -chaos-type=in-pod-memory-stress -intensity=10 -duration=120s -labels="app=critical"
```

### **4. Test Pod Management**

```bash
# Create test pods for chaos testing
kubechaos -create -count=5

# Create test pods and apply chaos
kubechaos -create -count=3 -chaos-type=in-pod-cpu-stress -intensity=5

# Clean up test pods
kubechaos -cleanup
```

### **5. Docker Usage**

```bash
# Run kubechaos in Docker
docker run -v ~/.kube:/home/chaos/.kube:ro kubechaos --help

# Run specific chaos type in Docker
docker run -v ~/.kube:/home/chaos/.kube:ro kubechaos -chaos-type=in-pod-cpu-stress -labels="app=nginx"

# Use docker-compose
docker-compose --profile cpu-stress up
```

## Chaos Types Explained

### **Pod Deletion**
```bash
kubechaos -chaos-type=pod-delete -labels="app=nginx"
```
- **What it does**: Deletes random pods
- **Use case**: Test pod restart and recovery
- **Safety**: Use `-dry-run` first

### **CPU Stress**
```bash
kubechaos -chaos-type=in-pod-cpu-stress -intensity=7 -duration=60s
```
- **What it does**: Exhausts CPU resources inside pods
- **Use case**: Test application performance under load
- **Effects**: Slows down applications, may cause timeouts

### **Memory Stress**
```bash
kubechaos -chaos-type=in-pod-memory-stress -intensity=8 -duration=90s
```
- **What it does**: Exhausts memory resources inside pods
- **Use case**: Test OOM handling and memory limits
- **Effects**: May trigger OOM kills, container restarts

### **Process Killing**
```bash
kubechaos -chaos-type=kill-process -intensity=3 -duration=30s
```
- **What it does**: Kills random processes in containers
- **Use case**: Test application crash recovery
- **Effects**: Container restarts, service interruptions

### **Memory Corruption**
```bash
kubechaos -chaos-type=corrupt-memory -intensity=2 -duration=20s
```
- **What it does**: Attempts to corrupt memory
- **Use case**: Test application stability
- **Effects**: Unpredictable crashes, data corruption

## Monitoring & Safety

### **Real-time Monitoring**
```bash
# Watch pod status during chaos
kubectl get pods -w -l app=nginx

# Check for failures
kubectl describe pods -l app=nginx | grep -i "oom\|killed\|restart"

# Monitor logs
kubectl logs -l app=nginx --tail=50 -f
```

### **Safety Guidelines**
```bash
# Always start with dry-run
kubechaos -chaos-type=pod-delete -dry-run -labels="app=nginx"

# Use low intensity initially
kubechaos -chaos-type=in-pod-cpu-stress -intensity=2 -duration=15s

# Test on non-critical services first
kubechaos -namespace=staging -chaos-type=in-pod-memory-stress
```

### **Emergency Stop**
```bash
# Stop all chaos jobs
kubectl delete job -l chaos-type=stress

# Restart critical deployments
kubectl rollout restart deployment/nginx

# Scale down if needed
kubectl scale deployment nginx --replicas=0
```

## Testing Scripts

### **Run Demo Tests**
```bash
# Test on real application pods (PowerShell)
.\scripts\demo_real_app_failures.ps1

# Test on real application pods (Bash)
./scripts/demo_real_app_failures.sh

# Test failure scenarios (PowerShell)
.\scripts\test_failures.ps1

# Test failure scenarios (Bash)
./scripts/demo_failures.sh
```

### **Docker Testing**
```bash
# Run CPU stress test
docker-compose -f docker/docker-compose.yml --profile cpu-stress up

# Run memory stress test
docker-compose -f docker/docker-compose.yml --profile memory-stress up

# Run cron-based chaos
docker-compose -f docker/docker-compose.yml --profile cron-chaos up
```

## Configuration

### **Environment Variables**
```bash
export KUBECONFIG=/path/to/kubeconfig
export CHAOS_MONKEY_LOG_LEVEL=debug
```

### **Configuration File**
Create `~/.kubechaos/config.yaml`:
```yaml
defaults:
  namespace: default
  intensity: 5
  duration: 30s
  probability: 0.5

safety:
  max_pods_per_chaos: 3
  min_ready_pods: 1
  exclude_namespaces:
    - kube-system
    - default
```

## Production Examples

### **Web Application Testing**
```bash
# Test web app resilience
kubechaos -namespace=prod -chaos-type=in-pod-cpu-stress -intensity=6 -duration=120s -labels="app=web"

# Test web app memory handling
kubechaos -namespace=prod -chaos-type=in-pod-memory-stress -intensity=7 -duration=90s -labels="app=web"
```

### **Database Testing**
```bash
# Test database resilience
kubechaos -namespace=prod -chaos-type=in-pod-memory-stress -intensity=7 -duration=90s -labels="app=postgres"

# Test database process recovery
kubechaos -namespace=prod -chaos-type=kill-process -intensity=4 -duration=60s -labels="app=postgres"
```

### **API Gateway Testing**
```bash
# Test API gateway resilience
kubechaos -namespace=prod -chaos-type=kill-process -intensity=4 -duration=60s -labels="app=api-gateway"

# Test API gateway under load
kubechaos -namespace=prod -chaos-type=in-pod-mixed-stress -intensity=5 -duration=120s -labels="app=api-gateway"
```

### **Continuous Chaos Engineering**
```bash
# Run chaos every hour in production
kubechaos -cron="0 * * * *" -chaos-type=in-pod-mixed-stress -intensity=5 -labels="app=web" -probability=0.3

# Run chaos every 30 minutes in staging
kubechaos -cron="*/30 * * * *" -chaos-type=in-pod-cpu-stress -intensity=7 -labels="app=web" -namespace=staging
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

- **Issues**: [GitHub Issues](https://github.com/iamkrati22/kubechaos/issues)
- **Discussions**: [GitHub Discussions](https://github.com/iamkrati22/kubechaos/discussions)
- **Documentation**: [Wiki](https://github.com/iamkrati22/kubechaos/wiki)

## Acknowledgments

- Inspired by Netflix's Chaos Monkey
- Built with Go and Kubernetes client-go
- Community contributions welcome!

---

**Remember: The goal is to test resilience, not destroy production!** ðŸŽ­ 
