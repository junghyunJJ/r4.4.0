#!/usr/bin/env Rscript

# Script to install BiocManager with proper error handling
# This helps with QEMU compatibility issues

cat("Installing BiocManager...\n")

# Set CRAN mirror
options(repos = c(CRAN = "https://cloud.r-project.org/"))

# Try to install BiocManager
tryCatch({
    install.packages("BiocManager", quiet = TRUE)
    cat("BiocManager package installed.\n")
}, error = function(e) {
    cat("Error installing BiocManager:", conditionMessage(e), "\n")
    quit(status = 1)
})

# Verify installation
if (!requireNamespace("BiocManager", quietly = TRUE)) {
    cat("BiocManager not found after installation!\n")
    quit(status = 1)
}

# Load BiocManager
library(BiocManager)
cat("BiocManager loaded successfully.\n")

# Set Bioconductor version
BiocManager::install(version = "3.19", ask = FALSE, update = FALSE)
cat("Bioconductor version 3.19 set.\n")

# Install additional packages
install.packages(c("remotes", "reticulate"), quiet = TRUE)
cat("Additional packages installed.\n")

cat("All installations completed successfully!\n")