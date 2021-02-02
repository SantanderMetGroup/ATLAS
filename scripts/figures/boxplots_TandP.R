# THIS SCRIPT COMPUTES TEMPERATURE AND PRECIPITATION CHANGES FROM DATA FILES THAT ARE
# AVAILABLE IN THIS REPOSITORY (CSV FILES IN aggregated-datasets) AND 
# PRODUCES BOXPLOTS AND SCATTERPLOTS CONSIDERING THE MEDIAN, P10 AND P90.
# REQUIREMENTS TO RUN THE SCRIPT:
# - R 
# - R packages magrittr, httr, lattice, latticeExtra, gridExtra

#----------------------------------------------------------------------------------------------


## The package magrittr is used to pipe (%>%) sequences of data operations improving readability
#install.packages("magrittr")
library(magrittr)
## The package httr is used towork with URLs and HTTP
#install.packages("httr")
library(httr)
## Libraries lattice and latticeExtra are used internally to produce the figures
#install.packages("lattice")
#install.packages("latticeExtra")
library(lattice)
library(latticeExtra)
## To produce the final pannel of the plots library gridExtra is used.
#install.packages("gridExtra")
library(gridExtra)

# Function computeDeltas available at this repo is used:
source("https://raw.githubusercontent.com/SantanderMetGroup/ATLAS/devel/aggregated-datasets/scripts/computeDeltas.R")
source("https://raw.githubusercontent.com/SantanderMetGroup/ATLAS/devel/aggregated-datasets/scripts/computeFigures.R")


# select seasons, use c(12,1,2) for winter
scatter.seasons <- list(c(12, 1, 2), 6:8)
# select reference period
ref.period <- 1995:2014
# select the area, i.e. "land", "sea" or "landsea"
area <- "land"
# Select reference regions
regions <- c("NWN","NEN","WNA","CNA","ENA", "NCA")




a <- computeFigures(regions,
                    area, 
                    ref.period, 
                    scatter.seasons)

# select the path and the name of the output pdf
outfilename <- paste0("NAM_", area, "_ATvsAP.pdf")
# Play with arguments width and height to create different size pds-s
pdf(outfilename, width = 30/2, height = 50/2)
do.call("grid.arrange", a)
dev.off()
