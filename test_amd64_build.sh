#!/bin/bash

# Test script for AMD64-only build
# This tests the separated build approach to avoid QEMU issues

echo "Testing AMD64-only Docker build..."
echo "=================================="

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if Dockerfile.amd64 exists
if [ ! -f "Dockerfile.amd64" ]; then
    echo -e "${RED}Error: Dockerfile.amd64 not found!${NC}"
    exit 1
fi

# Function to test build
test_build() {
    local dockerfile=$1
    local tag=$2
    local platform=$3
    
    echo ""
    echo "Building with $dockerfile for $platform..."
    echo "----------------------------------------"
    
    if [ -n "$platform" ]; then
        # Build with specific platform
        docker buildx build --platform=$platform -f $dockerfile -t $tag . 2>&1 | tee build_${tag}.log
    else
        # Build for current platform
        docker build -f $dockerfile -t $tag . 2>&1 | tee build_${tag}.log
    fi
    
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        echo -e "${GREEN}✅ Build succeeded for $tag${NC}"
        
        # Test the image
        echo "Testing image functionality..."
        docker run --rm $tag R --version
        docker run --rm $tag Rscript -e "library(BiocManager); cat('BiocManager version:', as.character(BiocManager::version()), '\n')"
        
        return 0
    else
        echo -e "${RED}❌ Build failed for $tag${NC}"
        echo "Error details:"
        grep -i "error\|failed" build_${tag}.log | tail -10
        return 1
    fi
}

# Ensure buildx is available
if ! docker buildx version >/dev/null 2>&1; then
    echo "Setting up Docker buildx..."
    docker buildx create --name test-builder --use
fi

# Test AMD64 build
echo "1. Testing AMD64-specific Dockerfile..."
test_build "Dockerfile.amd64" "r4.4.0:amd64-test" "linux/amd64"
amd64_result=$?

# Test original Dockerfile (for comparison)
echo ""
echo "2. Testing original Dockerfile (current platform only)..."
test_build "Dockerfile" "r4.4.0:original-test" ""
original_result=$?

# Summary
echo ""
echo "========== Build Summary =========="
if [ $amd64_result -eq 0 ]; then
    echo -e "${GREEN}✅ AMD64 build: SUCCESS${NC}"
    echo "   Ready for GitHub Actions deployment"
else
    echo -e "${RED}❌ AMD64 build: FAILED${NC}"
fi

if [ $original_result -eq 0 ]; then
    echo -e "${GREEN}✅ Original build: SUCCESS${NC}"
else
    echo -e "${RED}❌ Original build: FAILED${NC}"
fi

# Cleanup
echo ""
echo "Cleaning up test images..."
docker rmi r4.4.0:amd64-test 2>/dev/null
docker rmi r4.4.0:original-test 2>/dev/null
rm -f build_*.log

# Remove buildx builder if we created it
if docker buildx ls | grep -q test-builder; then
    docker buildx rm test-builder
fi

echo ""
echo "Test complete!"

# Exit with appropriate code
if [ $amd64_result -eq 0 ]; then
    echo ""
    echo "Recommendation: Use Dockerfile.amd64 with GitHub Actions"
    exit 0
else
    exit 1
fi