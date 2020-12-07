#!/bin/bash

set -u

esgf_utils="../../esgf-utils"
database="../CMIP6.json"

# This is needed to filter from ../CMIP6_day_1run.csv
awk -F, '
NR>1 && NF>2 {
  gsub("\"", "", $1)
  sub("\\.(gn|gr|gr[0-9]+)$", "", $1)
  printf("%s\n", $1)
}' ../CMIP6_day_1run.csv > master_ids

# For daily and tos (monthly) we want to filter as specified in ../CMIP6_day_1run.csv
jq 'select(((.variable_id|first == ("pr", "tas" ,"tasmin", "tasmax", "psl")) and (.frequency|first == "day")) or (.variable_id|first == "tos"))' $database | \
  jq --rawfile master_ids master_ids '
      ($master_ids|split("\n")[0:-1]) as $master_ids_list |
      select( (.master_id|split(".")[:6]|join(".")) == $master_ids_list[] )' | ${esgf_utils}/esgf-aria2c > CMIP6_atmos_day.aria
jq 'select(.table_id|first == "Amon") |
    select(.realm|first == "atmos") |
    select(.variable|first == ("pr", "tas" ,"tasmin", "tasmax", "psl", "sfcWind"))' ${database} | ${esgf_utils}/esgf-aria2c > CMIP6_atmos_mon.aria
jq 'select(.table_id|first == "fx")' ${database} | ${esgf_utils}/esgf-aria2c > CMIP6_fx.aria
jq 'select(.variable|first == ("ph", "o2"))' ${database} | ${esgf_utils}/esgf-aria2c > CMIP6_ocean_mon.aria
jq 'select(.variable|first == "siconc")' ${database} | ${esgf_utils}/esgf-aria2c > CMIP6_seaIce_mon.aria
jq 'select(.realm|first == "land")|select(.variable|first == ("snc", "snd", "snw", "snm", "mrso", "mrro"))' ${database} | ${esgf_utils}/esgf-aria2c > CMIP6_land_mon.aria

# This is how to generate selection files from CMIP6_day_1run.csv, here just for reference
#awk -F, '
#NR==1 {
#  variables=gensub(/"/, "", "g")
#  sub("dataset_id,size,", "", variables)
#}
#
#NR<3 || NF<3 {
#  next
#}
#
#{
#  id=gensub(/"/, "", "g", $1)
#  nfacets=split(id, facets, ".")
#
#  printf("project=%s\n", facets[1])
#  printf("activity_id=%s\n", facets[2])
#  printf("institution_id=%s\n", facets[3])
#  printf("source_id=%s\n", facets[4])
#  printf("experiment_id=%s\n", facets[5])
#  printf("member_id=%s\n", facets[6])
#  printf("grid_label=%s\n", facets[7])
#  printf("table_id=day\n")
#  printf("variable_id=%s\n", variables)
#  printf("latest=True type=File\n\n")
#}
#' ../CMIP6_day_1run.csv > selection.day
#
#sed -e 's/variable_id=.*/variable_id=tos/' -e 's/table_id=day/frequency=mon/' selection.day > selection.tos
