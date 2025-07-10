# Multi-stage build for Chaos Monkey
FROM golang:1.21-alpine AS builder

# Install build dependencies
RUN apk add --no-cache git ca-certificates tzdata

# Set working directory
WORKDIR /app

# Copy go mod files
COPY go.mod go.sum ./

# Download dependencies
RUN go mod download

# Copy source code
COPY *.go ./

# Build the application
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o chaos-monkey .

# Final stage
FROM alpine:latest

# Install runtime dependencies
RUN apk --no-cache add ca-certificates tzdata kubectl

# Create non-root user
RUN addgroup -g 1001 -S chaos && \
    adduser -u 1001 -S chaos -G chaos

# Set working directory
WORKDIR /app

# Copy binary from builder stage
COPY --from=builder /app/chaos-monkey .

# Copy scripts
COPY *.sh *.ps1 ./

# Make executable
RUN chmod +x chaos-monkey *.sh

# Change ownership
RUN chown -R chaos:chaos /app

# Switch to non-root user
USER chaos

# Set entrypoint
ENTRYPOINT ["./chaos-monkey"]

# Default command
CMD ["--help"] 