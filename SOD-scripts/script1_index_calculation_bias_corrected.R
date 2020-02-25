#     script1_index_calculation_bias_corrected.R Generate bias-corrected Climate Index NetCDF4 files from CMIP5 and CMIP6 Model Outputs for Atlas Product Reproducibility
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


# Misc utilities for remote repo interaction:
library(devtools)

# Climate4R libraries for data loading, manipulation and output writing:
library(transformeR)
library(loadeR)
library(loadeR.2nc)

# Climate4R package for bias correction
library(downscaleR)

# Climate4R libraries for climate index calculation:
library(climate4R.indices)
library(climate4R.climdex)
library(drought4R)

# Function for latitudinal chunking (read script from remote master branch):
## For further details: https://github.com/SantanderMetGroup/climate4R/tree/master/R 
source_url("https://github.com/SantanderMetGroup/climate4R/blob/master/R/climate4R.chunk.R?raw=TRUE")

# DATA ACCESS ------------------------------------------------------------------------------------
# Data is accessed remotely from the Santander Climate Data Service
# Obtain a user and password at http://meteo.unican.es/udg-wiki
climate4R.UDG::loginUDG(username = "yourUser", password = "yourPassword")

# USER PARAMETER SETTING: SELECT INDEX, SCENARIO, DATASETS, NUMBER OF CHUNKS AND OUTPUT DIRECTORY--------------


# SELECT THE ATLAS INDEX
# Atlas indices are: 
# | code   | description                           | units      | script 
# | ------ | ------------------------------------  | ---------- | --------
# | pr     | Precipitation                         | mm         | script1_index_calculation.R
# | pr99   | 99 percentile of all days             | mm         | script1_index_calculation.R
# | tas    | Temperature                           | degC       | script1_index_calculation.R
# | tasmin | mean min. temp                        | degC       | script1_index_calculation.R
# | tasmax | mean max. temp                        | degC       | script1_index_calculation.R
# | TNn    | minimum of min.temp                   | degC       | script1_index_calculation.R
# | TXx    | maximum of max.temp                   | degC       | script1_index_calculation.R
# | TX35   | max. temp avobe 35degC                | days       | script1_index_calculation.R
# | TX40   | max. temp avobe 40degC                | days       | script1_index_calculation.R
# | TX35bc | bias corrected max. temp avobe 35degC | days       | script1_index_calculation_bias_correction.R
# | TX40bc | bias corrected max. temp avobe 40degC | days       | script1_index_calculation_bias_correction.R
# | SPI6   | SPI-6                                 |            | script1_index_calculation_SPI.R
# | SPI12  | SPI-12                                |            | script1_index_calculation_SPI.R
# | Rx1day | maximum 1-day precipitation           | mm         | script1_index_calculation.R
# | Rx5day | maximum 5-day precipitation           | mm         | script1_index_calculation.R
# | DS*    | dry spell, consecutive dry days CDD   | days       | script1_index_calculation.R
# | CDD*   | cooling degree days                   | degreedays | script1_index_calculation.R
# | HDD    | heating degree days                   | degreedays | script1_index_calculation.R
# | FD     | frost days                            | days       | script1_index_calculation.R
# | T21.5  | mean temperature above 21.5degC       | days       | script1_index_calculation.R
# Indices with * not ready yet
# Indices TX35bc, TX35bc, SPI6, SPI12 are calculated in scripts 
# "script1_index_calculation_bias_correction.R" and "script1_index_calculation_SPI.R"

# Next select one of TX35bc and TX40bc:
AtlasIndex <- "TX35bc"
AtlasIndex <- match.arg(AtlasIndex, choices = c("TX35bc", "TX40bc"))

# scenario, e.g.:
scenario <- "rcp85"
scenario <- match.arg(scenario, choices = c("historical", "rcp45", "rcp85"))

# select datasets, for the observational reference and the historical (datasets1) 
# and rcp (datasets2) scenarios, e.g.:
dataset.obs <- "ncml_to_the_daily_observational_dataset.ncml"
datasets1 <- UDG.datasets("CMIP5.*historical")[["CMIP5_AR5_1run"]]
datasets2 <-  UDG.datasets(paste0("CMIP5.*", scenario))[["CMIP5_AR5_1run"]]

# # TO USE THE SAME SET OF MODELS USED IN THE ATLAS uncomment this paragraph. 
# # Use the *.csv files of the inventories 
# # (https://github.com/SantanderMetGroup/ATLAS/tree/devel/AtlasHub-inventory).
# # This is the root of the ATLAS repo content:
# root <- "https://raw.githubusercontent.com/SantanderMetGroup/ATLAS/devel/"
# # read the first column of the desired *.csv file (e.g. CMIP5_Atlas_20191211.csv) as follows:
# file <- "AtlasHub-inventory/CMIP5_Atlas_20191211.csv"
# datasets <- read.csv(paste0(root, file))[,1]
# datasets1 <- grep(datasets, pattern = "historical", value = TRUE)
# datasets2 <- grep(datasets, pattern = scenario, value = TRUE)

# Years to be corrected
target.years <- 2006:2100


# Number of chunks, e.g.:
n.chunks <- 10

#output path, e.g.
out.dir <- getwd()


# PARAMETER DEFINITION BASED ON OBJECT `AtlasIndex` and COMPUTE INDEX ----------

# Match common datasets among scenarios
datasets1.aux <- gsub("_historical", "", datasets1)
datasets2.aux <- gsub(paste0("_", scenario), "", datasets2)

datasets1 <- datasets1[which(datasets1.aux %in% datasets2.aux)]
datasets2 <- datasets2[which(datasets2.aux %in% datasets1.aux)]

# Years for calibration
years.cal <- 1980:2005

# myfun is a wrapper function in order to undertake bias correction and index calculation in one step
# It includes a call to biasCorrection (pkg downscaleR) and indexGrid (pkg climate4R.indices)

myfun <- function(obs, hist, ssp, th) {
  # Empirical quantile mapping (EQM) with a 30-day moving window
  bc.ssp <- biasCorrection(obs, hist, ssp, method = "eqm", precipitation = FALSE, window = c(30, 30))
  obs <- NULL; hist <- NULL; ssp <- NULL
  # Index calculation from the EQM-corrected temperature series
  index.ssp <- indexGrid(tx = bc.ssp, index.code = "TXth", time.resolution = "month", th = th)
  bc.ssp <- NULL
  index.ssp <- redim(index.ssp, drop = TRUE)
  return(index.ssp)
}

# The following loop will compute the bias-corrected target index, and write a netcdf4 file of the corrected 
# index for each model output and year:

lapply(1:length(datasets1), function(x) {
  
  # PARAMETER DEFINITION (the function will grow as new indices are introduced in the Atlas product catalogue)
  
  C4R.FUN.args <- switch(AtlasIndex, 
                         TX35bc = {
                           var <- "tasmax"
                           list(FUN = "myfun",  obs = list(dataset = dataset.obs, var = var, years = years.cal),
                                hist = list(dataset = datasets1[x], var = var, years = years.cal),
                                ssp = list(dataset = datasets2[x], var = var, years = target.years),
                                th = 35)
                         },
                         TX40bc = {
                           var <- "tasmax"
                           list(FUN = "myfun",  obs = list(dataset = dataset.obs, var = var, years = years.cal),
                                hist = list(dataset = datasets1[x], var = var, years = years.cal),
                                ssp = list(dataset = datasets2[x], var = var, years = target.years),
                                th = 40)
                         })
  
  # Data inventories ensure that the required ECV for the target index is available in the model output database
  di <- dataInventory(datasets1[x])
  di2 <- dataInventory(datasets2[x])
  if (all(unlist(lapply(var, function(v) any(names(di) %in% v)))) & all(unlist(lapply(var, function(v) any(names(di2) %in% v))))) {
    
    # COMPUTE INDEX
    
    index <- climate4R.chunk(n.chunks = n.chunks, C4R.FUN.args = C4R.FUN.args)
    index[["Variable"]][["varName"]] <- AtlasIndex
    index <- redim(index, drop = TRUE)
    
    # WRITE .nc FILES
    
    lapply(target.years, function(y) {
      index.x <- subsetGrid(index, years = y)
      grid2nc(index.x, paste0(out.dir, datasets2[x], "_", AtlasIndex, "_", y, ".nc4"))
    })
    index <- NULL
  }
})

# End
