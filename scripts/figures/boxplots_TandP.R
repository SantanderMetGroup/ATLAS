# THIS SCRIPT COMPUTES TEMPERATURE AND PRECIPITATION CHANGES FROM DATA FILES THAT ARE
# AVAILABLE IN THIS REPOSITORY (CSV FILES IN aggregated-datasets) AND 
# PRODUCES BOXPLOTS CONSIDERING THE MEDIAN, P10 AND P90.
# REQUIREMENTS TO RUN THE SCRIPT:
# - R 
# - R packages magrittr and httr

#----------------------------------------------------------------------------------------------


## The package magrittr is used to pipe (%>%) sequences of data operations improving readability
#install.packages("magrittr")
library(magrittr)
## The package httr is used towork with URLs and HTTP
#install.packages("httr")
library(httr)

# Function computeDeltas available at this repo is used:
source("https://raw.githubusercontent.com/SantanderMetGroup/ATLAS/devel/aggregated-datasets/scripts/computeDeltas.R")
source("https://raw.githubusercontent.com/SantanderMetGroup/ATLAS/devel/aggregated-datasets/scripts/computeFigure.R")

# select variable, i.e. "tas" or "pr"
var <- "tas"
# select season, use c(12,1,2) for winter
season <- 1:12
# select reference period
ref.period <- 1995:2014
# select the area, i.e. "land", "sea" or "landsea"
area <- "land"
# Select a reference region
regions <- c("NWN","NEN","WNA","CNA","ENA")
type = "boxplot"




a <- computeFigure(var, 
                   season, 
                   ref.period, 
                   WL, 
                   periods, 
                   area, 
                   regions,
                   type)

library(gridExtra)
out.dir <- ""
outfilename <- paste0(out.dir, "NAM_", type,"_", area, "_", paste(season, collapse = "-"), "_ATvsAP.pdf")
pdf(outfilename, width = 20/2, height = 30/2)
do.call("grid.arrange", a)
dev.off()
