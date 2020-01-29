library(loadeR)
library(loadeR.2nc)
library(transformeR)

# PARAMETER SETTING ---------------------------------------------------------------------------

# Path to the directory containing the interpolated NetCDFs 
source.dir <- ""
# Output path
out.dir <- ""
# Project, variable, scenario and period, e.g.:
project <- "CMIP5"
var <- "tasmin"
scenario <- "historical"; years <- 1950:2005


# ENSEMBLE BUILDING --------------------------------------------------------------------------
for (i in 1:length(years)) {
  in.files <- list.files(source.dir, pattern = paste0(scenario, ".*", as.character(years[i])), full.names = TRUE)
  models <-  list.files(source.dir, pattern = paste0(scenario, ".*", as.character(years[i])))
  models <- gsub(models, pattern = paste0(project, "_|_", scenario, ".*"), replacement = "")
  g <- lapply(in.files, function(x) loadGridData(x, var = var))
  ind <- which(unlist(lapply(g, function(x) getShape(x, "time"))) < 12)
  if (length(ind) > 0) { # exception for hadgem
    aux <- subsetGrid(g[-ind][[1]], season = 12)
    aux$Data <- aux$Data * NA
    aux <- redim(aux, member = FALSE)
    g <- lapply(ind, function(k) {
      g[[k]] <- bindGrid(g[[k]], aux, dimension = "time")
      g
    })
  }
  mg <- bindGrid(g, dimension = "member")
  mg[["Members"]] <- models
  file.remove(paste0(out.dir, scenario, "_", var, "_", years[i], ".nc4"))
  grid2nc(mg, paste0(out.dir, scenario, "_", var, "_", years[i], ".nc4"))
}

# NCML construction ------------------------------------------------------------------------------

out.ncml.dir <- paste0(out.dir, "/ncml")
dir.create(out.ncml.dir)
makeAggregatedDataset(out.dir, 
                      ncml.file = paste0(out.ncml.dir, "/", project, "_", scenario, "_", var, ".ncml")
                      pattern = paste0(scenario, "_", var, "_.*.nc4"))




