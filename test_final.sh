#!/bin/bash

# Final test script for both platforms

echo "Final Docker build test for both platforms"
echo "=========================================="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Ensure buildx is available
if ! docker buildx version >/dev/null 2>&1; then
    echo "Setting up Docker buildx..."
    docker buildx create --name final-test --use
fi

# Test both platforms
echo -e "${YELLOW}Building for linux/amd64 and linux/arm64...${NC}"
echo ""

if docker buildx build --platform=linux/amd64,linux/arm64 -t r4.4.0:multiplatform .; then
    echo ""
    echo -e "${GREEN}✅ Multi-platform build succeeded!${NC}"
    echo ""
    echo "Image details:"
    docker buildx imagetools inspect r4.4.0:multiplatform 2>/dev/null || echo "Note: Image inspection requires push to registry"
    
    echo ""
    echo -e "${GREEN}SUCCESS: Ready for GitHub Actions!${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Commit and push changes"
    echo "2. GitHub Actions will build and push to Docker Hub"
    echo "3. Both AMD64 and ARM64 users can use the image"
else
    echo ""
    echo -e "${RED}❌ Multi-platform build failed${NC}"
    exit 1
fi

# Cleanup
if docker buildx ls | grep -q final-test; then
    docker buildx rm final-test
fi

echo ""
echo "Test complete!"