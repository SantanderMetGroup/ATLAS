options(java.parameters = "-Xmx8000m")
library(loadeR)
source("/oceano/gmeteo/WORK/maialen/WORKm/GIT/climate4R/R/climate4R.chunk.R")
library(loadeR)
library(transformeR)
library(loadeR.2nc)
library(climate4R.indices)

# PARAMETER SETTING FOR DATA LOADING, INDEX CALCULATION AND EXPORT---------------------------------------------------------------------------

out.dir <- "/oceano/gmeteo/WORK/PROYECTOS/2018_IPCC/data/CMIP5/"


## Datasets
# scenario <- "rcp85"
# cmip <- UDG.datasets(paste0("CMIP5"))$CMIP5_AR5_1run

datasets <- read.csv("/oceano/gmeteo/WORK/PROYECTOS/2018_IPCC/CMIP5/CMIP5_AR5_1run_subset.txt", header = FALSE, na.strings = "NA")
# ind <- unlist(lapply (1:nrow(datasets), function(i) if(all(!is.na(datasets[i,]))) i))
# datasets <- lapply(datasets[ind,], function(x) as.character(x))
datasets <- lapply(datasets, function(x) as.character(x))
cmip <- do.call("c", datasets)
cmip <- cmip[!is.na(cmip)]




# COMPUTE INDEX ----------------------------------------------------------------------------------------------------


lapply(1:length(cmip), function(i) {
  di <- dataInventory(cmip[i])
  if (any(names(di) %in% "pr")) {
    ch <- strsplit(di$pr$Dimensions$time$Date_range, "-")[[1]][c(1,4)]
    years <- as.numeric(ch[1]):as.numeric(ch[2])
years <- years[which(years<2101)]
years <- years[which(years>1949)]
    lapply(years, function(x){
      if (!file.exists(paste0(out.dir, "pr99/", cmip[i], "_pr99_annual_", x, ".nc4"))) {
        
      print(paste0(x, "----------------------------------------------------------------"))
      index <- climate4R.chunk(n.chunks = 2,
                               C4R.FUN.args = list(FUN = "indexGrid",
                                                   pr = list(dataset = cmip[i], var = "pr"),
                                                   index.code = "P",
                                                   time.resolution = "year",
                                                   percent = 99),
                               loadGridData.args = list(years = x))
      index <- redim(index, drop = TRUE)
      message(x, ".........", i)
      grid2nc(index, NetCDFOutFile = paste0(out.dir, "pr99/", cmip[i], "_pr99_annual_", x, ".nc4"))
      }
    })
  } 
})
