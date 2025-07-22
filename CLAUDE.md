# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Docker-based R 4.4.0 environment for single-cell RNA sequencing and spatial transcriptomics analysis. The project provides a containerized environment with pre-installed bioinformatics packages focused on cell-cell communication analysis and spatial data processing.

## Build Commands

Build the Docker image:
```bash
docker build -t r4.4.0:0.1 .
```

Clean build (no cache):
```bash
docker build --no-cache -t r4.4.0:0.1 .
```

## GitHub Actions CI/CD

The project includes GitHub Actions workflow for automated Docker image building:

### Workflow Features
- **Automatic builds** on push to main branch
- **Pull request testing** before merge
- **Multi-platform support** (linux/amd64, linux/arm64)
- **Registry support** for Docker Hub and GitHub Container Registry
- **Build caching** for faster builds

### Required Secrets
To enable automated pushing to registries, configure these secrets in GitHub:
- `DOCKER_USERNAME`: Docker Hub username
- `DOCKER_PASSWORD`: Docker Hub access token

### Manual Trigger
Run workflow manually from GitHub Actions tab using "workflow_dispatch"

## Running the Container

Interactive R session:
```bash
docker run -it r4.4.0:0.1
```

With data volumes:
```bash
docker run -it \
  -v /path/to/input:/data/input \
  -v /path/to/output:/data/output \
  r4.4.0:0.1
```

Run CellChat analysis:
```bash
docker run \
  -v /path/to/input:/data/input \
  -v /path/to/output:/data/output \
  r4.4.0:0.1 \
  Rscript /app/run_cellchat.R
```

## Testing

Test R installation:
```bash
docker run r4.4.0:0.1 R --version
```

Test key packages:
```bash
docker run r4.4.0:0.1 R -e "library(Seurat); library(CellChat); sessionInfo()"
```

Test all dependencies:
```bash
docker run r4.4.0:0.1 Rscript /app/test_dependencies.R
```

## Architecture

### Container Structure
- **Base**: `rocker/r-ver:4.4.0` with Bioconductor 3.19
- **Python Integration**: Includes Python environment for leidenalg via reticulate
- **Data Directories**: `/data/input/` (input) and `/data/output/` (results)
- **Scripts**: Located in `/app/`

### Key Package Groups
1. **Core Analysis**: Seurat, dplyr, ggplot2, patchwork
2. **Single Cell**: SingleCellExperiment, batchelor, scran, scater
3. **Spatial**: SpatialExperiment, escheR, SpotSweeper, IRIS, spatialLIBD
4. **Cell Communication**: CellChat, liger
5. **Deconvolution**: spacexr, CARDspa

### Special Considerations
- HDF5 packages require specific installation order (handled in Dockerfile)
- CellChat configured for mouse data by default (see `run_cellchat.R`)
- Entrypoint script sets up environment for SpotSweeper MCP server (requires `spotsweeper_mcp.R`)

### Development Workflow
1. Input data goes in `/data/input/` (expects `seurat_object.rds`)
2. For spatial data, include `/data/input/spatial/scalefactors_json.json`
3. Results saved to `/data/output/` with plots in subdirectories
4. Custom scripts can be mounted and run via `Rscript`