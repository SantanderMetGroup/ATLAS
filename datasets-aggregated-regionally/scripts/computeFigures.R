# computeFigures.R
#
# Copyright (C) 2021 Santander Meteorology Group (http://meteo.unican.es)
#
# This work is licensed under a Creative Commons Attribution 4.0 International
# License (CC BY 4.0 - http://creativecommons.org/licenses/by/4.0)

#' @title Scatter and boxplots of temperature and precipitation changes
#' @description Compute scatterplots and boxplots of temperature and precipitation changes from data 
#'   files of this repository (datasets-aggregated-regionally).
#' @details Functions computeDeltas (computeDeltas.R) and computeOffset (computeOffset.R) 
#'   are internally used.
#' @author M. Iturbide

computeFigures <- function(regions,
                           cordex.domain = NULL,
                           area,
                           ref.period,  
                           scatter.seasons,
                           xlim = NULL,
                           ylim = NULL) {
  library(lattice)
  library(latticeExtra)
  
  # select warming levels and list future periods, e.g. list(c(2021, 2040), c(2041, 2060), c(2081, 2100))
  WL <- c("1.5", "2", "3", "4")
  periods <- list(c(2021, 2040), c(2081, 2100))
  
  p <- lapply(regions, function(region) {
    
    
    
    ##### BOXPLOT-----------------------
    message("[", Sys.time(), "] Computing annual delta changes for the Boxplot of region ", region)
    ### CMIP5 WL 
    
    message("[", Sys.time(), "] Computing CMIP5..")
    # select project "CMIP5", "CMIP6" ("CORDEX" will be available soon)
    project = "CMIP5"
    # select scenario, i.e. "rcp26", "rcp45", "rcp85", "ssp126", "spp245", "ssp585" (select a single scenario for computing WLs)
    experiment <- "rcp85"
    
    WL.cmip5 <- suppressMessages(computeDeltas(project = project, var = "tas", experiment = experiment, season = 1:12, ref.period = ref.period, 
                                               periods = WL, area = area, region = region, cordex.domain = cordex.domain)[[1]])
    
    WLmediana.cmip5 <- apply(WL.cmip5, 2, median, na.rm = T)
    WLp90.cmip5 <- apply(WL.cmip5, 2, quantile, 0.9, na.rm = T)
    WLp10.cmip5 <- apply(WL.cmip5, 2, quantile, 0.1, na.rm = T)
    
    
    
    
    ##########  CMIP6 WL 
    
    message("[", Sys.time(), "] Computing CMIP6..")
    
    project = "CMIP6"
    experiment <- "ssp585"
    
    WL.cmip6 <- suppressMessages(computeDeltas(project = project, var = "tas", experiment = experiment, season = 1:12, ref.period = ref.period, 
                                               periods = WL, 
                                               area = area, region = region, cordex.domain = cordex.domain)[[1]])
    
    WLmediana.cmip6 <- apply(WL.cmip6, 2, median, na.rm = T)
    WLp90.cmip6 <- apply(WL.cmip6, 2, quantile, 0.9, na.rm = T)
    WLp10.cmip6 <- apply(WL.cmip6, 2, quantile, 0.1, na.rm = T)
    
    ###########  CORDEX WL
    
    message("[", Sys.time(), "] Computing CORDEX..")
    
    project = "CORDEX"
    experiment <- "rcp85"
    
    WL.cordex <- if (isFALSE(cordex.domain)) {
      NULL
    } else {
      suppressMessages(computeDeltas(project = project, var = "tas", experiment = experiment, season = 1:12, ref.period = ref.period, 
                                     periods = WL, area = area, region = region, cordex.domain = cordex.domain))
    }
    
    if (!is.null(WL.cordex)) {
      
      
      ###########  CMIP5 CORDEX WL subset 
      aur.cdx.gmc <- lapply(strsplit(rownames(WL.cordex), "_"), function(x) paste(x[1:2], collapse = "_"))
      WL.cmip5.sub <- WL.cmip5[unlist(lapply(aur.cdx.gmc, function(x) grep(x, rownames(WL.cmip5)))),]
      WL.cordex <- WL.cordex[unlist(lapply(unique(rownames(WL.cmip5.sub)), function(i) grep(i, rownames(WL.cordex)))), ]
      
      WLmediana.cordex <- apply(WL.cordex, 2, median, na.rm = T)
      WLp90.cordex <- apply(WL.cordex, 2, quantile, 0.9, na.rm = T)
      WLp10.cordex <- apply(WL.cordex, 2, quantile, 0.1, na.rm = T)
      
      WL.cmip5.sub <- WL.cmip5.sub + (WL.cordex*0)
      WLmediana.cmip5.sub <- apply(WL.cmip5.sub, 2, median, na.rm = T)
      WLp90.cmip5.sub <- apply(WL.cmip5.sub, 2, quantile, 0.9, na.rm = T)
      WLp10.cmip5.sub <- apply(WL.cmip5.sub, 2, quantile, 0.1, na.rm = T)
    } else {
      WLmediana.cordex <- WLp90.cordex <- WLp10.cordex <- NA
      WLmediana.cmip5.sub <- WLp90.cmip5.sub <- WLp10.cmip5.sub <- NA
    }
    ##########  CMIP5 ------------------------------------
    
    project = "CMIP5"
    experiment <- c("rcp26", "rcp45", "rcp85")
    
    cmip5 <- suppressMessages(computeDeltas(project = project, var = "tas", experiment = experiment, season = 1:12, ref.period = ref.period, 
                                            periods = periods, area = area, region = region, cordex.domain = cordex.domain)[[1]])
    
    mediana.cmip5 <- apply(cmip5, 2, median, na.rm = T)
    p90.cmip5 <- apply(cmip5, 2, quantile, 0.9, na.rm = T)
    p10.cmip5 <- apply(cmip5, 2, quantile, 0.1, na.rm = T)
    
    ##########  CMIP6 ------------------------------------
    
    project = "CMIP6"
    experiment <- c("ssp126", "ssp245", "ssp585")
    
    cmip6 <- suppressMessages(computeDeltas(project = project, var = "tas", experiment = experiment, season = 1:12, ref.period = ref.period, 
                                            periods = periods, area = area, region = region, cordex.domain = cordex.domain)[[1]])
    
    mediana.cmip6 <- apply(cmip6, 2, median, na.rm = T)
    p90.cmip6 <- apply(cmip6, 2, quantile, 0.9, na.rm = T)
    p10.cmip6 <- apply(cmip6, 2, quantile, 0.1, na.rm = T)
    
    
    # # ##########  CORDEX ------------------------------------
    
    project = "CORDEX"
    experiment <- c("rcp26", "rcp45", "rcp85")
    
    cordex <- if (isFALSE(cordex.domain)) {
      NULL
    } else {
      suppressMessages(computeDeltas(project = project, var = "tas", experiment = experiment, season = 1:12, ref.period = ref.period, 
                                     periods = periods, area = area, region = region, cordex.domain = cordex.domain))
    }
    
    if (!is.null(cordex)) {
      
      # # ##########  CMIP5 CORDEX subset ------------------------------------
      
      
      aux.ind <- lapply(rownames(cmip5), function(x) grep(x, rownames(cordex)))
      aux.ind.2 <- unlist(lapply(1:length(aux.ind), function(x) rep(x, length(aux.ind[[x]]))))
      cmip5.sub <- cmip5[aux.ind.2,]
      cordex <- cordex[unlist(lapply(unique(rownames(cmip5.sub)), function(i) grep(i, rownames(cordex)))), ]
      
      mediana.cordex <- apply(cordex, 2, median, na.rm = T)
      p90.cordex <- apply(cordex, 2, quantile, 0.9, na.rm = T)
      p10.cordex <- apply(cordex, 2, quantile, 0.1, na.rm = T)
      
      cmip5.sub <- cmip5.sub + (cordex*0)
      mediana.cmip5.sub <- apply(cmip5.sub, 2, median, na.rm = T)
      p90.cmip5.sub <- apply(cmip5.sub, 2, quantile, 0.9, na.rm = T)
      p10.cmip5.sub <- apply(cmip5.sub, 2, quantile, 0.1, na.rm = T)
    } else {
      mediana.cordex <- p90.cordex <- p10.cordex <- NA
      mediana.cmip5.sub <- p90.cmip5.sub <- p10.cmip5.sub <- NA
    }
    
    
    #### OFFSET
    
    cmip5.off <- suppressMessages(computeOffset(project = "CMIP5", 
                                                var = "tas",
                                                experiment = "rcp85",
                                                season = 1:12, 
                                                ref.period = ref.period, 
                                                area = area,
                                                region = region))
    cmip6.off <- suppressMessages(computeOffset(project = "CMIP6", 
                                                var = "tas",
                                                experiment = "ssp585",
                                                season = 1:12, 
                                                ref.period = ref.period, 
                                                area = area,
                                                region = region))
    
    cmip5.off.s <- lapply(scatter.seasons, function(s) suppressMessages(computeOffset(project = "CMIP5", 
                                                                                      var = "tas",
                                                                                      experiment = "rcp85",
                                                                                      season = s, 
                                                                                      ref.period = ref.period, 
                                                                                      area = area,
                                                                                      region = region)))
    cmip6.off.s <- lapply(scatter.seasons, function(s) suppressMessages(computeOffset(project = "CMIP6", 
                                                                                      var = "tas",
                                                                                      experiment = "ssp585",
                                                                                      season = s, 
                                                                                      ref.period = ref.period, 
                                                                                      area = area,
                                                                                      region = region)))
    #### PLOT 
    
    
    col = c(rep(c(rgb(0,0.204,0.4,0.5), rgb(0,0.204,0.4), rgb(0,0.204,0.4), 
                  rgb(112/255,160/255,205/255,0.5), rgb(112/255,160/255,205/255), rgb(112/255,160/255,205/255), 
                  rgb(153/255,0,2/255,0.5), rgb(153/255,0,2/255), rgb(153/255,0,2/255)),
                2),
            rgb(0.55,0,0.55,0.5), rgb(0.55,0,0.55), rgb(0.55,0,0.55), 
            rgb(1, 0.73, 0.06, 0.5), rgb(1, 0.73, 0.06), rgb(1, 0.73, 0.06), 
            rgb(0, 0, 0, 0.5), rgb(0, 0, 0),  rgb(0, 0, 0), 
            rgb(0.5, 0.3, 0.16, 0.5), rgb(0.5, 0.3, 0.16),  rgb(0.5, 0.3, 0.16))
    
    a1 <- c(WLmediana.cmip5[1], WLmediana.cordex[1], WLmediana.cmip6[1])
    a2 <- c(WLmediana.cmip5[2], WLmediana.cordex[2], WLmediana.cmip6[2])
    a3 <- c(WLmediana.cmip5[3], WLmediana.cordex[3], WLmediana.cmip6[3])
    a4 <- c(WLmediana.cmip5[4], WLmediana.cordex[4], WLmediana.cmip6[4])
    a <- c(mediana.cmip5[1], mediana.cordex[1], mediana.cmip6[1], mediana.cmip5[3], mediana.cordex[3], mediana.cmip6[3],mediana.cmip5[5], mediana.cordex[5], mediana.cmip6[5])
    b <- c(mediana.cmip5[2], mediana.cordex[2], mediana.cmip6[2], mediana.cmip5[4], mediana.cordex[4], mediana.cmip6[4],mediana.cmip5[6], mediana.cordex[6], mediana.cmip6[6])
    # d <- c(mediana.cmip5[3], mediana.cordex[3], mediana.cmip6[3], mediana.cmip5[6], mediana.cordex[6], mediana.cmip6[6],mediana.cmip5[9], mediana.cordex[9], mediana.cmip6[9])
    sc <- c("rcp26", "rcp26", "ssp126", "rcp45", "rcp45", "ssp245", "rcp85", "rcp85", "ssp585")
    x0 <- c(paste0("near-", sc), paste0("far-", sc),
            paste0("+1.5º-", c("rcp85", "rcp85", "ssp585")), paste0("+2º-", c("rcp85", "rcp85", "ssp585")), 
            paste0("+3º-", c("rcp85", "rcp85", "ssp585")), paste0("+4º-", c("rcp85", "rcp85","ssp585")))
    # ind <- c(1:4, c(5, 7, 9), c(6, 8, 10), c(11, 13, 15), c(12, 14, 16), c(17, 19, 21), c(18, 20, 22))
    ind <- 1:length(x0)
    n0 <- character()
    for (i in 1:length(x0)) n0[i] <- if (nchar(i) < 2) paste0("0", i) else as.character(i)
    x <- paste0(n0, ")",  x0[ind])
    
    
    
    df <- data.frame("term" = x, "value" = unname(do.call("c", list(a, b, a1, a2, a3, a4)))[ind])
    
    
    
    a1i <- c(WLp10.cmip5[1],WLp10.cordex[1],WLp10.cmip6[1])
    a2i <- c(WLp10.cmip5[2],WLp10.cordex[2],WLp10.cmip6[2])
    a3i <- c(WLp10.cmip5[3],WLp10.cordex[3],WLp10.cmip6[3])
    a4i <- c(WLp10.cmip5[4],WLp10.cordex[4],WLp10.cmip6[4])
    ai <- c(p10.cmip5[1], p10.cordex[1], p10.cmip6[1], p10.cmip5[3], p10.cordex[3], p10.cmip6[3],p10.cmip5[5], p10.cordex[5], p10.cmip6[5])
    bi <- c(p10.cmip5[2], p10.cordex[2], p10.cmip6[2], p10.cmip5[4], p10.cordex[4], p10.cmip6[4],p10.cmip5[6], p10.cordex[6], p10.cmip6[6])
    # di <- c(p10.cmip5[3], p10.cordex[3], p10.cmip6[3], p10.cmip5[6], p10.cordex[6], p10.cmip6[6],p10.cmip5[9], p10.cordex[9], p10.cmip6[9])
    dfi <- data.frame("term" = x, "value" = unname(do.call("c", list(ai, bi, a1i, a2i, a3i, a4i)))[ind])
    
    dfi.sub <- dfi 
    dfi.sub$value <- dfi.sub$value * NA
    dfi.sub[seq(2, nrow(dfi), by = 3), "value"] <- c(p10.cmip5.sub[seq(1, 6, 2)], p10.cmip5.sub[seq(2, 6, 2)], WLp10.cmip5.sub[1:4])
    
    a1j <- c(WLp90.cmip5[1],WLp90.cordex[1],WLp90.cmip6[1])
    a2j <- c(WLp90.cmip5[2],WLp90.cordex[2],WLp90.cmip6[2])
    a3j <- c(WLp90.cmip5[3],WLp90.cordex[3],WLp90.cmip6[3])
    a4j <- c(WLp90.cmip5[4],WLp90.cordex[4],WLp90.cmip6[4])
    aj <- c(p90.cmip5[1], p90.cordex[1], p90.cmip6[1], p90.cmip5[3], p90.cordex[3], p90.cmip6[3],p90.cmip5[5], p90.cordex[5], p90.cmip6[5])
    bj <- c(p90.cmip5[2], p90.cordex[2], p90.cmip6[2], p90.cmip5[4], p90.cordex[4], p90.cmip6[4],p90.cmip5[6], p90.cordex[6], p90.cmip6[6])
    # dj <- c(p90.cmip5[3], p90.cordex[3], p90.cmip6[3], p90.cmip5[6], p90.cordex[6], p90.cmip6[6],p90.cmip5[9], p90.cordex[9], p90.cmip6[9])
    dfj <- data.frame("term" = x, "value" = unname(do.call("c", list(aj, bj, a1j, a2j, a3j, a4j)))[ind])
    
    dfj.sub <- dfj 
    dfj.sub$value <- dfj.sub$value * NA
    dfj.sub[seq(2, nrow(dfj), by = 3), "value"] <- c(p90.cmip5.sub[seq(1,6, 2)], p90.cmip5.sub[seq(2, 6, 2)], WLp90.cmip5.sub[1:4])
    
    col <- col[ind]
    ylab <- bquote(Delta*"T(ºC)")
    
    if (is.null(ylim)) ylim <- c(floor(min(c(dfi$value, cmip5.off, cmip6.off, unlist(cmip5.off.s), unlist(cmip5.off.s)), na.rm = T)), ceiling(max(dfj$value, na.rm = T))); step <- 1
    
    bp <- xyplot(value~term, data = df, ylim = ylim, pch = 19, 
                 ylab = NULL, #list(ylab, cex = 1.2), 
                 aspect = "39",
                 # scales=list(x=list(at=c(2,5,8), alternating=2, tck = c(0,1))
                 scales = list(x = list(at = 1, cex = 1, col = "white"), y = list(cex = 1)),
                 col = col, cex = 0.7, 
                 xlab = NULL, #list("Periods and warming levels", cex = 1.2), #, 
                 main = list(region, cex = 1.2),
                 panel = function(...){
                   panel.abline(h = do.call("seq", as.list(c(ylim, step))),
                                col = "gray65", lwd = 0.5, lty = 2)
                   panel.abline(h = cmip5.off,
                                col = rgb(126/255, 128/255, 93/255, 0.5), lwd = 3/1.5)
                   panel.abline(h = cmip6.off,
                                col = rgb(126/255, 128/255, 93/255), lwd = 3/1.5)
                   panel.segments(-2, 0, 34, 0, lty = 1, col = "gray65")
                   panel.segments(df$term, dfi$value, df$term, dfj$value, col = col, lty = c(1, 2, 1), lwd = c(5, 2, 5)/1.5) #alpha = 0.5)
                   panel.segments(df$term, dfi.sub$value, df$term, dfj.sub$value, col = rep(col[seq(1, length(col), 3)], each = 3), lwd = 7/1.5) #alpha = 0.5)
                   panel.xyplot(...)
                 })
    
    
    ##### SCATTERPLOT-----------------------
    message("[", Sys.time(), "] Computing seasonal delta changes for the Scatterplots of region ", region)
    
    month.names <- c("J", "F", "M", "A", "M", "J", "J", "A", "S", "O", "N", "D")
    seas.names <- unlist(lapply(scatter.seasons, function(i) paste(month.names[i], collapse = "")))
    
    ### CMIP5 WL 
    message("[", Sys.time(), "] Computing CMIP5..")
    
    # select project "CMIP5", "CMIP6" ("CORDEX" will be available soon)
    project = "CMIP5"
    # select scenario, i.e. "rcp26", "rcp45", "rcp85", "ssp126", "spp245", "ssp585" (select a single scenario for computing WLs)
    experiment <- "rcp85"
    
    
    WL.cmip5 <- lapply(scatter.seasons, function(s) suppressMessages(computeDeltas(project = project, var = "tas", experiment = experiment, season = s, ref.period = ref.period, 
                                                                                   periods = WL, area = area, region = region, cordex.domain = cordex.domain)[[1]]))
    WL.cmip5.b <- lapply(scatter.seasons, function(s) suppressMessages(computeDeltas(project = project, var = "pr", experiment = experiment, season = s, ref.period = ref.period, 
                                                                                     periods = WL, area = area, region = region, cordex.domain = cordex.domain)[[1]]))
    names(WL.cmip5.b) <- names(WL.cmip5) <- seas.names
    
    WLmediana.cmip5 <- lapply(WL.cmip5, function(x) apply(x, MAR = 2, FUN = median, na.rm = T))
    WLp90.cmip5 <- lapply(WL.cmip5, function(x) apply(x, 2, quantile, 0.9, na.rm = T))
    WLp10.cmip5 <- lapply(WL.cmip5, function(x) apply(x, 2, quantile, 0.1, na.rm = T))
    WLmediana.cmip5.b <- lapply(WL.cmip5.b, function(x) apply(x, MAR = 2, FUN = median, na.rm = T))
    WLp90.cmip5.b <- lapply(WL.cmip5.b, function(x) apply(x, 2, quantile, 0.9, na.rm = T))
    WLp10.cmip5.b <- lapply(WL.cmip5.b, function(x) apply(x, 2, quantile, 0.1, na.rm = T))
    
    
    ##########  CMIP6 WL r------------------------------------
    message("[", Sys.time(), "] Computing CMIP6..")
    
    project = "CMIP6"
    experiment <- "ssp585"
    
    
    
    WL.cmip6 <- lapply(scatter.seasons, function(s) suppressMessages(computeDeltas(project = project, var = "tas", experiment = experiment, season = s, ref.period = ref.period, 
                                                                                   periods = WL, area = area, region = region, cordex.domain = cordex.domain)[[1]]))
    WL.cmip6.b <- lapply(scatter.seasons, function(s) suppressMessages(computeDeltas(project = project, var = "pr", experiment = experiment, season = s, ref.period = ref.period, 
                                                                                     periods = WL, area = area, region = region, cordex.domain = cordex.domain)[[1]]))
    names(WL.cmip6.b) <- names(WL.cmip6) <- seas.names
    
    WLmediana.cmip6 <- lapply(WL.cmip6, function(x) apply(x, 2, median, na.rm = T))
    WLp90.cmip6 <- lapply(WL.cmip6, function(x) apply(x, 2, quantile, 0.9, na.rm = T))
    WLp10.cmip6 <- lapply(WL.cmip6, function(x) apply(x, 2, quantile, 0.1, na.rm = T))
    WLmediana.cmip6.b <- lapply(WL.cmip6.b, function(x) apply(x, 2, median, na.rm = T))
    WLp90.cmip6.b <- lapply(WL.cmip6.b, function(x) apply(x, 2, quantile, 0.9, na.rm = T))
    WLp10.cmip6.b <- lapply(WL.cmip6.b, function(x) apply(x, 2, quantile, 0.1, na.rm = T))
    
    ### CORDEX WL ----------------------------------
    message("[", Sys.time(), "] Computing CORDEX..")
    
    # select project "CMIP5", "CMIP6" ("CORDEX" will be available soon)
    project = "CORDEX"
    # select scenario, i.e. "rcp26", "rcp45", "rcp85", "ssp126", "spp245", "ssp585" (select a single scenario for computing WLs)
    experiment <- "rcp85"
    
    
    
    if (isFALSE(cordex.domain)) {
      WL.cordex <- NULL
      WL.cordex.b <- NULL
    } else {
      WL.cordex <- lapply(scatter.seasons, function(s) suppressMessages(computeDeltas(project = project, var = "tas", experiment = experiment, season = s, ref.period = ref.period, 
                                                                         periods = WL, area = area, region = region, cordex.domain = cordex.domain)))
      WL.cordex.b <- lapply(scatter.seasons, function(s) suppressMessages(computeDeltas(project = project, var = "pr", experiment = experiment, season = s, ref.period = ref.period, 
                                                                                        periods = WL, area = area, region = region, cordex.domain = cordex.domain)))
      names(WL.cordex.b) <- names(WL.cordex) <- seas.names
    }
    
    if (!is.null(WL.cordex)) {
     
      ###########  CMIP5 CORDEX WL subset pr------------------------------------
      
      
      WL.cmip5.sub <- lapply(1:length(scatter.seasons), function(s){
        aur.cdx.gmc <- lapply(strsplit(rownames(WL.cordex[[s]]), "_"), function(x) paste(x[1:2], collapse = "_"))
        WL.cmip5[[s]][unlist(lapply(aur.cdx.gmc, function(x) grep(x, rownames(WL.cmip5[[s]])))),]
      })
      WL.cmip5.b.sub <- lapply(1:length(scatter.seasons), function(s){
        aur.cdx.gmc <- lapply(strsplit(rownames(WL.cordex.b[[s]]), "_"), function(x) paste(x[1:2], collapse = "_"))
        WL.cmip5.b[[s]][unlist(lapply(aur.cdx.gmc, function(x) grep(x, rownames(WL.cmip5.b[[s]])))),]
      })
      WL.cordex <- lapply(1:length(WL.cordex), function(x) WL.cordex[[x]][unlist(lapply(unique(rownames(WL.cmip5.sub[[x]])), function(i) grep(i, rownames(WL.cordex[[x]])))), ])
      WL.cordex.b <- lapply(1:length(WL.cordex.b), function(x) WL.cordex.b[[x]][unlist(lapply(unique(rownames(WL.cmip5.b.sub[[x]])), function(i) grep(i, rownames(WL.cordex.b[[x]])))), ])
      
      
      
      names(WL.cmip5.b.sub) <- names(WL.cmip5.sub) <- seas.names
     
      WLmediana.cordex <- lapply(WL.cordex, function(x) apply(x, 2, median, na.rm = T))
      WLp90.cordex <- lapply(WL.cordex, function(x) apply(x, 2, quantile, 0.9, na.rm = T))
      WLp10.cordex <- lapply(WL.cordex, function(x) apply(x, 2, quantile, 0.1, na.rm = T))
      WLmediana.cordex.b <- lapply(WL.cordex.b, function(x) apply(x, 2, median, na.rm = T))
      WLp90.cordex.b <- lapply(WL.cordex.b, function(x) apply(x, 2, quantile, 0.9, na.rm = T))
      WLp10.cordex.b <- lapply(WL.cordex.b, function(x) apply(x, 2, quantile, 0.1, na.rm = T))
      
      WL.cmip5.sub <- lapply(1:length(WL.cmip5.sub), function(x) WL.cmip5.sub[[x]] + (WL.cordex[[x]]*0))
      WL.cmip5.b.sub <- lapply(1:length(WL.cmip5.b.sub), function(x) WL.cmip5.b.sub[[x]] + (WL.cordex.b[[x]]*0))
      WLmediana.cmip5.sub <- lapply(WL.cmip5.sub, function(x) apply(x, 2, median, na.rm = T))
      WLp90.cmip5.sub <- lapply(WL.cmip5.sub, function(x) apply(x, 2, quantile, 0.9, na.rm = T))
      WLp10.cmip5.sub <- lapply(WL.cmip5.sub, function(x) apply(x, 2, quantile, 0.1, na.rm = T))
      WLmediana.cmip5.b.sub <- lapply(WL.cmip5.b.sub, function(x) apply(x, 2, median, na.rm = T))
      WLp90.cmip5.b.sub <- lapply(WL.cmip5.b.sub, function(x) apply(x, 2, quantile, 0.9, na.rm = T))
      WLp10.cmip5.b.sub <- lapply(WL.cmip5.b.sub, function(x) apply(x, 2, quantile, 0.1, na.rm = T))
    } else {
      WLmediana.cordex <- WLp90.cordex <- WLp10.cordex <- WLmediana.cordex.b <- WLp90.cordex.b <- WLp10.cordex.b <- NA
      WLmediana.cmip5.sub <- WLp90.cmip5.sub <- WLp10.cmip5.sub <- WLmediana.cmip5.b.sub <- WLp90.cmip5.b.sub <- WLp10.cmip5.b.sub <- NA
    }
    
    
    #### OFFSET
    

    cmip5.off.s.b <- lapply(scatter.seasons, function(s) suppressMessages(computeOffset(project = "CMIP5", 
                                                                                      var = "pr",
                                                                                      experiment = "rcp85",
                                                                                      season = s, 
                                                                                      ref.period = ref.period, 
                                                                                      area = area,
                                                                                      region = region)))
    cmip6.off.s.b <- lapply(scatter.seasons, function(s) suppressMessages(computeOffset(project = "CMIP6", 
                                                                                      var = "pr",
                                                                                      experiment = "ssp585",
                                                                                      season = s, 
                                                                                      ref.period = ref.period, 
                                                                                      area = area,
                                                                                      region = region)))
    
    ######## scatterplot 
    if (isFALSE(cordex.domain)) {
      WLmediana.cordex <- lapply(WLmediana.cmip5,  "*", NA)
      WLmediana.cordex.b <- lapply(WLmediana.cmip5,  "*", NA)
      WLp10.cordex <- lapply(WLmediana.cmip5,  "*", NA)
      WLp10.cordex.b <- lapply(WLmediana.cmip5,  "*", NA)
      WLp90.cordex <- lapply(WLmediana.cmip5,  "*", NA)
      WLp90.cordex.b <- lapply(WLmediana.cmip5,  "*", NA)
      WLmediana.cmip5.sub <- lapply(WLmediana.cmip5,  "*", NA)
      WLmediana.cmip5.b.sub <- lapply(WLmediana.cmip5,  "*", NA)
      WLp10.cmip5.sub <- lapply(WLmediana.cmip5,  "*", NA)
      WLp10.cmip5.b.sub <- lapply(WLmediana.cmip5,  "*", NA)
      WLp90.cmip5.sub <- lapply(WLmediana.cmip5,  "*", NA)
      WLp90.cmip5.b.sub <- lapply(WLmediana.cmip5,  "*", NA)
    }
    sp <- lapply(1:length(scatter.seasons), function(k) {
      
      #########remove cmip5.sub for WL1.5 and 2
      WLp10.cmip5.b.sub[[k]] <- WLp10.cmip5.b.sub[[k]] + c(NA, NA, 0, 0)
      WLp90.cmip5.b.sub[[k]] <- WLp90.cmip5.b.sub[[k]] + c(NA, NA, 0, 0)
      WLmediana.cmip5.b.sub[[k]] <- WLmediana.cmip5.b.sub[[k]] + c(NA, NA, 0, 0)
      WLp10.cmip5.sub[[k]] <- WLp10.cmip5.sub[[k]] + c(NA, NA, 0, 0)
      WLp90.cmip5.sub[[k]] <- WLp90.cmip5.sub[[k]] + c(NA, NA, 0, 0)
      WLmediana.cmip5.sub[[k]] <- WLmediana.cmip5.sub[[k]] + c(NA, NA, 0, 0)
      #############
      
      dfs <- data.frame("y" = c(WLmediana.cmip5.sub[[k]], WLmediana.cmip5[[k]], WLmediana.cordex[[k]], WLmediana.cmip6[[k]]), 
                          "x" = c(WLmediana.cmip5.b.sub[[k]], WLmediana.cmip5.b[[k]], WLmediana.cordex.b[[k]], WLmediana.cmip6.b[[k]]))
      

      
      
      col <- c(rgb(0.55,0,0.55,0.5), 
               rgb(1, 0.73, 0.06, 0.5), 
               rgb(0, 0, 0, 0.5), 
               rgb(0.5, 0.3, 0.16, 0.5), 
               rgb(0.55,0,0.55,0.5), 
               rgb(1, 0.73, 0.06, 0.5), 
               rgb(0, 0, 0, 0.5), 
               rgb(0.5, 0.3, 0.16, 0.5), 
               rgb(0.55,0,0.55), 
               rgb(1, 0.73, 0.06), 
               rgb(0, 0, 0),  
               rgb(0.5, 0.3, 0.16), 
               rgb(0.55,0,0.55), 
               rgb(1, 0.73, 0.06), 
               rgb(0, 0, 0), 
               rgb(0.5, 0.3, 0.16))
      
      xlimk <- xlim
      ylimk <- ylim
      if (is.null(xlimk)) xlimk <- c(floor(min(c(WLp10.cmip5.b[[k]],WLp10.cordex.b[[k]],WLp10.cmip6.b[[k]], cmip5.off.s.b[[k]], cmip6.off.s.b[[k]]), na.rm = T)), ceiling(max(c(WLp90.cmip5.b[[k]],WLp90.cordex.b[[k]], WLp90.cmip6.b[[k]], cmip5.off.s.b[[k]], cmip6.off.s.b[[k]]), na.rm = T)))
      if (is.null(ylimk)) ylimk <- c(floor(min(c(WLp10.cmip5[[k]],WLp10.cordex[[k]],WLp10.cmip6[[k]], cmip5.off.s[[k]], cmip6.off.s[[k]]), na.rm = T)), ceiling(max(c(WLp90.cmip5[[k]],WLp90.cordex[[k]], WLp90.cmip6[[k]], cmip5.off.s[[k]], cmip6.off.s[[k]]), na.rm = T)))
      
     
      
      
      xyplot(y~x, data = dfs, xlim = xlimk, ylim = ylimk, pch = 19, aspect = "39", 
             # scales = list(x = list(rot = 90)),
             col = col, cex = 0.7, ylab = NULL, #ylab = list(bquote(Delta*"T(ºC)"), cex = 1.2), 
             xlab = NULL,#xlab = list(bquote(Delta*"P(%)"), cex = 1.2),
             scales = list(x = list(cex = 1), y = list(cex = 1)),
             main = list(seas.names[[k]], cex = 1.2),
             panel = function(...){
               # panel.abline(h = do.call("seq", as.list(c(ylim, step))),
               #              col = "gray65", lwd = 0.5, lty = 2)
               panel.segments(WLp10.cmip6.b[[k]], WLmediana.cmip6[[k]], WLp90.cmip6.b[[k]], WLmediana.cmip6[[k]], col = col[13:16], lwd = 5/1.5)
               panel.segments(WLmediana.cmip6.b[[k]], WLp10.cmip6[[k]], WLmediana.cmip6.b[[k]], WLp90.cmip6[[k]], col = col[13:16], lwd = 5/1.5)
               panel.segments(WLp10.cmip5.b[[k]], WLmediana.cmip5[[k]], WLp90.cmip5.b[[k]], WLmediana.cmip5[[k]], col = col[1:4], lwd = 5/1.5)
               panel.segments(WLmediana.cmip5.b[[k]], WLp10.cmip5[[k]], WLmediana.cmip5.b[[k]], WLp90.cmip5[[k]], col = col[1:4], lwd = 5/1.5)
               panel.segments(WLp10.cordex.b[[k]], WLmediana.cordex[[k]], WLp90.cordex.b[[k]], WLmediana.cordex[[k]], col = col[9:12], lwd = 2/1.5, lty = 2)
               panel.segments(WLmediana.cordex.b[[k]], WLp10.cordex[[k]], WLmediana.cordex.b[[k]], WLp90.cordex[[k]], col = col[9:12], lwd = 2/1.5, lty = 2)
               
               # panel.segments(WLp10.cmip5.b.sub[[k]], WLmediana.cmip5.sub[[k]], WLp90.cmip5.b.sub[[k]], WLmediana.cmip5.sub[[k]], col = col[1:4], lwd = 2, lty = 2)
               panel.segments(WLmediana.cmip5.b.sub[[k]], WLp10.cmip5.sub[[k]], WLmediana.cmip5.b.sub[[k]], WLp90.cmip5.sub[[k]], col = col[5:8], lwd = 2/1.5, lty = 2)
               
               panel.segments(min(xlimk) - 10, 0, max(xlimk) + 10, 0, lty = 1, col = "gray65")
               panel.segments(0, min(ylimk) - 2, 0, max(ylimk) + 2, lty = 1, col = "gray65")
               
               panel.abline(h = do.call("seq", as.list(c(ylimk, step))),
                            col = "gray65", lwd = 0.5, lty = 2)
               
               panel.xyplot(cmip5.off.s.b[[k]], cmip5.off.s[[k]], col = rgb(126/255, 128/255, 93/255, 0.5), pch = 19, cex = 1)
               panel.xyplot(cmip6.off.s.b[[k]], cmip6.off.s[[k]], col = rgb(126/255, 128/255, 93/255), cex = 1, pch = 19)
               panel.xyplot(...)
             })
    })
    c(list(bp), sp)
  })
  ncol <- 1 + length(scatter.seasons)
  ppp <- unlist(p, recursive = FALSE)
  c(ppp, ncol = ncol)
}
