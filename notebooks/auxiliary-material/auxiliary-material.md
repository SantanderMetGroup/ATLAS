(auxiliary-material)=
# Auxiliary Materials for Notebooks

These are auxiliary materials to ease notebook reproducibility, preventing the
dependence on remote data servers for executing some notebook examples
requiring data from outside this repository.

The files you can find here are:

 * NetCDF files as available through ESGF

        CMIP6Amon_tas_CanESM5_r1i1p1f1_historical_gn_185001-201412.nc

 * NetCDF files storing data which can be accessed from the [Santander Meteorology Group UDG-TAP](http://meteo.unican.es/udg-tap/home), 
 but are included here for the sake of time. Instructions to create these objects are nevertheless provided in the corresponding notebooks.
   
        CMIP5_EC-EARTH_r12i1p1_historical_IP_tas-tasmin-tasmax_1986-2005_JJA.nc
        CMIP5_EC-EARTH_r12i1p1_rcp85_IP_tas-tasmin-tasmax_2041-2060_JJA.nc
        W5E5_IP_tas-tasmin-tasmax_1986-2005_JJA.nc
        W5E5_NorthAmerica_pr_1980-2014_yearly.nc4

 * Images used in the notebooks

        geotiff-access-ia.png
        CMIP5 - Mean temperature (T) Change deg C - Long Term (2081-2100) RCP 8.5 1986-2005 - Annual (mean of 29 models).tiff

 * Other small data files. E.g. those providing CORDEX domain boundaries or coastline plotting data.

        regular-CORDEX-grids.csv
        WORLD_coastline.dbf
        WORLD_coastline.prj
        WORLD_coastline.sbn
        WORLD_coastline.sbx
        WORLD_coastline.shp
        WORLD_coastline.shx

<script src="https://utteranc.es/client.js"
        repo="PhantomAurelia/Atlas"
        issue-term="pathname"
        theme="preferred-color-scheme"
        crossorigin="anonymous"
        async>
</script>