#!/bin/bash
# Unix Build Script for Chaos Monkey
# This script builds and creates checksums for Linux/macOS

echo "🔨 Building Chaos Monkey for Unix..."

# Build the binary
echo "Building binary..."
go build -v -o chaos-monkey-unix-amd64 main.go test_pods.go chaos_types.go version.go

if [ $? -ne 0 ]; then
    echo "❌ Build failed!"
    exit 1
fi

echo "✅ Build completed successfully"

# List the created file
echo "Created files:"
ls -la chaos-monkey-unix-amd64

# Create checksum
echo "Creating checksum..."
if command -v shasum &> /dev/null; then
    shasum -a 256 chaos-monkey-unix-amd64 > checksums.txt
    echo "✅ Checksum created:"
    cat checksums.txt
else
    echo "❌ shasum command not found"
    exit 1
fi

echo "✅ Unix build and checksum completed successfully!" 