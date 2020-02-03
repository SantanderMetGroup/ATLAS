options(java.parameters = "-Xmx8000m")
library(loadeR)
source("/oceano/gmeteo/WORK/maialen/WORKm/GIT/climate4R/R/climate4R.chunk.R")

#source("/IPCC/climate4R.chunk.R")
library(loadeR)
library(transformeR)
library(loadeR.2nc)
library(climate4R.indices)
library(drought4R)

# PARAMETER SETTING FOR DATA LOADING, INDEX CALCULATION AND EXPORT---------------------------------------------------------------------------

out.dir <- "/oceano/gmeteo/WORK/PROYECTOS/2018_IPCC/data/CMIP5/"

#out.dir <- "/IPCC/data/CMIP5/"

## Datasets
# scenario <- "rcp85"
# cmip <- UDG.datasets(paste0("CMIP5"))$CMIP5_AR5_1run

datasets <- read.csv("/oceano/gmeteo/WORK/PROYECTOS/2018_IPCC/CMIP5/CMIP5_AR5_1run_subset.txt", header = FALSE, na.strings = "NA")

#datasets <- read.csv("/IPCC/CMIP5_AR5_1run_subset.txt", header = FALSE, na.strings = "NA")

# ind <- unlist(lapply (1:nrow(datasets), function(i) if(all(!is.na(datasets[i,]))) i))
# datasets <- lapply(datasets[ind,], function(x) as.character(x))
datasets <- lapply(datasets, function(x) as.character(x))
cmip <- do.call("c", datasets)
cmip <- cmip[!is.na(cmip)]
cmip <- cmip[44:length(cmip)]

cmip <- cmip[12:length(cmip)]
cmip <- cmip[17:length(cmip)]
cmip <- cmip[31:length(cmip)]

# COMPUTE INDEX ----------------------------------------------------------------------------------------------------


lapply(1:length(cmip), function(i) {
  di <- dataInventory(cmip[i])
  if (any(names(di) %in% "pr")) {
    ch <- strsplit(di$pr$Dimensions$time$Date_range, "-")[[1]][c(1,4)]
    years <- as.numeric(ch[1]):as.numeric(ch[2])
years <- years[which(years<2101)]
years <- years[which(years>1949)]
    index <- climate4R.chunk(n.chunks = 2,
                             C4R.FUN.args = list(FUN = "speiGrid", pr.grid = list(dataset = cmip[i], var = "pr"), scale = 12),
                             loadGridData.args = list(years = years, aggr.m = "sum"))
    index <- redim(index, drop = TRUE)
    message(".........", i)
    object.size(index)
index$Data[which(is.infinite(index$Data))] <- NA
    lapply(years[-1], function(x){
      print(paste0("------", i, "-----------------------------------------------"))
      index.x <- subsetGrid(index, years = x)
      grid2nc(index.x, NetCDFOutFile = paste0(out.dir, "spi12/", cmip[i], "_spi12_monthly_", x, ".nc4"))
    })
  } 
})
