options(java.parameters = "-Xmx8000m")
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


# PARAMETER SETTING FOR DATA LOADING, INDEX CALCULATION AND EXPORT---------------------------------------------------------------------------
## see https://github.com/SantanderMetGroup/climate4R/tree/master/R !!!!!!!!!!!!!!!!!!!

#output path
out.dir <- ""
#select datasets, e.g.:
datasets <- UDG.datasets("CMIP5")[["CMIP5_AR5_1run"]]
# Number of chunks, e.g.:
n.chunks <- 2

# Variable and index
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

# COMPUTE INDEX ----------------------------------------------------------------------------------------------------

lapply(1:length(datasets), function(i) {
  di <- dataInventory(datasets[i])
  if (any(names(di) %in% var)) {
    ch <- strsplit(di[[var]]$Dimensions$time$Date_range, "-")[[1]][c(1,4)]
    years <- as.numeric(ch[1]):as.numeric(ch[2])
    years <- years[which(years<2101)]
    years <- years[which(years>1949)]
    lapply(years, function(x){
      if (!file.exists(paste0(out.dir, "/", datasets[i], "_", index,"_", x, ".nc4"))) {
        print(paste0(x, "----------------------------------------------------------------"))
        index <- climate4R.chunk(n.chunks = n.chunks,
                                 C4R.FUN.args = C4R.FUN.args,
                                 loadGridData.args = list(years = x))
        index[["Variable"]][["varName"]] <- index
        index <- redim(index, drop = TRUE)
        message(x, ".........", i)
        grid2nc(index, NetCDFOutFile = paste0(out.dir, "/", datasets[i], "_", index , "_", x, ".nc4"))
      }
    })
  } 
})
