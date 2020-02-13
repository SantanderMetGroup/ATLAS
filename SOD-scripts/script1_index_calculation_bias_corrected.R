library(devtools)
# Data loading and writting libraries:
library(loadeR)
library(loadeR.2nc)
# Index calculation libraries:
library(climate4R.indices)
# Function for latitudinal chunking (read script from website):
## see https://github.com/SantanderMetGroup/climate4R/tree/master/R !!!!!!!!!!!!!!!!!!!
source_url("https://github.com/SantanderMetGroup/climate4R/blob/master/R/climate4R.chunk.R?raw=TRUE")


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

# Next select one of TX35bc and TX40bc, e.g.
AtlasIndex <- "TX35bc"

#scenario, e.g.:
scenario <- "rcp85"

#select datasets, for the observational reference and the historical (datasets1) 
# and rcp (datasets2) scenarios, e.g.:
dataset.obs <- "ncml_to_the_daily_observational_dataset.ncml"
datasets1 <- UDG.datasets("CMIP5.*historical")[["CMIP5_AR5_1run"]]
datasets2 <-  UDG.datasets(paste0("CMIP5.*", scenario))[["CMIP5_AR5_1run"]]

# Number of chunks, e.g.:
n.chunks <- 2

#output path, e.g.
out.dir <- getwd()




# PARAMETER DEFINITION BASED ON OBJECT `AtlasIndex` and COMPUTE INDEX -------------------------------------------------

# Match commong datasets among scenarios
datasets1.aux <- gsub("_historical", "", datasets1)
datasets2.aux <- gsub(paste0("_", scenario), "", datasets2)

datasets1 <- datasets1[which(datasets1.aux %in% datasets2.aux)]
datasets2 <- datasets2[which(datasets2.aux %in% datasets1.aux)]

# Years for calibration and years to be corrected
years.cal <- 1980:2005
years.target <- 2006:2100


lapply(1:length(datasets1), function(x) {
  # PARAMETER DEFINITION
  switch(AtlasIndex, 
         TX35bc = {
           var <- "tasmax"
           # The climate4R function to be applied:
           funfun <- function(obs, hist, ssp, th){
             bc.ssp <- biasCorrection(obs, hist, ssp, method = "eqm", precipitation = FALSE, window = c(30, 30))
             obs <- NULL; hist <- NULL; ssp <- NULL
             index.ssp <- indexGrid(tx = bc.ssp, index.code = "TXth", th = th, time.resolution = "month")
             bc.ssp <- NULL
             index.ssp <- redim(index.ssp, drop = TRUE)
             return(index.ssp)
           }
             C4R.FUN.args = list(FUN = "funfun",  obs = list(dataset = dataset.obs, var = var, years = years.cal),
                                 hist = list(dataset = datasets1[x], var = var, years = years.cal),
                                 ssp = list(dataset = datasets2[x], var = var, years = years.target),
                                 th = 35)
         },
         TX40bc = {
           var <- "tasmax"
           funfun <- function(obs, hist, ssp, th){
             bc.ssp <- biasCorrection(obs, hist, ssp, method = "eqm", precipitation = FALSE, window = c(30, 30))
             obs <- NULL; hist <- NULL; ssp <- NULL
             index.ssp <- indexGrid(tx = bc.ssp, index.code = "TXth", th = th, time.resolution = "month")
             bc.ssp <- NULL
             index.ssp <- redim(index.ssp, drop = TRUE)
             return(index.ssp)
           }
           C4R.FUN.args = list(FUN = "funfun",  obs = list(dataset = dataset.obs, var = var, years = years.cal),
                               hist = list(dataset = datasets1[x], var = var, years = years.cal),
                               ssp = list(dataset = datasets2[x], var = var, years = years.target),
                               th = 40)
         })
  # COMPUTE INDEX
  di <- dataInventory(datasets1[x])
  di2 <- dataInventory(datasets2[x])
  if (all(unlist(lapply(var, function(v) any(names(di) %in% v)))) | all(unlist(lapply(var, function(v) any(names(di2) %in% v))))) {
    index <- climate4R.chunk(n.chunks = n.chunks, C4R.FUN.args = C4R.FUN.args)
    index[["Variable"]][["varName"]] <- AtlasIndex
    index <- redim(index, drop = TRUE)
    lapply(years.target, function(y) {
      index.x <- subsetGrid(index, years = y)
      grid2nc(index.x, paste0(out.dir, datasets2[x], "_", AtlasIndex, "_", y, ".nc4"))
    })
    index <- NULL
  }
})
