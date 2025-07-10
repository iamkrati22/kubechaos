# ðŸš€ GitHub Repository Setup Guide

This guide will help you set up the Chaos Monkey GitHub repository and create releases.

## ðŸ“‹ Prerequisites

- GitHub account
- Git installed locally
- GitHub CLI (optional but recommended)

## ðŸ”§ Step 1: Create GitHub Repository

### **Option A: Using GitHub CLI**
```bash
# Install GitHub CLI if not installed
# Windows: winget install GitHub.cli
# macOS: brew install gh
# Linux: sudo apt install gh

# Login to GitHub
gh auth login

# Create repository
gh repo create chaos-monkey --public --description "A powerful CLI tool for Kubernetes chaos engineering" --source=. --remote=origin --push
```

### **Option B: Using GitHub Web Interface**
1. Go to [GitHub.com](https://github.com)
2. Click "New repository"
3. Repository name: `chaos-monkey`
4. Description: `A powerful CLI tool for Kubernetes chaos engineering`
5. Make it Public
6. **Don't** initialize with README (we already have one)
7. Click "Create repository"

## ðŸ”§ Step 2: Initialize Local Repository

```bash
# Initialize git repository
git init

# Add all files
git add .

# Create initial commit
git commit -m "Initial commit: Chaos Monkey CLI tool for Kubernetes"

# Add remote origin (replace iamkrati22 with your GitHub username)
git remote add origin https://github.com/iamkrati22/chaos-monkey.git

# Push to GitHub
git push -u origin main
```

## ðŸ”§ Step 3: Create Release

### **Option A: Using GitHub CLI**
```bash
# Create a new release
gh release create v1.0.0 \
  --title "Chaos Monkey v1.0.0" \
  --notes "Initial release of Chaos Monkey CLI tool for Kubernetes chaos engineering" \
  --prerelease=false \
  --draft=false \
  releases/*.zip \
  releases/*.tar.gz \
  releases/*.ps1 \
  releases/*.sh
```

### **Option B: Using GitHub Web Interface**
1. Go to your repository on GitHub
2. Click "Releases" in the right sidebar
3. Click "Create a new release"
4. Tag version: `v1.0.0`
5. Release title: `Chaos Monkey v1.0.0`
6. Description:
```markdown
## ðŸŽ­ Chaos Monkey v1.0.0

Initial release of the Chaos Monkey CLI tool for Kubernetes chaos engineering.

### Features
- Multiple chaos types (CPU stress, memory stress, process killing, etc.)
- In-pod chaos execution
- Cron-based scheduling
- Label filtering
- Dry-run mode
- Health monitoring
- Cross-platform support (Windows, Linux, macOS)
- Docker support

### Downloads
- **Windows**: Download `chaos-monkey-windows-amd64.zip` or `chaos-monkey-windows-386.zip`
- **Linux**: Download `chaos-monkey-linux-amd64.tar.gz`, `chaos-monkey-linux-386.tar.gz`, or `chaos-monkey-linux-arm64.tar.gz`
- **macOS**: Download `chaos-monkey-darwin-amd64.tar.gz` or `chaos-monkey-darwin-arm64.tar.gz`

### Installation
- **Windows**: Run `install-windows.ps1`
- **Linux/macOS**: Run `install-unix.sh`

### Quick Start
```bash
# Show help
chaos-monkey --help

# CPU stress on nginx pods
chaos-monkey -chaos-type=in-pod-cpu-stress -labels="app=nginx"

# Memory stress with cron
chaos-monkey -cron="*/5 * * * *" -chaos-type=in-pod-memory-stress -labels="app=web"
```
```
7. Upload all files from the `releases/` directory
8. Click "Publish release"

## ðŸ”§ Step 4: Update README with Download Links

After creating the release, update the README.md with the correct download links:

```markdown
# Update these URLs in README.md


## ðŸ“¦ Installation Methods

### **Method 1: Direct Download (Recommended)**

#### **Windows**
```powershell
# Download the latest release
Invoke-WebRequest -Uri "https://github.com/iamkrati22/chaos-monkey/releases/latest/download/chaos-monkey-windows-amd64.zip" -OutFile "chaos-monkey.zip"
Expand-Archive chaos-monkey.zip -DestinationPath .
```

#### **Linux/macOS**
```bash
# Download the latest release
curl -L -o chaos-monkey.tar.gz https://github.com/iamkrati22/chaos-monkey/releases/latest/download/chaos-monkey-linux-amd64.tar.gz
tar -xzf chaos-monkey.tar.gz
chmod +x chaos-monkey
```
```

## ðŸ”§ Step 5: Enable GitHub Actions

The repository includes GitHub Actions for automated builds. To enable:

1. Go to your repository on GitHub
2. Click "Actions" tab
3. Click "Enable Actions"
4. The workflow will automatically run when you push tags

### **Create a new release with automated builds:**
```bash
# Create and push a new tag
git tag v1.0.1
git push origin v1.0.1

# This will trigger the GitHub Actions workflow
# The workflow will build binaries and create a release
```

## ðŸ”§ Step 6: Repository Settings

### **Enable Issues and Discussions**
1. Go to repository Settings
2. Scroll down to "Features"
3. Enable:
   - Issues
   - Discussions
   - Wiki (optional)

### **Add Repository Topics**
Add these topics to your repository:
- `kubernetes`
- `chaos-engineering`
- `cli`
- `go`
- `devops`
- `testing`
- `resilience`

### **Add Repository Description**
```
A powerful CLI tool for Kubernetes chaos engineering that tests application resilience through various failure scenarios.
```

## ðŸ”§ Step 7: Create Release Script

Create a script to automate releases:

```bash
#!/bin/bash
# release.sh - Automated release script

VERSION=$1
if [ -z "$VERSION" ]; then
    echo "Usage: ./release.sh <version>"
    echo "Example: ./release.sh v1.0.1"
    exit 1
fi

echo "Creating release $VERSION..."

# Build release package
./create_release.ps1

# Create git tag
git add .
git commit -m "Release $VERSION"
git tag $VERSION
git push origin main
git push origin $VERSION

# Create GitHub release
gh release create $VERSION \
  --title "Chaos Monkey $VERSION" \
  --notes "Release $VERSION of Chaos Monkey CLI tool" \
  releases/*.zip \
  releases/*.tar.gz \
  releases/*.ps1 \
  releases/*.sh

echo "Release $VERSION created successfully!"
```

## ðŸ“Š Repository Analytics

After setting up, you can track:

### **GitHub Insights**
- Traffic (clones, views)
- Contributors
- Stars and forks
- Release downloads

### **Metrics to Monitor**
- Number of releases
- Download counts
- Issue resolution time
- Community engagement

## ðŸŽ¯ Next Steps

1. **Documentation**: Add more examples and use cases
2. **Testing**: Add unit tests and integration tests
3. **CI/CD**: Enhance GitHub Actions workflow
4. **Community**: Engage with users and contributors
5. **Features**: Add new chaos types and capabilities

## ðŸ”— Useful Links

- [GitHub CLI Documentation](https://cli.github.com/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Go Modules Documentation](https://golang.org/doc/modules)
- [Kubernetes Client-Go](https://github.com/kubernetes/client-go)

## ðŸ†˜ Troubleshooting

### **Common Issues**

**Issue**: Build fails on GitHub Actions
**Solution**: Check Go version compatibility and dependencies

**Issue**: Release files not uploaded
**Solution**: Ensure files exist in releases/ directory before creating release

**Issue**: CLI tool not working
**Solution**: Check Kubernetes cluster access and kubeconfig

**Issue**: Permission denied on installation
**Solution**: Use sudo for Unix systems or run as administrator on Windows

---

**Happy Chaos Engineering! ðŸŽ­** 
