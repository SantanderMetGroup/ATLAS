library(climate4R.value)
library(loadeR)
library(visualizeR)
library(stringr)
library(gridExtra)

#ncmls <- list.files("/oceano/gmeteo/WORK/PROYECTOS/ATLAS/tds/content/thredds/public/CMIP6/", pattern = "day.*.ncml", recursive = TRUE, full.names = TRUE)
ncmls <- c("/oceano/gmeteo/WORK/zequi/ATLAS/ESGF-inventory/tds-content/public/CMIP6/CMIP/NCAR/CESM2-WACCM/historical/day/CMIP6_CMIP_NCAR_CESM2-WACCM_historical_r1i1p1f1_day.ncml")
out.dir <- "test_cmip6"
lapply(1:length(ncmls), function(i){
  d <- ncmls[i]
  name <- unlist(lapply(strsplit(ncmls[i], "/"), function(l) l[length(l)]))
  tryCatch({
      if(length(grep("historical", name)) > 0) {
        z <- loadGridData(d, var = "tas", years = 2000, season = 8)
      } else {
        z <- loadGridData(d, var = "tas", years = 2016, season = 8)
      }
      p <- spatialPlot(climatology(z), backdrop.theme = "coastline")
      #pdf(p, file = paste0(out.dir, "/", name, ".pdf"))
      pdf(file = paste0(out.dir, "/", name, ".pdf"))
      print(p)
      dev.off()
  }, error=function(cond) {
        message("There was an error with:")
        message(name)
     })
})
