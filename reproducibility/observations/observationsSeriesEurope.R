# observationsSeriesEurope.R
#
# Copyright (C) 2021 Santander Meteorology Group (http://meteo.unican.es)
#
# This work is licensed under a Creative Commons Attribution 4.0 International
# License (CC BY 4.0 - http://creativecommons.org/licenses/by/4.0)

#' @title 
#' @description 
#' @author J. Baño-Medina

### Loading Libraries ------------------------------------------------------------------------------
options(java.parameters = "-Xmx8g")
library(loadeR) # C4R
library(transformeR) # C4R
library(visualizeR) # C4R
library(geoprocessoR) # C4R
library(climate4R.indices) # C4R
library(magrittr) # The package magrittr is used to pipe (%>%) sequences of data operations improving readability
library(gridExtra) # plotting functionalities
library(sp) # plotting functionalities
library(RColorBrewer)  # plotting functionalities e.g., color palettes
library(rgdal)

### Loading the IPCC regions and the mask ------------------------------------------------------------------------------
regs <- get(load(url("https://raw.githubusercontent.com/SantanderMetGroup/ATLAS/master/reference-regions/IPCC-WGI-reference-regions-v4_R.rda")))
regs <- as(regs, "SpatialPolygons")

### Parameter Setting ------------------------------------------------------------------------------
regs.area <- c("MED", "WCE", "NEU", "EEU") # Europe regions
mask.file <- "Desktop/IPCC/Europe/land_sea_mask_025degree_EOBS.nc4" # mask Europe
latLim <- c(28,74) ; lonLim <- c(-12,60) # Europe
cols <- c("black","blue","green","red")
### PRCPTOT -------------
var <-  "prcptot"
datasets <- c("CRU_TS_v4.04","GPCC_v2020","GPCP_v2.3","EOBS_v21.0e")
years <- list(1901:2019,1901:2019,1979:2020,1950:2019)
pdfName <- "./Desktop/IPCC/temporalSerie_Europe_pr.pdf"
title <- "Annual mean precipitation (mm/day)"
ylim <- c(-1.5,1.5)
### TAS -------------
var <-  "tas"
datasets <- c("BerkeleyEarth","CRU_TS_v4.04","ERA5","EOBS_v21.0e") # Europe TAS
years <- list(1901:2020,1901:2019,1979:2020,1950:2019) # Europe  TAS
pdfName <- "./Desktop/IPCC/temporalSerie_Europe_tas.pdf"
title <- "Annual mean temperature (deg/day)"
ylim = c(-3,3)

### Loading the data and computing the trends ------------------------------------------------------------------------------
mask <- loadGridData(dataset = mask.file, var = "lsm", latLim = latLim, lonLim = lonLim) %>% binaryGrid(threshold = 0, condition = "GT", values = c(NaN,1))
labels <- paste0("oceano/gmeteo/WORK/PROYECTOS/2018_IPCC/data/OBSERVATIONS/",var,"/ncml/",datasets,"_",var,".ncml")

grid <- lapply(1:length(labels), FUN = function(z) {

  ### Loading the data ------------------------------------------------------------------------------
  grid <- loadGridData(dataset = labels[z], var = var, years = years[[z]], latLim = latLim, lonLim = lonLim) %>% 
    aggregateGrid(aggr.y = list(FUN = "mean", na.rm = TRUE)) %>% interpGrid(new.coordinates = getCoordinates(mask)) 
  grid <- lapply(unique(getYearsAsINDEX(grid)), FUN = function(zz) subsetGrid(grid, years = zz) %>% gridArithmetics(mask)) %>% bindGrid(dimension = "time")
  attr(grid$xyCoords, "projection") <- "+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0"  

  ### Computing the anomalies for each IPCC region ------------------------------------------------------------------------------
  grid.regs <- lapply(regs.area, function(r) overGrid(grid, regs[r]))
  names(grid.regs) <- regs.area
  lapply(grid.regs, function(x) aggregateGrid(x, aggr.lat = list(FUN = "mean", na.rm = TRUE), aggr.lon = list(FUN = "mean", na.rm = TRUE)) %>% scaleGrid(type = "center"))  
})  

### Depict the temporal plots ------------------------------------------------------------------------------
figs <- lapply(1:length(grid[[1]]), FUN = function(x) {
  aux <- sapply(1:length(grid), FUN = function(z) ((linearTrend(grid[[z]][[x]], p = 0.9) %>% subsetGrid(var = "b"))$Data[1]*10) %>% round(digits = 2))   
  key.trans <- list(space = "right", text = list(paste(datasets,"/",aux)), lines = list(col = cols, lty = rep(1,length(datasets))))
  gridplots <- lapply(1:length(datasets), FUN = function(z) grid[[z]][[x]])
  names(gridplots) <- datasets
  temporalPlot(gridplots, cols = cols, xyplot.custom = list(main = paste(title, regs.area[x]), ylim = ylim, key = key.trans))
})
pdf(pdfName, width = 15, height = 10)
grid.arrange(grobs = figs, ncol = 2)
dev.off() 
