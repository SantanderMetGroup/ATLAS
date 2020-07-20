## Updated AR5 Reference Regions and CMIP6 averaged results

The new references regions are provided as polygons in different formats (csv with coordinates, R data, and shapefile, *CMIP6_refereceRegions*) together with R and Python notebooks illustrating the use of these regions with worked out examples.

Spatially averaged results of CMIP6 and CMIP5 models (see [Altas Hub inventory](https://github.com/SantanderMetGroup/IPCC-Atlas/tree/devel/AtlasHub-inventory), version 20191211) have been computed for the different reference regions and are available at the *regional_means* folder. 

***
**NOTE!**: Region acronyms followed by the `*` suffix in the csv file define the part of the polygon of the same name that extends beyond the 180º meridian (i.e. RAR, NPO, EPO and SPO). This necessary distinction in the csv disappears in the spatial objects (the R data object and the shapefile), as the regions separated by the 180º meridian are merged and considered as a single polygon.
