# This script builds on the climate4R framework 
# https://github.com/SantanderMetGroup/climate4R

library(devtools)
# Data loading and writting libraries:
library(loadeR)
library(loadeR.2nc)
# Index calculation libraries:
library(transformeR)
library(climate4R.indices)
library(climate4R.climdex)
library(drought4R)
# Function for latitudinal chunking (read script from website):
## see https://github.com/SantanderMetGroup/climate4R/tree/master/R !!!!!!!!!!!!!!!!!!!
source_url("https://github.com/SantanderMetGroup/climate4R/blob/master/R/climate4R.chunk.R?raw=TRUE")


# DATA ACCESS ------------------------------------------------------------------------------------
# Data is accessed remotely from the Santander Climate Data Service
# Obtain a user and password at http://meteo.unican.es/udg-wiki
loginUDG(username = "yourUser", password = "yourPassword")


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

# therefore, next select one of the rest, e.g.
AtlasIndex <- "FD"


#select datasets, e.g.:
datasets <- UDG.datasets()[["CMIP5_AR5_1run"]]
#or, e.g.:
# datasets <- UDG.datasets()[["CMIP6_1run"]]

# to use the same subset of datasets used in the Atlas so far, use the *.csv files 
# of the inventories () 
# and read the first column as follows:
# datasets <- read.csv("AtlasHub-inventory/CMIP5_Atlas_20191211.csv")[,1]

# Number of chunks, e.g.:
n.chunks <- 2

#output path, e.g.
out.dir <- getwd()




# AUTHOMATIC PARAMETER DEFINITION BASED ON OBJECT `AtlasIndex` and COMPUTE INDEX-------------------------------------------------

lapply(1:length(datasets), function(i) {
  # PARAMETER DEFINITION
  switch(AtlasIndex, 
         FD = {
           var <- "tasmin"
           index <- "FD"
           # The climate4R function to be applied and the corresponding function arguments, e.g.:
           ## see https://github.com/SantanderMetGroup/climate4R/tree/master/R !!!!!!!!!!!!!!!!!!!
           C4R.FUN.args = list(FUN = "indexGrid",
                               tn = list(dataset = datasets[i], var = var),
                               index.code = index,
                               time.resolution = "month")
           # Note that [i] is added in datasets, this is because the index calculation is 
           # performed in a 1:length(datasets) loop !!!!!!!!!!!!!!
         },
         HDD = {
           var <- c("tasmin", "tasmax", "tas")
           index <- "HDD"
           C4R.FUN.args = list(FUN = "indexGrid",
                               tn = list(dataset = datasets[i], var = "tasmin"),
                               tx = list(dataset = datasets[i], var = "tasmax"),
                               tm = list(dataset = datasets[i], var = "tas"),
                               index.code = index,
                               time.resolution = "year")
         },
         pr = {
           var <- "pr"
           C4R.FUN.args = list(FUN = "aggregateGrid",
                               grid = list(dataset = datasets[i], var = var),
                               aggr.m = list(FUN = sum, na.rm = TRUE))
         },
         pr99 = {
           var <- "pr"
           index <- "P"
           C4R.FUN.args = list(FUN = "indexGrid",
                               pr = list(dataset = datasets[i], var = var),
                               index.code = index,
                               time.resolution = "year",
                               percent = 99)
         },
         Rx1day = {
           var <- "pr"
           C4R.FUN.args = list(FUN = "aggregateGrid",
                               grid = list(dataset = datasets[i], var = var),
                               aggr.m = list(FUN = max, na.rm = TRUE))
         },
         Rx5day = {
           var <- "pr"
           index <- "Rx5day"
           C4R.FUN.args = list(FUN = "climdexGrid",
                               pr = list(dataset = datasets[i], var = var),
                               index.code = index)
         },
         T21.5 = {
           var <- "tas"
           index <- "TXth"
           C4R.FUN.args = list(FUN = "indexGrid",
                               tx = list(dataset = datasets[i], var = var),
                               index.code = index,
                               time.resolution = "month",
                               th = 21.5)
         },
         tas = {
           var <- "tas"
           C4R.FUN.args = list(FUN = "aggregateGrid",
                               grid = list(dataset = datasets[i], var = var),
                               aggr.m = list(FUN = mean, na.rm = TRUE))
         },
         tasmax = {
           var <- "tasmax"
           C4R.FUN.args = list(FUN = "aggregateGrid",
                               grid = list(dataset = datasets[i], var = var),
                               aggr.m = list(FUN = mean, na.rm = TRUE))
         },
         tasmin = {
           var <- "tasmin"
           C4R.FUN.args = list(FUN = "aggregateGrid",
                               grid = list(dataset = datasets[i], var = var),
                               aggr.m = list(FUN = mean, na.rm = TRUE))
         },
         TNn = {
           var <- "tasmin"
           C4R.FUN.args = list(FUN = "aggregateGrid",
                               grid = list(dataset = datasets[i], var = var),
                               aggr.m = list(FUN = min, na.rm = TRUE))
         },
         TXx = {
           var <- "tasmax"
           C4R.FUN.args = list(FUN = "aggregateGrid",
                               grid = list(dataset = datasets[i], var = var),
                               aggr.m = list(FUN = max, na.rm = TRUE))
         },
         TX35 = {
           var <- "tasmax"
           index <- "TXth"
           C4R.FUN.args = list(FUN = "indexGrid",
                               tx = list(dataset = datasets[i], var = var),
                               index.code = index,
                               time.resolution = "month",
                               th = 35)
         },
         TX40 = {
           var <- "tasmax"
           index <- "TXth"
           C4R.FUN.args = list(FUN = "indexGrid",
                               tx = list(dataset = datasets[i], var = var),
                               index.code = index,
                               time.resolution = "month",
                               th = 40)
         }
  )
  # COMPUTE INDEX
  di <- dataInventory(datasets[i])
  if (all(unlist(lapply(var, function(v) any(names(di) %in% v))))) {
    ch <- strsplit(di[[var[1]]]$Dimensions$time$Date_range, "-")[[1]][c(1,4)]
    years <- as.numeric(ch[1]):as.numeric(ch[2])
    years <- years[which(years < 2101)]
    years <- years[which(years > 1949)]
    lapply(years, function(x){
      if (!file.exists(paste0(out.dir, "/", datasets[i], "_", AtlasIndex,"_", x, ".nc4"))) {
        print(paste0(x, "----------------------------------------------------------------"))
        index <- climate4R.chunk(n.chunks = n.chunks,
                                 C4R.FUN.args = C4R.FUN.args,
                                 loadGridData.args = list(years = x))
        index[["Variable"]][["varName"]] <- AtlasIndex
        index <- redim(index, drop = TRUE)
        message(x, ".........", datasets[i])
        grid2nc(index, NetCDFOutFile = paste0(out.dir, "/", datasets[i], "_", AtlasIndex, "_", x, ".nc4"))
      }
    })
  } 
})

# END
