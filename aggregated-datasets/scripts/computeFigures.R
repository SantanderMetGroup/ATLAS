computeFigure <- function(var, 
                          season, 
                          ref.period,  
                          area, 
                          regions,
                          type = c("boxplot", "scatterplot")) {
  library(lattice)
  library(latticeExtra)
  # select warming levels and list future periods, e.g. list(c(2021, 2040), c(2041, 2060), c(2081, 2100))
  WL <- c("1.5", "2", "3", "4")
  periods <- list(c(2021, 2040), c(2041, 2060), c(2081, 2100))
  
  p <- lapply(regions, function(region) {
    
    ### CMIP5 WL ----------------------------------
    
    # select project "CMIP5", "CMIP6" ("CORDEX" will be available soon)
    project = "CMIP5"
    # select scenario, i.e. "rcp26", "rcp45", "rcp85", "ssp126", "spp245", "ssp585" (select a single scenario for computing WLs)
    experiment <- "rcp85"
    
    WL.cmip5 <- computeDeltas(project, var, experiment, season, ref.period, periods = WL, area, region)[[1]]
    
    WLmediana.cmip5 <- apply(WL.cmip5, 2, median, na.rm = T)
    WLp90.cmip5 <- apply(WL.cmip5, 2, quantile, 0.9, na.rm = T)
    WLp10.cmip5 <- apply(WL.cmip5, 2, quantile, 0.1, na.rm = T)
    
    
    ##########  CMIP6 WL ------------------------------------
    
    project = "CMIP6"
    experiment <- "ssp585"
    
    WL.cmip6 <- computeDeltas(project, var, experiment, season, ref.period, periods = WL, area, region)[[1]]
    
    WLmediana.cmip6 <- apply(WL.cmip6, 2, median, na.rm = T)
    WLp90.cmip6 <- apply(WL.cmip6, 2, quantile, 0.9, na.rm = T)
    WLp10.cmip6 <- apply(WL.cmip6, 2, quantile, 0.1, na.rm = T)
    
    ###########  CORDEX WL------------------------------------
    
    project = "CORDEX"
    experiment <- "rcp85"
    
    WL.cordex <- computeDeltas(project, var, experiment, season, ref.period, periods = WL, area, region = "ENA")[[1]]
    
    WLmediana.cordex <- apply(WL.cordex, 2, median, na.rm = T)
    WLp90.cordex <- apply(WL.cordex, 2, quantile, 0.9, na.rm = T)
    WLp10.cordex <- apply(WL.cordex, 2, quantile, 0.1, na.rm = T)
    
    ###########  CMIP5 CORDEX WL subset------------------------------------
    
    WL.cmip5.sub <- WL.cmip5[which(unlist(lapply(rownames(WL.cmip5), function(x) length(grep(x, rownames(WL.cordex))) > 0))),]
    
    WLmediana.cmip5.sub <- apply(WL.cmip5.sub, 2, median, na.rm = T)
    WLp90.cmip5.sub <- apply(WL.cmip5.sub, 2, quantile, 0.9, na.rm = T)
    WLp10.cmip5.sub <- apply(WL.cmip5.sub, 2, quantile, 0.1, na.rm = T)
    
    
    if (type == "boxplot") {
      
      ##########  CMIP5 ------------------------------------
      
      project = "CMIP5"
      experiment <- c("rcp26", "rcp45", "rcp85")
      
      cmip5 <- computeDeltas(project, var, experiment, season, ref.period, periods, area, region)[[1]]
      
      mediana.cmip5 <- apply(cmip5, 2, median, na.rm = T)
      p90.cmip5 <- apply(cmip5, 2, quantile, 0.9, na.rm = T)
      p10.cmip5 <- apply(cmip5, 2, quantile, 0.1, na.rm = T)
      
      ##########  CMIP6 ------------------------------------
      
      project = "CMIP6"
      experiment <- c("ssp126", "ssp245", "ssp585")
      
      cmip6 <- computeDeltas(project, var, experiment, season, ref.period, periods, area, region)[[1]]
      
      mediana.cmip6 <- apply(cmip6, 2, median, na.rm = T)
      p90.cmip6 <- apply(cmip6, 2, quantile, 0.9, na.rm = T)
      p10.cmip6 <- apply(cmip6, 2, quantile, 0.1, na.rm = T)
      
      
      # # ##########  CORDEX ------------------------------------
      
      project = "CORDEX"
      experiment <- c("rcp26", "rcp45", "rcp85")
      
      cordex <- computeDeltas(project, var, experiment, season, ref.period, periods, area, region)[[1]]
      
      mediana.cordex <- apply(cordex, 2, median, na.rm = T)
      p90.cordex <- apply(cordex, 2, quantile, 0.9, na.rm = T)
      p10.cordex <- apply(cordex, 2, quantile, 0.1, na.rm = T)
      
      # # ##########  CMIP5 CORDEX subset ------------------------------------
      
      cmip5.sub <- cmip5[which(unlist(lapply(rownames(cmip5), function(x) length(grep(x, rownames(cordex))) > 0))),]
      
      mediana.cmip5.sub <- apply(cmip5.sub, 2, median, na.rm = T)
      p90.cmip5.sub <- apply(cmip5.sub, 2, quantile, 0.9, na.rm = T)
      p10.cmip5.sub <- apply(cmip5.sub, 2, quantile, 0.1, na.rm = T)
      
      ########## boxplot #######------------------------------------------------------------------------
      
      
      col = c(rgb(0.55,0,0.55,0.5), rgb(0.55,0,0.55), rgb(0.55,0,0.55), 
              rgb(1, 0.73, 0.06, 0.5), rgb(1, 0.73, 0.06), rgb(1, 0.73, 0.06), 
              rgb(0, 0, 0, 0.5), rgb(0, 0, 0),  rgb(0, 0, 0), 
              rgb(0.5, 0.3, 0.16, 0.5), rgb(0.5, 0.3, 0.16),  rgb(0.5, 0.3, 0.16), 
              rep(c(rgb(0,0,1,0.5), rgb(0,0,1), "blue", 
                    rgb(0,102/255,51/255,0.5), rgb(0,102/255,51/255), rgb(0,102/255,51/255), 
                    rgb(153/255,0,0,0.5), rgb(153/255,0,0), rgb(153/255,0,0)),
                  9))
      
      a1 <- c(WLmediana.cmip5[1], WLmediana.cordex[1], WLmediana.cmip6[1])
      a2 <- c(WLmediana.cmip5[2], WLmediana.cordex[2], WLmediana.cmip6[2])
      a3 <- c(WLmediana.cmip5[3], WLmediana.cordex[3], WLmediana.cmip6[3])
      a4 <- c(WLmediana.cmip5[4], WLmediana.cordex[4], WLmediana.cmip6[4])
      a <- c(mediana.cmip5[1], mediana.cordex[1], mediana.cmip6[1], mediana.cmip5[4], mediana.cordex[4], mediana.cmip6[4],mediana.cmip5[7], mediana.cordex[7], mediana.cmip6[7])
      b <- c(mediana.cmip5[2], mediana.cordex[2], mediana.cmip6[2], mediana.cmip5[5], mediana.cordex[5], mediana.cmip6[5],mediana.cmip5[8], mediana.cordex[8], mediana.cmip6[8])
      d <- c(mediana.cmip5[3], mediana.cordex[3], mediana.cmip6[3], mediana.cmip5[6], mediana.cordex[6], mediana.cmip6[6],mediana.cmip5[9], mediana.cordex[9], mediana.cmip6[9])
      sc <- c("rcp26", "rcp26", "ssp126", "rcp45", "rcp45", "ssp245", "rcp85", "rcp85", "ssp585")
      x0 <- c(paste0("+1.5º-", c("rcp85", "rcp85", "ssp585")), paste0("+2º-", c("rcp85", "rcp85", "ssp585")), paste0("+3º-", c("rcp85", "rcp85", "ssp585")), paste0("+4º-", c("rcp85", "rcp85","ssp585")), paste0("near-", sc), paste0("mid-", sc), paste0("far-", sc))
      # ind <- c(1:4, c(5, 7, 9), c(6, 8, 10), c(11, 13, 15), c(12, 14, 16), c(17, 19, 21), c(18, 20, 22))
      ind <- 1:length(x0)
      n0 <- character()
      for (i in 1:length(x0)) n0[i] <- if (nchar(i) < 2) paste0("0", i) else as.character(i)
      x <- paste0(n0, ")",  x0[ind])
      
      
      
      df <- data.frame("term" = x, "value" = unname(do.call("c", list(a1, a2, a3, a4, a, b, d)))[ind])
      
      
      
      a1i <- c(WLp10.cmip5[1],WLp10.cordex[1],WLp10.cmip6[1])
      a2i <- c(WLp10.cmip5[2],WLp10.cordex[2],WLp10.cmip6[2])
      a3i <- c(WLp10.cmip5[3],WLp10.cordex[3],WLp10.cmip6[3])
      a4i <- c(WLp10.cmip5[4],WLp10.cordex[4],WLp10.cmip6[4])
      ai <- c(p10.cmip5[1], p10.cordex[1], p10.cmip6[1], p10.cmip5[4], p10.cordex[4], p10.cmip6[4],p10.cmip5[7], p10.cordex[7], p10.cmip6[7])
      bi <- c(p10.cmip5[2], p10.cordex[2], p10.cmip6[2], p10.cmip5[5], p10.cordex[5], p10.cmip6[5],p10.cmip5[8], p10.cordex[8], p10.cmip6[8])
      di <- c(p10.cmip5[3], p10.cordex[3], p10.cmip6[3], p10.cmip5[6], p10.cordex[6], p10.cmip6[6],p10.cmip5[9], p10.cordex[9], p10.cmip6[9])
      dfi <- data.frame("term" = x, "value" = unname(do.call("c", list(a1i, a2i, a3i, a4i, ai, bi, di)))[ind])
      
      dfi.sub <- dfi 
      dfi.sub$value <- dfi.sub$value * NA
      dfi.sub[seq(2, nrow(dfi), by = 3), "value"] <- c(WLp10.cmip5.sub[1:4], p10.cmip5.sub[1:9])
      
      a1j <- c(WLp90.cmip5[1],WLp90.cordex[1],WLp90.cmip6[1])
      a2j <- c(WLp90.cmip5[2],WLp90.cordex[2],WLp90.cmip6[2])
      a3j <- c(WLp90.cmip5[3],WLp90.cordex[3],WLp90.cmip6[3])
      a4j <- c(WLp90.cmip5[4],WLp90.cordex[4],WLp90.cmip6[4])
      aj <- c(p90.cmip5[1], p90.cordex[1], p90.cmip6[1], p90.cmip5[4], p90.cordex[4], p90.cmip6[4],p90.cmip5[7], p90.cmip5[7], p90.cmip6[7])
      bj <- c(p90.cmip5[2], p90.cordex[2], p90.cmip6[2], p90.cmip5[5], p90.cordex[5], p90.cmip6[5],p90.cmip5[8], p90.cmip5[8], p90.cmip6[8])
      dj <- c(p90.cmip5[3], p90.cordex[3], p90.cmip6[3], p90.cmip5[6], p90.cordex[6], p90.cmip6[6],p90.cmip5[9], p90.cordex[9], p90.cmip6[9])
      dfj <- data.frame("term" = x, "value" = unname(do.call("c", list(a1j, a2j, a3j, a4j, aj, bj, dj)))[ind])
      
      dfj.sub <- dfj 
      dfj.sub$value <- dfj.sub$value * NA
      dfj.sub[seq(2, nrow(dfj), by = 3), "value"] <- c(WLp90.cmip5.sub[1:4], p90.cmip5.sub[1:9])
      
      col <- col[ind]
      ylim <- c(floor(min(df$value)) - 1, ceiling(max(df$value)) + 1); step <- 1
      ylab <- bquote(Delta*"T(ºC)")
      
      xyplot(value~term, data = df, ylim = ylim, pch = 19, ylab = ylab, scales=list(x=list(rot=90)),
             col = col, cex = 1, xlab = "", #, 
             main = region,
             panel = function(...){
               panel.abline(h = do.call("seq", as.list(c(ylim, step))),
                            col = "gray65", lwd = 0.5, lty = 2)
               panel.segments(df$term, dfi$value, df$term, dfj$value, col = col, lwd = c(5, 2, 5)) #alpha = 0.5)
               panel.segments(df$term, dfi.sub$value, df$term, dfj.sub$value, col = rep(col[seq(1, length(col), 3)], each = 3), lwd = 7) #alpha = 0.5)
               panel.xyplot(...)
             })
      
      
    } else if (type == "scatterplot") {
      vari <- setdiff(c("tas", "pr"), var)
      
      ### CMIP5 WL pr----------------------------------
      
      # select project "CMIP5", "CMIP6" ("CORDEX" will be available soon)
      project = "CMIP5"
      # select scenario, i.e. "rcp26", "rcp45", "rcp85", "ssp126", "spp245", "ssp585" (select a single scenario for computing WLs)
      experiment <- "rcp85"
      
      WL.cmip5.b <- computeDeltas(project, var = vari, experiment, season, ref.period, periods = WL, area, region)[[1]]
      
      WLmediana.cmip5.b <- apply(WL.cmip5, 2, median, na.rm = T)
      WLp90.cmip5.b <- apply(WL.cmip5, 2, quantile, 0.9, na.rm = T)
      WLp10.cmip5.b <- apply(WL.cmip5, 2, quantile, 0.1, na.rm = T)
      
      
      ##########  CMIP6 WL pr------------------------------------
      
      project = "CMIP6"
      experiment <- "ssp585"
      WL.cmip6.b <- computeDeltas(project, var = vari, experiment, season, ref.period, periods = WL, area, region)[[1]]
      
      WLmediana.cmip6.b <- apply(WL.cmip6, 2, median, na.rm = T)
      WLp90.cmip6.b <- apply(WL.cmip6, 2, quantile, 0.9, na.rm = T)
      WLp10.cmip6.b <- apply(WL.cmip6, 2, quantile, 0.1, na.rm = T)
      
      ### CORDEX WL pr----------------------------------
      
      # select project "CMIP5", "CMIP6" ("CORDEX" will be available soon)
      project = "CORDEX"
      # select scenario, i.e. "rcp26", "rcp45", "rcp85", "ssp126", "spp245", "ssp585" (select a single scenario for computing WLs)
      experiment <- "rcp85"
      
      WL.cordex.b <- computeDeltas(project, var = vari, experiment, season, ref.period, periods = WL, area, region)[[1]]
      
      WLmediana.cordex.b <- apply(WL.cordex, 2, median, na.rm = T)
      WLp90.cordex.b <- apply(WL.cordex, 2, quantile, 0.9, na.rm = T)
      WLp10.cordex.b <- apply(WL.cordex, 2, quantile, 0.1, na.rm = T)
      
      ###########  CMIP5 CORDEX WL subset pr------------------------------------
      
      WL.cmip5.b.sub <- WL.cmip5.b[which(unlist(lapply(rownames(WL.cmip5.b), function(x) length(grep(x, rownames(WL.cordex.b))) > 0))),]
      
      WLmediana.cmip5.b.sub <- apply(WL.cmip5.b.sub, 2, median, na.rm = T)
      WLp90.cmip5.b.sub <- apply(WL.cmip5.b.sub, 2, quantile, 0.9, na.rm = T)
      WLp10.cmip5.b.sub <- apply(WL.cmip5.b.sub, 2, quantile, 0.1, na.rm = T)
      
      ######## scatterplot 
      col1 <- c(rgb(0.55,0,0.55,0.5), rgb(1, 0.73, 0.06, 0.5),rgb(0, 0, 0, 0.5), rgb(0.5, 0.3, 0.16, 0.5))
      col2 <- c(rgb(0.55,0,0.55), rgb(1, 0.73, 0.06), rgb(0, 0, 0), rgb(0.5, 0.3, 0.16))
      plot(WLmediana.cmip6, WLmediana.cmip6.b, pch = 21,
           bg = rgb(1,0,0,0), col = rgb(1,0,0,0), 
           xlim = c(min(WLp10.cmip6), max(WLp90.cmip6)),
           ylim = c(min(WLp10.cmip6.b), max(WLp90.cmip6.b)),
           main = region,
           xlab = bquote(Delta*"T(ºC)"), ylab = bquote(Delta*"P(%)"))
      segments(WLp10.cmip6, WLmediana.cmip6.b, WLp90.cmip6, WLmediana.cmip6.b, col = col2, lwd = 4)
      segments(WLmediana.cmip6, WLp10.cmip6.b, WLmediana.cmip6, WLp90.cmip6.b, col = col2, lwd = 4)
      segments(min(WLp10.cmip6), 0, max(WLp90.cmip6), 0, lty = 3)
      segments(WLp10.cmip5, WLmediana.cmip5.b, WLp90.cmip5, WLmediana.cmip5.b, col = col1, lwd = 4)
      segments(WLmediana.cmip5, WLp10.cmip5.b, WLmediana.cmip5, WLp90.cmip5.b, col = col1, lwd = 4)
      points(WLmediana.cmip6, WLmediana.cmip6.b, pch = 21, bg = col2, xlim = c(0, 7))
      points(WLmediana.cmip5, WLmediana.cmip5.b, pch = 21, bg = col1, xlim = c(0, 7))
    }
  })
  return(p)
}