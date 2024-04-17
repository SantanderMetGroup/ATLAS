# computeDeltas.R
#
# Copyright (C) 2021 Santander Meteorology Group (http://meteo.unican.es)
#
# This work is licensed under a Creative Commons Attribution 4.0 International
# License (CC BY 4.0 - http://creativecommons.org/licenses/by/4.0)

#' @title Compute temperature and precipitation changes
#' @description Compute temperature and precipitation changes from data 
#'   files of this repository (datasets-aggregated-regionally).
#' @author M. Iturbide


computeDeltas <- function(project, 
                          var,
                          experiment, 
                          season, 
                          ref.period, 
                          periods = c("1.5", "2", "3", "4"), 
                          area = "land",
                          region = c("MED"),
                          cordex.domain = NULL){ 
  
  # root Url
  # https://stackoverflow.com/questions/25485216/how-to-get-list-files-from-a-github-repository-folder-using-r
  myurl <- "https://api.github.com/repos/SantanderMetGroup/ATLAS/git/trees/devel?recursive=1"
  
  ## for remote
  # req <- GET(myurl) %>% stop_for_status(req)
  # filelist <- unlist(lapply(content(req)$tree, "[", "path"), use.names = FALSE)
  # root <- "https://raw.githubusercontent.com/SantanderMetGroup/ATLAS/devel/"
  
  ## local option-----------
  root <- "../"
  filelist <- list.files(root, recursive = T)
  #-------------------------
  
  run <- TRUE
  ## data files Urls
  ls <- grep(paste0(project, "_", var,"_",area,"/"), filelist, value = TRUE, fixed = FALSE) %>% grep("\\.csv$", ., value = TRUE)
  if (project == "CORDEX") ls <- grep(paste0(project, ".*_", var,"_",area,"/"), filelist, value = TRUE, fixed = FALSE) %>% grep("\\.csv$", ., value = TRUE)
  allfiles <- paste0(root, ls)
  if (project == "CORDEX") {
    indf <- gsub(".*CORDEX-", "", lapply(strsplit(ls, split = "_"), "[", 1)) %>% as.factor()
    ls.aux <- split(ls, f = indf)
    allfiles.aux <- split(allfiles, f = indf)
    if (length(region) > 1) {
      warning("Multiple region option is not implemented for CORDEX yet. Firs value, i.e. ", region[1], "will be used")
      region <- region[1]
    }
    l.aux <- lapply(allfiles.aux, function(x) length(grep(region, suppressMessages(scan(x[1], skip = 15, nlines = 1, what = "raw")))) > 0)
    dom <- which(unlist(l.aux))
    dom <- if (!is.null(cordex.domain)) dom[cordex.domain]
    if (!is.null(dom)) {
      if (is.na(dom) | is.null(cordex.domain)) {
        dom <- 1
        warning("argument cordex.domain either is NULL or does not contain the requested region. The '", names(dom)[1], "' domain will be considered.")
      }
      ls <- ls.aux[[dom[1]]]
      allfiles <- allfiles.aux[[dom[1]]]
    } else {
      run <- FALSE
      warning("argument cordex.domain either is NULL or does not contain the requested region.")
    }
  }
  if (run) {
    exp <- experiment
    if (is.character(periods)) {
      ## define periods for WL
      wlls <- grep(paste0("CMIP5", "_Atlas_WarmingLevels"), filelist, value = TRUE, fixed = TRUE) %>% grep("\\.csv$", ., value = TRUE)
      if (project == "CMIP6") wlls <- grep(paste0(project, "_Atlas_WarmingLevels"), filelist, value = TRUE, fixed = TRUE) %>% grep("\\.csv$", ., value = TRUE)
      wlfiles <- paste0(root, wlls)
      aux <- lapply(periods, function(p) read.table(wlfiles, header = TRUE, sep = ",")[[paste0("X", p, "_", exp)]])
      modelruns <- as.character(read.table(wlfiles, header = TRUE, sep = ",")[,1])
      ind <- which(aux[[1]] != 9999)
      # "EC-EARTH_r3i1p1" is excluded because only run "EC-EARTH_r12i1p1" is considered for CMIP.
      if (project != "CORDEX") ind <- which(aux[[1]] != 9999 & modelruns != "EC-EARTH_r3i1p1")
      # "EC-EARTH_r3i1p1" is excluded because run "EC-EARTH_r12i1p1" is considered for CMIP.
      # "AWI-CM-1-1-MR_r1i1p1f1" is excluded for precipitation because there is no historical data.
      if (var == "pr" & project == "CMIP6") ind <- which(aux[[1]] != 9999 & modelruns != "EC-EARTH_r3i1p1" & modelruns != "AWI-CM-1-1-MR_r1i1p1f1")
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
    # region <- colnames(read.table(allfiles[1], header = TRUE, sep = ",", comment.char = "#"))[-1]
    aggrfun <- "mean"
    out <- lapply(1:length(modelruns), function(i) {
      modelfiles <- grep(modelruns[i], allfiles, value = TRUE) 
      if (length(modelfiles) > 0) {
        histf <- grep("historical", modelfiles, value = TRUE)
        if (length(histf) > 0) {
          l2 <- lapply(1:length(histf), function(h) {
            hist <-  read.table(histf[h], header = TRUE, sep = ",", comment.char = "#")
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
                rcp0 <- grep(gsub("historical", exp[j], histf[h]), modelfiles, value = TRUE) %>% read.table(header = TRUE, sep = ",", comment.char = "#")
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
                  message(modelruns[i], ".......", exp[j], "------filling reference period with rcp data")
                  rcphist <- rcp[which(rownames(rcp) == 2006) : which(rownames(rcp) == range(ref.period)[2]),,  drop = FALSE]
                  histexp <- apply(rbind(hist, rcphist), MARGIN = 2, FUN = mean, na.rm = TRUE)
                } else {
                  message(modelruns[i], ".......", exp[j], "------")
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
                    message(modelruns[i], ".......", exp[j], "------NO period")
                    a <- rep(NA, ncol(rcp))
                    names(a) <- colnames(rcp)
                    a
                  }
                })
              } else {
                message(modelruns[i], i, ".......", exp[j], "------NO DATA")
                delta <- rep(list(NULL), length(periods))
              }
              names(delta) <- names(periods)
              delta
            })
            names(l1) <- exp
            l1
            } else {
              NULL
            }
          })
          nn <- if (project != "CORDEX") {
            gsub("\\.\\*", "", modelruns[i])
          } else {
            paste0(modelruns[i], gsub(".*historical|.csv", "", histf))
          }
          names(l2) <- nn
          l2
        }
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
    if (project == "CORDEX") {
      return(data[[1]])
    } else {
      return(data)
    }
  }
}
