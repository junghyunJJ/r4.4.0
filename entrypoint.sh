#!/bin/bash

# SpotSweeper MCP Server Entrypoint
# This script starts the SpotSweeper MCP server

set -e

# Set working directory
cd /app

# Ensure R libraries are accessible
export R_LIBS_USER=/usr/local/lib/R/library

# Set locale for proper character handling
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

# Start the SpotSweeper MCP server
exec Rscript spotsweeper_mcp.R