# AR6.WGI_hatching.R
#
# Copyright (C) 2021 Santander Meteorology Group (http://meteo.unican.es)
#
# This work is licensed under a Creative Commons Attribution 4.0 International
# License (CC BY 4.0 - http://creativecommons.org/licenses/by/4.0)

#' @title Hatching wrapper function applying atomic hatching functions
#' @description Function for computing two different uncertainty
#'   measures (simple and advanced) for Atlas Product Reproducibility. 
#' @author M. Iturbide


AR6.WGI.hatching <- function(delta, historical.ref = NULL, method, relative.delta = NULL, map.hatching.args = list(), ...){
  plot.args <- list(...)
  if (method == "advanced" & is.null(historical.ref)) stop("Provide historical.ref to use the advanced method")
  if (is.null(map.hatching.args[["threshold"]])) map.hatching.args[["threshold"]] <- 0.5
  if (is.null(map.hatching.args[["angle"]])) map.hatching.args[["angle"]] <- "-45"
  if (is.null(map.hatching.args[["lwd"]])) map.hatching.args[["lwd"]] <- 0.6
  if (is.null(map.hatching.args[["density"]])) map.hatching.args[["density"]] <- 4
  if (is.null(map.hatching.args[["upscaling.aggr.fun"]])) map.hatching.args[["upscaling.aggr.fun"]] <- list(FUN = mean)
  if (is.null(map.hatching.args[["condition"]])) map.hatching.args[["condition"]] <- "LT"
  if (is.null(plot.args[["backdrop.theme"]])) plot.args[["backdrop.theme"]] <- "coastline"
  
  simple <- suppressMessages(aggregateGrid(delta, aggr.mem = list(FUN = agreement, th = 80)))  
  
  if (method == "simple") {
    
    map.hatching.args[["clim"]] <- suppressMessages(climatology(simple))
    plot.args[["sp.layout"]] <- list(do.call("map.hatching", map.hatching.args))
    
  } else if (method == "advanced") {
    
    sign <- suppressMessages(signal(h = historical.ref, d = delta))
    
    advanced1 <- suppressMessages(aggregateGrid(sign, aggr.mem = list(FUN = signal.ens1, th = 66)))
    
    advanced2.aux <- suppressMessages(aggregateGrid(sign, aggr.mem = list(FUN = signal.ens2, th = 66)))
    advanced2.aux <- gridArithmetics(advanced2.aux, simple, operator = "+") 
    advanced2 <- binaryGrid(advanced2.aux, condition = "GT", threshold = 0)
    
    map.hatching.args[["clim"]] <-  suppressMessages(climatology(advanced1))
    advanced1.hatch <- do.call("map.hatching", map.hatching.args)
    map.hatching.args[["clim"]] <-  suppressMessages(climatology(advanced2))
    advanced2.hatch <- do.call("map.hatching", map.hatching.args)
    map.hatching.args[["angle"]] <-  as.character(as.numeric(map.hatching.args[["angle"]]) * -1)
    advanced2.hatch.bis <- do.call("map.hatching", map.hatching.args)
    plot.args[["sp.layout"]] <- list( advanced1.hatch, advanced2.hatch, advanced2.hatch.bis)
    
  } else {
    stop("Wrong method. Select 'simple' or 'advanced'")
  }
  
  if (!is.null(relative.delta)) {
    plot.args[["grid"]] <- relative.delta
  } else {
    plot.args[["grid"]] <- suppressMessages(aggregateGrid(delta, aggr.mem = list(FUN = mean, na.rm = TRUE)))
  }
  suppressWarnings(do.call("spatialPlot", plot.args))
}
  
