## Sets of reference grids for the ATLAS

Several reference grids (with 0.5 deg, 1 deg, and 2 deg spatial resolution) are used in the Atlas to interpolate CORDEX, CMIP5 and CMIP6 ensembles to common regular grids (also 0.25 deg for regional observations and CORDEX-EUR). Some datasets produced using these masks are:
* land sea masks: land_sea_mask_*.nc4 
* mountain ranges masks: mountain_ranges_mask_*.nc4 

A jupyter notebook illustrating a simple example of their use in R is provided in *notebooks*. 

<p align="center">
  <img src="/man/reference-grids.png" alt="" width="" />
</p>

### Land-sea masks
TBC

### Mountain-ranges masks

The mountain ranges masks have been defined using the K1 global mountains raster GIS datalayer (USGS Land Change Science Global Ecosystems; Kapos et al. 2000). The K1 resource defines six classes of mountains using a 1 km DEM which was processed using a combination of elevation, slope and relative relief. The upper three classes are defined by elevation ranges.
https://rmgsc.cr.usgs.gov/outgoing/ecosystems/Global/ (file: GME_K1binary.zip)

Created from 1kbinary_upscaled05 (upscaled to 0.5 degree using the mean) and using a 0.75 threshold (for mountain area within the gridbox). The 2 deg and 1 deg masks are upscaled versions (using the mean) using a 0.5 threshold (to better match the areas in the different resolution grids).

