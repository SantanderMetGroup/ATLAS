# Code for reproducibility of the ATLAS boxplots and scatterplots of model projections

`boxplots_TandP.R` is the star script of the ATLAS!!

It is flexible and easy to use. There is no special requirements for executing the script (only an R environment with a few packages), as it uses R functions and data stored in this repository. 

The R function used is computeFigures (available at [aggregated-datsets/scripts](https://github.com/SantanderMetGroup/ATLAS/tree/devel/aggregated-datasets/scripts)) and the data used are the regional means available at [aggregated-datsets/data](https://github.com/SantanderMetGroup/ATLAS/tree/devel/aggregated-datasets/data).

It allows for the selection of:

* Seasons
* Reference period
* Surface (Land, sea or both)
* Region/s from the [Updated IPCC-WGI reference regions](https://github.com/SantanderMetGroup/ATLAS/tree/devel/reference-regions) ([Iturbide et al, 2020](https://essd.copernicus.org/articles/12/2959/2020/))

For example, the following parameter configuration,

```r
# select seasons, use c(12,1,2) for winter
scatter.seasons <- list(c(12, 1, 2), 6:8)
# select reference period
ref.period <- 1995:2014
# select the area, i.e. "land", "sea" or "landsea"
area <- "land"
# Select reference regions.  Select the CORDEX domain to be considered
regions <- c("ECA", "EAS"); cordex.domain <- "EAS"
```

Will result in the following boxplots and scatterplots:


<img src="../../../man/SEA_land_baseperiod_1995-2014_ATvsAP.png" align="left" alt="" width="300" />

