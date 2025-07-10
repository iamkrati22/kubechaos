# 📜 Scripts Directory

This directory contains all the automation and utility scripts for the Chaos Monkey project.

## 📁 Script Categories

### **Build Scripts**
- `build.sh` - Cross-platform build script for Linux/macOS
- `create_release.ps1` - PowerShell script to create release packages

### **Installation Scripts**
- `install.sh` - Unix/Linux installation script
- `install.ps1` - Windows PowerShell installation script

### **Test Scripts**
- `run_tests.sh` - Unix/Linux test runner
- `run_tests.ps1` - Windows PowerShell test runner

### **Demo Scripts**
- `demo_failures.sh` - Unix/Linux failure demonstration
- `demo_failures.ps1` - Windows PowerShell failure demonstration
- `demo_real_app_failures.sh` - Unix/Linux real app testing
- `demo_real_app_failures.ps1` - Windows PowerShell real app testing
- `test_failures.ps1` - Windows PowerShell failure testing

## 🚀 Usage

### **Build and Release**
```bash
# Build for all platforms
./scripts/build.sh

# Create release packages (Windows)
./scripts/create_release.ps1
```

### **Installation**
```bash
# Unix/Linux
./scripts/install.sh

# Windows
./scripts/install.ps1
```

### **Testing**
```bash
# Unix/Linux
./scripts/run_tests.sh

# Windows
./scripts/run_tests.ps1
```

### **Demo Scenarios**
```bash
# Unix/Linux
./scripts/demo_failures.sh
./scripts/demo_real_app_failures.sh

# Windows
./scripts/demo_failures.ps1
./scripts/demo_real_app_failures.ps1
./scripts/test_failures.ps1
``` 