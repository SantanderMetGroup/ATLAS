#!/bin/bash

experiments="historical,evaluation,rcp26,rcp45,rcp85"
frequencies="day,fx"
variables="tas,tasmin,tasmax,pr,sftlf,orog,sfcWind,huss,vas,uas,hurs,evspsbl,psl,ps,rsds,rlds,clt"
query="project=CORDEX product=output experiment=${experiments} time_frequency=${frequencies} variable=${variables}"
inventory="CORDEX_variables.csv"

../esgf-search "${query}" | jq -r --slurp --arg variables "${variables}" ' 
	map(. + map_values(arrays|first)) | 
	map(. + { dataset_id: (.master_id|split(".")|del(.[10,11])|join(".")) }) |
	group_by(.dataset_id) | 
	map(reduce .[] as $item (
	    ($variables|split(",")|map({(.): false})|reduce .[] as $i ({size: 0}; . + $i));
	    . + { dataset_id: $item.dataset_id, size: (.size + $item.size), ($item.variable): true } )) |
	(["dataset_id", "size"] + ($variables|split(",")|sort)) as $keys | $keys, map([.[ $keys[] ]])[] | @csv' > ${inventory}
