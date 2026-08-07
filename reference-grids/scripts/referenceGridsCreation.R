options(java.parameters = "-Xmx30g")
# referenceGridsCreation.R
#
# Copyright (C) 2021 Santander Meteorology Group (http://meteo.unican.es)
#
# This work is licensed under a Creative Commons Attribution 4.0 International
# License (CC BY 4.0 - http://creativecommons.org/licenses/by/4.0)

#' @title 
#' @description 
#' @author M. Iturbide

# This script builds on the climate4R framework 
# https://github.com/SantanderMetGroup/climate4R

library(loadeR)
library(loadeR.2nc)
library(transformeR)
library(magrittr)

# CREATE REFERENCE GRIDS -------------------------------------------------------
# Data is accessed remotely from the Santander Climate Data Service
# When required, obtain a user and password at http://meteo.unican.es/udg-wiki and run the folling:
# loginUDG(username = "yourUser", password = "yourPassword")

# Medium- to-low-resolution masks

## The 0.5 WFDEI grid is used as the reference 
watch <- UDG.datasets("WFDEI")[["OBSERVATIONS"]]

ref <- loadGridData(watch, var = "tas", year = 2000, season = 1, aggr.m = "mean")

## 0.5º reference grid/mask 
mask <- gridArithmetics(ref, 0, 1, operator = c("*", "+"))
mask$Data[which(is.na(mask$Data))] <- 0

mask$Variable$varName <- "sftlf"
attr(mask$Variable, "description") <- "land sea mask"
attr(mask$Variable, "longname") <- "land sea mask"

## 1º reference grid/mask 
mask1 <- upscaleGrid(mask, times = 2, aggr.fun = list(FUN = mean))

## 2º reference grid/mask
mask2 <- upscaleGrid(mask, times = 4, aggr.fun = list(FUN = mean))

## export NetCDF 
out.dir <- "../medium-low-resolution-masks/"
grid2nc(mask, NetCDFOutFile = paste0(out.dir, "land_sea_mask_05degree.nc4"))
grid2nc(mask1, NetCDFOutFile = paste0(out.dir, "land_sea_mask_1degree.nc4"))
grid2nc(mask2, NetCDFOutFile = paste0(out.dir, "land_sea_mask_2degree.nc4"))

# Medium- to-low-resolution masks
## The 0.03125 orog_GLO-3i grid is used as the reference 
glo3i <- "orog_GLO-3i_masked.nc"

mask <- loadGridData(glo3i, var = "orog")

## 0.03125º reference grid/mask 
mask$Variable$varName <- "sftlf"
attr(mask$Variable, "description") <- "land sea mask"
attr(mask$Variable, "longname") <- "land sea mask"

## 0.0625º reference grid/mask 
mask1 <- upscaleGrid(mask, times = 2, aggr.fun = list(FUN = mean))

## 0.125º reference grid/mask
mask2 <- upscaleGrid(mask, times = 4, aggr.fun = list(FUN = mean))

## export NetCDF 
out.dir <- "../high-resolution-masks/"
grid2nc(mask, NetCDFOutFile = paste0(out.dir, "land_sea_mask_0.03125degree.nc4"))
grid2nc(mask1, NetCDFOutFile = paste0(out.dir, "land_sea_mask_0.0625degree.nc4"))
grid2nc(mask2, NetCDFOutFile = paste0(out.dir, "land_sea_mask_0.125degree.nc4"))


## CREATE REFERENCE BINARY GRIDS -------------------------------------------------------

ERA.mask <- loadGridData("../medium-low-resolution-masks/land_sea_mask_025degree_ERA5.nc", var = "lsm")
land_sea_mask_025degree_binary <- binaryGrid(ERA.mask, condition = "GT", threshold = 0.5, values = c(0, 1)) %>% redim(drop = T)

deg1.mask <- loadGridData("../medium-low-resolution-masks/land_sea_mask_1degree.nc4", var = "sftlf")
land_sea_mask_1degree_binary <- binaryGrid(deg1.mask, condition = "GT", threshold = 0.5, values = c(0, 1)) %>% redim(drop = T)

deg2.mask <- loadGridData("../medium-low-resolution-masks/land_sea_mask_2degree.nc4", var = "sftlf")
land_sea_mask_2degree_binary <- binaryGrid(deg2.mask, condition = "GT", threshold = 0.5, values = c(0, 1)) %>% redim(drop = T)

deg006.mask <- loadGridData("../high-resolution-masks/land_sea_mask_0.0625degree.nc4", var = "sftlf")
land_sea_mask_1degree_binary <- binaryGrid(deg006.mask, condition = "GT", threshold = 0.5, values = c(0, 1)) %>% redim(drop = T)

deg012.mask <- loadGridData("../high-resolution-masks/land_sea_mask_0.125degree.nc4", var = "sftlf")
land_sea_mask_2degree_binary <- binaryGrid(deg012.mask, condition = "GT", threshold = 0.5, values = c(0, 1)) %>% redim(drop = T)

