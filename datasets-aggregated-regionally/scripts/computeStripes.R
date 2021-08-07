# computeStripes.R
#
# Copyright (C) 2021 Santander Meteorology Group (http://meteo.unican.es)
#
# This work is licensed under a Creative Commons Attribution 4.0 International
# License (CC BY 4.0 - http://creativecommons.org/licenses/by/4.0)

#' @title Compute temperature and precipitation stripes plots
#' @description Compute temperature and precipitation stripes plots from 
#' files of this repository (datasets-aggregated-regionally). Use argument
#' ... for additional graphical arguments of the levelplot function 
#' (library lattice).
#' @param project Choices are: CMIP6, CMIP5 and CORDEX.
#' @param var Choices are: tas and pr.
#' @param experiment Depending of the chosen projects, experiment choices are: 
#' rcp26, rcp45, rcp85, "ssp126", "ssp245", "ssp370", "ssp585".
#' @param season Numeric indicating seasons (e.g. 1:12 is for annual data). Use c(12, 1, 2) 
#' for winter.
#' @param area Choices are "land", "sea", and "landsea".
#' @param region Choices are any of the reference regions (e.g. "MED") or "World" or 
#' "full_domain" if project = "CORDEX".
#' @param cordex.domain = Used if project = "CORDEX". If the selected region does not
#' intersect the cordex domain other domain will be used. Choices are "AFR", "ANT", "ARC",
#' "AUS", "CAM", "EAS", "EUR", "NAM", "SAM", "SEA", "WAS".
#' @param brewer.pal.name Name of the brewer palette (e.g. "RdBu").
#' @param rev.colors Logical indicating if the color palette should be reversed.
#' @param ... Additional and optional graphical parameters of the levelplot function.
#' @author M. Iturbide
#' @example 
#' computeStripes(project = "CMIP6", 
#'                var = "tas",
#'                experiment = "ssp585",
#'                season = 1:12,
#'                area = "land",
#'                region = c("MED"),
#'                cordex.domain = "EUR",
#'                brewer.pal.name = "RdBu",
#'                rev.colors = TRUE)

computeStripes <- function(project, 
                           var,
                           experiment, 
                           season, 
                           area = "land",
                           region = "MED",
                           cordex.domain = NULL,
                           brewer.pal.name = "RdBu",
                           rev.colors = FALSE,
                           ...){ 
  lp <- list(...)
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
  years <- c(1950, 2100)
  if (project == "CORDEX")   years <- c(1970, 2100)

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
    dom <- if (!is.null(cordex.domain) & cordex.domain %in% names(dom)){
      dom[cordex.domain]
    } else {
      warning("argument cordex.domain either is NULL or does not contain the requested region. The '", names(dom)[1], "' domain will be considered.")
      dom[1]
    }
    if (!is.null(dom) & !is.na(dom)) {
      ls <- ls.aux[[dom[1]]]
      allfiles <- allfiles.aux[[dom[1]]]
    } else {
      warning("argument cordex.domain either is NULL or does not contain the requested region.")
      run <- FALSE
    }
  }
  if (run) {
    exp <- experiment
    aux <- grep("historical", ls, value = TRUE)
    modelruns <- lapply(strsplit(aux, "/"), function(x) x[length(x)])
    modelruns <- if (project != "CORDEX") {
      gsub(paste0(project, "_|_historical|.csv"), "", modelruns)
    } else {
      unique(gsub(paste0(project, "_|_historical.*"), "", modelruns))
    }
    if (project == "CMIP6") modelruns <- gsub("_", "_.*", modelruns)
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
            hist <- lapply(split(hist[,-1, drop = FALSE], f = yrs), function(x) apply(x, MARGIN = 2, FUN = "mean", na.rm = TRUE))
            hist <- do.call("rbind", hist) %>% data.frame
            indhist <- which(yearshist == years[1])
            if (length(indhist) == 0) {
              gap <- min(yearshist) - years[1]
              hna <- data.frame(rep(NA, gap))
              colnames(hna) <- colnames(hist)
              hist <- rbind(hna, hist)
              yearshist <- years[1]:max(yearshist)
            }
            # colnames(hist) <- gsub("\\.|\\*", "", modelruns[i])
            rcp <- tryCatch({
              rcp0 <- grep(gsub("historical", exp, histf[h]), modelfiles, value = TRUE) %>% read.table(header = TRUE, sep = ",", comment.char = "#")
              rcp0[, c("date", region), drop = FALSE]
            }, error = function(err) return(NULL))
            if (!is.null(rcp)) {
              seas <- rcp %>% subset(select = "date", drop = TRUE) %>% gsub(".*-", "", .) %>% as.integer()
              z <- sort(unlist(lapply(season, function(s) which(seas == s))))
              rcp <- rcp[z, ]
              yearsrcp <-  unique(rcp %>% subset(select = "date", drop = TRUE) %>% gsub("-.*", "", .) %>% as.integer())
              firstind <- which(seas[z] == season[1])[1]
              if (firstind > 1) {
                yrs <- c(rep(1, firstind - 1), rep(2:ceiling(nrow(rcp)/length(season)+1), each = length(season), length.out = nrow(rcp)-(firstind-1)))
                yearsrcp <- c(yearsrcp, yearsrcp[length(yearsrcp)] + 1)
              } else {
                yrs <-  rcp %>% subset(select = "date", drop = TRUE) %>% gsub("-.*", "", .) %>% as.integer()
                yearsrcp <-  unique(yrs)
              }
              rcp <- lapply(split(rcp[,-1, drop = FALSE], f = yrs), function(x) apply(x, MARGIN = 2, FUN = "mean", na.rm = TRUE))
              rcp <- do.call("rbind", rcp) %>% data.frame
              indrcp <- which(yearsrcp == max(yearsrcp)) + years[2] - max(yearsrcp)
              rcp <- rcp[1:indrcp, , drop = FALSE]
              yearintsec <- match(yearsrcp, yearshist) %>% na.omit
              if (length(yearintsec) > 0) hist <- hist[-yearintsec, , drop = FALSE]
              hist <- hist[which(yearshist == years[1]) : nrow(hist), , drop = FALSE]
              histrcp <- rbind(hist, rcp)
            } else {
              d <- data.frame(rep(NA, 2100 - max(yearshist)))
              rownames(d) <- max(yearshist + 1) : 2100
              colnames(d) <- colnames(hist)
              histrcp <- rbind(hist[which(yearshist == years[1]) : nrow(hist), , drop = FALSE], d)
            } 
            colnames(histrcp) <- NULL
            histrcp
          })
          nn <- if (project != "CORDEX") {
            gsub("\\.\\*", "", modelruns[i])
          } else {
            paste0(modelruns[i], gsub(".*historical|.csv", "", histf))
          }
          # message(paste0(nn, ", "), " processed...")
          names(l2) <- nn
          l2
        }
      }
    })
    out2 <- unlist(out, recursive = FALSE) %>% data.frame %>% as.matrix
    # PLOT
    col <- brewer.pal(n = 9, name = brewer.pal.name)
    if (rev.colors) col <- rev(col)
    seasonname <- paste(substring(month.abb, 1, 1)[season], collapse = "")
    if (seasonname == "JFMAMJJASOND") seasonname <- "Annual"
    lp[["x"]] <- out2
    lp[["col.regions"]] <- colorRampPalette(col)
    if (is.null(lp[["xlab"]])) lp[["xlab"]] <- ""
    if (is.null(lp[["ylab"]])) lp[["ylab"]] <- ""
    if (is.null(lp[["scales"]])) lp[["scales"]] <- list(x = list(at = seq(1, nrow(out2), 5), rot = 45, cex = 0.7), y = list(cex = 0.7))
    #if (is.null(lp[["scale"]])) lp[["scale"]] <- list(alternating = 1)
    if (is.null(lp[["main"]])) lp[["main"]] <- if(project == "CORDEX") {
      list(paste0("proj:", project, " var:", var, " exp:", experiment, " season:", seasonname, " area:", area, " region:", region, " cdx.domain:", names(dom)), cex = 0.9)
    } else {
      list(paste0("proj:", project, " var:", var, " exp:", experiment, " season:", seasonname, " area:", area, " region:", region), cex = 0.9)
    }
    if (is.null(lp[["colorkey"]])) lp[["colorkey"]] <- list(width = 0.9, labels = list(cex = 0.7))
    if (is.null(lp[["aspect"]])) lp[["aspect"]] <-  "fill"
    do.call("levelplot", lp)
  }
}
