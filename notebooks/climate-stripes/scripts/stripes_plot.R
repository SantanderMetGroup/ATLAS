library(climate4R.UDG)
library(loadeR)
library(lattice)
library(RColorBrewer)

# PARAMETER SETTING ----------------
#subset could be:
# > z <- UDG.datasets()
# Label names are returned, set argument full.info = TRUE to get more information
# > names(z)
project <- "CMIP6"; subset <- "CMIP6"; scenario <- "ssp585"
lonLim <- c(-10, 5)
latLim <- c(35, 44)
hist.years <- 1850:2014
fut.years <- 2015:2100
baseline <- 1981:2010
var <- "tas"
istheremask <- "NOmask" #"NOmask"
output.file <- "stripes"


stripes <- function(project, subset, scenario, latLim, lonLim, hist.years, fut.years, var, istheremask = "NOmask", output.dir) {
  # SELECT COMMON MODELS IN HIST AND SSP
  hist <- UDG.datasets(paste0(project, ".*historical"), full.info = T)[[subset]]
  fut <- UDG.datasets(paste0(project, ".*", scenario))[[subset]]
  
  hist.m.ind <- unlist(lapply(fut, function(i) grep(gsub(scenario, "", i), gsub("historical", "", hist))))
  
  if (!identical(gsub("historical", "", hist)[hist.m.ind], gsub(scenario, "", fut))) stop("NOT EQUAL DATASETS IN HISTORICAL")
  
  hist <- hist[hist.m.ind]
  
  
  # hist <- hist[-9]
  # fut <- fut[-9]
  
  # RETAIN MODELS CONTAINING THE TARGET VARIABLE ------------
  dih <- lapply(hist, function(d) {
    print(d)
    dataInventory(d)
  })
  dif <- lapply(fut, function(d) {
    print(d)
    dataInventory(d)
  })
  
  if (istheremask != "NOmask") {
    #WITH MASK--------------------------------------
    vh <- unlist(lapply(dih, function(i) var %in% names(i) & "sftlf" %in% names(i)))
    vf <- unlist(lapply(dif, function(i) var %in% names(i)))
    ind <- intersect(which(vh), which(vf))
    h <- lapply(hist[ind], function(x) loadGridData(x, var = var, years = hist.years, lonLim = lonLim, latLim = latLim, aggr.m = "mean"))
    f <- lapply(fut[ind], function(x) loadGridData(x, var = var, years = fut.years, lonLim = lonLim, latLim = latLim, aggr.m = "mean"))
    masks <- lapply(hist[ind], function(x) loadGridData(x, var = "sftlf", lonLim = lonLim, latLim = latLim))
    masks <- lapply(masks, function(x) binaryGrid(x, condition = "GT", threshold = 0.9, values = c(NA, 1)))
    
    hy <- lapply(h, function(i) aggregateGrid(redim(i, member = FALSE), aggr.y = list(FUN="mean", na.rm = TRUE)))
    fy <- lapply(f, function(i) aggregateGrid(redim(i, member = FALSE), aggr.y = list(FUN="mean", na.rm = TRUE)))
    
    hf <- lapply(1:length(hy), function(i) bindGrid(hy[[i]], fy[[i]], dimension = "time"))
    
    s <- lapply(hf, function(x) getShape(x)[["time"]])
    
    masks.redimed <- lapply(1:length(masks), function(x) bindGrid(rep(list(masks[[x]]), s[[x]]), dimension = "time"))
    
    hf <- lapply(1:length(hf), function(x) gridArithmetics(hf[[x]], masks.redimed[[x]], operator = "*"))
    
    hfa <- lapply(hf, function(x) aggregateGrid(x, aggr.lat = list(FUN = "mean", na.rm = TRUE), aggr.lon = list(FUN = "mean", na.rm = TRUE)))
    
  } else {
    # WITHOUT MASK------------------------------------------
    
    vh <- unlist(lapply(dih, function(i) var %in% names(i)))
    vf <- unlist(lapply(dif, function(i) var %in% names(i)))
    ind <- intersect(which(vh), which(vf))
    h <- lapply(hist[ind], function(x) loadGridData(x, var = var, years = hist.years, lonLim = lonLim, latLim = latLim, aggr.m = "mean"))
    f <- lapply(fut[ind], function(x) loadGridData(x, var = var, years = fut.years, lonLim = lonLim, latLim = latLim, aggr.m = "mean"))
    hy <- lapply(h, function(i) aggregateGrid(redim(i, member = FALSE), aggr.y = list(FUN="mean", na.rm = TRUE)))
    fy <- lapply(f, function(i) aggregateGrid(redim(i, member = FALSE), aggr.y = list(FUN="mean", na.rm = TRUE)))
    
    hf <- lapply(1:length(hy), function(i) bindGrid(hy[[i]], fy[[i]], dimension = "time"))
    hfa <- lapply(hf, function(x) aggregateGrid(x, aggr.lat = list(FUN = "mean", na.rm = TRUE), aggr.lon = list(FUN = "mean", na.rm = TRUE)))
    
  }
  # EXTRACT DATA MATRIX AND PLOT ---------------------------
  z <- lapply(hfa, "[[", "Data")
  df <- data.frame(z)
  colnames(df) <- gsub("_historical", "", hist[ind])
  rownames(df) <- substr(hf[[1]]$Dates$start, start = 1, stop = 4)
  save(df, file = paste0(output.file, "_df_", project, "_", scenario, "_", istheremask, ".rda"))
  
  # load(paste0("stripe_df_", project, "_", scenario, "_", istheremask,".rda"))
  # df <- df[-(1:100),]
  library(RColorBrewer)
  pal <- brewer.pal(9, name = "YlOrRd")
  x.scale <- seq(1, nrow(df), by = 5)
  col.scale <- seq(floor(min(df)), ceiling(max(df)), by = 1)
  
  pdf(paste0(output.file, "_plot_", scenario, "_", istheremask, "_", var, ".pdf"), width = 15, height = 7)
  levelplot(t(t(df)), aspect = 0.4,#"iso", 
            scales = list(x = list(at = x.scale, labels = rownames(df)[x.scale], rot = 45)),
            at = col.scale,
            main = var,
            col.regions = colorRampPalette(pal)(100), 
            xlab = NULL, ylab = NULL)
  dev.off()
  
  ind <- which(rownames(df) == baseline[1]):which(rownames(df) == baseline[length(baseline)])
  df.hist <- df[ind,]
  mean.hist <- apply(df.hist, MARGIN = 2, mean)
  delta <- df
  for (i in 1:nrow(df)) delta[i,] <- df[i,] - mean.hist
  pal <- rev(brewer.pal(9, name = "RdBu"))
  col.scale <- seq(ceiling(max(delta))*-1, ceiling(max(delta)), by = 0.5)
  pdf(paste0(output.file, "_plot_DELTA-wrt-", paste(range(baseline), collapse = "-"), "_", project, "_", scenario, "_", istheremask, "_", var,".pdf"), width = 15, height = 7)
  levelplot(t(t(delta)), aspect = 0.4, #"iso", 
            scales = list(x = list(at = x.scale, labels = rownames(df)[x.scale], rot = 45)),
            at = col.scale,
            main = var,
            col.regions = colorRampPalette(pal)(100), 
            xlab = NULL, ylab = NULL)
  dev.off()
}
