#!/usr/bin/env Rscript

# Test script to investigate IRIS dependencies

cat("=== R Version Information ===\n")
print(R.version)
cat("\n")

cat("=== Checking Bioconductor version ===\n")
if (!require("BiocManager", quietly = TRUE)) {
    install.packages("BiocManager", repos = "https://cloud.r-project.org/")
}
cat("BiocManager version: ", as.character(packageVersion("BiocManager")), "\n")
cat("Bioconductor version: ", BiocManager::version(), "\n\n")

cat("=== Checking package availability ===\n")

# Check if packages are available
packages_to_check <- c("HDF5Array", "hdf5r", "hdf5r.Extra", "RcppPlanc", "rliger")

for (pkg in packages_to_check) {
    cat("\nChecking", pkg, ":\n")
    
    # Check CRAN availability
    cran_avail <- pkg %in% rownames(available.packages(repos = "https://cloud.r-project.org/"))
    cat("  Available on CRAN:", cran_avail, "\n")
    
    # Check Bioconductor availability
    tryCatch({
        bioc_avail <- pkg %in% BiocManager::available()
        cat("  Available on Bioconductor:", bioc_avail, "\n")
    }, error = function(e) {
        cat("  Error checking Bioconductor:", conditionMessage(e), "\n")
    })
}

cat("\n=== Checking system HDF5 ===\n")
system("which h5cc", intern = FALSE)
system("h5cc -showconfig | head -10", intern = FALSE)

cat("\n=== Attempting to install hdf5r manually ===\n")
tryCatch({
    install.packages("hdf5r", repos = "https://cloud.r-project.org/", type = "source")
}, error = function(e) {
    cat("Error installing hdf5r:", conditionMessage(e), "\n")
})