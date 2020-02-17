# This script builds on the climate4R framework 
# https://github.com/SantanderMetGroup/climate4R

library(devtools)
# Data loading and writting libraries:
library(loadeR)
library(loadeR.2nc)
# Index calculation libraries:
library(transformeR)
library(drought4R)
# Function for latitudinal chunking (read script from website):
## see https://github.com/SantanderMetGroup/climate4R/tree/master/R !!!!!!!!!!!!!!!!!!!
source_url("https://github.com/SantanderMetGroup/climate4R/blob/master/R/climate4R.chunk.R?raw=TRUE")

# DATA ACCESS ------------------------------------------------------------------------------------
# Data is accessed remotely from the Santander Climate Data Service
# Obtain a user and password at http://meteo.unican.es/udg-wiki
loginUDG(username = "yourUser", password = "yourPassword")


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

# Next select one of SPI6 and SPI12, e.g.
AtlasIndex <- "SPI6"

#scenario, e.g.:
scenario <- "rcp85"

#select datasets, for the historical (datasets1) and rcp (datasets2) scenarios, e.g.:
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

# Number of chunks, e.g.:
n.chunks <- 2

#output path, e.g.
out.dir <- getwd()




# PARAMETER DEFINITION BASED ON OBJECT `AtlasIndex` and COMPUTE INDEX -------------------------------------------------

# Match common datasets among scenarios
datasets1.aux <- gsub("_historical", "", datasets1)
datasets2.aux <- gsub(paste0("_", scenario), "", datasets2)

datasets1 <- datasets1[which(datasets1.aux %in% datasets2.aux)]
datasets2 <- datasets2[which(datasets2.aux %in% datasets1.aux)]

# The climate4R function to be applied:
spifun <- function(h, f, scale, ref.start, ref.end) {
  hf <- bindGrid(h, f, dimension = "time")
  speiGrid(hf, scale = scale, ref.start = ref.start, ref.end = ref.end)
}

# PARAMETER DEFINITION
switch(AtlasIndex, 
       SPI6 = {
         scale <- 6
       },
       SPI12 = {
         scale <- 12
       })
# COMPUTE INDEX 
lapply(1:length(datasets1), function(i) {
  di <- dataInventory(datasets1[i])
  di2 <- dataInventory(datasets2[i])
  if (any(names(di) %in% "pr") | any(names(di2) %in% "pr")) {
    ch <- strsplit(di[["pr"]]$Dimensions$time$Date_range, "-")[[1]][c(1,4)]
    years <- as.numeric(ch[1]):as.numeric(ch[2])
    years <- years[which(years < 2101)]
    years <- years[which(years > 1949)]
    lapply(years, function(x){
      if (!file.exists(paste0(out.dir, "/", datasets2[i], "_", AtlasIndex,"_", x, ".nc4"))) {
        print(paste0(x, "----------------------------------------------------------------"))
        index <- climate4R.chunk(n.chunks = n.chunks,
                                 C4R.FUN.args = list(FUN = "spifun", h = list(dataset = datasets1[i], var = "pr", years = 1971:2005), 
                                                                     f = list(dataset = datasets2[i], var = "pr", years = years), 
                                                                     scale = scale,
                                                                     ref.start = c(1971, 1), ref.end = c(2010, 12)),
                                 loadGridData.args = list(aggr.m = "sum"))
        index[["Variable"]][["varName"]] <- AtlasIndex
        index <- redim(index, drop = TRUE)
        message(x, ".........", i)
        grid2nc(index, NetCDFOutFile = paste0(out.dir, "/", datasets2[i], "_", AtlasIndex , "_", x, ".nc4"))
      }
    })
  } 
})
