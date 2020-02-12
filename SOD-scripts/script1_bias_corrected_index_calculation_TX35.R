options(java.parameters = "-Xmx8000m")
library(devtools)
# Data loading and writting libraries:
library(loadeR)
library(loadeR.2nc)
# Index calculation libraries:
library(climate4R.indices)
# Bias correction library:
library(downscaleR)

# Function for latitudinal chunking (read script from website):
## see https://github.com/SantanderMetGroup/climate4R/tree/master/R !!!!!!!!!!!!!!!!!!!
source_url("https://github.com/SantanderMetGroup/climate4R/blob/master/R/climate4R.chunk.R?raw=TRUE")


# PARAMETER SETTING FOR DATA LOADING, INDEX CALCULATION AND EXPORT---------------------------------------------------------------------------
## see https://github.com/SantanderMetGroup/climate4R/tree/master/R !!!!!!!!!!!!!!!!!!!

#output path
out.dir <- ""

#scenario, e.g.:
scenario <- "rcp85"
#select datasets, e.g.:
datasets1 <- UDG.datasets("CMIP5.*historical")[["CMIP5_AR5_1run"]]
datasets2 <-  UDG.datasets(paste0("CMIP5.*", scenario))[["CMIP5_AR5_1run"]]
datasets1.aux <- gsub("_historical", "", datasets1)
datasets2.aux <- gsub(paste0("_", scenario), "", datasets2)

datasets.hist <- datasets1[which(datasets1.aux %in% datasets2.aux)]
datasets.ssp <- datasets2[which(datasets2.aux %in% datasets1.aux)]

#observational dataset for bias correction (ncml), e.g.:

dataset.obs <- "EWEMBI_tasmax.ncml"


# Number of chunks, e.g.:
n.chunks <- 20

# Periods
years.hist <- 1980:2005
years.ssp <- 2006:2100


# COMPUTE INDEX ----------------------------------------------------------------------------------------------------

# The climate4R function to be applied:
fun.txth <- function(obs, hist, ssp){
  obs$Data <- obs$Data - 273.15
  bc.ssp <- biasCorrection(obs, hist, ssp, method = "eqm", precipitation = FALSE, window = c(30, 30))
  obs <- NULL; hist <- NULL; ssp <- NULL
  index.ssp.35 <- indexGrid(tx = bc.ssp, index.code = "TXth", th = 35, time.resolution = "month")
  bc.ssp <- NULL
  index.ssp.35 <- redim(index.ssp.35, drop = TRUE)
  return(index.ssp.35)
}

# Application
lapply(1:length(datasets.hist), function(x) {
  di <- dataInventory(datasets.hist[x])
  di2 <- dataInventory(datasets.ssp[x])
  if (any(names(di) %in% "tasmax") & any(names(di2) %in% "tasmax")) {
    index <- climate4R.chunk(n.chunks = n.chunks, C4R.FUN.args = list(FUN = "fun.txth",  obs = list(dataset = dataset.obs, var = "tasmax", years = years.hist),
                                                                hist = list(dataset = datasets.hist[x], var = "tasmax", years = years.hist),
                                                                ssp = list(dataset = datasets.ssp[x], var = "tasmax", years = years.ssp)))
    index[["Variable"]][["varName"]] <- "tx35bc"
    index <- redim(index, drop = TRUE)
    lapply(years.ssp, function(y) {
      index.x <- subsetGrid(index, years = y)
      grid2nc(index.x, paste0(out.dir, datasets.ssp[x], "_", "tx35bc", "_monthly_", y, ".nc4"))
    })
    index <- NULL
  }
})
