##@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
## The code below calculates the data presented in this working document:
## https://docs.google.com/document/d/15DEqvABQQeHdk3ZTkkf5Zm0WIiShmZ-xc2uIoEKMQwU/view
##@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

## Warming level tables --------------------------------------------------------
source("GWL/R/getGWL.R")
require(magrittr)

#' @description The function computes the +1.5, +2, +3 and +4 degree Global Warming Levels (GWL's)
#'  for the list of models stored in the target directory "./GWL/data/CMIP5_global_tas"
#'  It assumes the ascii file format as downloaded from Climate Explorer.
#'  The function is a wrapper of the atomic function getGWL

doGWLtable <- function(rcp = c("rcp45", "rcp85"), wls = c(1.5, 2, 3, 4)) {
    gcms <- list.files("GWL/data/CMIP5_global_tas") %>% 
        gsub("^global_tas_Amon_","", .) %>% 
        gsub("_hist.*_|_rcp.*_", "_", .) %>% 
        gsub("\\.dat$", "", .) %>%
        unique()
    out <- sapply(1:length(gcms), function(i) {
        model <- gsub("_r.*", "_", gcms[i])
        run <- gsub(".*_","", gcms[i])
        lf <- list.files("GWL/data/CMIP5_global_tas",
                         pattern = paste0(model,".*", run),
                         full.names = TRUE)
        rcpx <- grep(rcp, lf, value = TRUE)
        if (length(rcpx) == 1L) {
            a <- read.table(rcpx, header = FALSE, skip = 2, row.names = 1)    
            yrs <- as.integer(rownames(a))
            a[a <= 0] <- NA
            ma <- rowMeans(a, na.rm = TRUE) 
            aux <- vapply(wls, FUN.VALUE = numeric(1L), FUN = function(i) {
                getGWL(data = ma, GWL = i)  
            })
        } else {
            aux <- rep(9999, length(wls))
        }
        as.data.frame(aux) %>% return()
    })
    names(out) <- gcms
    if (!is.data.frame(out)) out <- do.call("cbind.data.frame", out)
    row.names(out) <- c("+1.5", "+2", "+3", "+4")
    t(out) %>% return()
}

a <- doGWLtable("rcp45")
b <- doGWLtable("rcp85")

require(xtable)

cap = "Time periods for which the +1.5, +2, +3 and +4 degree Global Warming Levels (compared to pre-industrial times) are reached by the CMIP5 global climate projections for RCP 4.5 (first 4 columns) and RCP 8.5 (last 4 columns). Values correspond to the central year (n) of the 30-year window (the GWL period is thus calculated as [n-9, n+10]). Empty table cells indicate that the GWL was not reached before (the central year) 2100. \'9999\' correspond to models with no available experiment results."
xt <- cbind.data.frame(a,b) %>% xtable(caption = cap) 
# Force integers
digits(xt)[2:(length(xt) + 1)] <- 0
print.xtable(x = xt, type = "html", file = "/tmp/gwltable.html")

# %>% xtable() %>% print.xtable(type = "html", file = "/tmp/rc85table.html")


## Plumes ----------------------------------------------------------------------

require(lattice)   
require(RColorBrewer)

gcms <- list.files("GWL/data/CMIP5_global_tas") %>% 
    gsub("^global_tas_Amon_","", .) %>% 
    gsub("_hist.*_|_rcp.*_", "_", .) %>% 
    gsub("\\.dat$", "", .) %>%
    unique()
ref.years <- 1850:2100
piper <- 1850:1900

out.list <- lapply(1:length(gcms), function(i) {
    model <- gsub("_r.*", "_", gcms[i])
    run <- gsub(".*_","", gcms[i])
    lf <- list.files("GWL/data/CMIP5_global_tas",
                     pattern = paste0(model,".*", run),
                     full.names = TRUE)
    l1 <- lapply(c("rcp45", "rcp85"), function(j) {
        rcpx <- grep(j, lf, value = TRUE)
        if (length(rcpx) == 1L) {
            a <- read.table(rcpx, header = FALSE, skip = 2, row.names = 1)    
            a[a <= 0] <- NA
            yrs <- as.integer(rownames(a))
            ind <- which(yrs %in% ref.years)
            ts <- rowMeans(a, na.rm = TRUE)[ind] %>% subtract(273.15)
            piind <- which(yrs %in% piper)
            baseline <- mean(ts[piind], na.rm = TRUE)
            anom <- ts %>% filter(filter = rep(1/30, 30),
                                  sides = 2) %>% unclass() %>% subtract(baseline) #%>% cbind.data.frame("rcp" = j,
            # "anom" = .,
            # "gcm" = gcms[i],
            # "year" = ref.years)
        } else {
            anom <- rep(NA, length(ref.years))
        }
        cbind.data.frame("rcp" = j,
                         "anom" = anom,
                         "gcm" = gcms[i],
                         "year" = ref.years)
    })
    do.call("rbind.data.frame", l1)
})
datos <- do.call("rbind.data.frame", out.list)
# str(datos)


panelFun <- function(...) {
    panel.abline(v = c(1861,1890, 1971,2000), lty = 2, col = "black")
    panel.abline(h = c(1.5, 2, 3, 4), col = "grey")
    panel.xyplot(...)
}

# https://stackoverflow.com/questions/15282580/how-to-generate-a-number-of-most-distinctive-colors-in-r
n <- length(gcms)
qual_col_pals <- brewer.pal.info[brewer.pal.info$category == 'qual',]
col_vector <- unlist(mapply(brewer.pal, qual_col_pals$maxcolors, rownames(qual_col_pals)))
set.seed(2)
model.colors <- sample(col_vector, n)

# display.brewer.all()
key = list(text = list(levels(datos$gcm)),
           space = 'bottom',
           lines = list(col = model.colors[1:nlevels(datos$gcm)]),
           columns = 4)

xyplot(anom ~ year | rcp, group = gcm, data = datos,
       type = "l", ylab = "Anomaly (deg C)", key = key,
       panel = panelFun, scales = list(sides = 2, cex = 1.2), xlab = "",
       par.settings = list(superpose.line = list(col = model.colors)))






