#!/bin/bash

# Test Rscript approach for QEMU compatibility

echo "Testing Rscript approach for ARM64 build..."
echo "=========================================="

# Create minimal test Dockerfile
cat > Dockerfile.rscript-test << 'EOF'
FROM rocker/r-ver:4.4.0

# Minimal dependencies
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Test Rscript approach
RUN Rscript -e "install.packages('BiocManager', repos='https://cloud.r-project.org/')"
RUN Rscript -e "library(BiocManager); BiocManager::install(version='3.19', ask=FALSE, update=FALSE)"
RUN Rscript -e "library(BiocManager); cat('Bioconductor version:', as.character(BiocManager::version()), '\n')"
EOF

# Build test
echo "Building for ARM64..."
if docker buildx build --platform=linux/arm64 -f Dockerfile.rscript-test -t rscript-test:arm64 --progress=plain . 2>&1 | tee build.log; then
    echo ""
    echo "✅ Build succeeded with Rscript!"
else
    echo ""
    echo "❌ Build failed. Checking error..."
    grep -i "error\|exec format" build.log
fi

# Cleanup
rm -f Dockerfile.rscript-test build.log

echo ""
echo "Test complete!"