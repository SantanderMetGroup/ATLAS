# Sets of reference grids for the ATLAS

Several reference grids (with 0.5 deg, 1 deg, and 2 deg spatial resolution) are used in the Atlas to interpolate CORDEX, CMIP5 and CMIP6 ensembles to common regular grids (also 0.25 deg for regional observations and CORDEX-EUR). Some datasets produced using these masks are:
* land sea masks: land_sea_mask_*.nc4 
* mountain ranges masks: mountain_ranges_mask_*.nc4 

A jupyter notebook illustrating a simple example of their use in R is provided in *notebooks*. 

<p align="center">
  <img src="/man/reference_grids.png" alt="" width="400" />
</p>

(2) mountain_ranges_mask_1degree.nc4 = mountain_ranges_mask_05degree.nc4 upscaled to 1 degree with the mean & >=0.5
(3) mountain_ranges_mask_1degree.nc4 = mountain_ranges_mask_05degree.nc4 upscaled to 2 degree with the mean & >=0.5
Available no in github ATLAS.
script: /oceano/gmeteo/WORK/PROYECTOS/2018_IPCC/regions/GlobalMountainsK1Binary/create_mountain_masks.R

## Land-sea masks
TBC

### Mountain-ranges masks
Created from 1kbinary_upscaled05 (upscaled to 0.5 degree using the mean) and using a 0.75 threshold (for mountain area within the gridbox). The 2 deg and 1 deg masks are upscaled versions (using the mean) using a 0.5 threshold (to better match the areas in the different resolution grids).




