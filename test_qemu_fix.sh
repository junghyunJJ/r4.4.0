#!/bin/bash

# Test script for QEMU emulation fix
# Tests the binary package installation approach

echo "Creating test Dockerfile for QEMU fix..."

# Create a temporary test Dockerfile
cat > Dockerfile.qemu-test << 'EOF'
FROM rocker/r-ver:4.4.0

# Install minimal system dependencies
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Test binary package installation (QEMU fix)
RUN R -e "options(repos = c(CRAN = 'https://cloud.r-project.org/')); \
          options(pkgType = 'binary'); \
          install.packages(c('remotes', 'BiocManager', 'reticulate'), type='binary'); \
          library(BiocManager); \
          BiocManager::install(version='3.19', ask=FALSE, update=FALSE)"

# Verify installation
RUN R -e "library(BiocManager); \
          cat('BiocManager version:', as.character(BiocManager::version()), '\n'); \
          cat('Available packages:', length(available.packages()[,1]), '\n')"
EOF

echo "Testing ARM64 build with QEMU..."
echo "================================"

# Ensure buildx is available
if ! docker buildx version >/dev/null 2>&1; then
    echo "Setting up Docker buildx..."
    docker buildx create --name qemu-test --use
fi

# Test ARM64 build specifically
echo "Building for linux/arm64..."
if docker buildx build --platform=linux/arm64 -f Dockerfile.qemu-test -t qemu-test:arm64 --load . 2>&1; then
    echo ""
    echo "✅ ARM64 build succeeded with binary packages!"
    echo ""
    echo "Testing package installation..."
    docker run --rm --platform=linux/arm64 qemu-test:arm64 R -e "library(BiocManager); sessionInfo()"
else
    echo ""
    echo "❌ ARM64 build failed"
    echo ""
    echo "Trying alternative: separate build steps..."
    
    # Alternative approach: split installation steps
    cat > Dockerfile.qemu-test2 << 'EOF'
FROM rocker/r-ver:4.4.0

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Step 1: Install BiocManager separately
RUN R -e "install.packages('BiocManager', repos='https://cloud.r-project.org/', type='binary')"

# Step 2: Set Bioconductor version
RUN R -e "library(BiocManager); BiocManager::install(version='3.19', ask=FALSE, update=FALSE)"

# Step 3: Install other packages
RUN R -e "install.packages(c('remotes', 'reticulate'), repos='https://cloud.r-project.org/', type='binary')"
EOF

    echo "Testing alternative approach..."
    docker buildx build --platform=linux/arm64 -f Dockerfile.qemu-test2 -t qemu-test2:arm64 .
fi

# Clean up
rm -f Dockerfile.qemu-test Dockerfile.qemu-test2

# Remove buildx builder if we created it
if docker buildx ls | grep -q qemu-test; then
    docker buildx rm qemu-test
fi

echo ""
echo "Test complete!"
echo ""
echo "Recommendations:"
echo "1. The main Dockerfile has been updated to use binary packages"
echo "2. GitHub Actions workflow now includes QEMU setup"
echo "3. If issues persist, consider building platforms separately"