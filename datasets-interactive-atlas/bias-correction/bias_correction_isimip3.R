# bias_correction_isimip3.R
#
# Copyright (C) 2021 Santander Meteorology Group (http://meteo.unican.es)
#
# This work is licensed under a Creative Commons Attribution 4.0 International
# License (CC BY 4.0 - http://creativecommons.org/licenses/by/4.0)

#' @title Script to bias-correct CMIP6 with ISIMIP3ISIMIP3 
#' @description Script to bias-correct CMIP6 with the ISIMIP3 method. ISIMIP3 (Lange 2019, https://doi.org/10.5194/gmd-12-3055-2019) 
#' is a parametric quantile mapping which has been designed to robustly adjust biases in all percentiles of a distribution whilst 
#' preserving their trends. The observational reference used for calibration is W5E5 (Cucchi et al. 2020, https://doi.org/10.5194/essd-12-2097-2020),
#' which was previously conservatively remapped onto a 1ºx1º regular grid. Note that spatial chunking is required to alleviate computationally costly calculations.

#' @author S. Herrera
#' @author M. Iturbide
#' @author A. Casanueva

# GMS 2020. Script to bias-correct CMIP6 with isimip3
# S. Herrera, 25-07-2020. Prepare auxiliary function.
# M. Iturbide, 27-07-2020. First version.
# M. Iturbide, 28-08-2020. Allow lat-lon chunking and set number of chunks based on memory resources.
# A. Casanueva, 25-09-2020. Allow parse options in .sh
# A. Casanueva, 02-01-2021. Split test period

library(downscaleR)
library(loadeR)
library(loadeR.2nc)
library(climate4R.UDG)

# Source chunking function
source("https://raw.githubusercontent.com/SantanderMetGroup/climate4R/devel/R/climate4R.chunk.R") 


# ***************************************
## Argument setting for the C4R function:
years.hist <- 1980:2005
#years.ssp <- 2015:2100
years.ssp <- 2015:2057 # 2058-2100
max.size <- 700 #Mb
memory.offset <- 360

# Select SSP
# ssp <- "ssp126"
# ssp <- "ssp245"
ssp <- "ssp585"
# ssp <- "ssp370"


message("Starting bias adjustment of CMIP6 for ", ssp, " with isimip3 at ", Sys.time())

out.dir <- paste0("/oceano/gmeteo/WORK/PROYECTOS/2018_IPCC/data/BA_DATA/CMIP6/temperatures/")
# ***************************************

# ***************************************
## Datasets
dataset.obs <- "/oceano/gmeteo/WORK/PROYECTOS/2018_IPCC/data/OBSERVATIONS/W5E5/deg1/w5e5_v1.0.ncml"
di.obs <- dataInventory(dataset.obs)

datasets.hist <- UDG.datasets("historical")[["CMIP6"]]
datasets.ssp <- UDG.datasets(ssp)[["CMIP6"]]

hist.members <- gsub("CMIP6_|historical_", "", datasets.hist)
fut.members <- gsub(paste0("CMIP6_|", ssp, "_"), "", datasets.ssp)
members <- intersect(hist.members, fut.members)
ind.h <- sapply(members, function(x) grep(x, hist.members))
ind.f <- sapply(members, function(x) grep(x, fut.members))

datasets.hist <- datasets.hist[ind.h]
datasets.ssp <- datasets.ssp[ind.f]
# ***************************************

# ***************************************
# aux.fun.isimip3 ------------------
aux.fun.isimip3 <- function(y.tas, y.tasmin, y.tasmax, 
                            x.tas, x.tasmin, x.tasmax, 
                            newdata.tas, newdata.tasmin, newdata.tasmax, 
                            isimip3.args = list(lower_bound =  c(NULL),
                                                lower_threshold =  c(NULL),
                                                upper_bound =  c(NULL),
                                                upper_threshold =  c(NULL),
                                                randomization_seed =  NULL,
                                                detrend =  array(data  =  TRUE, dim = 1),
                                                rotation_matrices =  c(NULL),
                                                n_quantiles = 50,
                                                distribution =  c("normal"),
                                                trend_preservation = array(data  =  "additive", dim = 1),
                                                adjust_p_values = array(data  =  FALSE, dim = 1),
                                                if_all_invalid_use =  c(NULL),
                                                invalid_value_warnings = FALSE),
                            isimip3.range.args  =  list(lower_bound =  c(0),
                                                        lower_threshold =  c(0.01),
                                                        upper_bound =  c(NULL),
                                                        upper_threshold =  c(NULL),
                                                        randomization_seed =  NULL,
                                                        detrend =  array(data  =  FALSE, dim = 1),
                                                        rotation_matrices =  c(NULL),
                                                        n_quantiles = 50,
                                                        distribution =  c("rice"),
                                                        trend_preservation = array(data = "mixed", dim=1),
                                                        adjust_p_values = array(data  =  FALSE, dim = 1),
                                                        if_all_invalid_use =  c(NULL),
                                                        invalid_value_warnings = FALSE),
                            isimip3.skew.args  =  list(lower_bound =  c(0),
                                                       lower_threshold =  c(0.0001),
                                                       upper_bound =  c(1),
                                                       upper_threshold =  c(0.9999),
                                                       randomization_seed =  NULL,
                                                       detrend =  array(data  =  FALSE, dim = 1),
                                                       rotation_matrices =  c(NULL),
                                                       n_quantiles = 50,
                                                       distribution =  c("beta"),
                                                       trend_preservation = array(data = "bounded", dim = 1),
                                                       adjust_p_values = array(data  =  FALSE, dim = 1),
                                                       if_all_invalid_use  =  c(NULL),
                                                       invalid_value_warnings  =  FALSE)){
  # Calculate range and skewness
  y.range <- gridArithmetics(y.tasmax, y.tasmin, operator = c("-"))
  x.range <- gridArithmetics(x.tasmax, x.tasmin, operator = c("-"))
  newdata.range <- gridArithmetics(newdata.tasmax,newdata.tasmin, operator = c("-"))
  y.skew <- gridArithmetics(gridArithmetics(y.tas, y.tasmin, operator = "-"), y.range, operator = "/")
  x.skew <- gridArithmetics(gridArithmetics(x.tas,x.tasmin, operator = "-"), x.range, operator = "/")
  newdata.skew <- gridArithmetics(gridArithmetics(newdata.tas, newdata.tasmin, operator = "-"), newdata.range, operator = "/")
  
  attr.tasmin <- y.tasmin$Variable
  attr.tasmax <- y.tasmax$Variable
  y.tasmax <- NULL; y.tasmin <- NULL; x.tasmax <- NULL; x.tasmin <- NULL; newdata.tasmax <- NULL;newdata.tasmin <- NULL
  
  # tas
  message("Starting bias adjustment of mean temperature at ", Sys.time())
  bc.tas.args <- list("y" = y.tas, "x" = x.tas, "newdata" = newdata.tas, "precipitation" = FALSE, "isimip3.args" = isimip3.args, "method"="isimip3")
  bc.tas <- do.call("biasCorrection", bc.tas.args)
  bc.tas.args <- NULL;  y.tas <- NULL;  x.tas <- NULL;  newdata.tas <- NULL
  
  # range
  message("Starting bias adjustment of temperature range at ", Sys.time())
  bc.range.args <- list("y" = y.range, "x" = x.range, "newdata" = newdata.range, "precipitation" = FALSE, "isimip3.args" = isimip3.range.args, "method"="isimip3")
  bc.range <- do.call("biasCorrection", bc.range.args)
  bc.range.args <- NULL;  y.range <- NULL;  x.range <- NULL;  newdata.range <- NULL
  
  # skewness
  message("Starting bias adjustment of temperature skewness at ", Sys.time())
  bc.skew.args <- list("y" = y.skew, "x" = x.skew, "newdata" = newdata.skew, "precipitation" = FALSE, "isimip3.args" = isimip3.skew.args, "method"="isimip3")
  bc.skew <- do.call("biasCorrection", bc.skew.args) 
  bc.skew.args <- NULL;   y.skew <- NULL;  x.skew <- NULL;  newdata.skew <- NULL
  
  message("Calculating bias-adjusted minimum temperature at ", Sys.time())
  bc.tasmin <- gridArithmetics(bc.tas, gridArithmetics(bc.range, bc.skew, operator = c("*")), operator = c("-"))
  # put right attributes 
  bc.tasmin$Variable <- attr.tasmin
  attr(bc.tasmin$Variable, "correction") <- "isimip3"
  message("Calculating bias-adjusted maximum temperature at ", Sys.time())
  bc.tasmax <- gridArithmetics(bc.tasmin, bc.range, operator = c("+"))
  # put right attributes 
  bc.tasmax$Variable <- attr.tasmax
  attr(bc.tasmax$Variable, "correction") <- "isimip3"
  
  bc.range <- NULL;  bc.skew <- NULL
  makeMultiGrid(bc.tas, bc.tasmin, bc.tasmax)
}
# ***************************************


# ***************************************
# apply bias correction -----------------
models <- 1:length(datasets.hist)
message("Ready to start models:\n ",paste(datasets.ssp[models], collapse="\n "))

lapply(models, function(x) {

if(datasets.ssp[x]=="CMIP6_AWI-CM-1-1-MR_ssp585_r1i1p1f1"){
	n.chunks <- 60; chunk.horiz <- FALSE
} else if(datasets.ssp[x]=="CMIP6_CNRM-CM6-1-HR_ssp585_r1i1p1f2"){
	n.chunks <- 90; chunk.horiz <- FALSE
}  else{ n.chunks <- 45; chunk.horiz <- FALSE}


if(!file.exists(paste0(out.dir,"/",datasets.ssp[x],"_chunk0",n.chunks,".nc"))){ 

	message("Starting GCM ",datasets.ssp[x], " at ", Sys.time())
	di <- dataInventory(datasets.hist[x])
	di2 <- dataInventory(datasets.ssp[x])
	if (any(names(di) %in% "tas") & any(names(di) %in% "tasmax") & any(names(di) %in% "tasmin")) {
	  if (any(names(di2) %in% "tas") & any(names(di2) %in% "tasmax") & any(names(di2) %in% "tasmin")) {
	    ###COMPUTE BC:
	    index <- climate4R.chunk(n.chunks = n.chunks, 
		                     chunk.horizontally = chunk.horiz,
		                     C4R.FUN.args = list(FUN = "aux.fun.isimip3",  
		                                         y.tas = list(dataset = dataset.obs, var = "tas", years = years.hist),
		                                         y.tasmin = list(dataset = dataset.obs, var = "tasmin", years = years.hist), 
		                                         y.tasmax = list(dataset = dataset.obs, var = "tasmax", years = years.hist), 
		                                         x.tas = list(dataset = datasets.hist[x], var = "tas", years = years.hist), 
		                                         x.tasmin = list(dataset = datasets.hist[x], var = "tasmin", years = years.hist), 
		                                         x.tasmax = list(dataset = datasets.hist[x], var = "tasmax", years = years.hist), 
		                                         newdata.tas = list(dataset = datasets.ssp[x], var = "tas", years = years.ssp), 
		                                         newdata.tasmin = list(dataset = datasets.ssp[x], var = "tasmin", years = years.ssp), 
		                                         newdata.tasmax = list(dataset = datasets.ssp[x], var = "tasmax", years = years.ssp)),
				     output.path = out.dir,
				     filename = paste0(datasets.ssp[x],'_', years.ssp[1], '-',years.ssp[length(years.ssp)]) )
	    index <- NULL
	    message("Finished GCM ",datasets.ssp[x], " at ", Sys.time())
	  } else{message("Variable missing in ", datasets.ssp[x])}
	} else{message("Variable missing in ", datasets.hist[x])}
} else{message("Skipping GCM ",datasets.ssp[x], ", already available")}
})
# ***************************************

