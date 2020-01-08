library(magrittr)
library(httr)

# https://stackoverflow.com/questions/25485216/how-to-get-list-files-from-a-github-repository-folder-using-r
myurl <- "https://api.github.com/repos/SantanderMetGroup/IPCC-Atlas/git/trees/devel?recursive=1"
req <- GET(myurl) %>% stop_for_status(req)
filelist <- unlist(lapply(content(req)$tree, "[", "path"), use.names = FALSE)
root <- "https://raw.githubusercontent.com/SantanderMetGroup/IPCC-Atlas/devel/"
ref.period <- 1986:2005



#### FUNCTION FOR PREPEARING DATA (standard periods)#####--------------------------

prepareData <- function(allfiles, modelruns, aggr.fun, periods, exp){
  region <- colnames(grep("historical", allfiles[1], value = TRUE) %>% read.table(header = TRUE, sep = ",", skip = 7))[-1]
  dat <- lapply(1:length(modelruns), function(i) {
  modelfiles <- grep(modelruns[i], allfiles, value = TRUE) 
  hist <- grep("historical", modelfiles, value = TRUE) %>% read.table(header = TRUE, sep = ",", skip = 7)
  yrs <- grep("historical", modelfiles, value = TRUE) %>% read.table(header = TRUE, sep = ",", skip = 7) %>% subset(select = "date", drop = TRUE) %>% gsub("-.*", "", .) %>% as.integer()
  hist <- lapply(split(hist[,-1], f = yrs), function(x) apply(x, MARGIN = 2, FUN = aggr.fun, na.rm = TRUE))
  hist <- do.call("rbind", hist)
  hist <- hist[which(rownames(hist) == range(ref.period)[1]): which(rownames(hist) == range(ref.period)[2]),]
  hist <- apply(hist, MARGIN = 2, FUN = mean, na.rm = TRUE)
  l1 <- lapply(1:length(exp), FUN = function(j) {
    message("i =", i, ".......", "j =", j)
    rcp <- tryCatch({
      grep(exp[j], modelfiles, value = TRUE) %>% read.table(header = TRUE, sep = ",", skip = 7)
    }, error = function(err) return(NULL))
    dates <- tryCatch({
      yrs <- grep(exp[j], modelfiles, value = TRUE) %>% read.table(header = TRUE, sep = ",", skip = 7) %>% subset(select = "date", drop = TRUE) %>% gsub("-.*", "", .) %>% as.integer()
      rcp <- lapply(split(rcp[,-1], f = yrs), function(x) apply(x, MARGIN = 2, FUN = "mean", na.rm = TRUE))
    }, error = function(err) return(NULL))
    if (!is.null(rcp)) {
      rcp <- do.call("rbind", rcp)
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
        apply(rcpk, MARGIN = 2, FUN = mean, na.rm = TRUE) - hist
      })
    } else {
      delta <- rep(list(NULL), length(periods))
    }
    
    names(delta) <- names(periods)
    delta
  })
  names(l1) <- exp
  l1
})
names(dat) <- modelruns


data <- lapply(region, function(i) {
  eo <- lapply(exp, function(l){
    z <- lapply(dat, function(x){
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


########## tas CMIP5 WL ##########------------------------------------
aggr.fun <- "mean"
ls <- grep("CMIP5_tas_landsea", filelist, value = TRUE, fixed = TRUE) %>% grep("\\.csv$", ., value = TRUE)
allfiles <- paste0(root, ls)
aux <- grep("historical", ls, value = TRUE)

wlls <- grep("CMIP5_Atlas_WarmingLevels", filelist, value = TRUE, fixed = TRUE) %>% grep("\\.csv$", ., value = TRUE)
wlfiles <- paste0(root, wlls)
aux1.5 <- read.table(wlfiles, header = TRUE, sep = ",")[["X1.5_RCP85"]]
aux2 <- read.table(wlfiles, header = TRUE, sep = ",")[["X2_RCP85"]]
modelruns <- as.character(read.table(wlfiles, header = TRUE, sep = ",")[,1])[-which(aux1.5 == 9999)]
modelruns[18] <- "HadGEM2-ES_r1i1p1"
per1.5 <- cbind(aux1.5-9, aux1.5+10)[-which(aux1.5 == 9999),]
per2 <- cbind(aux2-9, aux2+10)[-which(aux1.5 == 9999),]
exp <- "rcp85"

tasWL.cmip5 <- prepareData(allfiles, modelruns, aggr.fun, periods = list("+1.5º" = per1.5, "+2º" = per2), exp)

tasWLmediana.cmip5 <- lapply(tasWL.cmip5, apply, 2, median, na.rm = T)
tasWLp90.cmip5 <- lapply(tasWL.cmip5, apply, 2, quantile, 0.9, na.rm = T)
tasWLp10.cmip5 <- lapply(tasWL.cmip5, apply, 2, quantile, 0.1, na.rm = T)


########## tas CMIP6 WL ##########------------------------------------
aggr.fun <- "mean"
ls <- grep("CMIP6Amon_tas_landsea", filelist, value = TRUE, fixed = TRUE) %>% grep("\\.csv$", ., value = TRUE)
allfiles <- paste0(root, ls)
aux <- grep("historical", ls, value = TRUE)

wlls <- grep("CMIP6_Atlas_WarmingLevels", filelist, value = TRUE, fixed = TRUE) %>% grep("\\.csv$", ., value = TRUE)
wlfiles <- paste0(root, wlls)
aux1.5 <- read.table(wlfiles, header = TRUE, sep = ",")[["X1.5_ssp5.85"]]
aux2 <- read.table(wlfiles, header = TRUE, sep = ",")[["X2_ssp5.85"]]
modelruns <- as.character(read.table(wlfiles, header = TRUE, sep = ",")[,1])[-which(aux1.5 == 9999)]
per1.5 <- cbind(aux1.5-9, aux1.5+10)[-which(aux1.5 == 9999),]
per2 <- cbind(aux2-9, aux2+10)[-which(aux1.5 == 9999),]
exp <- "ssp585"

tasWL.cmip6 <- prepareData(allfiles, modelruns, aggr.fun, periods = list("+1.5º" = per1.5, "+2º" = per2), exp)

tasWLmediana.cmip6 <- lapply(tasWL.cmip6, apply, 2, median, na.rm = T)
tasWLp90.cmip6 <- lapply(tasWL.cmip6, apply, 2, quantile, 0.9, na.rm = T)
tasWLp10.cmip6 <- lapply(tasWL.cmip6, apply, 2, quantile, 0.1, na.rm = T)

########## tas CMIP5##########------------------------------------
ls <- grep("CMIP5_tas_landsea", filelist, value = TRUE, fixed = TRUE) %>% grep("\\.csv$", ., value = TRUE)
allfiles <- paste0(root, ls)
aux <- grep("historical", ls, value = TRUE)
modelruns <- gsub("reference_regions/regional_means/data/CMIP5_tas_landsea/CMIP5_|_historical.csv", "", aux)

exp <- c("rcp26", "rcp45", "rcp85")
periods <- list( "near" = cbind(rep(2021, length(modelruns)),rep(2040, length(modelruns))), 
                 "mid"= cbind(rep(2041, length(modelruns)),rep(2060, length(modelruns))), 
                 "far" = cbind(rep(2081, length(modelruns)),rep(2100, length(modelruns))))

tas.cmip5 <- prepareData(allfiles, modelruns, "mean", periods, exp)

tasmediana.cmip5 <- lapply(tas.cmip5, apply, 2, median, na.rm = T)
tasp90.cmip5 <- lapply(tas.cmip5, apply, 2, quantile, 0.9, na.rm = T)
tasp10.cmip5 <- lapply(tas.cmip5, apply, 2, quantile, 0.1, na.rm = T)

########## tas CMIP6##########------------------------------------
ls <- grep("CMIP6Amon_tas_landsea", filelist, value = TRUE, fixed = TRUE) %>% grep("\\.csv$", ., value = TRUE)
allfiles <- paste0(root, ls)
aux <- grep("historical", ls, value = TRUE)
modelruns <- gsub("reference_regions/regional_means/data/CMIP6Amon_tas_landsea/CMIP6Amon_|_historical.csv", "", aux)

exp <- c("ssp126", "ssp245", "ssp585")
periods <- list( "near" = cbind(rep(2021, length(modelruns)),rep(2040, length(modelruns))), 
                 "mid"= cbind(rep(2041, length(modelruns)),rep(2060, length(modelruns))), 
                 "far" = cbind(rep(2081, length(modelruns)),rep(2100, length(modelruns))))

tas.cmip6 <- prepareData(allfiles, modelruns, "mean", periods, exp)

tasmediana.cmip6 <- lapply(tas.cmip6, apply, 2, median, na.rm = T)
tasp90.cmip6 <- lapply(tas.cmip6, apply, 2, quantile, 0.9, na.rm = T)
tasp10.cmip6 <- lapply(tas.cmip6, apply, 2, quantile, 0.1, na.rm = T)

######## pr CMIP5 ###########------------------------------------
ls <- grep("CMIP5_pr_landsea", filelist, value = TRUE, fixed = TRUE) %>% grep("\\.csv$", ., value = TRUE)
allfiles <- paste0(root, ls)
aux <- grep("historical", ls, value = TRUE)
modelruns <- gsub("reference_regions/regional_means/data/CMIP5_pr_landsea/CMIP5_|_historical.csv", "", aux)

pr.cmip5 <- prepareData(allfiles, modelruns, "sum", periods, exp)

prmediana.cmip5 <- lapply(tas.cmip6, apply, 2, median, na.rm = T)
prp90.cmip5 <- lapply(tas.cmip6, apply, 2, quantile, 0.9, na.rm = T)
prp10.cmip5 <- lapply(tas.cmip6, apply, 2, quantile, 0.1, na.rm = T)


######## pr CMIP6 ###########------------------------------------
ls <- grep("CMIP6Amon_pr_landsea", filelist, value = TRUE, fixed = TRUE) %>% grep("\\.csv$", ., value = TRUE)
allfiles <- paste0(root, ls)
aux <- grep("historical", ls, value = TRUE)
modelruns <- gsub("reference_regions/regional_means/data/CMIP6Amon_pr_landsea/CMIP6Amon_|_historical.csv", "", aux)

pr.cmip6 <- prepareData(allfiles, modelruns, "sum")

prmediana.cmip6 <- lapply(tas.cmip6, apply, 2, median, na.rm = T)
prp90.cmip6 <- lapply(tas.cmip6, apply, 2, quantile, 0.9, na.rm = T)
prp10.cmip6 <- lapply(tas.cmip6, apply, 2, quantile, 0.1, na.rm = T)


########## plot #######------------------------------------------------------------------------

library(lattice)
library(gridExtra)

p <- lapply(1:length(tasmediana.cmip5), function(i){
  col = c("darkmagenta", "darkgoldenrod1", "green", "blue", "red")
  a1 <- c(tasWLmediana.cmip5[[i]][1],tasWLmediana.cmip6[[i]][1], rep(NA, 8))
  a2 <- c(rep(NA, 2),tasWLmediana.cmip5[[i]][2],tasWLmediana.cmip6[[i]][2], rep(NA, 6))
  a <- c(c(NA,NA,NA,NA),tasmediana.cmip5[[i]][1], tasmediana.cmip6[[i]][1], tasmediana.cmip5[[i]][4], tasmediana.cmip6[[i]][4],tasmediana.cmip5[[i]][7], tasmediana.cmip6[[i]][7])
  b <- c(c(NA,NA,NA,NA),tasmediana.cmip5[[i]][2], tasmediana.cmip6[[i]][2], tasmediana.cmip5[[i]][5], tasmediana.cmip6[[i]][5],tasmediana.cmip5[[i]][8], tasmediana.cmip6[[i]][8])
  d <- c(c(NA,NA,NA,NA),tasmediana.cmip5[[i]][3], tasmediana.cmip6[[i]][3], tasmediana.cmip5[[i]][6], tasmediana.cmip6[[i]][6],tasmediana.cmip5[[i]][9], tasmediana.cmip6[[i]][9])
  x <- c("+1.5º5","+1.5º6", "+2º5","+2º6", "anear5", "anear6", "bmid5", "bmid6", "clong5", "clong6")
  df <- data.frame("term" = x, "WL1" = a1, "WL2" = a2, "ssp126" = a, "ssp245" = b, "ssp585" = d)
  
  a1i <- c(tasWLp10.cmip5[[i]][1],tasWLp10.cmip6[[i]][1], rep(NA, 8))
  a2i <- c(rep(NA, 2), tasWLp10.cmip5[[i]][2],tasWLp10.cmip6[[i]][2], rep(NA, 6))
  ai <- c(c(NA,NA,NA,NA),tasp10.cmip5[[i]][1], tasp10.cmip6[[i]][1], tasp10.cmip5[[i]][4], tasp10.cmip6[[i]][4],tasp10.cmip5[[i]][7], tasp10.cmip6[[i]][7])
  bi <- c(c(NA,NA,NA,NA),tasp10.cmip5[[i]][2], tasp10.cmip6[[i]][2], tasp10.cmip5[[i]][5], tasp10.cmip6[[i]][5],tasp10.cmip5[[i]][8], tasp10.cmip6[[i]][8])
  di <- c(c(NA,NA,NA,NA),tasp10.cmip5[[i]][3], tasp10.cmip6[[i]][3], tasp10.cmip5[[i]][6], tasp10.cmip6[[i]][6],tasp10.cmip5[[i]][9], tasp10.cmip6[[i]][9])
  xi <- c("+1.5º5","+1.5º6", "+2º5","+2º6", "anear5", "anear6", "bmid5", "bmid6", "clong5", "clong6")
  dfi <- data.frame("term" = xi, "WL1" = a1i, "WL2" = a2i, "ssp126" = ai, "ssp245" = bi, "ssp585" = di)
  
  a1j <- c(tasWLp90.cmip5[[i]][1],tasWLp90.cmip6[[i]][1], rep(NA, 8))
  a2j <- c(rep(NA, 2),tasWLp90.cmip5[[i]][2],tasWLp90.cmip6[[i]][2], rep(NA, 6))
  aj <- c(c(NA,NA,NA,NA),tasp90.cmip5[[i]][1], tasp90.cmip6[[i]][1], tasp90.cmip5[[i]][4], tasp90.cmip6[[i]][4],tasp90.cmip5[[i]][7], tasp90.cmip6[[i]][7])
  bj <- c(c(NA,NA,NA,NA),tasp90.cmip5[[i]][2], tasp90.cmip6[[i]][2], tasp90.cmip5[[i]][5], tasp90.cmip6[[i]][5],tasp90.cmip5[[i]][8], tasp90.cmip6[[i]][8])
  dj <- c(c(NA,NA,NA,NA),tasp90.cmip5[[i]][3], tasp90.cmip6[[i]][3], tasp90.cmip5[[i]][6], tasp90.cmip6[[i]][6],tasp90.cmip5[[i]][9], tasp90.cmip6[[i]][9])
  xj <- c("+1.5º5","+1.5º6", "+2º5","+2º6", "anear5", "anear6", "bmid5", "bmid6", "clong5", "clong6")
  dfj <- data.frame("term" = xj, "WL1" = a1j, "WL2" = a2j, "ssp126" = aj, "ssp245" = bj, "ssp585" = dj)
  
  xyplot(WL1+WL2+ssp126+ssp245+ssp585~term, data = df, ylim = c(0, 10), pch = 19, ylab = "AT(ºC)",
         col = col, cex = 1.5, xlab = "", 
         main = names(tasmediana.cmip5)[i],
         panel = function(...){
           panel.abline(h = seq(0, 10, 1),
                        col = "gray65", lwd = 0.5, lty = 2)
           panel.segments(df$term, dfi$WL1, df$term, dfj$WL1, col = "darkmagenta", lwd=3, alpha = 0.5)
           panel.segments(df$term, dfi$WL2, df$term, dfj$WL2, col = "darkgoldenrod1", lwd=3, alpha = 0.5)
           panel.segments(df$term, dfi$ssp126, df$term, dfj$ssp126, col = "green", lwd=3, alpha = 0.5)
           panel.segments(df$term, dfi$ssp245, df$term, dfj$ssp245, col = "blue", lwd=3, alpha = 0.5)
           panel.segments(df$term, dfi$ssp585, df$term, dfj$ssp585, col = "red", lwd=3, alpha = 0.5)
           panel.xyplot(...)
         })
})
pdf("/oceano/gmeteo/WORK/PROYECTOS/2018_IPCC/figs/boxplots_AT.pdf", width = 40, height = 50)
do.call("grid.arrange", p)
dev.off()



