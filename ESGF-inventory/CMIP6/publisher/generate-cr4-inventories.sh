#!/bin/bash

set -u

content=/oceano/gmeteo/WORK/zequi/atlas-cmip6/tds-content

echo "name,type,url,dicname" > datasets_CMIP6.txt
find ${content}/devel/atlas/CMIP6 -type f -name catalog.xml | grep -v Amon | sort -V | xargs -I{} awk '
BEGIN{ OFS="" }
/urlPath=/{
  prefix="https://data.meteo.unican.es/thredds/dodsC/"
  drs=gensub(/.*urlPath="(.+)".*/, "\\1", "g")

  nfacets=split(drs, facets, "/")
  filename=facets[nfacets]
  nffacets=split(filename, ffacets, "_")

  printf "%s_%s_%s_%s,projection,%s%s,CMIP6.dic\n", ffacets[1], ffacets[4], ffacets[5], ffacets[6], prefix, drs
}' {} >> datasets_CMIP6.txt

echo "name,type,url,dicname" > datasets_CMIP6Amon.txt
find ${content}/devel/atlas/CMIP6 -type f -name catalog.xml | grep Amon | sort -V | xargs -I{} awk '
BEGIN{ OFS="" }
/urlPath=/{
  prefix="https://data.meteo.unican.es/thredds/dodsC/"
  drs=gensub(/.*urlPath="(.+)".*/, "\\1", "g")

  nfacets=split(drs, facets, "/")
  filename=facets[nfacets]
  nffacets=split(filename, ffacets, "_")

  printf "%sAmon_%s_%s_%s,projection,%s%s,CMIP6Amon.dic\n", ffacets[1], ffacets[4], ffacets[5], ffacets[6], prefix, drs
}' {} >> datasets_CMIP6Amon.txt
