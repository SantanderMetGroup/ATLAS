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

area <- "land"
var = "tas"
season = c(12, 1, 2)


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
    if (length(start) == 0) {
      start <-  1
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
        delta <- lapply (periods, function(k){
          endyear <- k[i,][2]
          startyear <- k[i,][1]
          if (!is.na(endyear) & !is.na(startyear)) {
            while (length(which(rownames(rcp) == endyear)) == 0) {
              endyear <- endyear - 1
            }
            while (length(which(rownames(rcp) == startyear)) == 0) {
              startyear <- startyear + 1
            }
            
            rcpk <- rcp[which(rownames(rcp) == startyear) : which(rownames(rcp) == endyear),]
            if (var == "tas") {
              apply(rcpk, MARGIN = 2, FUN = mean, na.rm = TRUE) - histexp
            } else if (var == "pr") {
              (apply(rcpk, MARGIN = 2, FUN = mean, na.rm = TRUE) - histexp) / histexp * 100
            }  
          } else {
            message("i =", i, ".......", exp[j], "------NO period")
            a <- rep(NA, ncol(rcp))
            names(a) <- colnames(rcp)
            a
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
ref.period <- 1850:1900

ls <- grep(paste0("CMIP5_", var,"_",area,"/"), filelist, value = TRUE, fixed = TRUE) %>% grep("\\.csv$", ., value = TRUE)
allfiles <- paste0(root, ls)
aux <- grep("historical", ls, value = TRUE)

wlls <- grep("CMIP5_Atlas_WarmingLevels", filelist, value = TRUE, fixed = TRUE) %>% grep("\\.csv$", ., value = TRUE)
wlfiles <- paste0(root, wlls)
aux1.5 <- read.table(wlfiles, header = TRUE, sep = ",")[["X1.5_rcp85"]]
aux2 <- read.table(wlfiles, header = TRUE, sep = ",")[["X2_rcp85"]]
aux3 <- read.table(wlfiles, header = TRUE, sep = ",")[["X3_rcp85"]]
aux4 <- read.table(wlfiles, header = TRUE, sep = ",")[["X4_rcp85"]]
modelruns <- as.character(read.table(wlfiles, header = TRUE, sep = ",")[,1])
# modelruns[modelruns == "HadGEM2-CC_r1i1p1"] <- "HadGEM2-ES_r1i1p1"
ind <- which(aux1.5 != 9999 & modelruns != "EC-EARTH_r3i1p1")
modelruns <- modelruns[ind]
per1.5 <- cbind(aux1.5-9, aux1.5+10)[ind,]
per2 <- cbind(aux2-9, aux2+10)[ind,]
per3 <- cbind(aux3-9, aux3+10)[ind,]
per4 <- cbind(aux4-9, aux4+10)[ind,]

exp <- "rcp85"

WL.cmip5 <- computeDeltas(allfiles, modelruns, ref.period, periods = list("+1.5º" = per1.5, "+2º" = per2, "+3º" = per3, "+4º" = per4), exp, season)

WLmediana.cmip5 <- lapply(WL.cmip5, apply, 2, median, na.rm = T)
WLp90.cmip5 <- lapply(WL.cmip5, apply, 2, quantile, 0.9, na.rm = T)
WLp10.cmip5 <- lapply(WL.cmip5, apply, 2, quantile, 0.1, na.rm = T)


##########  CMIP6 WL ##########------------------------------------
ref.period <- 1850:1900

aggr.fun <- "mean"
ls <- grep(paste0("CMIP6_", var,"_",area,"/"), filelist, value = TRUE, fixed = TRUE) %>% grep("\\.csv$", ., value = TRUE)
allfiles <- paste0(root, ls)
aux <- grep("historical", ls, value = TRUE)

wlls <- grep("CMIP6_Atlas_WarmingLevels", filelist, value = TRUE, fixed = TRUE) %>% grep("\\.csv$", ., value = TRUE)
wlfiles <- paste0(root, wlls)
aux1.5 <- read.table(wlfiles, header = TRUE, sep = ",")[["X1.5_ssp585"]]
aux2 <- read.table(wlfiles, header = TRUE, sep = ",")[["X2_ssp585"]]
aux3 <- read.table(wlfiles, header = TRUE, sep = ",")[["X3_ssp585"]]
aux4 <- read.table(wlfiles, header = TRUE, sep = ",")[["X4_ssp585"]]
modelruns <- as.character(read.table(wlfiles, header = TRUE, sep = ",")[,1])
# modelruns[modelruns == "HadGEM2-CC_r1i1p1"] <- "HadGEM2-ES_r1i1p1"
ind <- which(aux1.5 != 9999 & modelruns != "EC-EARTH_r3i1p1")
modelruns <- modelruns[ind]
per1.5 <- cbind(aux1.5-9, aux1.5+10)[ind,]
per2 <- cbind(aux2-9, aux2+10)[ind,]
per3 <- cbind(aux3-9, aux3+10)[ind,]
per4 <- cbind(aux4-9, aux4+10)[ind,]

modelruns <- gsub("_", "_.*", modelruns)

exp <- "ssp585"

WL.cmip6 <- computeDeltas(allfiles, modelruns, ref.period, periods = list("+1.5º" = per1.5, "+2º" = per2, "+3º" = per3, "+4º" = per4), exp, season)

WLmediana.cmip6 <- lapply(WL.cmip6, apply, 2, median, na.rm = T)
WLp90.cmip6 <- lapply(WL.cmip6, apply, 2, quantile, 0.9, na.rm = T)
WLp10.cmip6 <- lapply(WL.cmip6, apply, 2, quantile, 0.1, na.rm = T)

##########  CMIP5##########------------------------------------
ref.period <- 1995:2014
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
ref.period <- 1995:2014
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



# ##########  CORDEX##########------------------------------------
# 
# ref.period <- 1986:2005
# ls <- grep(paste0("CORDEX_", var,"_",area,"/"), filelist, value = TRUE, fixed = TRUE) %>% grep("\\.csv$", ., value = TRUE)
# allfiles <- paste0(root, ls)
# aux <- grep("historical", ls, value = TRUE)
# modelruns <- gsub(paste0("reference_regions/regional_means/data/CORDEX_", var,"_",area,"/CORDEX_|historical_|.csv"), ".*", aux)
# 
# exp <- c("rcp26", "rcp45", "rcp85")
# periods <- list( "near" = cbind(rep(2021, length(modelruns)),rep(2040, length(modelruns))), 
#                  "mid"= cbind(rep(2041, length(modelruns)),rep(2060, length(modelruns))), 
#                  "far" = cbind(rep(2081, length(modelruns)),rep(2100, length(modelruns))))
# 
# cordex <- computeDeltas(allfiles, modelruns, ref.period, periods, exp, season)
# 
# mediana.cordex <- lapply(cordex, apply, 2, median, na.rm = T)
# p90.cordex <- lapply(cordex, apply, 2, quantile, 0.9, na.rm = T)
# p10.cordex <- lapply(cordex, apply, 2, quantile, 0.1, na.rm = T)


########## plot #######------------------------------------------------------------------------

library(lattice)
library(gridExtra)

ylim <- c(0, 10); step <- 1
ylab <- bquote(Delta*"T(ºC)")

p <- lapply(1:length(mediana.cmip5), function(i){
  col = c(rgb(0.55,0,0.55,0.5), rgb(0.55,0,0.55), rgb(1, 0.73, 0.06, 0.5),  rgb(1, 0.73, 0.06), 
          rgb(0, 0, 0, 0.5),  rgb(0, 0, 0), rgb(0.5, 0.3, 0.16, 0.5),  rgb(0.5, 0.3, 0.16), 
          rep(c(rgb(0,0,1,0.5), "blue", rgb(0,1,0,0.5), "green", rgb(1,0,0,0.5), "red"), 9))
  a1 <- c(WLmediana.cmip5[[i]][1],WLmediana.cmip6[[i]][1])
  a2 <- c(WLmediana.cmip5[[i]][2],WLmediana.cmip6[[i]][2])
  a3 <- c(WLmediana.cmip5[[i]][3],WLmediana.cmip6[[i]][3])
  a4 <- c(WLmediana.cmip5[[i]][4],WLmediana.cmip6[[i]][4])
  a <- c(mediana.cmip5[[i]][1], mediana.cmip6[[i]][1], mediana.cmip5[[i]][4], mediana.cmip6[[i]][4],mediana.cmip5[[i]][7], mediana.cmip6[[i]][7])
  b <- c(mediana.cmip5[[i]][2], mediana.cmip6[[i]][2], mediana.cmip5[[i]][5], mediana.cmip6[[i]][5],mediana.cmip5[[i]][8], mediana.cmip6[[i]][8])
  d <- c(mediana.cmip5[[i]][3], mediana.cmip6[[i]][3], mediana.cmip5[[i]][6], mediana.cmip6[[i]][6],mediana.cmip5[[i]][9], mediana.cmip6[[i]][9])
  sc <- c("rcp26", "ssp126", "rcp45", "ssp245", "rcp85", "ssp585")
  x0 <- c(paste0("+1.5º-", c("rcp85","ssp585")), paste0("+2º-", c("rcp85","ssp585")), paste0("+3º-", c("rcp85","ssp585")), paste0("+4º-", c("rcp85","ssp585")), paste0("near-", sc), paste0("mid-", sc), paste0("far-", sc))
  # ind <- c(1:4, c(5, 7, 9), c(6, 8, 10), c(11, 13, 15), c(12, 14, 16), c(17, 19, 21), c(18, 20, 22))
  ind <- 1:length(x0)
  x <- paste0(letters[1:length(x0)], ")",  x0[ind])
  
  
  
  df <- data.frame("term" = x, "value" = unname(do.call("c", list(a1, a2, a3, a4, a, b, d)))[ind])
  
  
  
  a1i <- c(WLp10.cmip5[[i]][1],WLp10.cmip6[[i]][1])
  a2i <- c(WLp10.cmip5[[i]][2],WLp10.cmip6[[i]][2])
  a3i <- c(WLp10.cmip5[[i]][3],WLp10.cmip6[[i]][3])
  a4i <- c(WLp10.cmip5[[i]][4],WLp10.cmip6[[i]][4])
  ai <- c(p10.cmip5[[i]][1], p10.cmip6[[i]][1], p10.cmip5[[i]][4], p10.cmip6[[i]][4],p10.cmip5[[i]][7], p10.cmip6[[i]][7])
  bi <- c(p10.cmip5[[i]][2], p10.cmip6[[i]][2], p10.cmip5[[i]][5], p10.cmip6[[i]][5],p10.cmip5[[i]][8], p10.cmip6[[i]][8])
  di <- c(p10.cmip5[[i]][3], p10.cmip6[[i]][3], p10.cmip5[[i]][6], p10.cmip6[[i]][6],p10.cmip5[[i]][9], p10.cmip6[[i]][9])
  dfi <- data.frame("term" = x, "value" = unname(do.call("c", list(a1i, a2i, a3i, a4i, ai, bi, di)))[ind])
  
  a1j <- c(WLp90.cmip5[[i]][1],WLp90.cmip6[[i]][1])
  a2j <- c(WLp90.cmip5[[i]][2],WLp90.cmip6[[i]][2])
  a3j <- c(WLp90.cmip5[[i]][3],WLp90.cmip6[[i]][3])
  a4j <- c(WLp90.cmip5[[i]][4],WLp90.cmip6[[i]][4])
  aj <- c(p90.cmip5[[i]][1], p90.cmip6[[i]][1], p90.cmip5[[i]][4], p90.cmip6[[i]][4],p90.cmip5[[i]][7], p90.cmip6[[i]][7])
  bj <- c(p90.cmip5[[i]][2], p90.cmip6[[i]][2], p90.cmip5[[i]][5], p90.cmip6[[i]][5],p90.cmip5[[i]][8], p90.cmip6[[i]][8])
  dj <- c(p90.cmip5[[i]][3], p90.cmip6[[i]][3], p90.cmip5[[i]][6], p90.cmip6[[i]][6],p90.cmip5[[i]][9], p90.cmip6[[i]][9])
  dfj <- data.frame("term" = x, "value" = unname(do.call("c", list(a1j, a2j, a3j, a4j, aj, bj, dj)))[ind])
  
  col <- col[ind]
  
  xyplot(value~term, data = df, ylim = ylim, pch = 19, ylab = ylab, scales=list(x=list(rot=90)),
         col = col, cex = 1, xlab = "", #, 
         main = names(mediana.cmip5)[i],
         panel = function(...){
           panel.abline(h = do.call("seq", as.list(c(ylim, step))),
                        col = "gray65", lwd = 0.5, lty = 2)
           panel.segments(df$term, dfi$value, df$term, dfj$value, col = col, lwd = 5) #alpha = 0.5)
           panel.xyplot(...)
         })
})

nn <- "AT"
if (var == "pr") nn <- "AP"
pdf(paste0("/oceano/gmeteo/WORK/PROYECTOS/2018_IPCC/figs/boxplots/FGD_boxplots_",area,"_", nn, "_season_", paste(season, collapse = "-"), "_ylim_", paste(ylim, collapse = "-"), ".pdf"), width = 40, height = 50)
do.call("grid.arrange", p)
dev.off()

