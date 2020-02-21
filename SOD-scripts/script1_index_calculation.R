#     script1_index_calculation.R Generate Climate Index NetCDF4 files from CMIP5 and CMIP6 Model Outputs for Atlas Product Reproducibility
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

# Climate4R libraries for climate index calculation:
library(climate4R.indices)
library(climate4R.climdex)
library(drought4R)

# Function for latitudinal chunking (read script from remote master branch):
## For further details: https://github.com/SantanderMetGroup/climate4R/tree/master/R 
source_url("https://github.com/SantanderMetGroup/climate4R/blob/master/R/climate4R.chunk.R?raw=TRUE")


# DATA ACCESS ------------------------------------------------------------------
# Data is accessed remotely from the Santander Climate Data Service
# Obtain a user and password at http://meteo.unican.es/udg-wiki
climate4R.UDG::loginUDG(username = "yourUser", password = "yourPassword")


# USER PARAMETER SETTING: SELECT INDEX, DATASETS, NUMBER OF CHUNKS AND OUTPUT DIRECTORY--------------

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


## In the next example, the climate index FD (frost days) is selected:
AtlasIndex <- "FD"
# Note: DS and CDD are not yet included in the list of valid choices:
AtlasIndex <- match.arg(AtlasIndex, choices = c("pr", "pr99", "tas", "tasmin",
                                                "tasmax", "TNn", "TXx", "TX35", "TX40",
                                                "Rx1day", "Rx5day", "HDD", "FD", "T21.5")) 

# select datasets, e.g., the CMIP5 datasets:
datasets <- UDG.datasets()[["CMIP5_AR5_1run"]]
# or, e.g., for CMIP6:
# datasets <- UDG.datasets()[["CMIP6_1run"]]

# # TO USE THE SAME SET OF MODELS USED IN THE ATLAS uncomment this paragraph. 
# # Use the *.csv files of the inventories 
# # (https://github.com/SantanderMetGroup/ATLAS/tree/devel/AtlasHub-inventory).
# # This is the root of the ATLAS repo content:
# root <- "https://raw.githubusercontent.com/SantanderMetGroup/ATLAS/devel/"
# # read the first column of the desired *.csv file (e.g. CMIP5_Atlas_20191211.csv) as follows:
# file <- "AtlasHub-inventory/CMIP5_Atlas_20191211.csv"
# datasets <- read.csv(paste0(root, file))[,1]

# Number of chunks
# Note: chunking sequentially splits the task into manageable data chunks to avoid memory problems
# chunking operates by spliting the data into a predefined number latitudinal slices (n=2 in this example).
# Further details: https://github.com/SantanderMetGroup/climate4R/tree/master/R 
n.chunks <- 2

# outputs are stored in this directory (the working directory by default):
out.dir <- getwd()

# AUTOMATIC PARAMETER DEFINITION and INDEX CALCULATION -------------------------

lapply(1:length(datasets), function(i) {
  # Select the adequate parameters for target index computation based on 'AtlasIndex' value
  # The loop iterates over datasets
  C4R.FUN.args <- switch(AtlasIndex, 
                         FD = {
                           var <- "tasmin"
                           index <- "FD"
                           # The climate4R function to be applied and the corresponding function arguments, e.g.:
                           ## see https://github.com/SantanderMetGroup/climate4R/tree/master/R
                           list(FUN = "indexGrid",
                                tn = list(dataset = datasets[i], var = var),
                                index.code = index,
                                time.resolution = "month")
                         },
                         HDD = {
                           var <- c("tasmin", "tasmax", "tas")
                           index <- "HDD"
                           list(FUN = "indexGrid",
                                tn = list(dataset = datasets[i], var = "tasmin"),
                                tx = list(dataset = datasets[i], var = "tasmax"),
                                tm = list(dataset = datasets[i], var = "tas"),
                                index.code = index,
                                time.resolution = "year")
                         },
                         pr = {
                           var <- "pr"
                           list(FUN = "aggregateGrid",
                                grid = list(dataset = datasets[i], var = var),
                                aggr.m = list(FUN = sum, na.rm = TRUE))
                         },
                         pr99 = {
                           var <- "pr"
                           index <- "P"
                           list(FUN = "indexGrid",
                                pr = list(dataset = datasets[i], var = var),
                                index.code = index,
                                time.resolution = "year",
                                percent = 99)
                         },
                         Rx1day = {
                           var <- "pr"
                           list(FUN = "aggregateGrid",
                                grid = list(dataset = datasets[i], var = var),
                                aggr.m = list(FUN = max, na.rm = TRUE))
                         },
                         Rx5day = {
                           var <- "pr"
                           index <- "Rx5day"
                           list(FUN = "climdexGrid",
                                pr = list(dataset = datasets[i], var = var),
                                index.code = index)
                         },
                         T21.5 = {
                           var <- "tas"
                           index <- "TXth"
                           list(FUN = "indexGrid",
                                tx = list(dataset = datasets[i], var = var),
                                index.code = index,
                                time.resolution = "month",
                                th = 21.5)
                         },
                         tas = {
                           var <- "tas"
                           list(FUN = "aggregateGrid",
                                grid = list(dataset = datasets[i], var = var),
                                aggr.m = list(FUN = mean, na.rm = TRUE))
                         },
                         tasmax = {
                           var <- "tasmax"
                           list(FUN = "aggregateGrid",
                                grid = list(dataset = datasets[i], var = var),
                                aggr.m = list(FUN = mean, na.rm = TRUE))
                         },
                         tasmin = {
                           var <- "tasmin"
                           list(FUN = "aggregateGrid",
                                grid = list(dataset = datasets[i], var = var),
                                aggr.m = list(FUN = mean, na.rm = TRUE))
                         },
                         TNn = {
                           var <- "tasmin"
                           list(FUN = "aggregateGrid",
                                grid = list(dataset = datasets[i], var = var),
                                aggr.m = list(FUN = min, na.rm = TRUE))
                         },
                         TXx = {
                           var <- "tasmax"
                           list(FUN = "aggregateGrid",
                                grid = list(dataset = datasets[i], var = var),
                                aggr.m = list(FUN = max, na.rm = TRUE))
                         },
                         TX35 = {
                           var <- "tasmax"
                           index <- "TXth"
                           list(FUN = "indexGrid",
                                tx = list(dataset = datasets[i], var = var),
                                index.code = index,
                                time.resolution = "month",
                                th = 35)
                         },
                         TX40 = {
                           var <- "tasmax"
                           index <- "TXth"
                           list(FUN = "indexGrid",
                                tx = list(dataset = datasets[i], var = var),
                                index.code = index,
                                time.resolution = "month",
                                th = 40)
                         }
  )
  # COMPUTE INDEX 
  # Inventory of available variables in the dataset[i]:
  di <- dataInventory(datasets[i])
  
  # Check variable availability:
  if (all(unlist(lapply(var, function(v) any(names(di) %in% v))))) {
    
    # Retrieve annual sequence from start year to end year of the dataset, as integers:
    ch <- as.integer(strsplit(di[[var[1]]]$Dimensions$time$Date_range, "-")[[1]][c(1,4)])
    years <- seq(ch[1], ch[2])
    years <- years[which(years < 2101 & years > 1949)]
    
    # The function iterates over years, generating one NetCDF4 file per dataset and year:
    lapply(years, function(x){
      # Check that the file does not exist already
      if (!file.exists(paste0(out.dir, "/", datasets[i], "_", AtlasIndex, "_", x, ".nc4"))) {
        message(paste0(x, "----------------------------------------------------------------"))
        index <- climate4R.chunk(n.chunks = n.chunks,
                                 C4R.FUN.args = C4R.FUN.args,
                                 loadGridData.args = list(years = x))
        index[["Variable"]][["varName"]] <- AtlasIndex
        index <- redim(index, drop = TRUE)
        message(x, ".........", datasets[i])
        # Write NetCDF4
        grid2nc(index, NetCDFOutFile = paste0(out.dir, "/", datasets[i], "_", AtlasIndex, "_", x, ".nc4"))
      }
    })
  } 
})

# END
