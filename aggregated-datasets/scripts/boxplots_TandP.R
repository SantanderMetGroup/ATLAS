## The package magrittr is used to pipe (%>%) sequences of data operations improving readability
#install.packages("magrittr")
library(magrittr)
## The package httr is used towork with URLs and HTTP
#install.packages("httr")
library(httr)

## Some help on how to read files from a GitHub repository
## https://stackoverflow.com/questions/25485216/how-to-get-list-files-from-a-github-repository-folder-using-r

myurl <- "https://api.github.com/repos/SantanderMetGroup/ATLAS/git/trees/devel?recursive=1"
req <- GET(myurl) %>% stop_for_status(req)
filelist <- unlist(lapply(content(req)$tree, "[", "path"), use.names = FALSE)
root <- "https://raw.githubusercontent.com/SantanderMetGroup/ATLAS/devel/"

ref.period <- 1986:2005
area <- "land"
var = "tas"
season = 1:12

#### FUNCTION FOR PREPEARING DATA --------------------------

computeDeltas <- function(allfiles, modelruns, ref.period, periods, exp, season){ 
  var <- scan(allfiles[1], "character", n = 7)[4]
  region <- colnames(read.table(allfiles[1], header = TRUE, sep = ",", skip = 7))[-1]
  aggrfun <- "mean"
  if (var == "pr") aggrfun <- "sum"
  out <- lapply(1:length(modelruns), function(i) {
    modelfiles <- grep(modelruns[i], allfiles, value = TRUE) 
    hist <- grep("historical", modelfiles, value = TRUE) %>% read.table(header = TRUE, sep = ",", skip = 7)
    seas <- hist %>% subset(select = "date", drop = TRUE) %>% gsub(".*-", "", .) %>% as.integer()
    z <- sort(unlist(lapply(season, function(s) which(seas == s))))
    hist <- hist[z, ]
    yearshist <-  unique(hist %>% subset(select = "date", drop = TRUE) %>% gsub("-.*", "", .) %>% as.integer())
    firstind <- which(seas[z] == season[1])[1]
    if (firstind > 1) {
      yrs <- c(rep(1, firstind-1), rep(2:ceiling(nrow(hist)/length(season)+1), each = length(season), length.out = nrow(hist)-(firstind-1)))
      yearshist <- c(yearshist, yearshist[length(yearshist)] + 1)
    } else {
      yrs <-  hist %>% subset(select = "date", drop = TRUE) %>% gsub("-.*", "", .) %>% as.integer()
      yearshist <-  unique(yrs)
    }
    hist <- lapply(split(hist[,-1], f = yrs), function(x) apply(x, MARGIN = 2, FUN = aggrfun, na.rm = TRUE))
    hist <- do.call("rbind", hist)
    rownames(hist) <- yearshist[1:nrow(hist)]
    start <- which(rownames(hist) == range(ref.period)[1])
    end <- which(rownames(hist) == range(ref.period)[2])
    fill <- FALSE
    if (length(end) == 0) {
      fill <- TRUE
      end <- which(rownames(hist) == 2005)
    }
    hist <- hist[start:end,]
    l1 <- lapply(1:length(exp), FUN = function(j) {
      rcp <- tryCatch({
        grep(exp[j], modelfiles, value = TRUE) %>% read.table(header = TRUE, sep = ",", skip = 7)
      }, error = function(err) return(NULL))
      dates <- tryCatch({
        seas <- rcp %>% subset(select = "date", drop = TRUE) %>% gsub(".*-", "", .) %>% as.integer()
        z <- sort(unlist(lapply(season, function(s) which(seas == s))))
        rcp <- rcp[z, ]
        yearsrcp <-  unique(rcp %>% subset(select = "date", drop = TRUE) %>% gsub("-.*", "", .) %>% as.integer())
        firstind <- which(seas[z] == season[1])[1]
        if (firstind > 1) {
          yrs <- c(rep(1, firstind-1), rep(2:ceiling(nrow(rcp)/length(season)+1), each = length(season), length.out = nrow(rcp)-(firstind-1)))
          yearsrcp <- c(yearsrcp, yearsrcp[length(yearsrcp)] + 1)
        } else {
          yrs <-  rcp %>% subset(select = "date", drop = TRUE) %>% gsub("-.*", "", .) %>% as.integer()
          yearsrcp <-  unique(yrs)
        }
        rcp <- lapply(split(rcp[,-1], f = yrs), function(x) apply(x, MARGIN = 2, FUN = aggrfun, na.rm = TRUE))
      }, error = function(err) return(NULL))
      if (!is.null(rcp)) {
        rcp <- do.call("rbind", rcp)
        rownames(rcp) <- yearsrcp[1:nrow(rcp)]
        if (fill) {
          message("i =", i, ".......", exp[j], "------filling reference period with rcp data")
          rcphist <- rcp[which(rownames(rcp) == 2006) : which(rownames(rcp) == range(ref.period)[2]),]
          histexp <- apply(rbind(hist, rcphist), MARGIN = 2, FUN = mean, na.rm = TRUE)
        } else {
          message("i =", i, ".......", exp[j], "------")
          histexp <- apply(hist, MARGIN = 2, FUN = mean, na.rm = TRUE)
        }
        delta <- lapply(periods, function(k){
          endyear <- k[i,][2]
          while (length(which(rownames(rcp) == endyear)) == 0) {
            endyear <- endyear - 1
          }
          startyear <- k[i,][1]
          while (length(which(rownames(rcp) == startyear)) == 0) {
            startyear <- startyear + 1
          }
          rcpk <- rcp[which(rownames(rcp) == startyear) : which(rownames(rcp) == endyear),]
          if (var == "tas") {
            apply(rcpk, MARGIN = 2, FUN = mean, na.rm = TRUE) - histexp
          } else if (var == "pr") {
            (apply(rcpk, MARGIN = 2, FUN = mean, na.rm = TRUE) - histexp) / histexp * 100
          }        
          })
      } else {
        message("i =", i, ".......", exp[j], "------NO DATA")
        delta <- rep(list(NULL), length(periods))
      }
      
      names(delta) <- names(periods)
      delta
    })
    names(l1) <- exp
    l1
  })
  names(out) <- modelruns
  
  
  data <- lapply(region, function(i) {
    eo <- lapply(exp, function(l){
      z <- lapply(out, function(x){
        values <- unname(do.call("cbind", lapply(x[[l]], "[[", i)))
        if (is.null(values)) values <- rep(NA, length(periods))
        values
      })
      df <- do.call("rbind", z)
      rownames(df) <- names(z)
      colnames(df) <- rep(l, length(periods))
      df
    })
    do.call("cbind", eo)
  })
  names(data) <- region
  return(data)
}



##########  CMIP5 WL ##########------------------------------------

ls <- grep(paste0("CMIP5_", var,"_",area,"/"), filelist, value = TRUE, fixed = TRUE) %>% grep("\\.csv$", ., value = TRUE)
allfiles <- paste0(root, ls)
aux <- grep("historical", ls, value = TRUE)

wlls <- grep("CMIP5_Atlas_WarmingLevels", filelist, value = TRUE, fixed = TRUE) %>% grep("\\.csv$", ., value = TRUE)
wlfiles <- paste0(root, wlls)
aux1.5 <- read.table(wlfiles, header = TRUE, sep = ",")[["X1.5_rcp85"]]
aux2 <- read.table(wlfiles, header = TRUE, sep = ",")[["X2_rcp85"]]
modelruns <- as.character(read.table(wlfiles, header = TRUE, sep = ",")[,1])
modelruns[modelruns == "HadGEM2-CC_r1i1p1"] <- "HadGEM2-ES_r1i1p1"
ind <- which(aux1.5 != 9999 & !is.na(aux1.5) & modelruns != "EC-EARTH_r3i1p1")
modelruns <- modelruns[ind]
per1.5 <- cbind(aux1.5-9, aux1.5+10)[ind,]
per2 <- cbind(aux2-9, aux2+10)[ind,]

exp <- "rcp85"

WL.cmip5 <- computeDeltas(allfiles, modelruns, ref.period, periods = list("+1.5º" = per1.5, "+2º" = per2), exp, season)

WLmediana.cmip5 <- lapply(WL.cmip5, apply, 2, median, na.rm = T)
WLp90.cmip5 <- lapply(WL.cmip5, apply, 2, quantile, 0.9, na.rm = T)
WLp10.cmip5 <- lapply(WL.cmip5, apply, 2, quantile, 0.1, na.rm = T)


##########  CMIP6 WL ##########------------------------------------
aggr.fun <- "mean"
ls <- grep(paste0("CMIP6_", var,"_",area,"/"), filelist, value = TRUE, fixed = TRUE) %>% grep("\\.csv$", ., value = TRUE)
allfiles <- paste0(root, ls)
aux <- grep("historical", ls, value = TRUE)

wlls <- grep("CMIP6_Atlas_WarmingLevels", filelist, value = TRUE, fixed = TRUE) %>% grep("\\.csv$", ., value = TRUE)
wlfiles <- paste0(root, wlls)
aux1.5 <- read.table(wlfiles, header = TRUE, sep = ",")[["X1.5_ssp585"]]
aux2 <- read.table(wlfiles, header = TRUE, sep = ",")[["X2_ssp585"]]
modelruns <- as.character(read.table(wlfiles, header = TRUE, sep = ",")[,1])
ind <- which(aux1.5 != 9999 & !is.na(aux1.5))
modelruns <- modelruns[ind]
per1.5 <- cbind(aux1.5-9, aux1.5+10)[ind,]
per2 <- cbind(aux2-9, aux2+10)[ind,]
modelruns <- gsub("_", "_.*", modelruns)

exp <- "ssp585"

WL.cmip6 <- computeDeltas(allfiles, modelruns, ref.period, periods = list("+1.5º" = per1.5, "+2º" = per2), exp, season)

WLmediana.cmip6 <- lapply(WL.cmip6, apply, 2, median, na.rm = T)
WLp90.cmip6 <- lapply(WL.cmip6, apply, 2, quantile, 0.9, na.rm = T)
WLp10.cmip6 <- lapply(WL.cmip6, apply, 2, quantile, 0.1, na.rm = T)

##########  CMIP5##########------------------------------------
ls <- grep(paste0("CMIP5_", var,"_",area,"/"), filelist, value = TRUE, fixed = TRUE) %>% grep("\\.csv$", ., value = TRUE)
allfiles <- paste0(root, ls)
aux <- grep("historical", ls, value = TRUE)
modelruns <- gsub(paste0("reference_regions/regional_means/data/CMIP5_", var,"_",area,"/CMIP5_|_historical.csv"), "", aux)

exp <- c("rcp26", "rcp45", "rcp85")
periods <- list( "near" = cbind(rep(2021, length(modelruns)),rep(2040, length(modelruns))), 
                 "mid"= cbind(rep(2041, length(modelruns)),rep(2060, length(modelruns))), 
                 "far" = cbind(rep(2081, length(modelruns)),rep(2100, length(modelruns))))

cmip5 <- computeDeltas(allfiles, modelruns, ref.period, periods, exp, season)

mediana.cmip5 <- lapply(cmip5, apply, 2, median, na.rm = T)
p90.cmip5 <- lapply(cmip5, apply, 2, quantile, 0.9, na.rm = T)
p10.cmip5 <- lapply(cmip5, apply, 2, quantile, 0.1, na.rm = T)

##########  CMIP6##########------------------------------------
ls <- grep(paste0("CMIP6_", var,"_",area,"/"), filelist, value = TRUE, fixed = TRUE) %>% grep("\\.csv$", ., value = TRUE)
allfiles <- paste0(root, ls)
aux <- grep("historical", ls, value = TRUE)
modelruns <- gsub(paste0("reference_regions/regional_means/data/CMIP6_", var,"_",area,"/CMIP6_|historical_|.csv"), ".*", aux)

exp <- c("ssp126", "ssp245", "ssp585")
periods <- list( "near" = cbind(rep(2021, length(modelruns)),rep(2040, length(modelruns))), 
                 "mid"= cbind(rep(2041, length(modelruns)),rep(2060, length(modelruns))), 
                 "far" = cbind(rep(2081, length(modelruns)),rep(2100, length(modelruns))))

cmip6 <- computeDeltas(allfiles, modelruns, ref.period, periods, exp, season)

mediana.cmip6 <- lapply(cmip6, apply, 2, median, na.rm = T)
p90.cmip6 <- lapply(cmip6, apply, 2, quantile, 0.9, na.rm = T)
p10.cmip6 <- lapply(cmip6, apply, 2, quantile, 0.1, na.rm = T)




########## plot #######------------------------------------------------------------------------

library(lattice)
library(gridExtra)

ylim <- c(0, 10); step <- 1

p <- lapply(1:length(mediana.cmip5), function(i){
  col = c("darkmagenta", "darkgoldenrod1", "green", "blue", "red")
  a1 <- c(WLmediana.cmip5[[i]][1],WLmediana.cmip6[[i]][1], rep(NA, 8))
  a2 <- c(rep(NA, 2),WLmediana.cmip5[[i]][2],WLmediana.cmip6[[i]][2], rep(NA, 6))
  a <- c(c(NA,NA,NA,NA),mediana.cmip5[[i]][1], mediana.cmip6[[i]][1], mediana.cmip5[[i]][4], mediana.cmip6[[i]][4],mediana.cmip5[[i]][7], mediana.cmip6[[i]][7])
  b <- c(c(NA,NA,NA,NA),mediana.cmip5[[i]][2], mediana.cmip6[[i]][2], mediana.cmip5[[i]][5], mediana.cmip6[[i]][5],mediana.cmip5[[i]][8], mediana.cmip6[[i]][8])
  d <- c(c(NA,NA,NA,NA),mediana.cmip5[[i]][3], mediana.cmip6[[i]][3], mediana.cmip5[[i]][6], mediana.cmip6[[i]][6],mediana.cmip5[[i]][9], mediana.cmip6[[i]][9])
  x <- c("+1.5º5","+1.5º6", "+2º5","+2º6", "anear5", "anear6", "bmid5", "bmid6", "clong5", "clong6")
  df <- data.frame("term" = x, "WL1" = a1, "WL2" = a2, "ssp126" = a, "ssp245" = b, "ssp585" = d)
  
  a1i <- c(WLp10.cmip5[[i]][1],WLp10.cmip6[[i]][1], rep(NA, 8))
  a2i <- c(rep(NA, 2), WLp10.cmip5[[i]][2],WLp10.cmip6[[i]][2], rep(NA, 6))
  ai <- c(c(NA,NA,NA,NA),p10.cmip5[[i]][1], p10.cmip6[[i]][1], p10.cmip5[[i]][4], p10.cmip6[[i]][4],p10.cmip5[[i]][7], p10.cmip6[[i]][7])
  bi <- c(c(NA,NA,NA,NA),p10.cmip5[[i]][2], p10.cmip6[[i]][2], p10.cmip5[[i]][5], p10.cmip6[[i]][5],p10.cmip5[[i]][8], p10.cmip6[[i]][8])
  di <- c(c(NA,NA,NA,NA),p10.cmip5[[i]][3], p10.cmip6[[i]][3], p10.cmip5[[i]][6], p10.cmip6[[i]][6],p10.cmip5[[i]][9], p10.cmip6[[i]][9])
  xi <- c("+1.5º5","+1.5º6", "+2º5","+2º6", "anear5", "anear6", "bmid5", "bmid6", "clong5", "clong6")
  dfi <- data.frame("term" = xi, "WL1" = a1i, "WL2" = a2i, "ssp126" = ai, "ssp245" = bi, "ssp585" = di)
  
  a1j <- c(WLp90.cmip5[[i]][1],WLp90.cmip6[[i]][1], rep(NA, 8))
  a2j <- c(rep(NA, 2),WLp90.cmip5[[i]][2],WLp90.cmip6[[i]][2], rep(NA, 6))
  aj <- c(c(NA,NA,NA,NA),p90.cmip5[[i]][1], p90.cmip6[[i]][1], p90.cmip5[[i]][4], p90.cmip6[[i]][4],p90.cmip5[[i]][7], p90.cmip6[[i]][7])
  bj <- c(c(NA,NA,NA,NA),p90.cmip5[[i]][2], p90.cmip6[[i]][2], p90.cmip5[[i]][5], p90.cmip6[[i]][5],p90.cmip5[[i]][8], p90.cmip6[[i]][8])
  dj <- c(c(NA,NA,NA,NA),p90.cmip5[[i]][3], p90.cmip6[[i]][3], p90.cmip5[[i]][6], p90.cmip6[[i]][6],p90.cmip5[[i]][9], p90.cmip6[[i]][9])
  xj <- c("+1.5º5","+1.5º6", "+2º5","+2º6", "anear5", "anear6", "bmid5", "bmid6", "clong5", "clong6")
  dfj <- data.frame("term" = xj, "WL1" = a1j, "WL2" = a2j, "ssp126" = aj, "ssp245" = bj, "ssp585" = dj)
  
  xyplot(WL1+WL2+ssp126+ssp245+ssp585~term, data = df, ylim = ylim, pch = 19, ylab = "AT(ºC)",
         col = col, cex = 1.5, xlab = "", 
         main = names(mediana.cmip5)[i],
         panel = function(...){
           panel.abline(h = do.call("seq", as.list(c(ylim, step))),
                        col = "gray65", lwd = 0.5, lty = 2)
           panel.segments(df$term, dfi$WL1, df$term, dfj$WL1, col = "darkmagenta", lwd=3, alpha = 0.5)
           panel.segments(df$term, dfi$WL2, df$term, dfj$WL2, col = "darkgoldenrod1", lwd=3, alpha = 0.5)
           panel.segments(df$term, dfi$ssp126, df$term, dfj$ssp126, col = "green", lwd=3, alpha = 0.5)
           panel.segments(df$term, dfi$ssp245, df$term, dfj$ssp245, col = "blue", lwd=3, alpha = 0.5)
           panel.segments(df$term, dfi$ssp585, df$term, dfj$ssp585, col = "red", lwd=3, alpha = 0.5)
           panel.xyplot(...)
         })
})

nn <- "AT"
if (var == "pr") nn <- "AP"
pdf(paste0("/oceano/gmeteo/WORK/PROYECTOS/2018_IPCC/figs/boxplots/AAAAboxplots_",area,"_", nn, "_season_", paste(season, collapse = "-"), "_ylim_", paste(ylim, collapse = "-"), ".pdf"), width = 40, height = 50)
do.call("grid.arrange", p)
dev.off()

