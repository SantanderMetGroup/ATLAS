options(java.parameters = "-Xmx8000m")
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

datasets1 <- datasets1[which(datasets1.aux %in% datasets2.aux)]
datasets2 <- datasets2[which(datasets2.aux %in% datasets1.aux)]


# scale argument in function speiGrid, e.g.:
scale <- 12
# Number of chunks, e.g.:
n.chunks <- 2




# COMPUTE INDEX ----------------------------------------------------------------------------------------------------

# The climate4R function to be applied:
spifun <- function(h, f, scale, ref.start, ref.end) {
  hf <- bindGrid(h, f, dimension = "time")
  speiGrid(hf, scale = scale, ref.start = ref.start, ref.end = ref.end)
}

# Application
lapply(1:length(datasets1), function(i) {
  di <- dataInventory(datasets1[i])
  if (any(names(di) %in% var)) {
    ch <- strsplit(di[[var]]$Dimensions$time$Date_range, "-")[[1]][c(1,4)]
    years <- as.numeric(ch[1]):as.numeric(ch[2])
    years <- years[which(years < 2101)]
    years <- years[which(years > 1949)]
    lapply(years, function(x){
      if (!file.exists(paste0(out.dir, "/", datasets2[i], "_", paste0("SPI-", scale),"_", x, ".nc4"))) {
        print(paste0(x, "----------------------------------------------------------------"))
        index <- climate4R.chunk(n.chunks = n.chunks,
                                 C4R.FUN.args = list(FUN = "spifun", h = list(dataset = datasets1[i], var = "pr", years = 1971:2005), 
                                                                     f = list(dataset = datasets2[i], var = "pr", years = years), 
                                                                     scale = scale,
                                                                     ref.start = c(1971, 1), ref.end = c(2010, 12)),
                                 loadGridData.args = list(aggr.m = "sum"))
        index[["Variable"]][["varName"]] <- paste0("SPI-", scale)
        index <- redim(index, drop = TRUE)
        message(x, ".........", i)
        grid2nc(index, NetCDFOutFile = paste0(out.dir, "/", datasets2[i], "_", paste0("SPI-", scale) , "_", x, ".nc4"))
      }
    })
  } 
})
