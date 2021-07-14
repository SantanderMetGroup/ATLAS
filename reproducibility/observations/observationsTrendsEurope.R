# observationsTrendsEurope.R
#
# Copyright (C) 2021 Santander Meteorology Group (http://meteo.unican.es)
#
# This work is licensed under a Creative Commons Attribution 4.0 International
# License (CC BY 4.0 - http://creativecommons.org/licenses/by/4.0)

#' @title 
#' @description 
#' @author M. Iturbide

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

### Loading the IPCC regions ------------------------------------------------------------------------------
coast <- readOGR("Desktop/IPCC/WORLD_coastline.shp") 
regs <- get(load(url("https://raw.githubusercontent.com/SantanderMetGroup/ATLAS/master/reference-regions/IPCC-WGI-reference-regions-v4_R.rda")))
regs <- as(regs, "SpatialPolygons")

### Parameter Setting ------------------------------------------------------------------------------
regs.area <- c("MED", "WCE", "NEU", "EEU") # Europe regions
mask.file <- "Desktop/IPCC/Europe/land_sea_mask_025degree_EOBS.nc4" # mask Europe
dataset <- "EOBS_v21.0e" 
latLim <- c(28,74) ; lonLim <- c(-12,60) # Europe
### PRCPTOT -------------
var <-  "prcptot"
colorScale_trends <- seq(-0.3, 0.3, 0.015) # PRCPTOT
colorPalette <- brewer.pal(n = 9, "BrBG") %>% colorRampPalette() # PRCPTOT
title <- "Lin. trends of the annual mean precipitation (mm/day per decade)" # PRCPTOT
### TAS -------------
var <-  "tas"
colorScale_trends <- seq(-0.7, 0.7, 0.025) # TAS
colorPalette <- rev(brewer.pal(n = 9, "RdBu")) %>% colorRampPalette() # TAS
title <- "Lin. trends of the annual mean tempearture (deg/day per decade)" # TAS


### We load the data and compute the trends ------------------------------------------------------------------------------
mask <- loadGridData(dataset = mask.file, var = "lsm", latLim = latLim, lonLim = lonLim) %>% binaryGrid(threshold = 0, condition = "GT", values = c(NaN,1))
label <- paste0("oceano/gmeteo/WORK/PROYECTOS/2018_IPCC/data/OBSERVATIONS/",var,"/ncml/",dataset,"_",var,".ncml")
years <- list(1980:2015,"1980-2015")
# years <- list(1980:2019,"1980-2019")


### We load the data ------------------------------------------------------------------------------
grid <- loadGridData(dataset = label, var = var, years = years[[1]], latLim = latLim, lonLim = lonLim) %>% 
  aggregateGrid(aggr.y = list(FUN = "mean", na.rm = TRUE)) 
grid <- lapply(unique(getYearsAsINDEX(grid)), FUN = function(zz) subsetGrid(grid, years = zz) %>% gridArithmetics(mask)) %>% bindGrid(dimension = "time")
attr(grid$xyCoords, "projection") <- "+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0"  

### We compute the trends and the p-values for each IPCC region ------------------------------------------------------------------------------
objGrid <- linearTrend(grid, p = 0.9) 
trendGrid <- subsetGrid(objGrid, var = "b") %>% gridArithmetics(10) %>% overGrid(regs[regs.area])
pvalGrid <- subsetGrid(objGrid, var = "pval") %>% gridArithmetics(mask) %>% overGrid(regs[regs.area]) %>% binaryGrid(threshold = 0.1, condition = "GT")

### We evaluate the significance of the trends through hatching ------------------------------------------------------------------------------
l <- lapply(c("45","-45"), FUN = function(z) {
  c(map.hatching(clim = climatology(pvalGrid), 
                 threshold = 0.5, 
                 condition = "GE", 
                 density = 4,
                 angle = z, coverage.percent = 50,
                 upscaling.aggr.fun = list(FUN = "mean", na.rm = TRUE)
  ), 
  "which" = 1, lwd = 0.5)
})

### We depict the spatial maps ------------------------------------------------------------------------------
pdf(paste0("Desktop/IPCC/spatialMap_EOBS_",var,"_",years[[2]],"_hatching1º.pdf"))
spatialPlot(trendGrid, 
            col.regions = colorPalette,
            at = colorScale_trends, 
            set.min = colorScale_trends[1],
            set.max = colorScale_trends[length(colorScale_trends)],
            main = title,
            ylab = paste(dataset,years[2]),
            sp.layout = list(
              l[[1]],l[[2]],  
              list(regs[regs.area], first = FALSE, lwd = 0.6),
              list(coast, col = "gray50", first = FALSE, lwd = 0.6),  
              list("sp.text", coordinates(regs[regs.area]), names(regs[regs.area]), first = FALSE, cex = 0.6)
            ))
dev.off()


