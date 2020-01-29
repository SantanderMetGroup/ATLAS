library(magrittr)
library(httr)

# list files in Url -----------------------------------------------------------------------------

# https://stackoverflow.com/questions/25485216/how-to-get-list-files-from-a-github-repository-folder-using-r
myurl <- "https://api.github.com/repos/SantanderMetGroup/ATLAS/git/trees/devel?recursive=1"
req <- GET(myurl) %>% stop_for_status(req)
filelist <- unlist(lapply(content(req)$tree, "[", "path"), use.names = FALSE)
root <- "https://raw.githubusercontent.com/SantanderMetGroup/ATLAS/devel/"


# select reference and target periods, scenarios, and the area ("land", "sea", "landsea"):-----------
ref.period <- 1995:2014
season <- c(12, 1, 2)
periods <- list(2021:2040, 2041:2060, 2061:2080, 2081:2100)
exp <- c("rcp26", "rcp45", "rcp85") #c("ssp126", "ssp245", "ssp585")
area <- "land" #sea #landsea
project <- "CMIP5" #"CMIP6Amon"



##### function to get the data and compute deltas: -------------------------------

computeDeltas <- function(allfiles, modelruns, exp, ref.period, periods, season){ 
  var <- scan(allfiles[1], "character", n = 7)[4]
  region <- colnames(read.table(allfiles[1], header = TRUE, sep = ",", skip = 7))[-1]
  aggrfun <- "mean"
  if (var == "pr") aggrfun <- "sum"
  out <- lapply(modelruns, function(i) {
    modelfiles <- grep(i, allfiles, value = TRUE) 
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
          endyear <- range(k)[2]
          while (length(which(yearsrcp == endyear)) == 0) {
            endyear <- endyear - 1
          }
          rcpk <- rcp[which(yearsrcp == range(k)[1]) : which(yearsrcp == endyear),]
          if (var == "tas") {
            apply(rcpk, MARGIN = 2, FUN = mean, na.rm = TRUE) - histexp
          } else if (var == "pr") {
            (apply(rcpk, MARGIN = 2, FUN = mean, na.rm = TRUE) - histexp) / histexp * 100
          }
        })
      } else {
        message("i =", i, ".......", exp[j], "------NO DATA")
        delta <- rep(list(NULL), 4)
      }
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
  return(data)
}


########## tas ##########------------------------------------
# list the subset of target files
ls <- grep(paste0(project, "_tas_", area, "/"), filelist, value = TRUE, fixed = TRUE) %>% grep("\\.csv$", ., value = TRUE)
allfiles <- paste0(root, ls)
# extract model names 
aux <- grep("historical", ls, value = TRUE)
modelruns <- gsub(paste0("reference_regions/regional_means/data/", project, "_tas_", area, "/",project, "_|_historical.csv"), "", aux)

# compute (apply computeDeltas)
tas <- computeDeltas(allfiles, modelruns, exp, ref.period, periods, season)
#str(tas)

# calculate percentiles
tasmediana <- lapply(tas, apply, 2, median, na.rm = T)
tasp90 <- lapply(tas, apply, 2, quantile, 0.9, na.rm = T)
tasp10 <- lapply(tas, apply, 2, quantile, 0.1, na.rm = T)



######## pr ###########------------------------------------
ls <- grep(paste0(project, "_pr_", area, "/"), filelist, value = TRUE, fixed = TRUE) %>% grep("\\.csv$", ., value = TRUE)
allfiles <- paste0(root, ls)
aux <- grep("historical", ls, value = TRUE)
modelruns <- gsub(paste0("reference_regions/regional_means/data/", project, "_pr_", area, "/",project, "_|_historical.csv"), "", aux)

pr <- computeDeltas(allfiles, modelruns, exp, ref.period, periods, season)

prmediana <- lapply(pr, apply, 2, median, na.rm = T)
prp90 <- lapply(pr, apply, 2, quantile, 0.9, na.rm = T)
prp10 <- lapply(pr, apply, 2, quantile, 0.1, na.rm = T)


########## plot #######------------------------------------------------------------------------
if (area == "land") region.subset <- names(tas)[c(1:44, 56)]
if(area == "sea") region.subset <-  names(tas)[44:56]

#select the output figure file name
outfilename <- paste0(project, "_scatterplots_", area, "_", paste(season, collapse = "-"), "_ATvsAP.pdf")

#plot and write figure
pdf(outfilename, width = 20, height = 25)
par(mfrow= c(7, 8))
for(i in region.subset) {
  plot(tasmediana[[i]], prmediana[[i]], pch = 21,
       bg = rgb(1,0,0,0), col = rgb(1,0,0,0), 
       xlim = c(min(tasp10[[i]]), max(tasp90[[i]])),
       ylim = c(min(prp10[[i]]), max(prp90[[i]])),
       # xlim = c(0, 8),
       # ylim = c(-10, 50),
       main = i,
       xlab = "AT(ºC)", ylab = "AP(%)")
  segments(tasp10[[i]], prmediana[[i]], tasp90[[i]], prmediana[[i]], col = c(rep(rgb(0,0,0.6,0.4),4), rep(rgb(0.2,0.6,1,0.4),4), rep(rgb(1,0,0,0.4),4)), lwd = 4)
  segments(tasmediana[[i]], prp10[[i]], tasmediana[[i]], prp90[[i]], col = c(rep(rgb(0,0,0.6,0.4),4), rep(rgb(0.2,0.6,1,0.4),4), rep(rgb(1,0,0,0.4),4)), lwd = 4)
  points(tasmediana[[i]], prmediana[[i]], pch = 21, bg = c(rep(rgb(0,0,0.6),4), rep(rgb(0.2,0.6,1),4), rep(rgb(1,0,0),4)), xlim = c(0, 7))
}
dev.off()

save(list=c("tas", "pr"), file = paste0(project, "_scatterplots_", area, "_", paste(season, collapse = "-"), "_ATvsAP.rda"))




