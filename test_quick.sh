#!/bin/bash

# Quick test for the fixed Dockerfile

echo "Quick test of fixed Dockerfile..."
echo "================================"

# Test just the BiocManager installation steps
cat > Dockerfile.test-quick << 'EOF'
FROM rocker/r-ver:4.4.0

# Minimal dependencies
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Test the fixed installation
RUN Rscript -e "install.packages('BiocManager', repos='https://cloud.r-project.org/')"
RUN Rscript -e "library(BiocManager); BiocManager::install(version='3.19', ask=FALSE, update=FALSE)"
RUN Rscript -e "install.packages(c('remotes', 'reticulate'), repos='https://cloud.r-project.org/')"

# Verify
RUN Rscript -e "library(BiocManager); cat('Success! BiocManager version:', as.character(BiocManager::version()), '\n')"
EOF

# Build
echo "Building test image..."
if docker build -f Dockerfile.test-quick -t biocmanager-fixed:test .; then
    echo ""
    echo "✅ Build succeeded!"
    echo ""
    echo "Testing installation..."
    docker run --rm biocmanager-fixed:test Rscript -e "library(BiocManager); sessionInfo()"
else
    echo ""
    echo "❌ Build failed"
fi

# Cleanup
docker rmi biocmanager-fixed:test 2>/dev/null
rm -f Dockerfile.test-quick

echo ""
echo "Quick test complete!"