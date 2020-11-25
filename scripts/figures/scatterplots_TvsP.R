# THIS SCRIPT COMPUTES TEMPERATURE AND PRECIPITATION CHANGES FROM DATA FILES THAT ARE
# AVAILABLE IN THIS REPOSITORY (CSV FILES IN aggregated-datasets) AND 
# PRODUCES TEMPRATURE vs PRECIPITATION SCATTERPLOTS FOR THE MEDIAN, P10 AND P90.
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

# Function computeDeltas (available at this repo is used) to compute the mean delta changes:
source("https://raw.githubusercontent.com/SantanderMetGroup/ATLAS/devel/aggregated-datasets/scripts/computeDeltas.R")

### SET COMMON ARGUMENTS -----------------------------

# select season, use c(12,1,2) for winter
season <- 1:12 
# select reference period
ref.period <- 1850:1900
# select warming levels or list of future periods, e.g. list(c(2021, 2040), c(2041, 2060), c(2081, 2100))
periods <- c("1.5", "2", "3", "4")
# select the area, i.e. "land", "sea" or "landsea"
area <- "landsea"

### CMIP5 WL tas----------------------------------

# Set parameters to calculate mean delta changes for CMIP5 temperature ("tas"):
# select project "CMIP5", "CMIP6" ("CORDEX" will be available soon)
project = "CMIP5"
# select variable, i.e. "tas" or "pr"
var <- "tas"
# select scenario, i.e. "rcp26", "rcp45", "rcp85" (select a single scenario for computing WLs)
experiment <- "rcp85"


WL.cmip5.tas <- computeDeltas(project, var, experiment, season, ref.period, periods, area)

WLmediana.cmip5.tas <- lapply(WL.cmip5.tas, apply, 2, median, na.rm = T)
WLp90.cmip5.tas <- lapply(WL.cmip5.tas, apply, 2, quantile, 0.9, na.rm = T)
WLp10.cmip5.tas <- lapply(WL.cmip5.tas, apply, 2, quantile, 0.1, na.rm = T)

### CMIP5 WL pr----------------------------------

# Set parameters to calculate mean delta changes for CMIP5 precipitation ("pr"):
# select project "CMIP5", "CMIP6" ("CORDEX" will be available soon)
project = "CMIP5"
# select variable, i.e. "tas" or "pr"
var <- "pr"
# select scenario, i.e. "rcp26", "rcp45", "rcp85" (select a single scenario for computing WLs)
experiment <- "rcp85"

WL.cmip5.pr <- computeDeltas(project, var, experiment, season, ref.period, periods, area)

WLmediana.cmip5.pr <- lapply(WL.cmip5.pr, apply, 2, median, na.rm = T)
WLp90.cmip5.pr <- lapply(WL.cmip5.pr, apply, 2, quantile, 0.9, na.rm = T)
WLp10.cmip5.pr <- lapply(WL.cmip5.pr, apply, 2, quantile, 0.1, na.rm = T)


### CMIP6 WL tas----------------------------------

# Set parameters to calculate mean delta changes for CMIP6 temperature ("tas"):
# select project "CMIP5", "CMIP6" ("CORDEX" will be available soon)
project = "CMIP6"
# select variable, i.e. "tas" or "pr"
var <- "tas"
# select scenario, i.e. "ssp126", "ssp245", "ssp585" (select a single scenario for computing WLs)
experiment <- "ssp585"

WL.cmip6.tas <- computeDeltas(project, var, experiment, season, ref.period, periods, area)

WLmediana.cmip6.tas <- lapply(WL.cmip6.tas, apply, 2, median, na.rm = T)
WLp90.cmip6.tas <- lapply(WL.cmip6.tas, apply, 2, quantile, 0.9, na.rm = T)
WLp10.cmip6.tas <- lapply(WL.cmip6.tas, apply, 2, quantile, 0.1, na.rm = T)

### CMIP6 WL pr----------------------------------

# Set parameters to calculate mean delta changes for CMIP6 precipitation ("pr"):
# select project "CMIP5", "CMIP6" ("CORDEX" will be available soon)
project = "CMIP6"
# select variable, i.e. "tas" or "pr"
var <- "pr"
# select scenario, i.e. "ssp126", "ssp245", "ssp585" (select a single scenario for computing WLs)
experiment <- "ssp585"

WL.cmip6.pr <- computeDeltas(project, var, experiment, season, ref.period, periods, area)

WLmediana.cmip6.pr <- lapply(WL.cmip6.pr, apply, 2, median, na.rm = T)
WLp90.cmip6.pr <- lapply(WL.cmip6.pr, apply, 2, quantile, 0.9, na.rm = T)
WLp10.cmip6.pr <- lapply(WL.cmip6.pr, apply, 2, quantile, 0.1, na.rm = T)



########## plot #######------------------------------------------------------------------------
region.subset <- names(WL.cmip5.tas) ## all regions

#select the output figure file name
out.dir <- ""



#plot and write figure
col1 <- c(rgb(0.55,0,0.55,0.5), rgb(1, 0.73, 0.06, 0.5),rgb(0, 0, 0, 0.5), rgb(0.5, 0.3, 0.16, 0.5))
col2 <- c(rgb(0.55,0,0.55), rgb(1, 0.73, 0.06), rgb(0, 0, 0), rgb(0.5, 0.3, 0.16))
outfilename <- paste0(out.dir, project, "_scatterplots_", area, "_", paste(season, collapse = "-"), "_ATvsAP.pdf")
pdf(outfilename, width = 20, height = 25)
par(mfrow = c(7, 8))
for(i in region.subset) {
  plot(WLmediana.cmip6.tas[[i]], WLmediana.cmip6.pr[[i]], pch = 21,
       bg = rgb(1,0,0,0), col = rgb(1,0,0,0), 
       xlim = c(min(WLp10.cmip6.tas[[i]]), max(WLp90.cmip6.tas[[i]])),
       ylim = c(min(WLp10.cmip6.pr[[i]]), max(WLp90.cmip6.pr[[i]])),
       main = i,
       xlab = bquote(Delta*"T(ºC)"), ylab = bquote(Delta*"P(%)"))
  segments(WLp10.cmip6.tas[[i]], WLmediana.cmip6.pr[[i]], WLp90.cmip6.tas[[i]], WLmediana.cmip6.pr[[i]], col = col2, lwd = 4)
  segments(WLmediana.cmip6.tas[[i]], WLp10.cmip6.pr[[i]], WLmediana.cmip6.tas[[i]], WLp90.cmip6.pr[[i]], col = col2, lwd = 4)
  segments(min(WLp10.cmip6.tas[[i]]), 0, max(WLp90.cmip6.tas[[i]]), 0, lty = 3)
  segments(WLp10.cmip5.tas[[i]], WLmediana.cmip5.pr[[i]], WLp90.cmip5.tas[[i]], WLmediana.cmip5.pr[[i]], col = col1, lwd = 4)
  segments(WLmediana.cmip5.tas[[i]], WLp10.cmip5.pr[[i]], WLmediana.cmip5.tas[[i]], WLp90.cmip5.pr[[i]], col = col1, lwd = 4)
  points(WLmediana.cmip6.tas[[i]], WLmediana.cmip6.pr[[i]], pch = 21, bg = col2, xlim = c(0, 7))
  points(WLmediana.cmip5.tas[[i]], WLmediana.cmip5.pr[[i]], pch = 21, bg = col1, xlim = c(0, 7))
}
dev.off()





