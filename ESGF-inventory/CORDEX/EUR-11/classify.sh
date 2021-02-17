#!/bin/bash

prefix=/gpfs/projects/meteo/DATA/CORDEX/synda/
dest=datasets

find_fxs() {
    reference=${1#${prefix}}
    reference=$(echo ${reference} | cut -d/ -f1-9)
    reference=$(echo ${reference} | awk -F/ 'BEGIN{OFS="/"} {$7="r0i0p0"; print}')
    reference=${prefix}${reference}
    
    if [ -d ${reference} ] ; then
        find ${reference} -type f
    fi
}

find ${prefix} -mindepth 10 -maxdepth 10 | while read d
do
    dataset=${d#${prefix}}
    
    # If it is a directory with fx just ignore
    if $(echo ${dataset} | awk -F/ '$10=="fx"{exit(1)}') ; then
        dataset=${dataset//\//_}
        find ${d} -type f > ${dest}/${dataset}
        find_fxs ${d} >> ${dest}/${dataset}
    fi
done
