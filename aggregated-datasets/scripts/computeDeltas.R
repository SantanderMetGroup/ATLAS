#     computeDeltas.R Compute temperature and precipitation changes from data files 
#      of this repository (aggregated-datasets).
#
#     Copyright (C) 2017 Santander Meteorology Group (http://www.meteo.unican.es)
#
#     This program is free software: you can redistribute it and/or modify
#     it under the terms of the GNU General Public License as published by
#     the Free Software Foundation, either version 3 of the License, or
#     (at your option) any later version.
# 
#     This program is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#     GNU General Public License for more details.
# 
#     You should have received a copy of the GNU General Public License
#     along with this program.  If not, see <http://www.gnu.org/licenses/>.

#' @title Compute temperature and precipitation changes from data files of this repository (aggregated-datasets).
#' @description Function to Compute CMIP5, CMIP6 and CORDEX regional temperature and 
#' precipitation changes. This function can be used to produce summary climate change information 
#' (see scatterplots_TvsP.R and boxplots_TandP.R).
#' 
#' @param n.chunks number of latitude chunks over which iterate
#' @param C4R.FUN.args list of arguments being the name of the C4R function (character)
#' the first. The rest of the arguments are those passed to the selected C4R function. 
#' This list is passed to function \link{\code{do.call}} internally. For the parameters 
#' (of a particular C4R function) where data (grids) need to be provided, here, a list of 2 
#' arguments are passed (instead of a grid): \code{list(dataset = "", var = "")}.
#' @param loadGridData.args list of collocation arguments passed to function loadGridData.
#' @param output.path Optional. Path where the results of each iteration will be saved (*.rda). 
#' Useful when the amount of data after the C4R function application is large, i.e. similar
#' to the pre-processed data (e.g. when the \link{\code{biasCorrection}} function is applied.)
#' @details Note that the appropriate libraries need to be loaded before applying this function. Packages
#' \code{loadeR} and \code{transformeR} are always needed. Depending on the C4R function that 
#' is applied the will also be needed to load the corresponding package/s.
#' etc.)
#' @return If \code{output.path} is NULL a grid containing all latitudes is returned. If \code{output.path}
#' is provided *.rda objects for each latitude chunk are saved in the specified path.
#' @family climate4R
#' 
#'
#' @author M. Iturbide
#' @export

computeDeltas <- function(project, 
                          var,
                          experiment, 
                          season, 
                          ref.period, 
                          periods = c("1.5", "2", "3", "4"), 
                          area = "land",
                          region = c("MED")){ 
  
  # root Url
  # https://stackoverflow.com/questions/25485216/how-to-get-list-files-from-a-github-repository-folder-using-r
  myurl <- "https://api.github.com/repos/SantanderMetGroup/ATLAS/git/trees/devel?recursive=1"
  req <- GET(myurl) %>% stop_for_status(req)
  filelist <- unlist(lapply(content(req)$tree, "[", "path"), use.names = FALSE)
  root <- "https://raw.githubusercontent.com/SantanderMetGroup/ATLAS/devel/"
  
  ## local option-----------
  # root <- "/media/maialen/work/WORK/GIT/ATLAS/"
  # filelist <- list.files(root, recursive = T)
  #-------------------------
  
  
  ## data files Urls
  ls <- grep(paste0(project, "_", var,"_",area,"/"), filelist, value = TRUE, fixed = FALSE) %>% grep("\\.csv$", ., value = TRUE)
  if (project == "CORDEX") ls <- grep(paste0(project, ".*_", var,"_",area,"/"), filelist, value = TRUE, fixed = FALSE) %>% grep("\\.csv$", ., value = TRUE)
  allfiles <- paste0(root, ls)
  if (project == "CORDEX") {
    indf <- gsub(".*CORDEX-", "", lapply(strsplit(ls, split = "_"), "[", 1)) %>% as.factor()
    ls.aux <- split(ls, f = indf)
    allfiles.aux <- split(allfiles, f = indf)
    l.aux <- lapply(allfiles.aux, function(x) length(grep(region, scan(x[1], skip = 7, nlines = 1, what = "raw"))) > 0)
    dom <- which(unlist(l.aux))
    ls <- ls.aux[[dom[1]]]
    allfiles <- allfiles.aux[[dom]]
  }
  exp <- experiment
  if (is.character(periods)) {
    ## define periods for WL
    wlls <- grep(paste0("CMIP5", "_Atlas_WarmingLevels"), filelist, value = TRUE, fixed = TRUE) %>% grep("\\.csv$", ., value = TRUE)
    if (project == "CMIP6") wlls <- grep(paste0(project, "_Atlas_WarmingLevels"), filelist, value = TRUE, fixed = TRUE) %>% grep("\\.csv$", ., value = TRUE)
    wlfiles <- paste0(root, wlls)
    aux <- lapply(periods, function(p) read.table(wlfiles, header = TRUE, sep = ",")[[paste0("X", p, "_", exp)]])
    modelruns <- as.character(read.table(wlfiles, header = TRUE, sep = ",")[,1])
    ind <- which(aux[[1]] != 9999 & modelruns != "EC-EARTH_r3i1p1")
    if (var == "pr" & project == "CMIP5") ind <- which(aux[[1]] != 9999 & modelruns != "EC-EARTH_r3i1p1" & modelruns != "GFDL-CM3_r1i1p1" & modelruns != "GFDL-ESM2M_r1i1p1" & modelruns != "HadGEM2-CC_r1i1p1" & modelruns != "BNU-ESM_r1i1p1")
    if (var == "pr" & project == "CMIP6") ind <- which(aux[[1]] != 9999 & modelruns != "EC-EARTH_r3i1p1" & modelruns != "AWI-CM-1-1-MR_r1i1p1f1"  & modelruns != "FGOALS-g3_r1i1p1f1")
    modelruns <- modelruns[ind]
    p <- paste0("+", periods, "º")
    periods <- lapply(aux, function(p) cbind(p - 9, p + 10)[ind,])
    names(periods) <- p
  } else {
    aux <- grep("historical", ls, value = TRUE)
    modelruns <- lapply(strsplit(aux, "/"), function(x) x[length(x)])
    modelruns <- if (project != "CORDEX") {
      gsub(paste0(project, "_|_historical|.csv"), "", modelruns)
    } else {
      unique(gsub(paste0(project, "_|_historical.*"), "", modelruns))
    }
    p <- lapply(periods, paste, collapse = "_")
    periods <- lapply(periods, function(p) cbind(rep(p[1], length(modelruns)), rep(p[2], length(modelruns)))) 
    names(periods) <- p
  }
  if (project == "CMIP6") modelruns <- gsub("_", "_.*", modelruns)
  
  if (!is.list(periods)) stop("please provide the correct object in periods.")
  # region <- colnames(read.table(allfiles[1], header = TRUE, sep = ",", skip = 7))[-1]
  aggrfun <- "mean"
  if (var == "pr") aggrfun <- "sum"
  out <- lapply(1:length(modelruns), function(i) {
    modelfiles <- grep(modelruns[i], allfiles, value = TRUE) 
    print(i)
    if (length(modelfiles) > 0) {
      histf <- grep("historical", modelfiles, value = TRUE)
      l2 <- lapply(1:length(histf), function(h) {
        hist <-  read.table(histf[h], header = TRUE, sep = ",", skip = 7)
        hist <- hist[, c("date", region), drop = FALSE]
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
        hist <- lapply(split(hist[,-1, drop = FALSE], f = yrs), function(x) apply(x, MARGIN = 2, FUN = aggrfun, na.rm = TRUE))
        hist <- do.call("rbind", hist)
        rownames(hist) <- yearshist[1:nrow(hist)]
        colnames(hist) <- region
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
        hist <- hist[start:end,, drop = FALSE]
        l1 <- lapply(1:length(exp), FUN = function(j) {
          rcp <- tryCatch({
            rcp0 <- grep(gsub("historical", exp[j], histf[h]), modelfiles, value = TRUE) %>% read.table(header = TRUE, sep = ",", skip = 7)
            rcp0[, c("date", region), drop = FALSE]
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
            rcp <- lapply(split(rcp[,-1, drop = FALSE], f = yrs), function(x) apply(x, MARGIN = 2, FUN = aggrfun, na.rm = TRUE))
          }, error = function(err) return(NULL))
          if (!is.null(rcp)) {
            rcp <- do.call("rbind", rcp)
            rownames(rcp) <- yearsrcp[1:nrow(rcp)]
            if (fill) {
              message("i =", i, ".......", exp[j], "------filling reference period with rcp data")
              rcphist <- rcp[which(rownames(rcp) == 2006) : which(rownames(rcp) == range(ref.period)[2]),,  drop = FALSE]
              histexp <- apply(rbind(hist, rcphist), MARGIN = 2, FUN = mean, na.rm = TRUE)
            } else {
              message("i =", i, ".......", exp[j], "------")
              histexp <- apply(hist, MARGIN = 2, FUN = mean, na.rm = TRUE)
            }
            delta <- lapply(periods, function(k){
              endyear <- k[i,][2]
              startyear <- k[i,][1]
              if (!is.na(endyear) & !is.na(startyear)) {
                while (length(which(rownames(rcp) == endyear)) == 0) {
                  endyear <- endyear - 1
                }
                while (length(which(rownames(rcp) == startyear)) == 0) {
                  startyear <- startyear + 1
                }
                
                rcpk <- rcp[which(rownames(rcp) == startyear) : which(rownames(rcp) == endyear),, drop = FALSE]
                
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
      nn <- if (project != "CORDEX") {
        gsub("\\.\\*", "", modelruns[i])
      } else {
        paste0(modelruns[i], gsub(".*historical|.csv", "", histf))
      }
      names(l2) <- nn
      l2
    }
  })
  out <- unlist(out, recursive = F)
  
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
