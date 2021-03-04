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

computeOffset <- function(project, 
                          var,
                          experiment,
                          season, 
                          ref.period, 
                          area = "land",
                          region){ 
  
  # root Url
  # https://stackoverflow.com/questions/25485216/how-to-get-list-files-from-a-github-repository-folder-using-r
  myurl <- "https://api.github.com/repos/SantanderMetGroup/ATLAS/git/trees/devel?recursive=1"
  
  ## for remote
  # req <- GET(myurl) %>% stop_for_status(req)
  # filelist <- unlist(lapply(content(req)$tree, "[", "path"), use.names = FALSE)
  # root <- "https://raw.githubusercontent.com/SantanderMetGroup/ATLAS/devel/"
  
  ## local option-----------
  root <- "/media/maialen/work/WORK/GIT/ATLAS/"
  filelist <- list.files(root, recursive = T)
  #-------------------------
  
  run <- TRUE
  ## data files Urls
  ls <- grep(paste0(project, "_", var,"_",area,"/"), filelist, value = TRUE, fixed = FALSE) %>% grep("\\.csv$", ., value = TRUE)
  allfiles <- paste0(root, ls)
  if (run) {
    exp <- experiment
    
    aux <- grep("historical", ls, value = TRUE)
    modelruns <- lapply(strsplit(aux, "/"), function(x) x[length(x)])
    modelruns <- gsub(paste0(project, "_|_historical|.csv"), "", modelruns)
    
  if (project == "CMIP6") modelruns <- gsub("_", "_.*", modelruns) 
    
    aggrfun <- "mean"
    if (var == "pr") aggrfun <- "sum"
    out <- lapply(1:length(modelruns), function(i) {
      modelfiles <- grep(modelruns[i], allfiles, value = TRUE) 
      if (length(modelfiles) > 0) {
        histf <- grep("historical", modelfiles, value = TRUE)
        if (length(histf) > 0) {
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
            start.pre <- which(rownames(hist) == range(1850:1900)[1])
            end.pre <- which(rownames(hist) == range(1850:1900)[2])
            if(length(start.pre) != 0 & length(end.pre) != 0) {
              hist.pre <- mean(hist[start.pre:end.pre, ], na.rm = T)
              start <- which(rownames(hist) == range(ref.period)[1])
              end <- which(rownames(hist) == range(ref.period)[2])
              fill <- FALSE
              if (length(end) == 0 & length(start) > 0) {
                fill <- TRUE
                end <- which(rownames(hist) == 2005)
              }
              if (length(start) == 0 & length(end) > 0) {
                start <-  1
              }
              if (length(start) == 0 & length(end) == 0) run <- FALSE
              if (run) {
                
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
                    delta <- hist.pre - histexp
                  } else {
                    message("i =", i, ".......", exp[j], "------NO DATA")
                    delta <- NA
                  }
                })
                names(l1) <- exp
                l1
              } else {
                NULL
              }
            } else {
              NULL
            }
          })
          nn <- gsub("\\.\\*", "", modelruns[i])
          names(l2) <- nn
          l2
        }
      }
    })
    out <- unlist(out, recursive = T)
    data <- median(out, na.rm = T)
    names(data) <- region
    return(data)
  }
}
