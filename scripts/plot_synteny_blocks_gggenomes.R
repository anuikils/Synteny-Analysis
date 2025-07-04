#!/usr/bin/env Rscript
.libPaths("/mnt/Part3/LuisHernandez/sinteny_data/ntSynt/prueba1chrdladlas/r_libs")
library(argparse)
library(gggenomes)
library(gtools)
library(scales)
library(dplyr)

# Definir la función no_x_axis
no_x_axis <- function() {
  theme(axis.title.x = element_blank(),
        axis.text.x = element_blank(),
        axis.ticks.x = element_blank())
}

# Parse the input arguments
parser <- ArgumentParser(description = "Plot the ntSynt synteny blocks using gggenomes")
parser$add_argument("-s", "--sequences", help = "Input sequence lengths TSV", required = TRUE)
parser$add_argument("-l", "--links", help = "Synteny block links", required = TRUE)
parser$add_argument("--scale", help = "Length of scale bar in bases (default 1 Gbp)", default = 1e9,
                    required = FALSE, type = "double")
parser$add_argument("-p", "--prefix",
                    help = "Output prefix for PNG image (default synteny_gggenomes_plot)", required = FALSE,
                    default = "synteny_gggenomes_plot")

args <- parser$parse_args()

# Read in and prepare sequences
sequences <- read.csv(args$sequences, sep = "\t", header = TRUE)

input_order <- unique(sequences$bin_id)
input_chrom_order <- unique(sequences$seq_id)
mixedrank <- function(x) order(gtools::mixedorder(x))
sequences <- sequences %>%
  arrange(factor(bin_id, levels=input_order), factor(seq_id, levels=input_chrom_order))

# Read in and prepare synteny links
links_ntsynt <- read.csv(args$links,
                         sep = "\t", header = TRUE)
links_ntsynt$seq_id <- factor(links_ntsynt$seq_id,
                              levels = mixedsort(unique(links_ntsynt$seq_id)))
links_ntsynt <- links_ntsynt[mixedorder(links_ntsynt$seq_id), ]
links_ntsynt$seq_id2 <- as.character(links_ntsynt$seq_id2)
links_ntsynt$colour_block <- as.factor(links_ntsynt$colour_block)

# Prepare scale bar data frame
scale_bar <- tibble(x = c(0), xend = c(args$scale),
                    y = c(0), yend = c(0))

# Infer best units for scale bar
label <- paste(args$scale, "bp", sep = " ")
if (args$scale %% 1e9 == 0) {
  label <- paste(args$scale / 1e9, "Gbp", sep = " ")
} else if (args$scale %% 1e6 == 0) {
  label <- paste(args$scale / 1e6, "Mbp", sep = " ")
} else if (args$scale %% 1e3 == 0) {
  label <- paste(args$scale / 1e3, "kbp", sep = " ")
}

# Make the ribbon plot
make_plot <- function(links, sequences, add_scale_bar = FALSE) {
  num_colours <- length(unique(links$colour_block))
  p <-  gggenomes(seqs = sequences, links = links)
  plot <- p + theme_gggenomes_clean(base_size = 15) +
    geom_link(aes(fill = colour_block), offset = 0, alpha = 0.5, size = 0.05) +
    geom_seq(size = 2, colour = "grey") + # draw contig/chromosome lines
    geom_bin_label(aes(label = bin_id), size = 6, hjust = 0.9) + # label each bin
    theme(axis.text.x = element_text(size = 25),
          legend.position = "bottom") +
    scale_fill_manual(values = hue_pal()(num_colours),
                      breaks = unique(links$seq_id)) +
    scale_colour_manual(values = c("red")) +
    guides(fill = guide_legend(title = "", ncol = 10),
           colour = guide_legend(title = ""))

  if (add_scale_bar) {
    plot <- plot + geom_segment(data = scale_bar, aes(x = x, xend = xend, y = y, yend = yend),
                                linewidth = 1.5) +
      geom_text(data = scale_bar, aes(x = x + (xend / 2), y = y - 0.3, label = label)) + no_x_axis()
  }

  return(plot)
}

synteny_plot <- make_plot(links_ntsynt, sequences, add_scale_bar = TRUE)

# Save the ribbon plot
ggsave(paste(args$prefix, ".png", sep = ""), synteny_plot,
       units = "cm", width = 50, height = 20, bg = "white")

cat(paste("Plot saved:", paste(args$prefix, ".png", sep = ""), "\n", sep = " "))
