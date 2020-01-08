library(magrittr)
library(httr)

# https://stackoverflow.com/questions/25485216/how-to-get-list-files-from-a-github-repository-folder-using-r
myurl <- "https://api.github.com/repos/SantanderMetGroup/IPCC-Atlas/git/trees/devel?recursive=1"
req <- GET(myurl) %>% stop_for_status(req)
filelist <- unlist(lapply(content(req)$tree, "[", "path"), use.names = FALSE)
root <- "https://raw.githubusercontent.com/SantanderMetGroup/IPCC-Atlas/devel/"
exp <- c("ssp126", "ssp245", "ssp585")
ref.period <- 1986:2005
periods <- list(2021:2040, 2041:2060, 2061:2080, 2081:2100)

########## tas ##########------------------------------------
ls <- grep("CMIP6Amon_tas_land/", filelist, value = TRUE, fixed = TRUE) %>% grep("\\.csv$", ., value = TRUE)
allfiles <- paste0(root, ls)
aux <- grep("historical", ls, value = TRUE)
modelruns <- gsub("reference_regions/regional_means/data/CMIP6Amon_tas_land/CMIP6Amon_|_historical.csv", "", aux)

tas <- lapply(modelruns, function(i) {
  modelfiles <- grep(i, allfiles, value = TRUE) 
  hist <- grep("historical", modelfiles, value = TRUE) %>% read.table(header = TRUE, sep = ",", skip = 7)
  yrs <- grep("historical", modelfiles, value = TRUE) %>% read.table(header = TRUE, sep = ",", skip = 7) %>% subset(select = "date", drop = TRUE) %>% gsub("-.*", "", .) %>% as.integer()
  hist <- lapply(split(hist[,-1], f = yrs), function(x) apply(x, MARGIN = 2, FUN = "mean", na.rm = TRUE))
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
      endyear <- range(k)[2]
      while (length(which(rownames(rcp) == endyear)) == 0) {
        endyear <- endyear - 1
      }
      rcpk <- rcp[which(rownames(rcp) == range(k)[1]) : which(rownames(rcp) == endyear),]
      apply(rcpk, MARGIN = 2, FUN = mean, na.rm = TRUE) - hist
    })
    } else {
      delta <- rep(list(NULL), 4)
    }
    names(delta) <- c("near", "mid", "far", "end")
    delta
  })
  names(l1) <- exp
  l1
})
names(tas) <- modelruns


region <- names(tas[[1]][[1]][[1]])
scenario <- c("ssp126", "ssp245", "ssp585")
terms <- c("near", "mid", "far", "end")


data <- lapply(region, function(i) {
  eo <- lapply(scenario, function(l){
    z <- lapply(tas, function(x){
      values <- unname(do.call("cbind", lapply(x[[l]], "[[", i)))
      if(is.null(values)) values <- rep(NA, 4)
      values
    })
    df <- do.call("rbind", z)
    rownames(df) <- names(z)
    colnames(df) <- rep(l, 4)
    df
  })
  do.call("cbind", eo)
})
names(data) <- region

tasmediana <- lapply(data, apply, 2, median, na.rm = T)
tasp90 <- lapply(data, apply, 2, quantile, 0.9, na.rm = T)
tasp10 <- lapply(data, apply, 2, quantile, 0.1, na.rm = T)



######## pr ###########------------------------------------
ls <- grep("CMIP6Amon_pr_land/", filelist, value = TRUE, fixed = TRUE) %>% grep("\\.csv$", ., value = TRUE)
allfiles <- paste0(root, ls)
aux <- grep("historical", ls, value = TRUE)
modelruns <- gsub("reference_regions/regional_means/data/CMIP6Amon_pr_land/CMIP6Amon_|_historical.csv", "", aux)

pr <- lapply(modelruns, function(i) {
  modelfiles <- grep(i, allfiles, value = TRUE) 
  hist <- grep("historical", modelfiles, value = TRUE) %>% read.table(header = TRUE, sep = ",", skip = 7)
  yrs <- grep("historical", modelfiles, value = TRUE) %>% read.table(header = TRUE, sep = ",", skip = 7) %>% subset(select = "date", drop = TRUE) %>% gsub("-.*", "", .) %>% as.integer()
  hist <- lapply(split(hist[,-1], f = yrs), function(x) apply(x, MARGIN = 2, FUN = "sum", na.rm = TRUE))
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
      rcp <- lapply(split(rcp[,-1], f = yrs), function(x) apply(x, MARGIN = 2, FUN = "sum", na.rm = TRUE))
    }, error = function(err) return(NULL))
    if (!is.null(rcp)) {
      rcp <- do.call("rbind", rcp)
      delta <- lapply(periods, function(k){
        endyear <- range(k)[2]
        while (length(which(rownames(rcp) == endyear)) == 0) {
          endyear <- endyear - 1
        }
        rcpk <- rcp[which(rownames(rcp) == range(k)[1]) : which(rownames(rcp) == endyear),]
        (apply(rcpk, MARGIN = 2, FUN = mean, na.rm = TRUE) - hist)/ hist * 100
      })
    } else {
      delta <- rep(list(NULL), 4)
    }
    names(delta) <- c("near", "mid", "far", "end")
    delta
  })
  names(l1) <- exp
  l1
})
names(pr) <- modelruns


region <- names(pr[[1]][[1]][[1]])
scenario <- c("ssp126", "ssp245", "ssp585")
terms <- c("near", "mid", "far", "end")


data <- lapply(region, function(i) {
  eo <- lapply(scenario, function(l){
    z <- lapply(pr, function(x){
      values <- unname(do.call("cbind", lapply(x[[l]], "[[", i)))
      if (is.null(values)) values <- rep(NA, 4)
      values
    })
    df <- do.call("rbind", z)
    rownames(df) <- names(z)
    colnames(df) <- rep(l, 4)
    df
  })
  do.call("cbind", eo)
})
names(data) <- region

prmediana <- lapply(data, apply, 2, median, na.rm = T)
prp90 <- lapply(data, apply, 2, quantile, 0.9, na.rm = T)
prp10 <- lapply(data, apply, 2, quantile, 0.1, na.rm = T)


########## plot #######------------------------------------------------------------------------
region <- region[1:44]
pdf("/oceano/gmeteo/WORK/PROYECTOS/2018_IPCC/figs/scatterplots_land_fixed_ranges_DOWN_ATvsAP.pdf", width = 20, height = 25)
par(mfrow= c(7, 8))
for(i in region) {
plot(tasmediana[[i]], prmediana[[i]], pch = 21,
     bg = rgb(1,0,0,0), col = rgb(1,0,0,0), 
     # xlim = c(min(tasp10[[i]]), max(tasp90[[i]])), 
     # ylim = c(min(prp10[[i]]), max(prp90[[i]])), 
     xlim = c(0, 8), 
     ylim = c(-25, 5), 
     main = i,
     xlab = "AT(ºC)", ylab = "AP(%)")
segments(tasp10[[i]], prmediana[[i]], tasp90[[i]], prmediana[[i]], col = c(rep(rgb(0,0,0.6,0.4),4), rep(rgb(0.2,0.6,1,0.4),4), rep(rgb(1,0,0,0.4),4)), lwd = 4)
segments(tasmediana[[i]], prp10[[i]], tasmediana[[i]], prp90[[i]], col = c(rep(rgb(0,0,0.6,0.4),4), rep(rgb(0.2,0.6,1,0.4),4), rep(rgb(1,0,0,0.4),4)), lwd = 4)
points(tasmediana[[i]], prmediana[[i]], pch = 21, bg = c(rep(rgb(0,0,0.6),4), rep(rgb(0.2,0.6,1),4), rep(rgb(1,0,0),4)), xlim = c(0, 7))
}
dev.off()

