# This script builds on the climate4R framework 
# https://github.com/SantanderMetGroup/climate4R

library(loadeR)
library(loadeR.2nc)
library(transformeR)

# USER PARAMETER SETTING ---------------------------------------------------------------------------

# Path to the directory containing the interpolated NetCDFs, e.g.:
source.dir <- paste0(getwd(), "/interpolatedData")
# Output path
out.dir <- paste0(getwd(), "/ensembleData")
# Project, variable, scenario and period, e.g.:
project <- "CMIP5"
AtlasIndex <- "FD"
scenario <- "historical"; years <- 1950:2005


# ENSEMBLE BUILDING --------------------------------------------------------------------------
for (i in 1:length(years)) {
  in.files <- list.files(source.dir, pattern = paste0(scenario, ".*", as.character(years[i])), full.names = TRUE)
  models <-  list.files(source.dir, pattern = paste0(scenario, ".*", as.character(years[i])))
  models <- gsub(models, pattern = paste0(project, "_|_", scenario, ".*"), replacement = "")
  g <- lapply(in.files, function(x) loadGridData(x, var = AtlasIndex))
  ind <- which(unlist(lapply(g, function(x) getShape(x, "time"))) < 12)
  if (length(ind) > 0) { # exception for hadgem
    aux <- subsetGrid(g[-ind][[1]], season = 12)
    aux$Data <- aux$Data * NA
    aux <- redim(aux, member = FALSE)
    for (k in ind) g[[k]] <- bindGrid(g[[k]], aux, dimension = "time")
  }
  mg <- bindGrid(g, dimension = "member")
  mg[["Members"]] <- models
  file.remove(paste0(out.dir, "/", project, "_", scenario, "_", AtlasIndex, "_", years[i], ".nc4"))
  grid2nc(mg, paste0(out.dir, "/", project, "_", scenario, "_", AtlasIndex, "_", years[i], ".nc4"))
}

# optional NCML construction ------------------------------------------------------------------------------

out.ncml.dir <- paste0(out.dir, "/ncml")
dir.create(out.ncml.dir)
makeAggregatedDataset(out.dir, 
                      ncml.file = paste0(out.ncml.dir, "/", project, "_", scenario, "_", AtlasIndex, ".ncml")
                      pattern = paste0(scenario, "_", AtlasIndex, "_.*.nc4"))




