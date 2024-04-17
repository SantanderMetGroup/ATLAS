(warming-levels)=
# Global Warming Levels 

Time periods for which +1.5, +2, +3 and +4 degree Transient Global Warming Levels (GWLs) are reached (with respect to pre-industrial 1850-1900 mean value) are computed for CMIP5 and CMIP6 data using a 20-year moving window, building on the datasets listed in the corresponding CMIP5 and CMIP6 [data sources](data-sources). 

The approach is similar to that described by e.g. {cite}`nikulinEffectsDegreesGlobal2018`. The values provided in the GWL tables in this directory (*CMIP5_Atlas_WarmingLevels.csv* and *CMIP6_Atlas_WarmingLevels.csv*) correspond to the **central year (n) of the 20-year window** where the warming is first reached (the GWL period is thus calculated as **[n-9, n+10]**). Cells with **'NA'** indicate that the GWL was not reached before (the central year) 2100. Cells with **'9999'** correspond to models with no available data for the particular scenario. The script provided for GWL calculation builds directly on the information available at the [datasets-aggregated-regionally](datasets-aggregated-regionally) directory, in particular using the global values in the last column of the files (*'tas_landsea'* csv files, under the `"world"` heading).

The use of a 20-year moving window is selected to be consistent with 20-year time slices typically used for future projections: the near-term (2021-2040), mid-term (2041-2060) and long-term (2081-2100). However, the figures in the *CMIPx_WarmingLevels_spread_scenario.pdf* files compare the results for 20- and 30-year windows using the large CMIP5/CMIP6 ensembles. 

The *scripts* folder also contains a script to produce plots of the GWL crossing time, with a flexible parameter setting. For instance, the following parameter set:
```R
cmip <- "CMIP6"
gwl <- 2        # Possible values: 1.5, 2 , 3 or 4 (degrees)
exp <- "ssp370" # This is a CMIP-dependent parameter
window <- 20    # window width (in years) for centered moving average.
```
produces the following plot:

<p align="center">
  <img src="CMIP6_GWL_2degC_SSP370.png" alt="" width="" />
</p>

See also the [global warming levels](global-warming-levels_R) notebook in the notebooks section to learn the basics of GWL calculation.

## Similar repositories

A similar repository for GWL calculation is maintained by {cite:authorpar}`MathauseCmipWarming` and provides similar information which allows double-checking the results. Small differences (1-year shifts) are attributable to different postprocessing methods and/or different members/versions.

### References 

```{bibliography}
:filter: docname in docnames
```

<script src="https://utteranc.es/client.js"
        repo="PhantomAurelia/Atlas"
        issue-term="pathname"
        theme="preferred-color-scheme"
        crossorigin="anonymous"
        async>
</script>