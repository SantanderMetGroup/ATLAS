library(loadeR)

datasets <- UDG.datasets("CMIP6")[["CMIP6"]]
datasets <- readLines('inventory_ncmls')

datasets.h <- datasets[grep("historical", datasets)]
datasets.f <- datasets[grep("ssp", datasets)]
test.h <- lapply(datasets.h, function(x){
  tryCatch({
    print(x)
    di <- dataInventory(x)
    loadGridData(x, var = names(di)[1], years = 2000, lonLim=c(0,180), season = 2:3, aggr.m = "mean")
  }, error = function(err) {print(err)})
})
test.f <- lapply(datasets.f, function(x){
  tryCatch({
    print(x)
    di <- dataInventory(x)
    loadGridData(x, var = names(di)[1], years = 2020, lonLim=c(0,180), season = 2:3, aggr.m = "mean")
  }, error = function(err) {print(err)})
})
names(test.h) <- datasets.h
names(test.f) <- datasets.f
lapply(test.h, is.null)
lapply(test.f, is.null)
