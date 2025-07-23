#!/bin/bash

# Test script for BiocManager installation issue
# This script creates a minimal Dockerfile to test the BiocManager fix

echo "Creating test Dockerfile for BiocManager issue..."

# Create a temporary test Dockerfile
cat > Dockerfile.test << 'EOF'
FROM rocker/r-ver:4.4.0

# Install minimal system dependencies
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Test the BiocManager installation fix
RUN R -e "options(repos = c(CRAN = 'https://cloud.r-project.org/')); \
          install.packages(c('BiocManager')); \
          library(BiocManager); \
          BiocManager::install(version='3.19', ask=FALSE, update=FALSE)"

# Verify BiocManager is working
RUN R -e "library(BiocManager); BiocManager::version()"
EOF

echo "Building test image..."
echo "========================"

# Build for current architecture
if docker build -f Dockerfile.test -t biocmanager-test:latest .; then
    echo ""
    echo "✅ Build succeeded!"
    echo ""
    echo "Testing BiocManager..."
    docker run --rm biocmanager-test:latest R -e "library(BiocManager); cat('BiocManager version:', as.character(BiocManager::version()), '\n')"
else
    echo ""
    echo "❌ Build failed!"
fi

# Clean up
rm -f Dockerfile.test

echo ""
echo "Test complete!"