# hatching-functions.R
#
# Copyright (C) 2021 Santander Meteorology Group (http://meteo.unican.es)
#
# This work is licensed under a Creative Commons Attribution 4.0 International
# License (CC BY 4.0 - http://creativecommons.org/licenses/by/4.0)

#' @title Atomic function used in hatching
#' @description Functions for computing two different uncertainty
#'   measures (signal and agreement) for Atlas Product Reproducibility. 
#' @author M. Iturbide

# (1) Signal --------

# Auxiliary function applying the formula defined by IPCC-WGI to calculate the sigma 
# of the historical reference (x is a vector of a temporal series). 
# The output is used to subsecuently calculate 
# the presence/absence of signal in the projected future delta changes (see 
# function signal in this script).

hist.sigma <- function(x) {
  (sqrt(2) * 1.645 * sd(x))/sqrt(20) 
}

# Function for calculating the presence/absence of signal in the projected
# delta changes (d is the C4R grid of the delta change) with reference to 
# the historical baseline (h is the C4R grid of the historical reference). 
# Function hist.sigma is used internally.

signal <- function(h, d) {
  h.sd <- climatology(h, clim.fun = list(FUN = hist.sigma))
  d$Data <- abs(d$Data)
  sig <- gridArithmetics(d, h.sd, operator = "-")
  binaryGrid(sig, condition = "GT", threshold = 0, values = c(0, 1))
}

# Auxiliary function for calculating the multi-model signal based on a minimum 
# threshold percentage (th) of presence of signal in the multi-model ensemble 
# (x is the vector of the presence/absence of signal of each model). 

signal.ens1 <- function(x, th = 66) {
  as.numeric((sum(x)/length(x)*100) > th)
}

signal.ens2 <- function(x, th = 66) {
  as.numeric((sum(x)/length(x)*100) < th)
}

# (2) Agreement -----

# Auxiliary function for calculating the uncertainty given by the percentage (th) 
# of multi-model agreement on the sign of the change (positive/negative) w.r.t the ensemble 
# mean delta change (x is the vector of the delta change of each model). 

agreement <- function(x, th = 80) {
  mp <- mean(x, na.rm = TRUE)
  if (is.na(mp)) {
    1
  } else {
    if (mp > 0) {
      as.numeric(sum(as.numeric(x > 0), na.rm = TRUE) > as.integer(length(x) * th / 100))
    } else if (mp < 0) {
      as.numeric(sum(as.numeric(x < 0), na.rm = TRUE) > as.integer(length(x) * th / 100))
    } else if (mp == 0){
      1
    }
  }
}

