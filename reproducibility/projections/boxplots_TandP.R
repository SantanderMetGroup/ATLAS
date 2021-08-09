# boxplots_TandP.R
#
# Copyright (C) 2021 Santander Meteorology Group (http://meteo.unican.es)
#
# This work is licensed under a Creative Commons Attribution 4.0 International
# License (CC BY 4.0 - http://creativecommons.org/licenses/by/4.0)

#' @title Boxplots and scatterplots of temperature and precipitation changes
#' @description This script computes temperature and precipitation changes from
#'   data files that are available in this repository (CSV files in
#'   datasets-aggregated-regionally) and produces boxplots and scatterplots
#'   considering the median, p10 and p90. Requirements to run the script:
#'    - R 
#'    - R packages magrittr, httr, lattice, latticeExtra, gridExtra
#' @author M. Iturbide

## Package magrittr is used to pipe (%>%) sequences of data operations improving readability
#install.packages("magrittr")
library(magrittr)
## The package httr is used towork with URLs and HTTP
#install.packages("httr")
library(httr)
## Libraries lattice and latticeExtra are used internally to produce the figures
#install.packages("lattice")
#install.packages("latticeExtra")
library(lattice)
library(latticeExtra)
## To produce the final pannel of the plots library gridExtra is used.
#install.packages("gridExtra")
library(gridExtra)
library(Cairo)


# Function computeDeltas available at this repo is used:
source("../datasets-aggregated-regionally/scripts/computeDeltas.R")
source("../datasets-aggregated-regionally/scripts/computeFigures.R")
source("../datasets-aggregated-regionally/scripts/computeOffset.R")


# select seasons, use c(12,1,2) for winter
scatter.seasons <- list(c(12, 1, 2), 6:8)
# scatter.seasons <- list(c(12, 1, 2, 3), 6:9)
# scatter.seasons <- list(c(12, 1, 2), 6:9)
scatter.seasons <- list(1:12)
# select reference period
ref.period <- 1995:2014
# ref.period <- 1986:2005
# ref.period <- 1850:1900
# select the area, i.e. "land", "sea" or "landsea"
area <- "land"

# Select reference regions.  Select the CORDEX domain to be considered
regions <- c("ARO"); cordex.domain <- "ARC"
# regions <- c("TIB", "SAS"); cordex.domain <- "WAS"
regions <- c("MED","SAH","WAF","CAF","NEAF", "SEAF", "WSAF", "ESAF", "MDG"); cordex.domain <- "AFR"
# regions <- c("world"); cordex.domain <- FALSE


# regions <- c("NWN","NEN","GIC","RAR"); cordex.domain <- "ARC"
# regions <- c("SEA"); cordex.domain <- "SEA"
# regions <- c("ECA", "EAS"); cordex.domain <- "EAS"
# regions <- c("NWN","NEN","WNA","CNA","ENA", "NCA"); cordex.domain <- "NAM"
# regions <- c("WAN","EAN"); cordex.domain <- "ANT"
# regions <- c("NCA", "SCA", "CAR"); cordex.domain <- "CAM"
# regions <- c("WCA","TIB", "ARP", "SAS"); cordex.domain <- "WAS"
# regions <- c("EEU","WSB","ESB","RFE", "WCA", "ECA"); cordex.domain <- FALSE
# regions <- c("NEU","WCE","EEU","MED"); cordex.domain <- "EUR"
# regions <- c("NWS","NSA", "SAM", "NES", "SWS", "SES", "SSA"); cordex.domain <- "SAM"
# regions <- c("SEA", "NAU","CAU","EAU","SAU","NZ"); cordex.domain <- "AUS"




# select figure axes ranges (ylim for temperature, xlim for precipitation percentage)
ylim <- NULL
xlim <- NULL



a <- computeFigures(regions = regions,
                    cordex.domain = cordex.domain,
                    area = area, 
                    ref.period = ref.period, 
                    scatter.seasons = scatter.seasons,
                    xlim = xlim,
                    ylim = ylim)

# select the path and the name of the output pdf
outfilename <- paste0(cordex.domain, "_", area, "_baseperiod_", paste(range(ref.period), collapse = "-"), "_ATvsAP.pdf")
# outfilename <- paste0("GLOBAL", "_", area, "_baseperiod_", paste(range(ref.period), collapse = "-"), "_ATvsAP.pdf")
# Play with arguments width and height to create different size pds-s
CairoPDF(outfilename, width = (length(scatter.seasons)+1)*10/2*0.85, height = length(regions)*10/2*0.85)
do.call("grid.arrange", a)
dev.off()
