library(magrittr)
library(httr)

## Source getGWL function
devtools::source_url("https://github.com/SantanderMetGroup/ATLAS/blob/devel/GWL/scripts/getGWL.R?raw=TRUE")
# source("GWL/scripts/getGWL.R")

## Set source directory storing the files 
# remote = https://github.com/SantanderMetGroup/ATLAS/tree/devel/reference_regions/regional_means/data/CMIP5_tas_landsea)
# local = updated cloned ATLAS repo

sourcefrom <- "remote"# "local" # "remote"
sourcefrom <- match.arg(sourcefrom, choices = c("local", "remote"))

if (sourcefrom == "remote") {
    # https://stackoverflow.com/questions/25485216/how-to-get-list-files-from-a-github-repository-folder-using-r
    myurl <- "https://api.github.com/repos/SantanderMetGroup/IPCC-Atlas/git/trees/devel?recursive=1"
    req <- GET(myurl) %>% stop_for_status(req)
    filelist <- unlist(lapply(content(req)$tree, "[", "path"), use.names = FALSE)
    ls <- grep("CMIP5_tas_landsea", filelist, value = TRUE, fixed = TRUE) %>% grep("\\.csv$", ., value = TRUE)
    root <- "https://raw.githubusercontent.com/SantanderMetGroup/IPCC-Atlas/devel/"
    allfiles <- paste0(root, ls)
} else {
    allfiles <- ls <- list.files("reference_regions/regional_means/data/CMIP5_tas_landsea", full.names = TRUE)  
}

# exp <- c("ssp126", "ssp245", "ssp585")
exp <- c("rcp26", "rcp45", "rcp85")
gwls <- c(1.5, 2 ,3, 4)
aux <- grep("historical", ls, value = TRUE)
modelruns <- gsub("reference_regions/regional_means/data/CMIP5_tas_landsea/CMIP5_|_historical.csv", "", aux)

l <- lapply(1:length(modelruns), function(i) {
    # grep(modelruns[i], ls, value = TRUE) %>% length() %>% print()
    modelfiles <- grep(modelruns[i], allfiles, value = TRUE) 
    hist <- grep("historical", modelfiles, value = TRUE) %>% read.table(header = TRUE, sep = ",", skip = 7) %>% subset(select = "world", drop = TRUE)
    yrs <- grep("historical", modelfiles, value = TRUE) %>% read.table(header = TRUE, sep = ",", skip = 7) %>% subset(select = "date", drop = TRUE) %>% gsub("-.*", "", .) %>% as.integer()
    hist <- tapply(hist, INDEX = yrs, FUN = "mean", na.rm = TRUE)
    names(hist) <- unique(yrs)
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
                getGWL(data = tas, base.period = c(1850,1900), proj.period = c(1971, 2100), window = 20, GWL = k) 
                # interval <- attr(out, "interval") %>% paste(collapse = "-")
                # paste0(unname(out), " [", interval, "]") %>% return()
            })
        }
    }) 
    do.call("c", l1)
})
dat <- do.call("rbind", l) 
dat <- cbind.data.frame(modelruns, dat)
names(dat) <- c("model_run", paste(rep(gwls, 3), rep(exp, each = 4), sep = "_"))
write.table(dat, file = "GWL/ignore/CMIP5_GWLs.csv", quote = FALSE, sep = ",", row.names = FALSE)

# check starting year
# histfiles <- grep("historical", allfiles, value = TRUE)
# yrs <- sapply(1:length(histfiles), function(i) {
#     read.table(histfiles[i], header = TRUE, sep = ",", skip = 7) %>% subset(select = "date", drop = TRUE) %>% extract(1) %>% substr(start = 1, stop = 4)
# })
# cbind(modelruns, yrs)



