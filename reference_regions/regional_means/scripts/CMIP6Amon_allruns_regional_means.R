
library(RNetCDF)
library(loadeR)
library(transformeR)
library(visualizeR)
library(geoprocessoR)


regs <- as(regions, "SpatialPolygons")

project <- "CMIP6Amon"
scenario <- "historical"
var <- "pr"

root.dir <- ""

out.dir <- "

orig.masks <- list.files(paste0(root.dir, ""))
mask <- loadGridData("land_sea_mask_1.nc4", var = "sftlf")
maskland <- binaryGrid(mask, condition = "GT", threshold = 0.999, values = c(NA, 1))
masksea <- binaryGrid(mask, condition = "LT", threshold = 0.001, values = c(NA, 1))
attr(maskland$xyCoords, "projection") <- "+init=epsg:4326"
attr(masksea$xyCoords, "projection") <- "+init=epsg:4326"

lf <-  list.files(paste0(root.dir, ""), full.names = TRUE, pattern = scenario)
filename <- gsub(lf, pattern = ".*//", replacement = "")
mods <- unique(gsub(filename, pattern = paste0("_", var, ".*"), replacement = ""))


lapply(1:length(mods), function(m){ 
  ind <- grep(mods[m], lf)
  lfi <- lf[ind]
  ydatal <- lapply(1:length(lfi), function(i){
    grid <- loadGridData(lfi[i], var = var)
    attr(grid$xyCoords, "projection") <- "+init=epsg:4326"
    regdatal <- lapply(1:length(regs), function(r){
      ov <- overGrid(grid, regs[r], subset = TRUE)
      mland <- overGrid(maskland, regs[r], subset = TRUE)
      msea <- overGrid(masksea, regs[r], subset = TRUE)
      ovland <- gridArithmetics(ov, bindGrid(rep(list(mland), getShape(grid, "time")), dimension = "time"), operator = "*")
      ovsea <- gridArithmetics(ov, bindGrid(rep(list(msea), getShape(grid, "time")), dimension = "time"), operator = "*")
      regmean <- aggregateGrid(ov, aggr.lon = list(FUN = mean, na.rm = TRUE), aggr.lat = list(FUN = "mean", na.rm = TRUE))
      regmeanland <- aggregateGrid(ovland, aggr.lon = list(FUN = mean, na.rm = TRUE), aggr.lat = list(FUN = "mean", na.rm = TRUE))
      regmeansea <- aggregateGrid(ovsea, aggr.lon = list(FUN = mean, na.rm = TRUE), aggr.lat = list(FUN = "mean", na.rm = TRUE))
      list(landsea = regmean$Data, land = regmeanland$Data, sea = regmeansea$Data)
    })
    dates <- substr(grid$Dates$start, start = 1, stop = 7) 
    names(regdatal) <- names(regs)
    regdata <- lapply(regdatal, "[[", 1)
    regdataland <- lapply(regdatal, "[[", 2)
    regdatasea <- lapply(regdatal, "[[", 3)
    df <- do.call("data.frame", regdata)
    dfland <- do.call("data.frame", regdataland)
    dfsea <- do.call("data.frame", regdatasea)
    world <- apply(df, MARGIN = 1, FUN = mean, na.rm = TRUE)
    worldland <- apply(dfland, MARGIN = 1, FUN = mean, na.rm = TRUE)
    worldsea <- apply(dfsea, MARGIN = 1, FUN = mean, na.rm = TRUE)
    dfw <- data.frame("date" = dates, df, "world" = world)
    dfwland <- data.frame("date" = dates, dfland, "world" = worldland)
    dfwsea <- data.frame("date" = dates, dfsea, "world" = worldsea)
    list(landsea = dfw, land = dfwland, sea = dfwsea)
  })
  ydata <- lapply(ydatal, "[[", 1)
  ydataland <- lapply(ydatal, "[[", 2)
  ydatasea <- lapply(ydatal, "[[", 3)
  dfw <- cbind(do.call("rbind", ydata))
  dfwland <- do.call("rbind", ydataland)
  dfwsea <- do.call("rbind", ydatasea)
  modmod <- unlist(strsplit(mods[m], split = "_"))
  interp <- if (length(grep(modmod[2], orig.masks)) != 0){
    "cdo remap"
  } else {
    "cdo remapbil"
  }
  ######
  ll <- "landsea"
  file <- paste0(out.dir, "/", ll,"/", mods[m],".csv")
  file.create(file)
  meta <- paste(c(paste("#Dataset:", mods[m]), 
                  paste("#Variable:", var),
                  paste("#Area:", ll),
                  paste("#Interpolation_method:", interp),
                  paste("#Spatial_resolution:", "1º"),
                  paste("#Creation_Date:", as.character(Sys.Date())),
                  paste("#Author: IPCC-WGI Atlas Hub (https://github.com/SantanderMetGroup/IPCC-Atlas). Santander Meteorology Group.")), collapse = "\n")
  writeLines(meta, file)
  write.table(dfw, file, row.names = FALSE, sep = ",", append = TRUE)
  ####
  ll <- "land"
  file <- paste0(out.dir, "/", ll,"/", mods[m],".csv")
  file.create(file)
  meta <- paste(c(paste("#Dataset:", mods[m]), 
                  paste("#Variable:", var),
                  paste("#Area:", ll),
                  paste("#Interpolation_method:", interp),
                  paste("#Spatial_resolution:", "1º"),
                  paste("#Creation_Date:", as.character(Sys.Date())),
                  paste("#Author: IPCC-WGI Atlas Hub (https://github.com/SantanderMetGroup/IPCC-Atlas). Santander Meteorology Group.")), collapse = "\n")
  writeLines(meta, file)
  write.table(dfwland, file, row.names = FALSE, sep = ",", append = TRUE)
  #####
  ll <- "sea"
  file <- paste0(out.dir, "/", ll,"/", mods[m],".csv")
  file.create(file)
  meta <- paste(c(paste("#Dataset:", mods[m]), 
                  paste("#Variable:", var),
                  paste("#Area:", ll),
                  paste("#Interpolation_method:", interp),
                  paste("#Spatial_resolution:", "1º"),
                  paste("#Creation_Date:", as.character(Sys.Date())),
                  paste("#Author: IPCC-WGI Atlas Hub (https://github.com/SantanderMetGroup/IPCC-Atlas). Santander Meteorology Group.")), collapse = "\n")
  writeLines(meta, file)
  write.table(dfwsea, file, row.names = FALSE, sep = ",", append = TRUE)
})

