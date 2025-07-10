# Makefile for Chaos Monkey
# Provides easy commands for building, testing, and installing

.PHONY: help build install test clean docker-build docker-run demo

# Default target
help:
	@echo "ðŸŽ­ Chaos Monkey - Available Commands:"
	@echo ""
	@echo "ðŸ“¦ Build & Install:"
	@echo "  make build          - Build binaries for all platforms"
	@echo "  make install        - Install chaos-monkey globally"
	@echo "  make clean          - Clean build artifacts"
	@echo ""
	@echo "ðŸ³ Docker:"
	@echo "  make docker-build   - Build Docker image"
	@echo "  make docker-run     - Run chaos-monkey in Docker"
	@echo ""
	@echo "ðŸ§ª Testing:"
	@echo "  make test           - Run all tests"
	@echo "  make demo           - Run demo on real app pods"
	@echo ""
	@echo "ðŸ“š Documentation:"
	@echo "  make help           - Show this help message"
	@echo "  make version        - Show version information"

# Build binaries for all platforms
build:
	@echo "ðŸŽ­ Building Chaos Monkey for all platforms..."
	@chmod +x build.sh
	@./scripts/build.sh

# Install globally
install:
	@echo "ðŸ“¦ Installing Chaos Monkey..."
	@if [ "$(OS)" = "Windows_NT" ]; then \
		powershell -ExecutionPolicy Bypass -File scripts/install.ps1; \
	else \
		sudo ./scripts/install.sh; \
	fi

# Clean build artifacts
clean:
	@echo "ðŸ§¹ Cleaning build artifacts..."
	@rm -rf dist/
	@rm -f chaos-monkey
	@rm -f chaos-monkey.exe

# Build Docker image
docker-build:
	@echo "ðŸ³ Building Docker image..."
	@docker build -t chaos-monkey docker/

# Run chaos-monkey in Docker
docker-run:
	@echo "ðŸ³ Running chaos-monkey in Docker..."
	@docker run -v ~/.kube:/home/chaos/.kube:ro chaos-monkey --help

# Run all tests
test:
	@echo "ðŸ§ª Running tests..."
	@if [ "$(OS)" = "Windows_NT" ]; then \
		powershell -ExecutionPolicy Bypass -File scripts/test_failures.ps1; \
	else \
		chmod +x scripts/demo_failures.sh && ./scripts/demo_failures.sh; \
	fi

# Run demo on real app pods
demo:
	@echo "ðŸŽ­ Running demo on real application pods..."
	@if [ "$(OS)" = "Windows_NT" ]; then \
		powershell -ExecutionPolicy Bypass -File scripts/demo_real_app_failures.ps1; \
	else \
		chmod +x scripts/demo_real_app_failures.sh && ./scripts/demo_real_app_failures.sh; \
	fi

# Show version information
version:
	@go run main.go test_pods.go chaos_types.go version.go --version

# Development helpers
dev-build:
	@echo "ðŸ”¨ Building for development..."
	@go build -o chaos-monkey main.go test_pods.go chaos_types.go version.go

dev-run:
	@echo "ðŸš€ Running chaos-monkey..."
	@go run main.go test_pods.go chaos_types.go version.go --help

# Docker Compose helpers
compose-cpu:
	@echo "ðŸ”¥ Running CPU stress test..."
	@docker-compose -f docker/docker-compose.yml --profile cpu-stress up

compose-memory:
	@echo "ðŸ’¾ Running memory stress test..."
	@docker-compose -f docker/docker-compose.yml --profile memory-stress up

compose-cron:
	@echo "â° Running cron-based chaos..."
	@docker-compose -f docker/docker-compose.yml --profile cron-chaos up

# Release helpers
release-build:
	@echo "ðŸ“¦ Building release binaries..."
	@./scripts/build.sh
	@echo "âœ… Release binaries built in dist/ directory"

release-package:
	@echo "ðŸ“¦ Creating release packages..."
	@mkdir -p releases
	@cd dist && tar -czf ../releases/chaos-monkey-linux-amd64.tar.gz chaos-monkey-linux-amd64
	@cd dist && tar -czf ../releases/chaos-monkey-darwin-amd64.tar.gz chaos-monkey-darwin-amd64
	@cd dist && zip ../releases/chaos-monkey-windows-amd64.zip chaos-monkey-windows-amd64.exe
	@echo "âœ… Release packages created in releases/ directory" 
