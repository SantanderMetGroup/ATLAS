# This script builds on the climate4R framework 
# https://github.com/SantanderMetGroup/climate4R

library(loadeR)
library(visualizeR)
library(sp)
library(rgdal)
library(geoprocessoR)

# Function for latitudinal chunking (read script from website):
## see https://github.com/SantanderMetGroup/climate4R/tree/master/R !!!!!!!!!!!!!!!!!!!
source_url("https://github.com/SantanderMetGroup/climate4R/blob/master/R/climate4R.chunk.R?raw=TRUE")



# USER PARAMETER SETTING ---------------------------------------------------------------------------

# Number of chunks
n.chunks <- 2

# Atlas Index, scenario and season, reference period, and target future periods, e.g.:
AtlasIndex <- "tas"
scenario <- "rcp85"
season <- 1:12 #(entire year, for winter: season = c(12, 1, 2))
years.hist <- 1986:2005
years.ssp <- list(2021:2040, 2041:2060, 2080:2100)

# Graphical parameters (n <- min value, m <- max value, s, cut value frequency, ct = Brewer color code), e.g.:
if (AtlasIndex != "pr") {
  m <- 8
  n <- 0
  s <- 0.5
  ct <- "Reds"
} else {
  m <- 50
  n <- -50
  s <- 5
  ct <- "BrBG"
}

# Path of the shapefile of World coastlines, e.g. 
## available for download: https://github.com/SantanderMetGroup/ATLAS/tree/devel/man !!!!!!!!!!!!!!!!!!!
coast.dir <- "WORLD_coastline.shp"

# Level of aggrement of the models, e.g.:
th <- 80 # 80%

# Source path where the ncml-s are
source.dir <- ""

# Output path to save the .rda object of the computed deltas and to export the pdf of the figure
out.dir <- ""





## COMPUTE DELTAS -------------------------------------------------------------------------------------------------

dataset.hist <- list.files(source.dir, pattern = paste0("historical_", AtlasIndex, ".ncml"), full.names = TRUE)
dataset.ssp <- list.files(source.dir, pattern = paste0(scenario,"_", AtlasIndex, ".ncml"), full.names = TRUE)

# Retain common members among scenarios
hist.members <- dataInventory(dataset.hist)[[AtlasIndex]][["Dimensions"]][["member"]][["Values"]]
ssp.members <- dataInventory(dataset.ssp)[[AtlasIndex]][["Dimensions"]][["member"]][["Values"]]
hist.m.ind <- which(hist.members %in% ssp.members)
ssp.m.ind <- which(ssp.members %in% hist.members)

membernames <- ssp.members[ssp.m.ind]

## Data loading and aggregation
funfun <- function(grid, var, season = 1:12) {
  if (var == "tas") {
    gy <- aggregateGrid(subsetGrid(grid, season = season), aggr.y = list(FUN = mean, na.rm = TRUE))
  } else if (var == "pr") {
    gy <- aggregateGrid(subsetGrid(grid, season = season), aggr.y = list(FUN = sum, na.rm = TRUE))
  }
  climatology(gy, clim.fun = list(FUN = mean, na.rm = TRUE))
}

hist <- climate4R.chunk(n.chunks = 2,
                        C4R.FUN.args = list(FUN = "funfun",
                                            grid = list(dataset = dataset.hist, var = AtlasIndex),
                                            AtlasIndex = AtlasIndex,
                                            season = season,
                                            members = hist.m.ind),
                        loadGridData.args = list(years = years.hist))
hist <- redim(hist, drop = TRUE); hist <- redim(hist)

ssp <- lapply(years.ssp, function(y) climate4R.chunk(n.chunks = 2,
                        C4R.FUN.args = list(FUN = "funfun",
                                            grid = list(dataset = dataset.ssp, var = AtlasIndex),
                                            AtlasIndex = AtlasIndex,
                                            season = season,
                                            members = ssp.m.ind),
                        loadGridData.args = list(years = y)))
ssp <- lapply(ssp, function(x) redim(x, drop = TRUE)); ssp <- lapply(ssp, function(x) redim(x))

## compute delta 
if (AtlasIndex != "pr") {
  delta <- lapply(ssp, function(x) gridArithmetics(x, hist, operator = "-"))
} else {
  delta <- lapply(ssp, function(x) gridArithmetics(x, hist, operator = "-"))
  delta <- lapply(delta, function(x) gridArithmetics(x, hist, 100, operator = c("/", "*")))
}

delta <- lapply(delta, function(x) {
  x[["Members"]] <- membernames
  x
})

# save(delta, file = paste0(out.dir, "delta_", AtlasIndex, "_", scenario, "_",  paste(season, collapse = "-"),".rda"))
# load(paste0(out.dir, "delta_", AtlasIndex, "_", scenario, "_",  paste(season, collapse = "-"),".rda"), verbose = TRUE)


# PLOT MAPS ----------------------------------------------------------------------------------------------------

## AUXILIARY FUNCTIONS (for hatching)

agrfun.cons <- function(x, th) {
  mp <- mean(x, na.rm = TRUE)
  if (is.na(mp)){
    1
  } else {
    if (mp > 0) {
      as.numeric(sum(as.numeric(x > 0), na.rm = TRUE) > as.integer(length(x) * th / 100))
    } else {
      as.numeric(sum(as.numeric(x < 0), na.rm = TRUE) > as.integer(length(x) * th / 100))
    }
  }
}

agrfun.sig <- function(x, th) {
  as.numeric((mean(x, na.rm = TRUE)/sd(x, na.rm = TRUE)) > 1)
}


## WORLD MAP 
regs <- as(regions, "SpatialPolygons")
coast <- readOGR(coast.dir)
proj4string(coast) <- proj4string(regs)
rregs <- spTransform(regs, CRS("+proj=robin +lon_0=0 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs"))
ccoast <- spTransform(coast, CRS("+proj=robin +lon_0=0 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs"))

delta.p <- lapply(delta, function(x) warpGrid(x, original.CRS = CRS("+init=epsg:4326"), new.CRS = CRS("+proj=robin +lon_0=0 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs")))

l1 <- lapply(1:length(delta.p), function(x){
  deltaagr1 <- aggregateGrid(delta.p[[x]], aggr.mem = list(FUN = agrfun.cons, th = th))
  c(map.hatching(clim = climatology(deltaagr1), threshold = 0.5, condition = "LT", density = 2), "which" = x, lwd = 0.6)
})

delta.w <- lapply(1:length(delta.p), function(x){
  deltamean <- aggregateGrid(delta.p[[x]], aggr.mem = list(FUN = "mean", na.rm = TRUE))
  deltamean$Dates$start <- "2021-01-16 00:00:00 GMT"
  deltamean$Dates$end <- "2100-12-16 00:00:00 GMT"
  deltamean
})

delta.m <- bindGrid(delta.w, dimension = "member")
delta.m[["Members"]] <- paste0("p", unlist(lapply(years.ssp, function(l) paste(range(l), collapse = "_"))), "_", nmodels, "_models")

p <- spatialPlot(delta.m, set.min = n, set.max = m, at = seq(n, m, s),
                 layout = c(1, length(years.ssp)),
                 as.table = TRUE,
                 strip = FALSE,
                 main = paste("season", paste(season, collapse = "-")),
                 color.theme = ct, backdrop.theme = "coastline",
                 colorkey = list(at = seq(n, m, s),
                                 labels = list(at = seq(n, m, s*2),
                                               labels = c(as.character(seq(n, m, s*2)[-c(length(seq(n, m, s*2)))]),
                                                          paste0(">=", seq(n, m, s*2)[length(seq(n, m, s*2))])))),
                 sp.layout = list(list(ccoast, first = FALSE), l1, list(rregs, first = FALSE, lwd = 1.5)))




pdf(paste0(out.dir, "/World_delta_", AtlasIndex, "_", scenario, "_",  paste(season, collapse = "-"),".pdf"), width = 10, height = 10)
p
dev.off()

