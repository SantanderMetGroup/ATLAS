
library(sp)
library(loadeR)
library(transformeR)
library(geoprocessoR)

## load regions (available for download at: https://github.com/SantanderMetGroup/ATLAS/blob/master/reference-regions/IPCC-WGI-reference-regions-v4_R.rda)
regions <- get(load("reference-regions/IPCC-WGI-reference-regions-v4_R.rda"))
# Convert to a simpler objetc, i.e. from SpatialPolygonsDataFrame to SpatialPolygons
regs <- as(regions, "SpatialPolygons")

# Organize regions as a list (i.e. each polygon/region is a slot of the list) 
ind <- 1:length(regs)
names(ind) <- names(regs)#[-grep("\\*", nams)]
regs <- lapply(ind, function(x) regs[x])
names(regs) <- names(ind)

## PARAMETER SETTING --------
project <- "CMIP5"
scenario <- "historical"
scenario <- "rcp85"
var <- "tas"
vari <- "tas"

# Directoy of the interactiva atlas dataset (see datasets-interactive-atlas)
root.dir <- "/oceano/gmeteo/WORK/PROYECTOS/2018_IPCC/data"
# Output directory
out.dir <- paste0(root.dir, "/", project,"/", var, "/regional_means/") 


maskname <- switch(project,
                   "CMIP5" = "land_sea_mask_2degree.nc4",
                   "CMIP6" = "land_sea_mask_1degree.nc4")

mask <- loadGridData(paste0("reference-grids/", maskname), var = "sftlf")
maskland <- binaryGrid(mask, condition = "GT", threshold = 0.5, values = c(NA, 1))
masksea <- binaryGrid(mask, condition = "LT", threshold = 0.5, values = c(NA, 1))
attr(maskland$xyCoords, "projection") <- proj4string(regions)
attr(masksea$xyCoords, "projection") <- proj4string(regions)

# Point to the directory where the post-procesed data is and list the NetCDFs there
lf <-  list.files(paste0(root.dir, "/", project, "/", var, "/cdo/"), full.names = TRUE, pattern = scenario, recursive = T)
filename <- unlist(lapply(strsplit(lf, "/"), function(x) x[length(x)]))
mods <- unique(gsub(filename, pattern = paste0("_", var, ".*"), replacement = ""))


lapply(1:length(mods), function(m){
  ind <- grep(mods[m], lf)
  lfi <- lf[ind]
  ydatal <- lapply(1:length(lfi), function(i){
    message("!!!!!!!!!!!!!!!!!!!!!!!!__________", m, "___", i, "_________!!!!!!!!!!!!!!!!!")
    grid <- loadGridData(lfi[i], var = vari)
    attr(grid$xyCoords, "projection") <- proj4string(regions)
    regdatal <- lapply(1:(length(regs) + 1), function(r){
      if (r == length(regs) + 1) {
        ov <- grid
        mland <- maskland
        msea <- masksea
      } else {
        ov <- overGrid(grid, regs[[r]], subset = TRUE)
        mland <- overGrid(maskland, regs[[r]], subset = TRUE)
        msea <- overGrid(masksea, regs[[r]], subset = TRUE)
      }
      w <- cos(ov$xyCoords$y/360*2*pi)
      vv <- matrix(w, nrow = length(ov$xyCoords$y), ncol = length(ov$xyCoords$x))
      if (getShape(redim(grid), "time") > 1) {
        ovland <- gridArithmetics(ov, bindGrid(rep(list(mland), getShape(grid, "time")), dimension = "time"), operator = "*")
        ovsea <- gridArithmetics(ov, bindGrid(rep(list(msea), getShape(grid, "time")), dimension = "time"), operator = "*")
      } else {
        ovland <- gridArithmetics(ov, mland, operator = "*")
        ovsea <- gridArithmetics(ov, msea, operator = "*")
      }
      regmean <- aggregateGrid(ov, aggr.spatial = list(FUN = "mean", na.rm = T), weight.by.lat = TRUE)[["Data"]]
      regmeanland <- aggregateGrid(ovland, aggr.spatial = list(FUN = "mean", na.rm = T), weight.by.lat = TRUE)[["Data"]]
      regmeansea <- aggregateGrid(ovsea, aggr.spatial = list(FUN = "mean", na.rm = T), weight.by.lat = TRUE)[["Data"]]
      list(landsea = regmean, land = regmeanland, sea = regmeansea)
    })
    dates <- substr(grid$Dates$start, start = 1, stop = 7) 
    names(regdatal) <- c(names(regs), "world")
    regdata <- lapply(regdatal, "[[", 1)
    regdataland <- lapply(regdatal, "[[", 2)
    regdatasea <- lapply(regdatal, "[[", 3)
    df <- round(do.call("data.frame", regdata), digits = 3)
    dfland <- round(do.call("data.frame", regdataland), digits = 3)
    dfsea <- round(do.call("data.frame", regdatasea), digits = 3)
    world <- apply(df, MARGIN = 1, FUN = mean, na.rm = TRUE)
    worldland <- apply(dfland, MARGIN = 1, FUN = mean, na.rm = TRUE)
    worldsea <- apply(dfsea, MARGIN = 1, FUN = mean, na.rm = TRUE)
    dfw <- data.frame("date" = dates, df)
    dfwland <- data.frame("date" = dates, dfland)
    dfwsea <- data.frame("date" = dates, dfsea)
    list(landsea = dfw, land = dfwland, sea = dfwsea)
  })
  ydata <- lapply(ydatal, "[[", 1)
  ydataland <- lapply(ydatal, "[[", 2)
  ydatasea <- lapply(ydatal, "[[", 3)
  dfw <- cbind(do.call("rbind", ydata))
  dfwland <- do.call("rbind", ydataland)
  dfwsea <- do.call("rbind", ydatasea)
  ######
  for (ll in c("landsea", "land", "sea")) {
    out.df <- switch(ll,
                     "landsea" = dfw,
                     "land" = dfwland,
                     "sea" = dfwsea)
    file <- paste0(out.dir, "/", ll,"/", mods[m],".csv")
    file.create(file)
    meta <- paste(c(paste("#Dataset:", mods[m]), 
                    paste("#Variable:", var),
                    paste("#Area:", ll),
                    paste("#Interpolation_method:", "cdo remapcon"),
                    paste("#Spatial_resolution:", "1º"),
                    paste("#Creation_Date:", as.character(Sys.Date())),
                    paste("#Author: IPCC-WGI Atlas Hub (https://github.com/SantanderMetGroup/IPCC-Atlas). Santander Meteorology Group.")), collapse = "\n")
    writeLines(meta, file)
    write.table(out.df, file, row.names = FALSE, sep = ",", append = TRUE)
  }
})

