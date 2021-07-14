# calculate_regional_means.R
#
# Copyright (C) 2021 Santander Meteorology Group (http://meteo.unican.es)
#
# This work is licensed under a Creative Commons Attribution 4.0 International
# License (CC BY 4.0 - http://creativecommons.org/licenses/by/4.0)

#' @title Monthly regional area-weighted means for the reference regions
#' @description 
#'   This script computes monthly regional area-weighted means for the
#' IPCC AR6 reference regions, for each model run in a given CMIP project,
#' scenario and variable. Regional means are computed for all grid-points
#' (landsea) in the region, and also separately for land and sea grid-points.
#' @author M. Iturbide

library(sp)
library(loadeR)
library(transformeR)
library(geoprocessoR)

#
# 1. Set parameters
#
project <- "CMIP5"
scenario <- "historical" # or "rcp45", "rcp85", etc.
var <- "tas"
vari <- "tas" # NetCDF variable name (usually, vari = var) 

#
# 2. Load regions
#
regions <- get(load("../../reference-regions/IPCC-WGI-reference-regions-v4_R.rda"))
# Organize regions as a list (i.e. each polygon/region is a slot of the list) 
region.list <- as(regions, "SpatialPolygons")
ind <- 1:length(region.list)
names(ind) <- names(region.list)
region.list <- lapply(ind, function(x) region.list[x])
# Fix for bug in library sp reordering the proj4 string
for (i in 1:length(region.list)) proj4string(region.list[[i]]) <- proj4string(region.list[[1]])

#
# 3. Load masks
#
resolution.degrees <- switch(project, "CMIP5" = 2, "CMIP6" = 1)
maskname <- sprintf("land_sea_mask_%ddegree.nc4", resolution.degrees)
landsea <- loadGridData(paste0("../../reference-grids/", maskname), var = "sftlf")
attr(landsea$xyCoords, "projection") <- proj4string(regions)
mask <- list(
  landsea = binaryGrid(landsea, condition = "GT", threshold = -1, values = c(NA, 1)), # All in
  land = binaryGrid(landsea, condition = "GT", threshold = 0.5, values = c(NA, 1)),
  sea = binaryGrid(landsea, condition = "LT", threshold = 0.5, values = c(NA, 1))
)

#
# 4. Load filenames to process
#
# Directoy of the Interactive Atlas Dataset (see datasets-interactive-atlas)
iad.dir <- "../../datasets-interactive-atlas/data"
# Point to the directory where the post-procesed data is and list the NetCDFs there
file.list <- list.files(paste0(iad.dir, "/", project, "/", var, "/cdo/"),
                        full.names = TRUE,
                        pattern = scenario,
                        recursive = T)
filename <- unlist(lapply(strsplit(file.list, "/"), function(x) x[length(x)]))
models <- unique(gsub(filename, pattern = paste0("_", var, "_.*"), replacement = ""))

#
# 5. Some commodity functions
#
spatial.mean <- function(x) {
  aggregateGrid(x, aggr.spatial = list(FUN = "mean", na.rm = T), weight.by.lat = TRUE)[["Data"]]
}

mask.data <- function(grid, region, area){
  if (region == "world") {
    ov <- grid
    regionmask <- mask[[area]]
  } else {
    ov <- overGrid(grid, region.list[[region]], subset = TRUE)
    regionmask <- overGrid(mask[[area]], region.list[[region]], subset = TRUE)
  }
  if (getShape(redim(grid), "time") > 1) {
     regionmask <- bindGrid(rep(list(regionmask), getShape(grid, "time")), dimension = "time")
  }
  return(gridArithmetics(ov, regionmask, operator = "*"))
}

grid.yearmon <- function(grid) substr(grid$Dates$start, start = 1, stop = 7)

varlong <- list(
  tas = "mean near-surface air temperature",
  pr = "mean daily precipitation"
)

units <- list(tas = "degC", pr="mm/day")

#
# 6. Main loop
#
for (model in models){
  model.filenames <- file.list[grep(model, file.list)]
  for (area in names(mask)){
    out.list <- lapply(1:length(model.filenames), function(i){
      message(" -- Processing ", model, " (", area, "), file ", i)
      grid <- loadGridData(model.filenames[i], var = vari)
      attr(grid$xyCoords, "projection") <- proj4string(regions)
      regdatal <- lapply(c(names(region.list), "world"), function(region){
        spatial.mean(mask.data(grid, region, area))
      })
      names(regdatal) <- c(names(region.list), "world")
      df <- round(do.call("data.frame", regdatal), digits = 3)
      return(data.frame("date" = grid.yearmon(grid), df))
    })
    out.df <- cbind(do.call("rbind", out.list))
    out.path <- sprintf("data/%s/%s_%s_%s", project, project, var, area) 
    dir.create(out.path, recursive = TRUE)
    out.file <- paste0(out.path, "/", model,".csv")
    file.create(out.file)
    meta <- sprintf("#Dataset: Monthly information aggregated on IPCC reference regions for CMIP6/6 and CORDEX
#Reference: https://doi.org/10.5194/essd-12-2959-2019
#Project: %s
#Experiment: %s
#Model: %s
#Variable: %s
#Variable_longname: %s
#Units: %s
#Time_frequency: month
#Feature_type: regional mean time series
#Regions: IPCC-WGI-reference-regions-v4
#Area: %s
#Spatial_resolution: %s degrees
#Interpolation_method: cdo remapcon
#Creation_Date: %s",
      project, scenario, model, var, varlong[[var]], units[[var]],
      area, resolution.degrees, as.character(Sys.Date())
    ) 
    writeLines(meta, out.file)
    write.table(out.df, out.file, row.names = FALSE, sep = ",", append = TRUE)
  }
}
