(bash-interpolation-scripts)=
# Bash interpolation scripts

These are shell (bash) scripts used for the conservative interpolation of the Interactive Atlas Dataset.

All the raw model outputs from the CMIP5, CMIP6 and CORDEX experiments have been interpolated to a common grid using the first order conservative remapping implemented in *Climate Data Operators (CDO) version 1.9.8* {cite}`VistazoCDOProject`. See the *CDO User Guide* {cite}`CDOguide` for the details of the algorithm (*remapcon* operator).

**CMIP5** data have been interpolated to the 2 degree common grid (reference-grids/land_sea_mask_2degree_binary.nc4)
with *AtlasCDOremappeR_CMIP.sh*(datasets-interactive-atlas/bash-interpolation-scripts/AtlasCDOremappeR_CMIP.sh)

**CMIP6** data have been interpolated to the 1 degree common grid (reference-grids/land_sea_mask_1degree_binary.nc4), 
atmospheric data with *AtlasCDOremappeR_CMIP.sh*(datasets-interactive-atlas/bash-interpolation-scripts/AtlasCDOremappeR_CMIP.sh) and 
the outputs from the ocean models *AtlasCDOremappeR_CMIP6_Omon.sh*(datasets-interactive-atlas/bash-interpolation-scripts/AtlasCDOremappeR_CMIP6_Omon.sh).

**CORDEX** data have been interpolated to the 0.5 degree common grid (reference-grids/land_sea_mask_05degree.nc4) 
with *AtlasCDOremapperR_CORDEX*(datasets-interactive-atlas/bash-interpolation-scripts/AtlasCDOremappeR_CORDEX/AtlasCDOremappeR_CORDEX.sh).

CMIP atmospheric variables are interpolated not using land-sea correction (LSMAS=0). CORDEX interpolation follow guidelines for the interpolation coordinated within the CORDEX community.

Certain model grids from the models in CORDEX experiment were missing information on the coordinates of the grid corners for each grid cell - necessary for the conservative interpolation (e.g. ALADIN, ALARO, NCAR-WRF and RegCM4). In such cases a python script [grid_bounds_calc.py](./AtlasCDOremappeR_CORDEX/grid_bounds_calc.py) provided by Cécile Caillaud and Samuel Somot from Meteo France was used to fill the info gap.

## References
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