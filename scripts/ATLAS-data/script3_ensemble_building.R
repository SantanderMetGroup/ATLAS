#     script3_ensemble_building.R Create multi-member (model ensemble) NetCDFs from 
#     previoulsy interpolated data (using script2_interpolation.R)
#     for Atlas Product Reproducibility.
#
#     Copyright (C) 2020 Santander Meteorology Group (http://www.meteo.unican.es)
#
#     This program is free software: you can redistribute it and/or modify
#     it under the terms of the GNU General Public License as published by
#     the Free Software Foundation, either version 3 of the License, or
#     (at your option) any later version.
# 
#     This program is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#     GNU General Public License for more details.
# 
#     You should have received a copy of the GNU General Public License
#     along with this program.  If not, see <http://www.gnu.org/licenses/>.



# This script builds on the climate4R framework 
# https://github.com/SantanderMetGroup/climate4R

# Climate4R libraries for data loading, manipulation and output writing:
library(transformeR)
library(loadeR)
library(loadeR.2nc)

# USER PARAMETER SETTING -------------------------------------------------------

# Ensemble building is done after all model outputs have been put into a common reference grid
# Therefore, this script must be run after script2_interpolation.R, assuming that the interpolated grids are already available.

# Path to the directory containing the interpolated NetCDFs, e.g.:
source.dir <- paste0(getwd(), "/interpolatedData")
# Output path
out.dir <- paste0(getwd(), "/ensembleData")
# Project, variable, scenario and period, e.g.:
project <- "CMIP5"
AtlasIndex <- "FD"
scenario <- "historical"
years <- 1950:2005


# ENSEMBLE BUILDING ------------------------------------------------------------

# The loop iterates over years to produce one single netcdf4 file per year, storing the full ensemble of the target variable or index

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

# NCML construction ------------------------------------------------------------------------------

# An NcML document is an XML document that uses NcML, and defines a CDM dataset (NetCDF-Java Common Data Model),
# readily interpretable by the climate4R tools.

# More info: 
#   <https://github.com/SantanderMetGroup/loadeR/wiki/Model-Data-(reanalysis-and-climate-projections)>
#   <https://www.unidata.ucar.edu/software/netcdf-java/current/ncml/Tutorial.html>

out.ncml.dir <- paste0(out.dir, "/ncml")
dir.create(out.ncml.dir)

# This function creates the NcML file automatically by parsing the information stored in the nc files previously generated:

makeAggregatedDataset(out.dir, 
                      ncml.file = paste0(out.ncml.dir, "/", project, "_", scenario, "_", AtlasIndex, ".ncml"),
                      pattern = paste0(scenario, "_", AtlasIndex, "_.*.nc4"))

# End


