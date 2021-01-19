library(loadeR)

datasets <- UDG.datasets("CMIP6")[["CMIP6"]]
datasets <- readLines('ncmls')

dataset <- "/oceano/gmeteo/WORK/zequi/ATLAS/ESGF-inventory/tds-content/public/CMIP6/CMIP/NCAR/CESM2-WACCM/historical/day/CMIP6_CMIP_NCAR_CESM2-WACCM_historical_r1i1p1f1_day.ncml"
vars <- c("tas", "pr", "psl")
loadGridData(dataset, "tas", aggr.m = "mean")


#datasets.h <- datasets[grep("historical", datasets)]
#datasets.f <- datasets[-grep("historical", datasets)]
#test.h <- lapply(datasets.h, function(x){
#  tryCatch({
#    print(x)
#    loadGridData(x, var = "tas", lonLim = c(-10, -6), latLim = c(36, 38), years = 2000, season = 2:3, aggr.m = "mean")
#  }, error = function(err) {print(err)})
#})
#test.f <- lapply(datasets.f, function(x){
#  tryCatch({
#    print(x)
#    loadGridData(x, var = "tas", lonLim = c(-10, -6), latLim = c(36, 38), years = 2020, season = 2:3, aggr.m = "mean")
#  }, error = function(err) {print(err)})
#})
#names(test.h) <- datasets.h
#names(test.f) <- datasets.f
#lapply(test.h, is.null)
#lapply(test.f, is.null)
