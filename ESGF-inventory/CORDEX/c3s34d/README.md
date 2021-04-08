# 8 April 2021

I was requested to download AT IFCA additional variables from the download we did for c3s34d. Data already downloaded in /oceano must be excluded.

This was the selection file from c3s34d, we only downloaded first 6 variables at that time.

```
project=CORDEX
experiment=historical,evaluation,rcp26,rcp45,rcp85
time_frequency=day,fx
variable=tas,tasmin,tasmax,pr,sftlf,orog,sfcWind,huss,vas,uas,hurs,evspsbl,psl,ps,rsds,rlds,clt
domain=AFR-22,AFR-44,ANT-44,ARC-44,AUS-22,AUS-44,CAM-22,CAM-44,CAS-22,CAS-44,EAS-22,EAS-44,EUR-11,EUR-22,EUR-44,MED-11,MNA-22,MNA-44,NAM-11,NAM-22,NAM-44,SAM-20,SAM-22,SAM-44,SEA-22,WAS-22,WAS-44
data_node!=data.meteo.unican.es
type=File latest=True distrib=False
```

Already existing variables can be obtained from /oceano using `find /oceano/gmeteo/DATA/ESGF/REPLICA/DATA/cordex -mindepth 10 -maxdepth 10 -type d -printf '%P\n' | sort -u | sed -i 's|/|.|g' > existing`.
It is requested to download only models for which `tas` is already downloaded in /oceano `find /oceano/gmeteo/DATA/ESGF/REPLICA/DATA/cordex -mindepth 10 -maxdepth 10 -type d -printf '%P\n' | awk -F/ '$NF=="tas"' | sort -u | sed -e 's|/|.|g' -e 's|\.tas||' > tas`.

Generate aria file:

```
../../esgf-utils/esgf-search selection | jq -c '.' > esgf
grep -v -f existing -F esgf | grep -F -f tas | ../../esgf-utils/esgf-aria2c > download.aria
```
