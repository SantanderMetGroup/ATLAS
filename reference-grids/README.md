## Sets of reference grids for the ATLAS

Several reference grids (with 0.5 deg, 1 deg, and 2 deg spatial resolution) are used in the Atlas to interpolate CORDEX, CMIP5 and CMIP6 ensembles to common regular grids (also 0.25 deg for regional observations and CORDEX-EUR). Some datasets produced using these masks are:
* land sea masks: land_sea_mask_*.nc4 
* mountain ranges masks: mountain_ranges_mask_*.nc4 

A jupyter notebook illustrating a simple example of their use in R is provided in *notebooks*. 

<p align="center">
  <img src="/man/reference-grids.png" alt="" width="750" />
</p>

### Land-sea masks
TBC

### Mountain-ranges masks
Created from 1kbinary_upscaled05 (upscaled to 0.5 degree using the mean) and using a 0.75 threshold (for mountain area within the gridbox). The 2 deg and 1 deg masks are upscaled versions (using the mean) using a 0.5 threshold (to better match the areas in the different resolution grids).

