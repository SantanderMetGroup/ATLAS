library(magrittr)
library(httr)

devtools::source_url("https://github.com/SantanderMetGroup/ATLAS/blob/devel/warming-levels/scripts/getGWL.R?raw=TRUE")

# https://stackoverflow.com/questions/25485216/how-to-get-list-files-from-a-github-repository-folder-using-r
myurl <- "https://api.github.com/repos/SantanderMetGroup/ATLAS/git/trees/devel?recursive=1"
req <- GET(myurl) %>% stop_for_status(req)
filelist <- unlist(lapply(content(req)$tree, "[", "path"), use.names = FALSE)
ls <- grep("CMIP6Amon_tas_landsea", filelist, value = TRUE, fixed = TRUE) %>% grep("\\.csv$", ., value = TRUE)
root <- "https://raw.githubusercontent.com/SantanderMetGroup/ATLAS/devel/"
allfiles <- paste0(root, ls)

# ls <- list.files("GWL/ignore/data/CMIP6_data/CMIP6Amon_tas_landsea/")
exp <- c("ssp126", "ssp245", "ssp585")
gwls <- c(1.5, 2 ,3, 4)
aux <- grep("historical", ls, value = TRUE)
modelruns <- gsub("reference_regions/regional_means/data/CMIP6Amon_tas_landsea/CMIP6Amon_|_historical.csv", "", aux)

l <- lapply(1:length(modelruns), function(i) {
    # grep(modelruns[i], ls, value = TRUE) %>% length() %>% print()
    modelfiles <- grep(modelruns[i], allfiles, value = TRUE) 
    hist <- grep("historical", modelfiles, value = TRUE) %>% read.table(header = TRUE, sep = ",", skip = 7) %>% subset(select = "world", drop = TRUE)
    yrs <- grep("historical", modelfiles, value = TRUE) %>% read.table(header = TRUE, sep = ",", skip = 7) %>% subset(select = "date", drop = TRUE) %>% gsub("-.*", "", .) %>% as.integer()
    hist <- tapply(hist, INDEX = yrs, FUN = "mean", na.rm = TRUE)
    names(hist) <- unique(yrs)
    # Ensure historical period does not go beyond 2014
    na.ind <- which(as.integer(names(hist)) > 2014)
    if (length(na.ind) > 0) hist <- hist[-na.ind]
    l1 <- lapply(1:length(exp), FUN = function(j) {
        rcp <- tryCatch({
            grep(exp[j], modelfiles, value = TRUE) %>% read.table(header = TRUE, sep = ",", skip = 7) %>% subset(select = "world", drop = TRUE)
        }, error = function(err) return(NaN))
        dates <- tryCatch({
            yrs <- grep(exp[j], modelfiles, value = TRUE) %>% read.table(header = TRUE, sep = ",", skip = 7) %>% subset(select = "date", drop = TRUE) %>% gsub("-.*", "", .) %>% as.integer()
            rcp <- tapply(rcp, INDEX = yrs, FUN = "mean", na.rm = TRUE)
            names(rcp) <- unique(yrs)
        }, error = function(err) return(NaN))
        if (is.nan(rcp)) {
            return(rep("9999", length(gwls)))
        } else {
            tas <- append(hist, rcp)
            # plot(names(tas),tas, ty = "l")
            sapply(gwls, function(k) {
                out <- getGWL(data = tas, base.period = c(1850,1900), proj.period = c(1971, 2100), window = 20, GWL = k) 
                interval <- attr(out, "interval") %>% paste(collapse = "-")
                paste0(unname(out), " [", interval, "]") %>% return()
            })
        }
    }) 
    do.call("c", l1)
})
dat <- do.call("rbind", l)
rownames(dat) <- modelruns

# write.table(dat, file = "GWL/ignore/CMIP6_GWLs.csv", quote = FALSE, sep = ",")


