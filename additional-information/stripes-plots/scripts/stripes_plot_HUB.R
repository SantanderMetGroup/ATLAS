library(climate4R.UDG)
library(loadeR)
library(lattice)
library(RColorBrewer)

# PARAMETER SETTING ----------------
project <- "CMIP6"; scenario <- "ssp585"
lonLim <- c(-10, 5)
latLim <- c(35, 44)
var <- "meanpr"
output.dir <- paste0("/oceano/gmeteo/WORK/PROYECTOS/2018_IPCC/data/", project, "/")

# FUNCTION -----------------
stripes.hub <- function(project, scenario, latLim, lonLim, var, output.dir) {
  # SELECT COMMON MODELS IN HIST AND SSP
  all <- list.files(paste0("/oceano/gmeteo/WORK/PROYECTOS/2018_IPCC/data/", project, "/", var, "/ensemble/"), full.names = T)
  hist <- grep("historical", all, value = T)
  fut <- grep(scenario, all, value = T)
  all <- NULL
  members.fut <- dataInventory(fut[1])[[var]]$Dimensions$member$Values
  members <- dataInventory(hist[1])[[var]]$Dimensions$member$Values
  members <- unique(c(members, members.fut))
  # mems.f <- unlist(lapply(members.hist, grep, x = members.fut, value = T))
  # mems.h <- unlist(lapply(mems.f, grep, x = members.hist, value = T))
  # if (!identical(mems.f, mems.h)) stop("Error with members!!!")
  data <- lapply(c(hist, fut), function(x) {
    message("[", Sys.time(), "] Processing ", x)
    g <- suppressMessages(loadGridData(x, var = var, lonLim = lonLim, latLim = latLim))
    g <-  suppressMessages(climatology(g))
    ind <- lapply(members, function(i) {
      print(i)
      ind <- grep(i, x = g$Members)
      if (length(ind) == 0) {
        NA
      } else {
        g <- subsetGrid(g, members = ind)
        message("[", Sys.time(), "] Done.")
        suppressMessages(aggregateGrid(redim(g, member = F), aggr.lon = list(FUN = "mean", na.rm = T), aggr.lat = list(FUN = "mean", na.rm = T))$Data)
      }
    })
    do.call("c", ind)
  })
  df <- do.call("rbind", data)
  colnames(df) <- members
  rownames(df) <- gsub(".*_|.nc4", "", c(hist, fut))
  
  library(RColorBrewer)
  precip <- grep(var, c("pr", "meanpr", "Rx5day", "CDD", "spi6", "spi12"))
  pal <- if (length(precip) != 0) {
    brewer.pal(9, name = "GnBu")
  }  else {
    brewer.pal(9, name = "YlOrRd")
  }
  x.scale <- seq(1, nrow(df), by = 5)
  val.range <- c(floor(min(df, na.rm = T)) - 1, ceiling(max(df, na.rm = T)) + 1)
  by <- round((val.range[2] - val.range[1]) / 10, digits = 1)
  col.scale <- seq(from = val.range[1], to = val.range[2], by = 0.5)
  
  output.file <- paste0(output.dir, "/", project, "_", scenario, "_", var, "_stripes.pdf")
  pdf(paste0(), width = 15, height = 7)
  levelplot(t(t(df)), aspect = 0.4,#"iso", 
            scales = list(x = list(at = x.scale, labels = rownames(df)[x.scale], rot = 45)),
            at = col.scale,
            main = paste(project, scenario, var),
            col.regions = colorRampPalette(pal)(100), 
            xlab = NULL, ylab = NULL)
  dev.off()
}


#### APLLY

stripes.hub(project, scenario, latLim, lonLim, var, output.dir)
