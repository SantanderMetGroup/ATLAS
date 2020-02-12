library(devtools)

# PARAMETER SETTING ---------------------------------------------------------------------------

# Bash script performing the interpolation available at https://github.com/SantanderMetGroup/ATLAS/tree/mai-devel/SOD-scripts, e.g.: 
script <- "AtlasCDOremappeR_CMIP.sh"
# Path to the destination mask, available at https://github.com/SantanderMetGroup/ATLAS/tree/master/reference_masks, e.g.:
refmask <- "land_sea_mask_2degree.nc4"
# Path to the directory containing the NetCDFs to be interpolated
source.dir <- ""
# Output path
out.dir <- ""
# Path to the NetCDFs of the original masks (variable sftlf)
mask.dir <- ""


# INTERPOLATION ------------------------------------------------------------------------------------------------------

orig.masks <- list.files(mask.dir, full.names = T)
gridsdir <- list.files(source.dir, pattern = "nc4", full.names = TRUE)
grids <- list.files(source.dir, pattern = "nc4")
for (m in 1:length(grids)) {
  grid <- grids[m]
  griddir <- gridsdir[m]
  model <- strsplit(grid, "_")[[1]][2]
  gridmask <- orig.masks[grep(model, orig.masks)]
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
