# ðŸŽ­ Chaos Monkey

A powerful **CLI tool** for Kubernetes chaos engineering that tests application resilience through various failure scenarios.

[![Go Version](https://img.shields.io/badge/Go-1.21+-blue.svg)](https://golang.org)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20Linux%20%7C%20macOS-lightgrey.svg)]()

## ðŸš€ Features

- **Multiple Chaos Types**: CPU stress, memory stress, process killing, memory corruption
- **In-Pod Chaos**: Execute chaos directly inside target pods
- **Cron Scheduling**: Periodic chaos triggers with custom schedules
- **Label Filtering**: Target specific pods by labels
- **Dry-Run Mode**: Preview what would happen without execution
- **Health Monitoring**: Real-time pod health monitoring during chaos
- **Cross-Platform CLI**: Windows, Linux, and macOS support
- **Docker Support**: Run as a container
- **CLI Tool**: Full command-line interface with help and version commands

## ðŸ“¦ Installation Methods

### **Method 1: Direct Download (Recommended)**

#### **Windows**
```powershell
# Download the latest release
Invoke-WebRequest -Uri "https://github.com/iamkrati22/chaos-monkey/releases/latest/download/chaos-monkey-windows-amd64.exe" -OutFile "chaos-monkey.exe"

# Add to PATH (optional)
Move-Item chaos-monkey.exe "$env:USERPROFILE\AppData\Local\Microsoft\WinGet\Packages\"
```

#### **Linux/macOS**
```bash
# Download the latest release
curl -L -o chaos-monkey https://github.com/iamkrati22/chaos-monkey/releases/latest/download/chaos-monkey-linux-amd64
chmod +x chaos-monkey

# Move to PATH (optional)
sudo mv chaos-monkey /usr/local/bin/
```

### **Method 2: Build from Source**

#### **Prerequisites**
- Go 1.21+ installed
- Git installed
- Kubernetes cluster access

#### **Build Steps**
```bash
# Clone the repository
git clone https://github.com/iamkrati22/chaos-monkey.git
cd chaos-monkey

# Build for your platform
go build -o chaos-monkey main.go test_pods.go chaos_types.go version.go

# For Windows
go build -o chaos-monkey.exe main.go test_pods.go chaos_types.go version.go
```

### **Method 3: Docker**

```bash
# Build Docker image
docker build -t chaos-monkey docker/

# Run chaos-monkey in Docker
docker run -v ~/.kube:/home/chaos/.kube:ro chaos-monkey --help

# Run specific chaos type
docker run -v ~/.kube:/home/chaos/.kube:ro chaos-monkey -chaos-type=in-pod-cpu-stress -labels="app=nginx"

# Use docker-compose
docker-compose -f docker/docker-compose.yml --profile cpu-stress up
```

### **Method 4: Go Install**

```bash
# Install directly via Go
go install github.com/iamkrati22/chaos-monkey@latest
```

## ðŸŽ¯ CLI Usage

### **Basic Commands**

```bash
# Show help
chaos-monkey --help

# Show version
chaos-monkey --version

# List available chaos types
chaos-monkey --help | grep chaos-type
```

### **Chaos Types Available**

| Chaos Type | Description | Example |
|------------|-------------|---------|
| `pod-delete` | Delete random pods | `chaos-monkey -chaos-type=pod-delete` |
| `in-pod-cpu-stress` | CPU stress inside pods | `chaos-monkey -chaos-type=in-pod-cpu-stress` |
| `in-pod-memory-stress` | Memory stress inside pods | `chaos-monkey -chaos-type=in-pod-memory-stress` |
| `in-pod-mixed-stress` | Combined CPU and memory stress | `chaos-monkey -chaos-type=in-pod-mixed-stress` |
| `kill-process` | Kill random processes in pods | `chaos-monkey -chaos-type=kill-process` |
| `corrupt-memory` | Attempt memory corruption | `chaos-monkey -chaos-type=corrupt-memory` |

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

## ðŸ§ª Usage Examples

### **1. Basic Chaos Testing**

```bash
# CPU stress on nginx pods
chaos-monkey -chaos-type=in-pod-cpu-stress -labels="app=nginx" -intensity=5 -duration=30s

# Memory stress on database pods
chaos-monkey -chaos-type=in-pod-memory-stress -labels="app=postgres" -intensity=7 -duration=60s

# Kill random processes
chaos-monkey -chaos-type=kill-process -labels="app=web" -intensity=3 -duration=20s
```

### **2. Cron-based Chaos**

```bash
# Run chaos every 5 minutes
chaos-monkey -cron="*/5 * * * *" -chaos-type=in-pod-cpu-stress -labels="app=nginx"

# Run chaos every 30 seconds with 30% probability
chaos-monkey -cron="*/30 * * * * *" -chaos-type=kill-process -probability=0.3 -labels="app=web"

# Run chaos every hour in production
chaos-monkey -cron="0 * * * *" -chaos-type=in-pod-mixed-stress -labels="app=web" -namespace=production
```

### **3. Advanced Usage**

```bash
# Dry-run mode (preview only)
chaos-monkey -chaos-type=pod-delete -dry-run -labels="app=nginx"

# Target specific namespace
chaos-monkey -namespace=production -chaos-type=in-pod-mixed-stress -labels="app=api"

# Multiple labels
chaos-monkey -labels="app=web,env=prod,version=v2" -chaos-type=in-pod-memory-stress

# High intensity chaos
chaos-monkey -chaos-type=in-pod-memory-stress -intensity=10 -duration=120s -labels="app=critical"
```

### **4. Test Pod Management**

```bash
# Create test pods for chaos testing
chaos-monkey -create -count=5

# Create test pods and apply chaos
chaos-monkey -create -count=3 -chaos-type=in-pod-cpu-stress -intensity=5

# Clean up test pods
chaos-monkey -cleanup
```

### **5. Docker Usage**

```bash
# Run chaos-monkey in Docker
docker run -v ~/.kube:/home/chaos/.kube:ro chaos-monkey --help

# Run specific chaos type in Docker
docker run -v ~/.kube:/home/chaos/.kube:ro chaos-monkey -chaos-type=in-pod-cpu-stress -labels="app=nginx"

# Use docker-compose
docker-compose --profile cpu-stress up
```

## ðŸ”¥ Chaos Types Explained

### **Pod Deletion**
```bash
chaos-monkey -chaos-type=pod-delete -labels="app=nginx"
```
- **What it does**: Deletes random pods
- **Use case**: Test pod restart and recovery
- **Safety**: Use `-dry-run` first

### **CPU Stress**
```bash
chaos-monkey -chaos-type=in-pod-cpu-stress -intensity=7 -duration=60s
```
- **What it does**: Exhausts CPU resources inside pods
- **Use case**: Test application performance under load
- **Effects**: Slows down applications, may cause timeouts

### **Memory Stress**
```bash
chaos-monkey -chaos-type=in-pod-memory-stress -intensity=8 -duration=90s
```
- **What it does**: Exhausts memory resources inside pods
- **Use case**: Test OOM handling and memory limits
- **Effects**: May trigger OOM kills, container restarts

### **Process Killing**
```bash
chaos-monkey -chaos-type=kill-process -intensity=3 -duration=30s
```
- **What it does**: Kills random processes in containers
- **Use case**: Test application crash recovery
- **Effects**: Container restarts, service interruptions

### **Memory Corruption**
```bash
chaos-monkey -chaos-type=corrupt-memory -intensity=2 -duration=20s
```
- **What it does**: Attempts to corrupt memory
- **Use case**: Test application stability
- **Effects**: Unpredictable crashes, data corruption

## ðŸ“Š Monitoring & Safety

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
chaos-monkey -chaos-type=pod-delete -dry-run -labels="app=nginx"

# Use low intensity initially
chaos-monkey -chaos-type=in-pod-cpu-stress -intensity=2 -duration=15s

# Test on non-critical services first
chaos-monkey -namespace=staging -chaos-type=in-pod-memory-stress
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

## ðŸ§ª Testing Scripts

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

## ðŸ”§ Configuration

### **Environment Variables**
```bash
export KUBECONFIG=/path/to/kubeconfig
export CHAOS_MONKEY_LOG_LEVEL=debug
```

### **Configuration File**
Create `~/.chaos-monkey/config.yaml`:
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

## ðŸ“š Production Examples

### **Web Application Testing**
```bash
# Test web app resilience
chaos-monkey -namespace=prod -chaos-type=in-pod-cpu-stress -intensity=6 -duration=120s -labels="app=web"

# Test web app memory handling
chaos-monkey -namespace=prod -chaos-type=in-pod-memory-stress -intensity=7 -duration=90s -labels="app=web"
```

### **Database Testing**
```bash
# Test database resilience
chaos-monkey -namespace=prod -chaos-type=in-pod-memory-stress -intensity=7 -duration=90s -labels="app=postgres"

# Test database process recovery
chaos-monkey -namespace=prod -chaos-type=kill-process -intensity=4 -duration=60s -labels="app=postgres"
```

### **API Gateway Testing**
```bash
# Test API gateway resilience
chaos-monkey -namespace=prod -chaos-type=kill-process -intensity=4 -duration=60s -labels="app=api-gateway"

# Test API gateway under load
chaos-monkey -namespace=prod -chaos-type=in-pod-mixed-stress -intensity=5 -duration=120s -labels="app=api-gateway"
```

### **Continuous Chaos Engineering**
```bash
# Run chaos every hour in production
chaos-monkey -cron="0 * * * *" -chaos-type=in-pod-mixed-stress -intensity=5 -labels="app=web" -probability=0.3

# Run chaos every 30 minutes in staging
chaos-monkey -cron="*/30 * * * *" -chaos-type=in-pod-cpu-stress -intensity=7 -labels="app=web" -namespace=staging
```

## ðŸ¤ Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## ðŸ“„ License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## ðŸ†˜ Support

- **Issues**: [GitHub Issues](https://github.com/iamkrati22/chaos-monkey/issues)
- **Discussions**: [GitHub Discussions](https://github.com/iamkrati22/chaos-monkey/discussions)
- **Documentation**: [Wiki](https://github.com/iamkrati22/chaos-monkey/wiki)

## ðŸ™ Acknowledgments

- Inspired by Netflix's Chaos Monkey
- Built with Go and Kubernetes client-go
- Community contributions welcome!

---

**Remember: The goal is to test resilience, not destroy production systems!** ðŸŽ­ 
