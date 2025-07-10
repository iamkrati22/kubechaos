#!/bin/bash

# Build script for Chaos Monkey - Multi-platform binary distribution
# This script builds binaries for Windows, Linux, and macOS

echo "🎭 Building Chaos Monkey for multiple platforms..."
echo "================================================"

# Set version
VERSION="1.0.0"
BUILD_DIR="dist"

# Create build directory
mkdir -p $BUILD_DIR

# Build for different platforms
echo "Building for Windows..."
GOOS=windows GOARCH=amd64 go build -o $BUILD_DIR/chaos-monkey-windows-amd64.exe main.go test_pods.go chaos_types.go version.go
GOOS=windows GOARCH=386 go build -o $BUILD_DIR/chaos-monkey-windows-386.exe main.go test_pods.go chaos_types.go version.go

echo "Building for Linux..."
GOOS=linux GOARCH=amd64 go build -o $BUILD_DIR/chaos-monkey-linux-amd64 main.go test_pods.go chaos_types.go version.go
GOOS=linux GOARCH=386 go build -o $BUILD_DIR/chaos-monkey-linux-386 main.go test_pods.go chaos_types.go version.go
GOOS=linux GOARCH=arm64 go build -o $BUILD_DIR/chaos-monkey-linux-arm64 main.go test_pods.go chaos_types.go version.go

echo "Building for macOS..."
GOOS=darwin GOARCH=amd64 go build -o $BUILD_DIR/chaos-monkey-darwin-amd64 main.go test_pods.go chaos_types.go version.go
GOOS=darwin GOARCH=arm64 go build -o $BUILD_DIR/chaos-monkey-darwin-arm64 main.go test_pods.go chaos_types.go version.go

# Create checksums
echo "Creating checksums..."
cd $BUILD_DIR
for file in chaos-monkey-*; do
    if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
        # Windows
        certutil -hashfile "$file" SHA256 > "$file.sha256"
    else
        # Unix-like
        shasum -a 256 "$file" > "$file.sha256"
    fi
done
cd ..

echo "✅ Build completed! Binaries are in the $BUILD_DIR directory"
echo ""
echo "Available binaries:"
ls -la $BUILD_DIR/chaos-monkey-* 