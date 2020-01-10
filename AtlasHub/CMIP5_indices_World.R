source("/media/maialen/work/WORK/GIT/climate4R/R/climate4R.chunk.R")
library(loadeR)
library(transformeR)
library(loadeR.2nc)
library(visualizeR)
library(raster)
# PARAMETER SETTING FOR DATA LOADING, INDEX CALCULATION AND EXPORT---------------------------------------------------------------------------

## Output directory

out.dir <- getwd()
out.file <- "tasmax_monthly_max.rda"

## Datasets
pattern <- "CMIP5"
scenario <- "historical"

datasets <- UDG.datasets(paste0(pattern, ".*", scenario))$name
datasets <- datasets[-6]

## Argument setting for the C4R function:

var <- "tasmax"

## Argument setting for the loadGridData function
lonLim <- c(-10, 30)
latLim <- c(36, 70)

th.land <- 0.6
th.sea <- 0.1

# THE COMMON SPATIAL GRID --------------------------------------------------------------------------------------
ref.grid <- list(x = c(-179, 179), y = c(-89, 89))
attr(ref.grid, "resX") <- 2
attr(ref.grid, "resY") <- 2

ref.grid.reg <- limitArea(ref.grid, lonLim = lonLim, latLim = latLim)
# ref.grid.reg <- ref.grid

# COMPUTE INDEX ----------------------------------------------------------------------------------------------------

# Uncomment the following line if you are not loged in 
# loginUDG("", "") 

index <- lapply(datasets, function(d) climate4R.chunk(n.chunks = 3,
                                                      C4R.FUN.args = list(FUN = "aggregateGrid",
                                                                          grid = list(dataset = d, var = var),
                                                                          aggr.m = list(FUN = max, na.rm = TRUE)),
                                                      loadGridData.args = list(years = 2000,
                                                                               lonLim = lonLim,
                                                                               latLim = latLim)))

index <- lapply(index, function(r) redim(r, drop = TRUE))
# spatialPlot(climatology(index[[1]]), backdrop.theme = "coastline")
 save(index, file = paste0(out.dir, "/", pattern, "_", out.file))
# load(paste0(out.dir, "/", pattern, "_", out.file))

# LOAD MASKS AND INTERPOLATE --------------------------------------------------------------------------------------------------
datasets <- UDG.datasets(paste0(pattern, ".*historical"))$name
datasets <- datasets[-6]

masks <- lapply(datasets, function(d) loadGridData(d, var = "sftlf", lonLim = lonLim + c(-2, 2), latLim = latLim + c(-2, 2)))

masks <- lapply(1:length(masks), function(m) intersectGrid(index[[m]], masks[[m]], 
                                                           type = "spatial", which.return = 2))

masks <- lapply(1:length(masks), function(m) {
  masks[[m]]$Dates <- masks[[1]]$Dates
  masks[[m]]})

save(masks, file = "masks.rda")

## Apply original masks and interpolate

### Create sea and land masks separately

land <- lapply(masks, function(m) {
  binaryGrid(m, condition = "GT", threshold = th.land, values = c(NA, 1))
})

sea <- lapply(masks, function(m) {
  binaryGrid(m, condition = "LT", threshold = th.sea, values = c(NA, 0))
})

### Apply the masks to the index and interpolate te results to the common grid

#### Aux functions:
mean.fun <- function(x, n) {
  if (any(!is.na(x))) {
    sum(x, na.rm = TRUE)/n
  } else {
    NA
  }
}
na.fun <- function(x) {
  if (any(!is.na(x))) {
    x[!is.na(x)]
  } else {
    NA
  }
}

#### Apply
index.ens <- lapply(1:length(index), function(i){
  landredim <- bindGrid(rep(list(land[[i]]), getShape(index[[i]])["time"]), dimension = "time")
  searedim <- bindGrid(rep(list(sea[[i]]), getShape(index[[i]])["time"]), dimension = "time")

  li <- gridArithmetics(index[[i]], landredim, operator = "*")
  si <- gridArithmetics(index[[i]], searedim, operator = "+")
  li.i <- interpGrid(li, ref.grid.reg, method = "bilinear")
  si.i <- interpGrid(si, ref.grid.reg, method = "bilinear")
  sili <- bindGrid(si.i, li.i, dimension = "member")
  aggregateGrid(sili, aggr.mem = list(FUN = na.fun))
})

index.ens <- intersectGrid(index.ens, type = "temporal", which.return = 1:length(index.ens))
index.ens <- bindGrid(index.ens, dimension = "member")
index.ens$Members <- gsub(gsub(datasets, pattern = "_historical", replacement = ""), pattern = "-", replacement = ".")

spatialPlot(climatology(index.ens), backdrop.theme = "coastline")

## ENSEMBLE OF THE MASKS ----------------------------------------------------------------------------------------

### Interpolate the masks to the common grid
land.i <- lapply(land, function(l) interpGrid(l, ref.grid.reg, method = "bilinear"))
sea.i <- lapply(sea, function(s) interpGrid(s, ref.grid.reg, method = "bilinear"))



### Calculate the ensemble mean of the masks (for Dani):
### This mean is computed from values of 0 and 1, thus, the resulting ensemble mask contains values from 0 to 1.
### Considering the hipothetical situation of having 10 models; If 9 up to 10 of the 
### masks show land in a particular pixel the mean would be 0.9, 
### thus, the threshold applied to the resulting ensemble is based in model agreement
### If the land-threshold is e.g. 0.9, a high agreement is considered for land regions.
### In the case of the sea, a high agreement is given by a threshold value close to 0.

land.ens <- bindGrid(land.i, dimension = "member")
sea.ens <- bindGrid(sea.i, dimension = "member")



mask.ens <- aggregateGrid(bindGrid(land.ens, sea.ens, dimension = "member"), aggr.mem = list(FUN = mean.fun, n = length(datasets)))

spatialPlot(mask.ens, backdrop.theme = "coastline")
grid2nc(mask.ens, NetCDFOutFile = paste0(out.dir, "/", pattern, "_ensemble_mask.nc4"))


# DRAW MASK: 2 approaches -----------------------------------------------------------------------

## The mask without applying a threshold:

spatialPlot(mask.ens, backdrop.theme = "coastline")

a <- grid2sp(mask.ens)

index.ens.aggr <- aggregateGrid(index.ens, aggr.mem = list(FUN = mean, na.rm = TRUE))
spatialPlot(climatology(index.ens.aggr), color.theme = "Reds", 
            backdrop.theme = "coastline", 
            sp.layout = list(list(a, first = F,
                                  col = c(c("transparent", rev(grey.colors(10, alpha = 0.5))), 
                                          c(grey.colors(10, alpha = 0.5), "transparent")))))

## The mask applying a threshold:

land.th <- 7/9
sea.th <- 1/9


land <- binaryGrid(mask.ens, condition = "GT", threshold = land.th, values = c(NA, 1))
sea <- binaryGrid(mask.ens, condition = "LT", threshold = sea.th, values = c(NA, 0))
landsea <- aggregateGrid(bindGrid(land, sea, dimension = "member"), aggr.mem = list(FUN = na.fun))

spatialPlot(climatology(landsea), backdrop.theme = "coastline")


b <- grid2sp(landsea)
eo <- rasterToPolygons(raster(b), dissolve = T)


spatialPlot(climatology(index.ens), color.theme = "Reds", 
            backdrop.theme = "coastline", 
            sp.layout = list(list(eo, first = F, 
                                  fill = c(rgb(0, 0, 1, 0.2),
                                 rgb(0, 1, 0, 0.2)
                                 ),
                                 col = c("blue",
                                          "green"
                                 ))))



spatialPlot(climatology(index.ens.aggr), color.theme = "Reds", 
            backdrop.theme = "coastline", 
            sp.layout = list(list(eo, first = F, 
                                  fill = c(rgb(0, 0, 1, 0.2),
                                           rgb(0, 1, 0, 0.2)
                                  ),
                                  col = c("blue",
                                          "green"
                                  ))))




