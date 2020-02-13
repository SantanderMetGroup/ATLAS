# This script builds on the climate4R framework 
# https://github.com/SantanderMetGroup/climate4R

library(loadeR)
library(loadeR.2nc)
library(transformeR)

# Data is accessed remotely from the Santander Climate Data Service
# Obtain a user and password at http://meteo.unican.es/udg-wiki
loginUDG(username = "yourUser", password = "yourPassword")

# The 0.5 WFDEI grid is used as the reference 
watch <- UDG.datasets("WFDEI")[["OBSERVATIONS"]]

ref <- loadGridData(watch, var = "tas", year = 2000, season = 1, aggr.m = "mean")

# 0.5º reference grid/mask 
mask <- gridArithmetics(ref, 0, 1, operator = c("*", "+"))
mask$Data[which(is.na(mask$Data))] <- 0

mask$Variable$varName <- "sftlf"
attr(mask$Variable, "description") <- "land sea mask"
attr(mask$Variable, "longname") <- "land sea mask"

# 1º reference grid/mask 
mask1 <- upscaleGrid(mask, times = 2, aggr.fun = list(FUN = mean))

# 2º reference grid/mask
mask2 <- upscaleGrid(mask, times = 4, aggr.fun = list(FUN = mean))

# export NetCDF 
out.dir <- ""
grid2nc(mask, NetCDFOutFile = paste0(out.dir, "land_sea_mask_05degree.nc4"))
grid2nc(mask1, NetCDFOutFile = paste0(out.dir, "land_sea_mask_1degree.nc4"))
grid2nc(mask2, NetCDFOutFile = paste0(out.dir, "land_sea_mask_2degree.nc4"))
