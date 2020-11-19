# THIS SCRIPT COMPUTES TEMPERATURE AND PRECIPITATION CHANGES FROM DATA FILES THAT ARE
# AVAILABLE IN THIS REPOSITORY (CSV FILES IN AGGREGATED-DATASETS) AND 
# PRODUCES BOXPLOTS CONSIDERING THE MEDIAN, P10 AND P90.
# REQUIREMENTS TO RUN THE SCRIPT:
# - R 
# - R packages magrittr and httr

#----------------------------------------------------------------------------------------------


## The package magrittr is used to pipe (%>%) sequences of data operations improving readability
#install.packages("magrittr")
library(magrittr)
## The package httr is used towork with URLs and HTTP
#install.packages("httr")
library(httr)

# Function computeDeltas available at this repo is used:
source("https://raw.githubusercontent.com/SantanderMetGroup/ATLAS/devel/aggregated-datasets/scripts/computeDeltas.R")

### CMIP5 WL ----------------------------------

# select project "CMIP5", "CMIP6" ("CORDEX" will be available soon)
project = "CMIP5"
# select variable, i.e. "tas" or "pr"
var <- "tas"
# select scenario, i.e. "rcp26", "rcp45", "rcp85", "ssp126", "spp245", "ssp585" (select a single scenario for computing WLs)
experiment <- "rcp85"
# select season, use c(12,1,2) for winter
season <- 1:12
# select reference period
ref.period <- 1850:1900
# select warming levels or list of future periods, e.g. list(c(2021, 2040), c(2041, 2060), c(2081, 2100))
periods <- c("1.5", "2", "3", "4")
# select the area, i.e. "land", "sea" or "landsea"
area <- "landsea"

WL.cmip5 <- computeDeltas(project, var, experiment, season, ref.period, periods, area)

WLmediana.cmip5 <- lapply(WL.cmip5, apply, 2, median, na.rm = T)
WLp90.cmip5 <- lapply(WL.cmip5, apply, 2, quantile, 0.9, na.rm = T)
WLp10.cmip5 <- lapply(WL.cmip5, apply, 2, quantile, 0.1, na.rm = T)



##########  CMIP6 WL ------------------------------------

project = "CMIP6"
var <- "tas"
experiment <- "ssp585"
season <- 1:12
ref.period <- 1850:1900
periods <- c("1.5", "2", "3", "4")
area <- "landsea"

WL.cmip6 <- computeDeltas(project, var, experiment, season, ref.period, periods, area)

WLmediana.cmip6 <- lapply(WL.cmip6, apply, 2, median, na.rm = T)
WLp90.cmip6 <- lapply(WL.cmip6, apply, 2, quantile, 0.9, na.rm = T)
WLp10.cmip6 <- lapply(WL.cmip6, apply, 2, quantile, 0.1, na.rm = T)

##########  CMIP5 ------------------------------------

project = "CMIP5"
var <- "tas"
experiment <- c("rcp26", "rcp45", "rcp85")
season <- 1:12
ref.period <- 1995:2014
periods <- list(c(2021, 2040), c(2041, 2060), c(2081, 2100))
area <- "landsea"


cmip5 <- computeDeltas(project, var, experiment, season, ref.period, periods, area)

mediana.cmip5 <- lapply(cmip5, apply, 2, median, na.rm = T)
p90.cmip5 <- lapply(cmip5, apply, 2, quantile, 0.9, na.rm = T)
p10.cmip5 <- lapply(cmip5, apply, 2, quantile, 0.1, na.rm = T)

##########  CMIP6 ------------------------------------

project = "CMIP6"
var <- "tas"
experiment <- c("ssp126", "ssp245", "ssp585")
season <- 1:12
ref.period <- 1995:2014
periods <- list(c(2021, 2040), c(2041, 2060), c(2081, 2100))
area <- "landsea"

cmip6 <- computeDeltas(project, var, experiment, season, ref.period, periods, area)

mediana.cmip6 <- lapply(cmip6, apply, 2, median, na.rm = T)
p90.cmip6 <- lapply(cmip6, apply, 2, quantile, 0.9, na.rm = T)
p10.cmip6 <- lapply(cmip6, apply, 2, quantile, 0.1, na.rm = T)



# ##########  CORDEX ------------------------------------

# Under development


########## plot #######------------------------------------------------------------------------

library(lattice)
library(gridExtra)

out.dir <- ""
ylim <- c(0, 18); step <- 1
ylab <- bquote(Delta*"T(ºC)")

p <- lapply(1:length(mediana.cmip5), function(i){
  col = c(rgb(0.55,0,0.55,0.5), rgb(0.55,0,0.55), rgb(1, 0.73, 0.06, 0.5),  rgb(1, 0.73, 0.06), 
          rgb(0, 0, 0, 0.5),  rgb(0, 0, 0), rgb(0.5, 0.3, 0.16, 0.5),  rgb(0.5, 0.3, 0.16), 
          rep(c(rgb(0,0,1,0.5), "blue", rgb(0,1,0,0.5), "green", rgb(1,0,0,0.5), "red"), 9))
  a1 <- c(WLmediana.cmip5[[i]][1],WLmediana.cmip6[[i]][1])
  a2 <- c(WLmediana.cmip5[[i]][2],WLmediana.cmip6[[i]][2])
  a3 <- c(WLmediana.cmip5[[i]][3],WLmediana.cmip6[[i]][3])
  a4 <- c(WLmediana.cmip5[[i]][4],WLmediana.cmip6[[i]][4])
  a <- c(mediana.cmip5[[i]][1], mediana.cmip6[[i]][1], mediana.cmip5[[i]][4], mediana.cmip6[[i]][4],mediana.cmip5[[i]][7], mediana.cmip6[[i]][7])
  b <- c(mediana.cmip5[[i]][2], mediana.cmip6[[i]][2], mediana.cmip5[[i]][5], mediana.cmip6[[i]][5],mediana.cmip5[[i]][8], mediana.cmip6[[i]][8])
  d <- c(mediana.cmip5[[i]][3], mediana.cmip6[[i]][3], mediana.cmip5[[i]][6], mediana.cmip6[[i]][6],mediana.cmip5[[i]][9], mediana.cmip6[[i]][9])
  sc <- c("rcp26", "ssp126", "rcp45", "ssp245", "rcp85", "ssp585")
  x0 <- c(paste0("+1.5º-", c("rcp85","ssp585")), paste0("+2º-", c("rcp85","ssp585")), paste0("+3º-", c("rcp85","ssp585")), paste0("+4º-", c("rcp85","ssp585")), paste0("near-", sc), paste0("mid-", sc), paste0("far-", sc))
  # ind <- c(1:4, c(5, 7, 9), c(6, 8, 10), c(11, 13, 15), c(12, 14, 16), c(17, 19, 21), c(18, 20, 22))
  ind <- 1:length(x0)
  x <- paste0(letters[1:length(x0)], ")",  x0[ind])
  
  
  
  df <- data.frame("term" = x, "value" = unname(do.call("c", list(a1, a2, a3, a4, a, b, d)))[ind])
  
  
  
  a1i <- c(WLp10.cmip5[[i]][1],WLp10.cmip6[[i]][1])
  a2i <- c(WLp10.cmip5[[i]][2],WLp10.cmip6[[i]][2])
  a3i <- c(WLp10.cmip5[[i]][3],WLp10.cmip6[[i]][3])
  a4i <- c(WLp10.cmip5[[i]][4],WLp10.cmip6[[i]][4])
  ai <- c(p10.cmip5[[i]][1], p10.cmip6[[i]][1], p10.cmip5[[i]][4], p10.cmip6[[i]][4],p10.cmip5[[i]][7], p10.cmip6[[i]][7])
  bi <- c(p10.cmip5[[i]][2], p10.cmip6[[i]][2], p10.cmip5[[i]][5], p10.cmip6[[i]][5],p10.cmip5[[i]][8], p10.cmip6[[i]][8])
  di <- c(p10.cmip5[[i]][3], p10.cmip6[[i]][3], p10.cmip5[[i]][6], p10.cmip6[[i]][6],p10.cmip5[[i]][9], p10.cmip6[[i]][9])
  dfi <- data.frame("term" = x, "value" = unname(do.call("c", list(a1i, a2i, a3i, a4i, ai, bi, di)))[ind])
  
  a1j <- c(WLp90.cmip5[[i]][1],WLp90.cmip6[[i]][1])
  a2j <- c(WLp90.cmip5[[i]][2],WLp90.cmip6[[i]][2])
  a3j <- c(WLp90.cmip5[[i]][3],WLp90.cmip6[[i]][3])
  a4j <- c(WLp90.cmip5[[i]][4],WLp90.cmip6[[i]][4])
  aj <- c(p90.cmip5[[i]][1], p90.cmip6[[i]][1], p90.cmip5[[i]][4], p90.cmip6[[i]][4],p90.cmip5[[i]][7], p90.cmip6[[i]][7])
  bj <- c(p90.cmip5[[i]][2], p90.cmip6[[i]][2], p90.cmip5[[i]][5], p90.cmip6[[i]][5],p90.cmip5[[i]][8], p90.cmip6[[i]][8])
  dj <- c(p90.cmip5[[i]][3], p90.cmip6[[i]][3], p90.cmip5[[i]][6], p90.cmip6[[i]][6],p90.cmip5[[i]][9], p90.cmip6[[i]][9])
  dfj <- data.frame("term" = x, "value" = unname(do.call("c", list(a1j, a2j, a3j, a4j, aj, bj, dj)))[ind])
  
  col <- col[ind]
  
  xyplot(value~term, data = df, ylim = ylim, pch = 19, ylab = ylab, scales=list(x=list(rot=90)),
         col = col, cex = 1, xlab = "", #, 
         main = names(mediana.cmip5)[i],
         panel = function(...){
           panel.abline(h = do.call("seq", as.list(c(ylim, step))),
                        col = "gray65", lwd = 0.5, lty = 2)
           panel.segments(df$term, dfi$value, df$term, dfj$value, col = col, lwd = 5) #alpha = 0.5)
           panel.xyplot(...)
         })
})

nn <- "AT"
if (var == "pr") nn <- "AP"
pdf(paste0(out.dir, "/FGD_boxplots_",area,"_", nn, "_season_", paste(season, collapse = "-"), "_ylim_", paste(ylim, collapse = "-"), ".pdf"), width = 40, height = 50)
do.call("grid.arrange", p)
dev.off()

