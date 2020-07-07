#!/bin/bash

awk -F, '
NF>0 && NR>1{
  gsub("\"", "", $1)
  print $1
}' CMIP6_day_1run.csv | awk -F. '
BEGIN{
  printf("name,type,url,dicname\n")
}
{
  template="%s_%s_%s_%s_%s_%s_day,projection,https://data.meteo.unican.es/thredds/dodsC/devel/atlas/cmip6/%s/%s/%s/%s/day/cmip6_%s_%s_%s_%s_%s_day,CMIP6.dic\n"
  printf(template, $1, $2, $3, $4, $5, $6, $2, $3, $4, $5, $2, $3, $4, $5, $6)
}' > datasets_CMIP6_1run.txt

awk -F, '
NF>0 && NR>1{
  gsub("\"", "", $1)
  print $1
}' CMIP6_mon.csv | awk -F. '
BEGIN{
  printf("name,type,url,dicname\n")
}
{
  template="%s_%s_%s_%s_%s_%s_Amon,projection,https://data.meteo.unican.es/thredds/dodsC/devel/atlas/cmip6/%s/%s/%s/%s/Amon/cmip6_%s_%s_%s_%s_%s_Amon,CMIP6Amon.dic\n"
  printf(template, $1, $2, $3, $4, $5, $6, $2, $3, $4, $5, $2, $3, $4, $5, $6)
}' > datasets_CMIP6Amon.txt
