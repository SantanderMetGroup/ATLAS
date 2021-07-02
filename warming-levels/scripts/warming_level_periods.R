library(magrittr)
library(httr)
source("getGWL.R")

gwls <- c(1.5, 2 ,3, 4)
cmip <- "CMIP5"
return.interval <- FALSE # Logical flag, indicating if the table should display
                         # central year and interval, or central year only
exp <- list(
  CMIP5 = c("rcp26", "rcp45", "rcp85"),
  CMIP6 = c("ssp126", "ssp245", "ssp370", "ssp585")
)
last.hist.year <- list(CMIP5 = 2005, CMIP6 = 2014)

datadir <- sprintf("../../datasets-aggregated-regionally/data/%s/%s_tas_landsea", cmip, cmip)
filelist <- list.files(datadir)
allfiles <- sprintf("%s/%s", datadir, filelist)

aux <- grep("historical", filelist, value = TRUE)
modelruns <- gsub(sprintf("%s_|_historical|\\.csv", cmip), "", aux)

world.annual.mean <- function(csvfile){
    csvdata <- read.table(csvfile, header = TRUE, sep = ",")
    rval <- subset(csvdata, select = "world", drop = TRUE)
    yrs <- subset(csvdata, select = "date", drop = TRUE) %>%
        gsub("-.*", "", .) %>% as.integer()
    rval <- tapply(rval, INDEX = yrs, FUN = "mean", na.rm = TRUE)
    names(rval) <- unique(yrs)
    return(rval)
}

l <- lapply(1:length(modelruns), function(i) {
    message("[", Sys.time(), "] Processing ", modelruns[i])
    modelfiles <- gsub("_", "_.*", modelruns[i], fixed = TRUE) %>%
        grep(allfiles, value = TRUE)
    hist <- grep("historical", modelfiles, value = TRUE) %>% world.annual.mean()
    # Ensure historical period does not go beyond last year
    na.ind <- which(as.integer(names(hist)) > last.hist.year[[cmip]])
    if (length(na.ind) > 0) hist <- hist[-na.ind]
    l1 <- lapply(1:length(exp[[cmip]]), FUN = function(j) {
        rcp <- tryCatch({
            grep(exp[[cmip]][j], modelfiles, value = TRUE) %>% world.annual.mean() 
        }, error = function(err) return(NaN))
        if (is.nan(rcp)) {
            return(rep("9999", length(gwls)))
        } else {
            tas <- append(hist, rcp)
            # plot(names(tas),tas, ty = "l")
            sapply(gwls, function(k) {
                out <- getGWL(data = tas,
                    base.period = c(1850,1900), proj.period = c(1971, 2100),
                    window = 20, GWL = k
                ) 
                if (isTRUE(return.interval)) {
                    interval <- attr(out, "interval") %>% paste(collapse = "-")
                    return(sprintf("%s [%s]", unname(out), interval))
                } else {
                    return(out)
                }
            })
        }
    }) 
    do.call("c", l1)
})
dat <- do.call("rbind", l)
rownames(dat) <- modelruns
aux <- expand.grid(gwls, exp[[cmip]])
cnames <- paste(aux[ , 1], aux[ , 2], sep = "_")
colnames(dat) <- cnames

write.table(dat, file = sprintf("%s_Atlas_WarmingLevels.csv", cmip), quote = FALSE, sep = ",")
