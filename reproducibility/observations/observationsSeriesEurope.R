# observationsSeriesEurope.R
#
# Copyright (C) 2021 Santander Meteorology Group (http://meteo.unican.es)
#
# This work is licensed under a Creative Commons Attribution 4.0 International
# License (CC BY 4.0 - http://creativecommons.org/licenses/by/4.0)

#' @title Yearly anomalies temporal series for observational datasets over the European IPCC regions
#' @description 
#' This script aims to compute the temporal series of the yearly anomalies of precipitation and air surface temperature. We build on four
#' observational datasets for each of the two variables of interest, and show the series obtained for the four European IPCC regions.
#' Moreover, we include in these temporal plots the linear trends of these series for each of the variables, datasets and regions. 
#' We included a parameter setting in the first part of the script that permits to change certain aspects of the series 
#' (variable, temporal period), and of the graphical components (scale, text).
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
setwd("local_path/")

### Loading the IPCC regions and the mask ------------------------------------------------------------------------------
regs <- get(load("../../reference-regions/IPCC-WGI-reference-regions-v4_R.rda"))
regs <- as(regs, "SpatialPolygons")

### Parameter Setting (start) ------------------------------------------------------------------------------
regs.area <- c("MED", "WCE", "NEU", "EEU") # Europe regions
latLim <- c(28,74) ; lonLim <- c(-12,60) # Europe
cols <- c("black","blue","green","red")
### PRCPTOT -------------
var <-  "prcptot"
datasets <- c("CRU_TS_v4.04","GPCC_v2020","GPCP_v2.3","EOBS_v21.0e")
years <- list(1901:2019,1901:2019,1979:2020,1950:2019)
title <- "Annual mean precipitation (mm/day)"
ylim <- c(-1.5,1.5)
### TAS -------------
var <-  "tas"
datasets <- c("BerkeleyEarth","CRU_TS_v4.04","ERA5","EOBS_v21.0e") # Europe TAS
years <- list(1901:2020,1901:2019,1979:2020,1950:2019) # Europe  TAS
title <- "Annual mean temperature (deg/day)"
ylim = c(-3,3)
### Parameter Setting (end) ------------------------------------------------------------------------------

### Loading the data and computing the trends ------------------------------------------------------------------------------
mask <- loadGridData(dataset = "../../reference-grids/special-masks/land_sea_mask_025degree_EOBS_EuropeOnly.nc4", var = "lsm", latLim = latLim, lonLim = lonLim) %>% 
  binaryGrid(threshold = 0, condition = "GT", values = c(NaN,1))
labels <- c("dataset1_path","dataset2_path","dataset3_path")

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
pdf(paste0("temporalSerie_Europe_",var,".pdf"), width = 15, height = 10)
grid.arrange(grobs = figs, ncol = 2)
dev.off() 
