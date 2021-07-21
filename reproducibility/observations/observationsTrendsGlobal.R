# observationsTrendsGlobal.R
#
# Copyright (C) 2021 Santander Meteorology Group (http://meteo.unican.es)
#
# This work is licensed under a Creative Commons Attribution 4.0 International
# License (CC BY 4.0 - http://creativecommons.org/licenses/by/4.0)

#' @title Global observational linear trends for precipitation and air surface temperature
#' @description 
#' This script aims to compute the linear trends (rate of change per decade) for the mean annual precipitation and air surface
#' temperature for global observational datasets. We also calculate the p-values associated to
#' these trends, ---in order to measure their statistical significance based on a significane level
#' of 0.1,--- and use hatching to incorporate this information in the spatial plots (i.e., hatching whenever p-value >= 0.1). 
#' In addition, we included a parameter setting in the first part of the script that permits to change certain aspects of the trends 
#' (variable, dataset, temporal period), the graphical components (color scale, colorbar, text), 
#' and the resolution of the hatching.
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
library(smoothr)
setwd("local_path/")

### Loading the IPCC regions ------------------------------------------------------------------------------
# Coast
coast <- readOGR("../../notebooks/auxiliary-material/WORLD_coastline.shp") 
proj4string(coast) <- CRS("+proj=longlat +datum=WGS84 +no_defs")
coast.rob <- spTransform(coast, CRSobj = CRS("+proj=robin +lon_0=0 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs"))
# Contour
contour <- SpatialPolygons(list(Polygons(list(Polygon(matrix(c(-180, -180, 180, 180, -180, -90, 90, 90, -90, -90), ncol = 2))), ID = "A")))
proj4string(contour) <- proj4string(coast)
contour <- densify(contour, max_distance = 0.44)
contour.rob <- spTransform(contour, CRS("+proj=robin +lon_0=0 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m +no_defs"))
# IPCC regs
regs <- get(load("../../reference-regions/IPCC-WGI-reference-regions-v4_R.rda"))
regs <- as(regs, "SpatialPolygons")
regs.rob <- spTransform(regs, CRS("+proj=robin +lon_0=0 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs"))

### Parameter Setting (start) ------------------------------------------------------------------------------
### PRCPTOT ---------
var <-  "prcptot"
datasets <- c("CRU_TS_v4.04","GPCC_v2020") # PRCPTOT
colorScale_trends <- seq(-0.25, 0.25, length.out = 11) # PRCPTOT
colorPalette <- brewer.pal(n = 10, "BrBG") %>% colorRampPalette() # PRCPTOT
title <- "Lin. trends of the annual mean precipitation (mm/day per decade)" # PRCPTOT
d <- c(8,4)
### TAS -------------
var <-  "tas"
datasets <- c("CRU_TS_v4.04","BerkeleyEarth") #,"HadCRUT5_infilled") # TAS
colorScale_trends <- seq(-0.6, 0.6, 0.1) # TAS
colorPalette <- rev(brewer.pal(n = 9, "RdBu")) %>% colorRampPalette() # TAS
title <- "Lin. trends of the annual mean temperature (deg/day per decade)" # TAS
d <- c(8,4,1)
### Select the temporal period ----------------
years <- list(1961:2015,"1961-2015")
### Parameter Setting (end) ------------------------------------------------------------------------------
label <- c("dataset1_path","dataset2_path")
figs <- lapply(1:length(label), FUN = function(z) {
  
  ### We load the data ------------------------------------------------------------------------------
  grid <- loadGridData(dataset = label[z], var = var, years = years[[1]]) %>% 
    aggregateGrid(aggr.y = list(FUN = "mean", na.rm = TRUE))
  attr(grid$xyCoords, "projection") <- "+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0"  
  ### We compute the trends and the p-values for each IPCC region ------------------------------------------------------------------------------
  mask <- binaryGrid(climatology(grid), condition = "GT", threshold = -9999)
  ### We compute the trends and the p-values for each IPCC region ------------------------------------------------------------------------------
  objGrid <- linearTrend(grid, p = 0.9) 
  trendGrid <- subsetGrid(objGrid, var = "b") %>% gridArithmetics(10) 
  pvalGrid <- subsetGrid(objGrid, var = "pval") %>% gridArithmetics(mask) %>% binaryGrid(threshold = 0.1, condition = "GT")

  ### We change to Robinson projection ------------------------------------------------------------------------------
  trendGrid <- warpGrid(climatology(trendGrid), new.CRS = CRS("+proj=robin +lon_0=0 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs"))
  pvalGrid <- warpGrid(climatology(pvalGrid), new.CRS = CRS("+proj=robin +lon_0=0 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs"))
  
  ### We evaluate the significance of the trends through hatching ------------------------------------------------------------------------------
  l <- lapply(c("45","-45"), FUN = function(zz) {
    c(map.hatching(clim = climatology(pvalGrid), 
                   threshold = 0.5, 
                   condition = "GE", 
                   density = d[z],
                   angle = zz, coverage.percent = 50,
                   upscaling.aggr.fun = list(FUN = "mean", na.rm = TRUE)
    ), 
    "which" = 1, lwd = 0.5)
  })
  
  ### We depict the spatial maps ------------------------------------------------------------------------------
  spatialPlot(trendGrid, 
              col.regions = colorPalette,
              at = colorScale_trends, 
              set.min = colorScale_trends[1],
              set.max = colorScale_trends[length(colorScale_trends)],
              main = title,
              ylab = paste(datasets[z],paste0("(",years[2],")")),
              par.settings = list(axis.line = list(col = 'transparent')),
              sp.layout = list(
                l[[1]],l[[2]],  
                list(regs.rob, first = FALSE, lwd = 0.6),
                list(coast.rob, col = "gray50", first = FALSE, lwd = 0.6),
                list(contour.rob, col = "black", first = FALSE, lwd = 0.7),
                list("sp.text", coordinates(regs.rob), names(regs.rob), first = FALSE, cex = 0.6)
              ))
})

pdf(paste0("spatialMap_Global_",var,"_",years[[2]],".pdf"), width = 15, height = 10)
grid.arrange(grobs = figs, ncol = 2)
dev.off()
