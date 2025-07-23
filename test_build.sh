#!/bin/bash

# Test build script for R4.4.0 Docker image
# Tests both arm64 and amd64 architectures

echo "Testing Docker build for R4.4.0..."
echo "=================================="

# Function to test build for a specific platform
test_platform() {
    local platform=$1
    local tag_suffix=$(echo $platform | sed 's/\//-/g')  # Replace / with -
    echo ""
    echo "Testing $platform build..."
    echo "--------------------------"
    
    # Build with platform specification
    if docker buildx build --platform=$platform -t r4.4.0:test-$tag_suffix .; then
        echo "✅ $platform build succeeded"
        return 0
    else
        echo "❌ $platform build failed"
        return 1
    fi
}

# Ensure buildx is available
if ! docker buildx version >/dev/null 2>&1; then
    echo "Setting up Docker buildx..."
    docker buildx create --use
fi

# Test both platforms
arm64_result=0
amd64_result=0

if [[ "$1" == "--quick" ]]; then
    # Quick test - just build for current architecture
    echo "Quick test - current architecture only"
    docker build -t r4.4.0:0.1 .
else
    # Full test - both architectures
    test_platform "linux/arm64" || arm64_result=1
    test_platform "linux/amd64" || amd64_result=1
    
    echo ""
    echo "Summary:"
    echo "--------"
    [[ $arm64_result -eq 0 ]] && echo "✅ ARM64 build: SUCCESS" || echo "❌ ARM64 build: FAILED"
    [[ $amd64_result -eq 0 ]] && echo "✅ AMD64 build: SUCCESS" || echo "❌ AMD64 build: FAILED"
fi

echo ""
echo "Build test complete!"