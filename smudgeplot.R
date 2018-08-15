#!/usr/bin/env Rscript

args = commandArgs(trailingOnly=TRUE)
# args[1] - input tsv file
# args[2] - output [default: smudgeplot.png]

if(length(args) < 1) {
      stop("No arguments supplied.\nUsage: smudgeplot.R haplod_cov [input.tsv] [output.png]", call.=FALSE)
} else {
      n <- as.numeric( args[1] )
}

infile <- ifelse(length(args) < 2, 'coverages_2.tsv', args[2])
outfile <- ifelse(length(args) < 3, 'smudgeplot.png', args[3])
fig_title <- ifelse(length(args) < 4, NA, args[4])

library(methods)
library(MASS) # smoothing
library(RColorBrewer)
# library(hexbin) # honeycomb plot

pal <- brewer.pal(11,'Spectral')
rf <- colorRampPalette(rev(pal[3:11]))
r <- rf(32)

cov <- read.table(infile)

# calcualte relative coverage of the minor allele
minor_variant_rel_cov <- cov$V1 / (cov$V1 + cov$V2)
# total covarate of the kmer pair
total_pair_cov <- cov$V1 + cov$V2

# quantile filtering (remove top 1%, it's not really informative)
high_cov_filt <- quantile(total_pair_cov, 0.99) > total_pair_cov
minor_variant_rel_cov <- minor_variant_rel_cov[high_cov_filt]
total_pair_cov <- total_pair_cov[high_cov_filt]

# calculate historgrams
h1 <- hist(minor_variant_rel_cov, breaks = 100, plot = F)
h2 <- hist(total_pair_cov, breaks = 100, plot = F)

top <- max(h1$counts, h2$counts)
# the lims trick will make sure that the last column of squares will have the same width as the other squares
k <- kde2d(minor_variant_rel_cov, total_pair_cov, n=30,
           lims = c(0.02, 0.48, min(total_pair_cov), max(total_pair_cov)))
# to display densities on squared root scale (bit like log scale but less agressive)
k$z <- sqrt(k$z)

png(outfile)
      # margins 'c(bottom, left, top, right)'
      par(mar=c(4.8,4.8,1,1))
      layout(matrix(c(2,4,1,3), 2, 2, byrow=T), c(3,1), c(1,3))

      # 2D HISTOGRAM
      image(k, col = r,
            xlab = 'Normalized minor kmer coverage: B / (A + B)',
            ylab = 'Total coverage of the kmer pair: A + B', cex.lab = 1.4,
            axes=F
      )

    axis(2, at=2:8 * n)

    xlab_ticks <- c(1/5, 1/4, 1/3, 2/5, 0.487)
    axis(1, at=xlab_ticks, labels = F)
    text(xlab_ticks, par("usr")[3] - 30, pos = 1, xpd = TRUE,
         labels = c('1:4', '1:3', '1:2', '2:3', '1:1'))
      # TEST plot lines at expected coverages
      # for(i in 2:6){
      #       lines(c(0, 0.6), rep(i * n, 2), lwd = 1.4)
      #       text(0.1, i * n, paste0(i,'x'), pos = 3)
      # }

      # EXPECTED COMPOSITIONS - bettern than lines
      text(1/2 - 0.027, 2 * n, 'AB', offset = 0, cex = 1.4)
      text(1/3, 3 * n, 'AAB', offset = 0, cex = 1.4)
      text(1/4, 4 * n, 'AAAB', offset = 0, cex = 1.4)
      text(1/2 - 0.04, 4 * n, 'AABB', offset = 0, cex = 1.4)
      text(2/5, 5 * n, 'AAABB', offset = 0, cex = 1.4)
      text(1/5, 5 * n, 'AAAAB', offset = 0, cex = 1.4)
      text(3/6 - 0.055, 6 * n, 'AAABBB', offset = 0, cex = 1.4)
      text(2/6, 6 * n, 'AAAABB', offset = 0, cex = 1.4)
      text(1/6, 6 * n, 'AAAAAB', offset = 0, cex = 1.4)

      # minor_variant_rel_cov HISTOGRAM - top
      par(mar=c(0,3.8,1,0))
      barplot(h1$counts, axes=F, ylim=c(0, top), space=0, col = pal[2])
      if(!(is.na(fig_title))){
            mtext(bquote(italic(.(fig_title))), side=3, adj=0, line=-3, cex=1.6)
      }

      # total pair coverage HISTOGRAM - right
      par(mar=c(3.8,0,0.5,1))
      barplot(h2$counts, axes=F, xlim=c(0, top), space=0, col = pal[2], horiz=T)
      mtext(paste('1n = ', n), side=1, adj=0.8, line=-2, cex=1.4)

      # LEGEND (topright corener)
      par(mar=c(0,0,2,1))
      plot.new()
      title('kmers pairs')
      for(i in 1:32){
            rect(0,(i - 0.01) / 33, 0.5, (i + 0.99) / 33, col = r[i])
      }
      kmer_max <- (length(total_pair_cov) * max((k$z)^2)) / sum((k$z)^2)
      for(i in 0:6){
            text(0.75, i / 6, round((sqrt(kmer_max) * i)^2 / 6000) * 1000, offset = 0)
      }

dev.off()

## alternative plotting
# h <- hexbin(df)
# # h@count <- sqrt(h@count)
# plot(h, colramp=rf)
# gplot.hexbin(h, colorcut=10, colramp=rf)