# 02_interpolation.R
#
# Copyright (C) 2021 Santander Meteorology Group (http://meteo.unican.es)
#
# This work is licensed under a Creative Commons Attribution 4.0 International
# License (CC BY 4.0 - http://creativecommons.org/licenses/by/4.0)

#' @title Interpolate outputs from 01_index_calculation.R
#' @description
#'   The interpolation followed is the one used in EURO-CORDEX. It is a
#'   Conservative Remapping procedure in which parameters sensitive to land-sea
#'   transitions are dually interpolated, i.e. land-sea separated, and then
#'   re-combined in one file.  Residual missing values (NAs) in the interior
#'   domain are filled with values from a straighforward remap.  Land fraction
#'   thresholds used were > 0.999 and < 0.001 for land and sea respectively.
#'   This script uses bash interpolation scripts available under
#'   bash-interpolation-scripts/
#' @author M. Iturbide

# Misc utilities for remote repo interaction:
library(devtools)

# USER PARAMETER SETTING -------------------------------------------------------

# Path to the bash script performing the interpolation (AtlasCDOremappeR_CMIP.sh), downloable from https://github.com/SantanderMetGroup/ATLAS/tree/mai-devel/SOD-scripts/bash-interpolation-scripts: 
script <- "AtlasCDOremappeR_CMIP.sh"  # supposing the bash script is in the current directory
# Path to the directory containing the NetCDFs to be interpolated, e.g. the current directory:
source.dir <- getwd()
# Path to the output directory, e.g.:
out.dir <- getwd()
# Path to the NetCDFs of the original masks (variable sftlf), e.g.:
mask.dir <- paste0(getwd(), "/masks")
# Path to the destination mask (land_sea_mask_2degree.nc4), downloable from https://github.com/SantanderMetGroup/ATLAS/tree/master/reference-grids:
refmask = paste0(mask.dir, "/land_sea_mask_2degree.nc4")

# INTERPOLATION ----------------------------------------------------------------

# List of nectcdf files containing the land/sea masks of each model
orig.masks <- list.files(mask.dir, full.names = TRUE)
gridsdir <- list.files(source.dir, pattern = "nc4", full.names = TRUE)
grids <- list.files(source.dir, pattern = "nc4")

# The loop iterates over models and performs the Conservative Remapping described above,
# writing the interpolated files in the output directory (out.dir):

for (m in 1:length(grids)) {
  grid <- grids[m]
  griddir <- gridsdir[m]
  model <- strsplit(grid, "_")[[1]][2]
  gridmask <- orig.masks[grep(model, orig.masks)]
  out.dir <- gsub("/raw/", "/cdo/", gsub(grid, "", griddir))
  if (!dir.exists(out.dir)) dir.create(out.dir, recursive = TRUE)
  if (!file.exists(paste0(out.dir, "/", grid))) {
    if (length(gridmask) > 0) {
      print(paste0(out.dir, "/", grid))
      system(paste("bash", script, griddir, paste0(out.dir, "/", grid), gridmask, refmask))
    } else {
      print(paste0(out.dir, "/", grid))
      system(paste0("cdo remapcon,", refmask, " ", griddir, " ", paste0(out.dir, "/", grid)))
    }
  }
}
# END
