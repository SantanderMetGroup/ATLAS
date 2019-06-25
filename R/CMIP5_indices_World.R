source("climate4R/R/climate4R.chunk.R")
library(loadeR)
library(transformeR)
library(loadeR.2nc)

# PARAMETER SETTING FOR DATA LOADING, INDEX CALCULATION AND EXPORT---------------------------------------------------------------------------

## Output directory

out.dir <- getwd()

## Datasets
pattern <- "CMIP5"
scenario <- "historical"

datasets <- UDG.datasets(paste0(pattern, ".*", scenario))$name
datasets <- datasets[-6]

## Argument setting for the C4R function:

code <- "mean"
var <- "tasmax"

## Argument setting for the loadGridData function
lonLim <- c(40, 50)
latLim <- c(-20, 0)


# THE COMMON SPATIAL GRID --------------------------------------------------------------------------------------
ref.grid <- list(x = c(-179, 179), y = c(-89, 89))
attr(ref.grid, "resX") <- 2
attr(ref.grid, "resY") <- 2

ref.grid.reg <- limitArea(ref.grid, lonLim = lonLim, latLim = latLim)


# COMPUTE INDEX ----------------------------------------------------------------------------------------------------
index <- lapply(datasets, function(d) climate4R.chunk(n.chunks = 5,
                                                      C4R.FUN.args = list(FUN = "aggregateGrid",
                                                                          grid = list(dataset = d, var = var),
                                                                          aggr.m = code),
                                                      loadGridData.args = list(lonLim = lonLim,
                                                                               latLim = latLim)))


# LOAD MASKS AND INTERPOLATE --------------------------------------------------------------------------------------------------
datasets <- UDG.datasets(paste0(pattern, ".*historical"))$name
datasets <- datasets[-6]

masks <- lapply(datasets, function(d) loadGridData(d, var = "sflt"))

## Apply original masks and interpolate

### Ceate sea and land masks separately
land <- lapply(masks, function(m) {
                l <- gridArithmetics(m, 0.9, operator = "-")
                l$Data[which(l$Data) <= 0] <-  NA
                gridArithmetics(l, 0, 1, operator = c("*", "+"))
})

sea <- lapply(masks, function(m) {
              s <- gridArithmetics(m, 0.1, operator = "-")
              s$Data[which(s$Data) > 0] <-  NA
              gridArithmetics(s, 0, 1, operator = c("*", "+"))
})

### Apply the masks to the index and interpolate te results to the common grid
index.ens <- lapply(1:length(index), function(i){
  li <- gridArithmetics(index[[i]], land, operator = "*")
  si <- gridArithmetics(index[[i]], sea, operator = "*")
  li.i <- interpGrid(li, ref.grid.reg, method = "bilinear")
  si.i <- interpGrid(si, ref.grid.reg, method = "bilinear")
  sili <- bindGrid(si.i, li.i, dimension = "member")
  aggregateGrid(sili, aggr.mem = list(FUN = "sum", na.rm = TRUE))
})


## ENSEMBLE OF THE MASKS (do not need to repeat this part)----------------------------------------------------------------------------------------

### Interpolate the masks to the common grid
land.i <- lapply(land, function(l) interpGrid(l, ref.grid.reg, method = "bilinear"))
sea.i <- lapply(sea, function(s) interpGrid(s, ref.grid.reg, method = "bilinear"))

### Make the masks binary
land01 <- bindGrid(land.i, dimension = "member")
land01$Data[which(is.na(land01$Data))] <- 0

sea01 <- bindGrid(sea.i, dimension = "member")
sea01$Data[which(is.na(sea01$Data))] <- 0

### Calculate the ensemble mean of the masks:
### This mean is computed from values of 0 and 1, thus, the resulting ensemble mask contains values from 0 to 1.
### Considering the hipothetical situation of having 10 models; If 9 up to 10 of the 
### masks show land in a particular pixel the mean would be 0.9, 
### thus, the threshold applied to the resulting ensemble is based in model agreement
### If the land-threshold is e.g. 0.9, a high agreement is considered for land regions.
### In the case of the sea, a high agreement is given by a threshold value close to 0.
land.ens <- aggregateGrid(land01, aggr.mem = list(FUN = mean))
sea.ens <- aggregateGrid(sea01, aggr.mem = list(FUN = mean))

mask.ens <- aggregateGrid(bindGrid(land.ens, sea.ens, dimension = "member"), aggr.mem = list(FUN = sum))
 
grid2nc(mask.ens, NetCDFOutFile = paste0(out.dir, "/", pattern, "_ensemble_mask.nc4"))




