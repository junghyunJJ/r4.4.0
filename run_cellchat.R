#!/usr/bin/env Rscript


# Load required libraries
suppressMessages(library(Seurat))
suppressMessages(library(CellChat))
suppressMessages(library(dplyr))
suppressMessages(library(ggplot2))
suppressMessages(library(patchwork))

# Set up logging
log_file <- file("/data/output/cellchat_log.txt", open = "wt")
sink(log_file, type = "output")
sink(log_file, type = "message")

# Log start time
cat("[", format(Sys.time()), "]", " - Starting CellChat analysis\n", sep = "")

# Get input file path from arguments or use default
args <- commandArgs(trailingOnly = TRUE)
input_file <- if (length(args) > 0) args[1] else "/data/input/seurat_object.rds"
cat("Input file:", input_file, "\n")

# Check if input file exists
if (!file.exists(input_file)) {
    stop("Input file does not exist: ", input_file)
}

#######################################################
### Part I: Preprocessing #############################
#######################################################
cat("\n\n[", format(Sys.time()), "]", " - Part I: Preprocessing\n", sep = "")

# Load the Seurat object
cat("Loading Seurat object...\n")
seurat_obj <- readRDS(input_file)
cat("Seurat object loaded with dimensions:", dim(seurat_obj), "\n")
cat("Cell types:", as.character(unique(Idents(seurat_obj))), "\n")

# Prepare data for CellChat
cat("Preparing data for CellChat...\n")
data.input <- Seurat::GetAssayData(seurat_obj, assay = DefaultAssay(seurat_obj), slot = "data")
labels <- Seurat::Idents(seurat_obj)

meta <- data.frame(
    labels = Seurat::Idents(seurat_obj),
    samples = "sample1",
    row.names = names(Seurat::Idents(seurat_obj))
)
meta$samples <- factor(meta$samples)
spatial.locs <- as.matrix(Seurat::GetTissueCoordinates(seurat_obj, scale = NULL, cols = c("imagerow", "imagecol")))

# set spatial.factors for Visium
scalefactors <- jsonlite::fromJSON(txt = file.path("/data/input/spatial/", 'scalefactors_json.json'))
spot.size <- 65 # the theoretical spot size (um) in 10X Visium
conversion.factor <- spot.size / scalefactors$spot_diameter_fullres
spatial.factors <- data.frame(ratio = conversion.factor, tol = spot.size / 2)


# Create CellChat object
cat("Creating CellChat object...\n")
cellchat <- createCellChat(object = data.input, meta = meta, group.by = "labels",
                           datatype = "spatial", coordinates = spatial.locs, spatial.factors = spatial.factors)

# Set the database - CHANGED FROM HUMAN TO MOUSE
cat("Setting database to mouse secreted signaling...\n")
CellChatDB <- CellChatDB.mouse
cellchat@DB <- CellChatDB

# Preprocessing
cat("Preprocessing...\n")
cellchat <- subsetData(cellchat)
cellchat <- identifyOverExpressedGenes(cellchat)
# cellchat <- identifyOverExpressedInteractions(cellchat)
cellchat <- identifyOverExpressedInteractions(cellchat, variable.both = FALSE)

#######################################################
### Part II: Inference of CCC #########################
#######################################################
cat("\n\n[", format(Sys.time()), "]", " - Part II: Inference of CCC network\n", sep = "")

# Compute communication probability and infer cell-cell communication network
cat("Computing communication probability...\n")
# cellchat <- computeCommunProb(cellchat)
cellchat <- computeCommunProb(cellchat, type = "truncatedMean", trim = 0.1,
                              distance.use = TRUE, interaction.range = 250, scale.distance = 0.01,
                              contact.dependent = TRUE, contact.range = 100)

cat("Filtering communication...\n")
cellchat <- filterCommunication(cellchat, min.cells = 10)

# Infer the cell-cell communication at a signaling pathway level
cat("Inferring communication network...\n")
cellchat <- computeCommunProbPathway(cellchat)

# Calculate aggregated cell-cell communication network
cat("Calculating aggregated network...\n")
cellchat <- aggregateNet(cellchat)

#######################################################
### Part III: visualization ###########################
#######################################################
cat("\n\n[", format(Sys.time()), "]", " - Part III: visualization\n", sep = "")

# Visualization and save results
cat("Generating visualizations...\n")
output_dir <- "/data/output/"
dir.create(file.path(output_dir, "plots"), showWarnings = FALSE, recursive = TRUE)

# Save the CellChat object
cat("Saving CellChat object...\n")
saveRDS(cellchat, file = file.path(output_dir, "cellchat_results.rds"))

# Generate and save network plots
cat("Generating network plots...\n")
pdf(file.path(output_dir, "plots", "cellchat_networks.pdf"), width = 12, height = 8)
netVisual_circle(cellchat@net$count, vertex.weight = table(cellchat@idents), weight.scale = T, label.edge= F, title.name = "Number of interactions")
netVisual_circle(cellchat@net$weight, vertex.weight = table(cellchat@idents), weight.scale = T, label.edge= F, title.name = "Interaction weights/strength")
dev.off()

# Generate and save pathway contribution plots
cat("Generating pathway contribution plots...\n")
pdf(file.path(output_dir, "plots", "pathway_contribution.pdf"), width = 10, height = 6)
pathways.show <- top_pathways <- cellchat@netP$pathways
netAnalysis_contribution(cellchat, signaling = pathways.show)
dev.off()

# Generate and save cell-cell communication heatmap
cat("Generating heatmap...\n")
pdf(file.path(output_dir, "plots", "communication_heatmap.pdf"), width = 10, height = 8)
groupSize <- as.numeric(table(cellchat@idents))
netVisual_heatmap(cellchat, measure = "count", color.heatmap = "Reds")
dev.off()

# # Generate and save bubble plot for top pathways
# cat("Generating bubble plots...\n")
# for (i in 1:min(5, length(top_pathways))) {
#   pdf(file.path(output_dir, "plots", paste0("bubble_plots_", top_pathways[i],".pdf")), width = 12, height = 8)
#   netVisual_bubble(cellchat, sources.use = NULL, targets.use = NULL, signaling = top_pathways[i], remove.isolate = FALSE)
#   dev.off()
# }

# Generate summary report
# cat("Generating summary report...\n")
cat("[", format(Sys.time()), "]", " - End\n", sep = "")
sink()
sink(type = "message")
close(log_file)

cat("Analysis completed successfully!\n")
cat("Results saved in:", output_dir, "\n")
