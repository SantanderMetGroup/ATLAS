# varInventoryTable.R
#
# Copyright (C) 2021 Santander Meteorology Group (http://meteo.unican.es)
#
# This work is licensed under a Creative Commons Attribution 4.0 International
# License (CC BY 4.0 - http://creativecommons.org/licenses/by/4.0)

#' @title Variable inventory table
#' @description Retrieves inventory of variables available at the User Data
#'   Gateway, e.g. for CMIP and CORDEX projects and dumps them in CSV format
#' @author M. Iturbide

varInventoryTable <- function(datasets, output.file = NULL, plot = FALSE) {
  require(abind)
  require(lattice)
  di <- lapply(datasets, function(x) {
    print(x)
    dataInventory(x)
  })
  names(di) <- datasets
  divar <- lapply(di, function(x) names(x))
  divers <- lapply(di, function(x) unlist(lapply(x, function(v) v[["Version"]])))
  divarc <- unique(unname(do.call("abind", divar)))
  dilevel <- list()
  for(i in 1:length(di)) {
    dilevel[[i]] <- lapply(divarc, function(x) di[[i]][[x]][["Dimensions"]][["level"]][["Values"]])
  }
  names(dilevel) <- names(di)
  levels <- unique(unlist(dilevel))
  df <- array(dim = c(length(divar), length(divarc)), dimnames = list(names(divar), divarc))
  for (i in 1:length(divarc)) {
    df[,i] <- unlist(
      lapply(1:length(divar), function(x) {
        logi <- divarc[i] %in% divar[[x]]
        if (isTRUE(logi)) {
          divers[[x]][[divarc[i]]]
        } else {
          logi
        } 
      })
    )
  }
  dd <- lapply(dilevel, function(l) unlist(l))
  dflevels <- array(dim = c(length(di), length(levels)), dimnames = list(names(di), levels))
  for (i in 1:length(levels)) {
    dflevels[,i] <- unlist(lapply(dd, function(x) levels[i] %in% x))
  }
  df <- cbind(df, dflevels)
  if (!is.null(output.file)) write.csv(df, file = output.file)
  if (plot) {
  dfpl <- levelplot(t(df), scales=list(x=list(alternating=2, rot=90, cex = 0.5),
                                       y=list(cex = 0.5)),
                    border = "red", bw = 10, ylab = NULL, colorkey = FALSE,
                    col.regions = rev(gray.colors(16, start = 0.5, end = 1)),
                    xlab = list("gray = available      white = not available", cex = 0.8))
  return(list("data" = df, "plot" = dfpl))
  } else {
  return(df)
  }
}

library(loadeR)
loginUDG("username","password")
pattern <- "CMIP6"
destfile <- "CMIP6_inventory.csv"
datasets <- UDG.datasets(pattern)$CMIP6
varInventoryTable(datasets, output.file = destfile)
