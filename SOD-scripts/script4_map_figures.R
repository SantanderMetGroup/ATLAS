#     script4_map_figures.R Generate map figures from the ncml-s created 
#     using script3_ensemble_building.R, for Atlas Product Reproducibility.
#
#     Copyright (C) 2020 Santander Meteorology Group (http://www.meteo.unican.es)
#
#     This program is free software: you can redistribute it and/or modify
#     it under the terms of the GNU General Public License as published by
#     the Free Software Foundation, either version 3 of the License, or
#     (at your option) any later version.
# 
#     This program is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#     GNU General Public License for more details.
# 
#     You should have received a copy of the GNU General Public License
#     along with this program.  If not, see <http://www.gnu.org/licenses/>.

# This script builds on the climate4R framework 
# https://github.com/SantanderMetGroup/climate4R


# Climate4R package for data loading
library(loadeR)

# Climate4R package for data visualization
# <https://doi.org/10.1016/j.envsoft.2017.09.008>
library(visualizeR)

# climate 4R package for geoprocessing
library(geoprocessoR)

# Other utilities for spatial data handling and geoprocessing:
library(sp)
library(rgdal)

# Function for latitudinal chunking
# Note: chunking sequentially splits the task into manageable data chunks to avoid memory problems
# chunking operates by spliting the data into a predefined number latitudinal slices.
# Further details: https://github.com/SantanderMetGroup/climate4R/tree/master/R 
source_url("https://github.com/SantanderMetGroup/climate4R/blob/master/R/climate4R.chunk.R?raw=TRUE")


# USER PARAMETER SETTINGS ------------------------------------------------------

# Number of chunks
n.chunks <- 2

# Atlas Index, scenario and season, reference period, and target future periods, e.g.:
AtlasIndex <- "tas"
scenario <- "rcp85"
season <- 1:12  # (entire year: season = 1:12; boreal winter (DJF): season = c(12, 1, 2); boreal summer (JJA): season = 6:8, and so on...)
years.hist <- 1986:2005
years.ssp <- list(2021:2040,
                  2041:2060,
                  2080:2100)

# Path of the shapefile of World coastlines, e.g. 
## available for download: https://github.com/SantanderMetGroup/ATLAS/tree/devel/man 
coast.dir <- "WORLD_coastline.shp"

# Level of aggrement of the models (in %), e.g.:
th <- 80 # 80% multimode agreement

# Source path where the ncml-s are (those created in script3_ensemble_building.R)
source.dir <- ""

# Output path to save the .rda object of the computed deltas and to export the pdf of the figure
out.dir <- ""

# Color key graphical parameter:
  # n = min value
  # m = max value
  # s = cut value frequency
  # ct = Brewer color code (see 'RColorBrewer::display.brewer.all()')

if (AtlasIndex != "pr") {
  m <- 8
  n <- 0
  s <- 0.5
  ct <- "Reds"
} else {
  m <- 50
  n <- -50
  s <- 5
  ct <- "BrBG"
}

## COMPUTE DELTAS --------------------------------------------------------------

dataset.hist <- list.files(source.dir, pattern = paste0("historical_", AtlasIndex, ".ncml"), full.names = TRUE)
dataset.ssp <- list.files(source.dir, pattern = paste0(scenario,"_", AtlasIndex, ".ncml"), full.names = TRUE)

# Retain common members among scenarios
hist.members <- dataInventory(dataset.hist)[[AtlasIndex]][["Dimensions"]][["member"]][["Values"]]
ssp.members <- dataInventory(dataset.ssp)[[AtlasIndex]][["Dimensions"]][["member"]][["Values"]]
hist.m.ind <- which(hist.members %in% ssp.members)
ssp.m.ind <- which(ssp.members %in% hist.members)

membernames <- ssp.members[ssp.m.ind]

## Data loading and aggregation
# For convenience, the auxiliary wrapper 'aux.fun' is next defined, performing the following actions in one single step:
#  1. Performs data subsetting along the time dimension to extract the target season
#  2. Undertakes annual aggregation of the data, using a suitable aggregation function to that aim (i.e. sum of flux variables, i.e. precip, and averaging of other quantities, such as temperature)
#  3. Compute the climatology of the annualy aggregated data. This is the temporal mean for the whole target period

aux.fun <- function(grid, AtlasIndex, season = 1:12) {
  gy <- if (AtlasIndex != "pr") {
    aggregateGrid(subsetGrid(grid, season = season), aggr.y = list(FUN = mean, na.rm = TRUE))
  } else if (AtlasIndex == "pr") {
    aggregateGrid(subsetGrid(grid, season = season), aggr.y = list(FUN = sum, na.rm = TRUE))
  }
  return(climatology(gy, clim.fun = list(FUN = mean, na.rm = TRUE)))
}

## Historical experiment data are loaded sequentially according to the chunking definition

hist <- climate4R.chunk(n.chunks = n.chunks,
                        C4R.FUN.args = list(FUN = "aux.fun",
                                            grid = list(dataset = dataset.hist, var = AtlasIndex),
                                            AtlasIndex = AtlasIndex,
                                            season = season,
                                            members = hist.m.ind),
                        loadGridData.args = list(years = years.hist))

# redim is a helper function to ensure array structure consistency among the different models
hist <- redim(hist, drop = TRUE); hist <- redim(hist)

## RCP/SSP experiment future data are loaded sequentially according to the chunking definition:

ssp <- lapply(years.ssp, function(y) climate4R.chunk(n.chunks = n.chunks,
                        C4R.FUN.args = list(FUN = "aux.fun",
                                            grid = list(dataset = dataset.ssp, var = AtlasIndex),
                                            AtlasIndex = AtlasIndex,
                                            season = season,
                                            members = ssp.m.ind),
                        loadGridData.args = list(years = y)))

# redim is a helper function to ensure array structure consistency among the different models
ssp <- lapply(ssp, function(x) redim(x, drop = TRUE)); ssp <- lapply(ssp, function(x) redim(x))

## CALCULATE DELTAS ------------------------------------------------------------
# Deltas are the arithmetic difference between future and historical time slices.
# NOTE: Relative deltas are calculated in the case of precipitation (i.e.: future / historical, in %)

if (AtlasIndex != "pr") {
  delta <- lapply(ssp, function(x) gridArithmetics(x, hist, operator = "-"))
} else {
  delta <- lapply(ssp, function(x) gridArithmetics(x, hist, operator = "-"))
  delta <- lapply(delta, function(x) gridArithmetics(x, hist, 100, operator = c("/", "*")))
}

## The multimodel deltas are joined together along the 'member' dimension, generating the ensemble structure to be plotted:

delta <- lapply(delta, function(x) {
  x[["Members"]] <- membernames
  return(x)
})

# The intermediate object can be optionally stored as a R data object:
# save(delta, file = paste0(out.dir, "delta_", AtlasIndex, "_", scenario, "_",  paste(season, collapse = "-"),".rda"))
# load(paste0(out.dir, "delta_", AtlasIndex, "_", scenario, "_",  paste(season, collapse = "-"),".rda"), verbose = TRUE)


# PLOT MAPS --------------------------------------------------------------------

## AUXILIARY FUNCTIONS (for hatching)

agrfun.cons <- function(x, th) {
  mp <- mean(x, na.rm = TRUE)
  if (is.na(mp)) {
    1
  } else {
    if (mp > 0) {
      as.numeric(sum(as.numeric(x > 0), na.rm = TRUE) > as.integer(length(x) * th / 100))
    } else {
      as.numeric(sum(as.numeric(x < 0), na.rm = TRUE) > as.integer(length(x) * th / 100))
    }
  }
}

agrfun.sig <- function(x, th) {
  as.numeric((mean(x, na.rm = TRUE)/sd(x, na.rm = TRUE)) > 1)
}


## WORLD MAP -------------------------------------------------------------------

# spatial objects (regions and coastline)
regs <- as(regions, "SpatialPolygons")
coast <- readOGR(coast.dir)
proj4string(coast) <- proj4string(regs)

# project to Robinson
robin.proj.string <- "+proj=robin +lon_0=0 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs"
rregs <- spTransform(regs, CRS(robin.proj.string))
ccoast <- spTransform(coast, CRS(robin.proj.string))
delta.p <- lapply(delta, function(x) {
  warpGrid(x, original.CRS = CRS("+init=epsg:4326"), new.CRS = CRS(robin.proj.string))
})

# prepare the hatching spatial object
l1 <- lapply(1:length(delta.p), function(x) {
  deltaagr1 <- aggregateGrid(delta.p[[x]], aggr.mem = list(FUN = agrfun.cons, th = th))
  c(map.hatching(clim = climatology(deltaagr1),
                 threshold = .5,
                 condition = "LT",
                 density = 2),
    "which" = x, lwd = 0.6)
})

# calculate the ensemble mean for all periods
delta.w <- lapply(1:length(delta.p), function(x) {
  deltamean <- aggregateGrid(delta.p[[x]], aggr.mem = list(FUN = "mean", na.rm = TRUE))
  deltamean$Dates$start <- "2021-01-16 00:00:00 GMT"
  deltamean$Dates$end <- "2100-12-16 00:00:00 GMT"
  return(deltamean)
})

# handle periods as members to create a multipanel
delta.m <- bindGrid(delta.w, dimension = "member")
delta.m[["Members"]] <- paste0("p", unlist(lapply(years.ssp, function(l) {
  paste(range(l), collapse = "_")
})), "_", length(membernames), "_models")

# plot
p <- spatialPlot(delta.m, set.min = n, set.max = m, at = seq(n, m, s),
                 layout = c(1, length(years.ssp)),
                 as.table = TRUE,
                 strip = FALSE,
                 main = paste("season", paste(season, collapse = "-")),
                 color.theme = ct, backdrop.theme = "coastline",
                 colorkey = list(at = seq(n, m, s),
                                 labels = list(at = seq(n, m, s*2),
                                               labels = c(as.character(seq(n, m, s*2)[-c(length(seq(n, m, s*2)))]),
                                                          paste0(">=", seq(n, m, s*2)[length(seq(n, m, s*2))])))),
                 sp.layout = list(list(ccoast, first = FALSE), l1, list(rregs, first = FALSE, lwd = 1.5)))

# The map can be visulised on screen by typing 'print(p)'

# Export the figure as PDF file
pdf(paste0(out.dir, "/World_delta_", AtlasIndex, "_", scenario, "_",  paste(season, collapse = "-"),".pdf"), width = 10, height = 10)
print(p)
dev.off()

