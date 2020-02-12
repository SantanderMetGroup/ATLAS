library(loadeR)
library(loadeR.2nc)
library(transformeR)

watch <- UDG.datasets("WFDEI")[["OBSERVATIONS"]]

loginUDG(username = "", password = "")

ref <- loadGridData(watch, var = "tas", year = 2000, season = 1, aggr.m = "mean")

### 0.5 reference grid/mask -----------------------------------

mask <- gridArithmetics(ref, 0, 1, operator = c("*", "+"))
mask$Data[which(is.na(mask$Data))] <- 0

mask$Variable$varName <- "sftlf"
attr(mask$Variable, "description") <- "land sea mask"
attr(mask$Variable, "longname") <- "land sea mask"

### 1 reference grid/mask -----------------------------------
mask1 <- upscaleGrid(mask, times = 2, aggr.fun = list(FUN = mean))

### 2 reference grid/mask -----------------------------------

mask2 <- upscaleGrid(mask, times = 4, aggr.fun = list(FUN = mean))

### export NetCDF ---------------------------------------------
out.dir <- ""
grid2nc(mask, NetCDFOutFile = paste0(out.dir, "land_sea_mask_05degree.nc4"))
grid2nc(mask1, NetCDFOutFile = paste0(out.dir, "land_sea_mask_1degree.nc4"))
grid2nc(mask2, NetCDFOutFile = paste0(out.dir, "land_sea_mask_2degree.nc4"))

