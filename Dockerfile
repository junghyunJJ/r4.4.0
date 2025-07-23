FROM rocker/r-ver:4.4.0

# Install all system dependencies in one layer
RUN apt-get update && apt-get install -y \
    # HDF5 and compilation tools
    libhdf5-dev \
    patch \
    build-essential \
    # R package dependencies
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libgit2-dev \
    libgdal-dev \
    libgeos-dev \
    libproj-dev \
    libudunits2-dev \
    libmagick++-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    libglpk-dev \
    libgmp3-dev \
    # Additional tools
    cmake \
    git \
    # Python for leidenAlg
    python3 \
    python3-pip \
    python3-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
RUN pip3 install --upgrade pip && \
    pip3 install leidenalg numpy

# Set up R environment and BiocManager
RUN R -e "options(repos = c(CRAN = 'https://cloud.r-project.org/')); \
          install.packages(c('remotes', 'BiocManager', 'reticulate')); \
          library(BiocManager); \
          BiocManager::install(version='3.19', ask=FALSE, update=FALSE)"

# Install core dependencies
RUN R -e "install.packages(c('Rcpp', 'RcppArmadillo', 'Matrix', 'igraph'), type='source')"

# Install Seurat and visualization packages
RUN R -e "install.packages(c('Seurat', 'dplyr', 'ggplot2', 'Cairo', 'patchwork', 'cowplot'))"

# Install Bioconductor packages
RUN R -e "BiocManager::install(c( \
    'multtest', 'SingleCellExperiment', 'batchelor', \
    'scran', 'scater', 'ComplexHeatmap', 'SpatialExperiment', \
    'escheR', 'SpotSweeper' \
    ), ask=FALSE, update=FALSE)"

# Install HDF5 packages step by step
RUN R -e "BiocManager::install('rhdf5', ask=FALSE, update=FALSE)"
RUN R -e "BiocManager::install('HDF5Array', ask=FALSE, update=FALSE)"

# Install hdf5r with specific configuration
RUN R -e "install.packages('hdf5r', type='source')"

# Install GitHub packages
RUN R -e "remotes::install_github('immunogenomics/presto')"
RUN R -e "remotes::install_github('jinworks/CellChat')"

# Install additional Bioconductor packages
RUN R -e "BiocManager::install(c('CARDspa', 'spacexr'), ask=FALSE, update=FALSE)"

# Install IRIS dependencies in order
RUN R -e "install.packages(c('MCMCpack', 'fields', 'wrMisc', 'RANN', 'reshape2'))"

# Install leidenAlg
RUN R -e "install.packages('leidenAlg')"

# Try to install optional dependencies
RUN R -e "tryCatch(install.packages('hdf5r.Extra'), error=function(e) message('hdf5r.Extra not available'))"

# Install RcppPlanc from r-universe
RUN R -e "install.packages('RcppPlanc', repos = c('https://kharchenkolab.r-universe.dev', 'https://cloud.r-project.org'))"

# Install rliger
RUN R -e "remotes::install_github('welch-lab/liger', ref='master')"

# Finally install IRIS
RUN R -e "remotes::install_github('YingMa0107/IRIS')"

# Create directories
RUN mkdir -p /data/input /data/output

# Set working directory
WORKDIR /app

# Default command
CMD ["R"]