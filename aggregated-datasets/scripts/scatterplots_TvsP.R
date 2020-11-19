library(magrittr)
library(httr)

# list files in Url -----------------------------------------------------------------------------

# https://stackoverflow.com/questions/25485216/how-to-get-list-files-from-a-github-repository-folder-using-r
myurl <- "https://api.github.com/repos/SantanderMetGroup/ATLAS/git/trees/devel?recursive=1"
req <- GET(myurl) %>% stop_for_status(req)
filelist <- unlist(lapply(content(req)$tree, "[", "path"), use.names = FALSE)
root <- "https://raw.githubusercontent.com/SantanderMetGroup/ATLAS/devel/"


# select reference and target periods, scenarios, and the area ("land", "sea", "landsea"):-----------
season <- 1:12
area <- "land" #sea #landsea



##### function to get the data and compute deltas: -------------------------------

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

########## tas ##########------------------------------------
project <- "CMIP5"
ref.period <- ref.period <- 1850:1900
ls <- grep(paste0(project, "_tas_",area,"/"), filelist, value = TRUE, fixed = TRUE) %>% grep("\\.csv$", ., value = TRUE)
allfiles <- paste0(root, ls)
aux <- grep("historical", ls, value = TRUE)
modelruns <- gsub(paste0("reference_regions/regional_means/data/CMIP5_tas_",area,"/",project,"_|historical_|.csv"), ".*", aux)

wlls <- grep("CMIP5_Atlas_WarmingLevels", filelist, value = TRUE, fixed = TRUE) %>% grep("\\.csv$", ., value = TRUE)
wlfiles <- paste0(root, wlls)
aux1.5 <- read.table(wlfiles, header = TRUE, sep = ",")[["X1.5_rcp85"]]
aux2 <- read.table(wlfiles, header = TRUE, sep = ",")[["X2_rcp85"]]
aux3 <- read.table(wlfiles, header = TRUE, sep = ",")[["X3_rcp85"]]
aux4 <- read.table(wlfiles, header = TRUE, sep = ",")[["X4_rcp85"]]
modelruns <- as.character(read.table(wlfiles, header = TRUE, sep = ",")[,1])
# modelruns[modelruns == "HadGEM2-CC_r1i1p1"] <- "HadGEM2-ES_r1i1p1"
ind <- which(aux1.5 != 9999 & modelruns != "EC-EARTH_r3i1p1" & modelruns != "FGOALS-g2_r1i1p1")
modelruns <- modelruns[ind]
per1.5 <- cbind(aux1.5 - 9, aux1.5 + 10)[ind,]
per2 <- cbind(aux2 - 9, aux2 + 10)[ind,]
per3 <- cbind(aux3 - 9, aux3 + 10)[ind,]
per4 <- cbind(aux4 - 9, aux4 + 10)[ind,]


exp <- "rcp85"

periods <- list( "near" = cbind(rep(2021, length(modelruns)),rep(2040, length(modelruns))), 
                 "mid" = cbind(rep(2041, length(modelruns)),rep(2060, length(modelruns))), 
                 "far" = cbind(rep(2081, length(modelruns)),rep(2100, length(modelruns))))

tas.cmip5 <- computeDeltas(allfiles, modelruns, ref.period, periods = list("+1.5º" = per1.5, "+2º" = per2, "+3º" = per3, "+4º" = per4), exp, season)

tasmediana.cmip5 <- lapply(tas.cmip5, apply, 2, median, na.rm = T)
tasp90.cmip5 <- lapply(tas.cmip5, apply, 2, quantile, 0.9, na.rm = T)
tasp10.cmip5 <- lapply(tas.cmip5, apply, 2, quantile, 0.1, na.rm = T)




######## pr ###########------------------------------------
project <- "CMIP5"
ref.period <- 1850:1900
ls <- grep(paste0(project, "_pr_",area,"/"), filelist, value = TRUE, fixed = TRUE) %>% grep("\\.csv$", ., value = TRUE)
allfiles <- paste0(root, ls)
aux <- grep("historical", ls, value = TRUE)
modelruns <- gsub(paste0("reference_regions/regional_means/data/",project,"_pr_",area,"/",project,"_|historical_|.csv"), ".*", aux)

wlls <- grep("CMIP5_Atlas_WarmingLevels", filelist, value = TRUE, fixed = TRUE) %>% grep("\\.csv$", ., value = TRUE)
wlfiles <- paste0(root, wlls)
aux1.5 <- read.table(wlfiles, header = TRUE, sep = ",")[["X1.5_rcp85"]]
aux2 <- read.table(wlfiles, header = TRUE, sep = ",")[["X2_rcp85"]]
aux3 <- read.table(wlfiles, header = TRUE, sep = ",")[["X3_rcp85"]]
aux4 <- read.table(wlfiles, header = TRUE, sep = ",")[["X4_rcp85"]]
modelruns <- as.character(read.table(wlfiles, header = TRUE, sep = ",")[,1])
# modelruns[modelruns == "HadGEM2-CC_r1i1p1"] <- "HadGEM2-ES_r1i1p1"
ind <- which(aux1.5 != 9999 & modelruns != "EC-EARTH_r3i1p1" & modelruns != "FGOALS-g2_r1i1p1")
modelruns <- modelruns[ind]
per1.5 <- cbind(aux1.5 - 9, aux1.5 + 10)[ind,]
per2 <- cbind(aux2 - 9, aux2 + 10)[ind,]
per3 <- cbind(aux3 - 9, aux3 + 10)[ind,]
per4 <- cbind(aux4 - 9, aux4 + 10)[ind,]


exp <- "rcp85"

periods <- list( "near" = cbind(rep(2021, length(modelruns)),rep(2040, length(modelruns))), 
                 "mid"= cbind(rep(2041, length(modelruns)),rep(2060, length(modelruns))), 
                 "far" = cbind(rep(2081, length(modelruns)),rep(2100, length(modelruns))))

pr.cmip5 <- computeDeltas(allfiles, modelruns, ref.period, periods = list("+1.5º" = per1.5, "+2º" = per2, "+3º" = per3, "+4º" = per4), exp, season)

prmediana.cmip5 <- lapply(pr.cmip5, apply, 2, median, na.rm = T)
prp90.cmip5 <- lapply(pr.cmip5, apply, 2, quantile, 0.9, na.rm = T)
prp10.cmip5 <- lapply(pr.cmip5, apply, 2, quantile, 0.1, na.rm = T)

########## tas ##########------------------------------------
project <- "CMIP6"
ref.period <- ref.period <- 1850:1900
ls <- grep(paste0(project, "_tas_",area,"/"), filelist, value = TRUE, fixed = TRUE) %>% grep("\\.csv$", ., value = TRUE)
allfiles <- paste0(root, ls)
aux <- grep("historical", ls, value = TRUE)
modelruns <- gsub(paste0("reference_regions/regional_means/data/CMIP6_tas_",area,"/",project,"_|historical_|.csv"), ".*", aux)

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
per1.5 <- cbind(aux1.5 - 9, aux1.5 + 10)[ind,]
per2 <- cbind(aux2 - 9, aux2 + 10)[ind,]
per3 <- cbind(aux3 - 9, aux3 + 10)[ind,]
per4 <- cbind(aux4 - 9, aux4 + 10)[ind,]

modelruns <- gsub("_", "_.*", modelruns)

exp <- "ssp585"

periods <- list( "near" = cbind(rep(2021, length(modelruns)),rep(2040, length(modelruns))), 
                 "mid" = cbind(rep(2041, length(modelruns)),rep(2060, length(modelruns))), 
                 "far" = cbind(rep(2081, length(modelruns)),rep(2100, length(modelruns))))

tas.cmip6 <- computeDeltas(allfiles, modelruns, ref.period, periods = list("+1.5º" = per1.5, "+2º" = per2, "+3º" = per3, "+4º" = per4), exp, season)

tasmediana.cmip6 <- lapply(tas.cmip6, apply, 2, median, na.rm = T)
tasp90.cmip6 <- lapply(tas.cmip6, apply, 2, quantile, 0.9, na.rm = T)
tasp10.cmip6 <- lapply(tas.cmip6, apply, 2, quantile, 0.1, na.rm = T)




######## pr ###########------------------------------------
project <- "CMIP6"
ref.period <- 1850:1900
ls <- grep(paste0(project, "_pr_",area,"/"), filelist, value = TRUE, fixed = TRUE) %>% grep("\\.csv$", ., value = TRUE)
allfiles <- paste0(root, ls)
aux <- grep("historical", ls, value = TRUE)
modelruns <- gsub(paste0("reference_regions/regional_means/data/",project,"_pr_",area,"/",project,"_|historical_|.csv"), ".*", aux)

wlls <- grep("CMIP6_Atlas_WarmingLevels", filelist, value = TRUE, fixed = TRUE) %>% grep("\\.csv$", ., value = TRUE)
wlfiles <- paste0(root, wlls)
aux1.5 <- read.table(wlfiles, header = TRUE, sep = ",")[["X1.5_ssp585"]]
aux2 <- read.table(wlfiles, header = TRUE, sep = ",")[["X2_ssp585"]]
aux3 <- read.table(wlfiles, header = TRUE, sep = ",")[["X3_ssp585"]]
aux4 <- read.table(wlfiles, header = TRUE, sep = ",")[["X4_ssp585"]]
modelruns <- as.character(read.table(wlfiles, header = TRUE, sep = ",")[,1])
# modelruns[modelruns == "HadGEM2-CC_r1i1p1"] <- "HadGEM2-ES_r1i1p1"
ind <- which(aux1.5 != 9999 & modelruns != "EC-EARTH_r3i1p1" & modelruns != "AWI-CM-1-1-MR_r1i1p1f1")
modelruns <- modelruns[ind]
per1.5 <- cbind(aux1.5 - 9, aux1.5 + 10)[ind,]
per2 <- cbind(aux2 - 9, aux2 + 10)[ind,]
per3 <- cbind(aux3 - 9, aux3 + 10)[ind,]
per4 <- cbind(aux4 - 9, aux4 + 10)[ind,]

modelruns <- gsub("_", "_.*", modelruns)

exp <- "ssp585"

periods <- list( "near" = cbind(rep(2021, length(modelruns)),rep(2040, length(modelruns))), 
                 "mid"= cbind(rep(2041, length(modelruns)),rep(2060, length(modelruns))), 
                 "far" = cbind(rep(2081, length(modelruns)),rep(2100, length(modelruns))))

pr.cmip6 <- computeDeltas(allfiles, modelruns, ref.period, periods = list("+1.5º" = per1.5, "+2º" = per2, "+3º" = per3, "+4º" = per4), exp, season)

prmediana.cmip6 <- lapply(pr.cmip6, apply, 2, median, na.rm = T)
prp90.cmip6 <- lapply(pr.cmip6, apply, 2, quantile, 0.9, na.rm = T)
prp10.cmip6 <- lapply(pr.cmip6, apply, 2, quantile, 0.1, na.rm = T)


########## plot #######------------------------------------------------------------------------
if (area == "land") region.subset <- names(tas.cmip6)[c(1:46, 59)]
if (area == "sea") region.subset <-  names(tas.cmip6)[47:59]

#select the output figure file name
outfilename <- paste0("/oceano/gmeteo/WORK/PROYECTOS/2018_IPCC/figs/scatterplots/FGD_", project, "_scatterplots_", area, "_", paste(season, collapse = "-"), "_ATvsAP.pdf")

#plot and write figure
col1 <- c(rgb(0.55,0,0.55,0.5), rgb(1, 0.73, 0.06, 0.5),rgb(0, 0, 0, 0.5), rgb(0.5, 0.3, 0.16, 0.5))
col2 <- c(rgb(0.55,0,0.55), rgb(1, 0.73, 0.06), rgb(0, 0, 0), rgb(0.5, 0.3, 0.16))

pdf(outfilename, width = 20, height = 25)
par(mfrow= c(7, 8))
for(i in region.subset) {
  plot(tasmediana.cmip6[[i]], prmediana.cmip6[[i]], pch = 21,
       bg = rgb(1,0,0,0), col = rgb(1,0,0,0), 
       xlim = c(min(tasp10.cmip6[[i]]), max(tasp90.cmip6[[i]])),
       ylim = c(min(prp10.cmip6[[i]]), max(prp90.cmip6[[i]])),
       # xlim = c(0, 8),
       # ylim = c(-10, 50),
       main = i,
       xlab = "AT(ºC)", ylab = "AP(%)")
  segments(tasp10.cmip6[[i]], prmediana.cmip6[[i]], tasp90.cmip6[[i]], prmediana.cmip6[[i]], col = col2, lwd = 4)
  segments(tasmediana.cmip6[[i]], prp10.cmip6[[i]], tasmediana.cmip6[[i]], prp90.cmip6[[i]], col = col2, lwd = 4)
  segments(min(tasp10.cmip6[[i]]), 0, max(tasp90.cmip6[[i]]), 0, lty = 3)
  # segments(tasp10.cmip5[[i]], prmediana.cmip5[[i]], tasp90.cmip5[[i]], prmediana.cmip5[[i]], col = col1, lwd = 4)
  # segments(tasmediana.cmip5[[i]], prp10.cmip5[[i]], tasmediana.cmip5[[i]], prp90.cmip5[[i]], col = col1, lwd = 4)

  points(tasmediana.cmip6[[i]], prmediana.cmip6[[i]], pch = 21, bg = col2, xlim = c(0, 7))
  # points(tasmediana.cmip5[[i]], prmediana.cmip5[[i]], pch = 21, bg = col1, xlim = c(0, 7))
}
dev.off()

save(list=c("tas", "pr"), file = paste0(project, "_scatterplots_", area, "_", paste(season, collapse = "-"), "_ATvsAP.rda"))




