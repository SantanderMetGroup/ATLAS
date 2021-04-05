#!/bin/bash

#prefix=/gpfs/projects/meteo/DATA/CORDEX/synda/
prefix=/gpfs/external/IPCC/2018_IPCC/data/CORDEX/interp
dest=datasets

mkdir -p ${dest}
find "${prefix}/EUR-11" -type f | awk -F/ '
BEGIN{
  OFS="/"
}
{
  $NF=""
  $(NF-1)=""
  $(NF-2)=""
  sub(/\/+$/, "")
  print
}' | sort -u | grep -v r0i0p0 | while read d
do
  dataset=${d#${prefix}/}
  dataset=${dataset//\//_}
  find ${d} -type f > ${dest}/${dataset}

  fxs=$(echo ${d} | awk -F/ 'BEGIN{OFS="/"}{$NF="fx";$(NF-3)="r0i0p0";print}')
  if [ -d ${fxs} ] ; then
    find ${fxs} -type f >> ${dest}/${dataset}
  fi
done
