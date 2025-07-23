#!/bin/bash

# Simple local build test

echo "Testing local Docker build..."
echo "============================="

# Build with current Dockerfile
echo "Building image..."
if docker build -t r4.4.0:local .; then
    echo ""
    echo "✅ Build succeeded!"
    echo ""
    echo "Testing basic functionality..."
    docker run --rm r4.4.0:local R --version
    echo ""
    echo "Testing BiocManager..."
    docker run --rm r4.4.0:local Rscript -e "library(BiocManager); cat('BiocManager version:', as.character(BiocManager::version()), '\n')"
    echo ""
    echo "Testing key packages..."
    docker run --rm r4.4.0:local Rscript -e "library(Seurat); library(CellChat); cat('Seurat and CellChat loaded successfully!\n')"
else
    echo ""
    echo "❌ Build failed"
    exit 1
fi

echo ""
echo "Local test complete!"