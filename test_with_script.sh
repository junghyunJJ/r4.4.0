#!/bin/bash

# Test build with R script approach

echo "Testing Docker build with R script approach..."
echo "============================================="

# Check if install_biocmanager.R exists
if [ ! -f "install_biocmanager.R" ]; then
    echo "Error: install_biocmanager.R not found!"
    exit 1
fi

# Test local build first
echo "1. Testing local build (current platform)..."
echo "-------------------------------------------"
if docker build -t r4.4.0:script-test .; then
    echo "✅ Local build succeeded!"
    echo ""
    echo "Testing installation..."
    docker run --rm r4.4.0:script-test Rscript -e "library(BiocManager); cat('BiocManager version:', as.character(BiocManager::version()), '\n')"
else
    echo "❌ Local build failed"
    exit 1
fi

echo ""
echo "2. Testing ARM64 build with buildx..."
echo "------------------------------------"
# Ensure buildx is available
if ! docker buildx version >/dev/null 2>&1; then
    echo "Setting up Docker buildx..."
    docker buildx create --name arm-test --use
fi

# Try ARM64 build
if docker buildx build --platform=linux/arm64 -t r4.4.0:arm64-script-test --progress=plain . 2>&1 | tee arm64_build.log; then
    echo ""
    echo "✅ ARM64 build succeeded!"
else
    echo ""
    echo "❌ ARM64 build failed"
    echo "Key errors:"
    grep -A 2 -B 2 "Error\|failed" arm64_build.log | tail -20
fi

# Cleanup
docker rmi r4.4.0:script-test 2>/dev/null
rm -f arm64_build.log

# Remove buildx builder if we created it
if docker buildx ls | grep -q arm-test; then
    docker buildx rm arm-test
fi

echo ""
echo "Test complete!"
echo ""
echo "Recommendation:"
echo "- If local build works but ARM64 fails, use the simplified GitHub Actions workflow"
echo "- Consider building ARM64 images on native ARM64 hardware instead of QEMU"