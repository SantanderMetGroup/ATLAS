#!/bin/bash

experiments="historical,evaluation,rcp26,rcp45,rcp85"
frequencies="day,fx"
variables="tas,tasmin,tasmax,pr,sftlf,orog,sfcWind,huss,vas,uas,hurs,evspsbl,psl,ps,rsds,rlds,clt"
query="project=CORDEX product=output experiment=${experiments} time_frequency=${frequencies} variable=${variables} replica=False latest=True"

../esgf-search -i "esgf-node.llnl.gov" -q "${query}" > CORDEX.json

to_inventory() {
	jq -r --slurp '
		map(. + map_values(arrays|first)) |
		(map(.variable)|unique) as $variables |
	
		map(. + { dataset_id: (.master_id|split(".")|del(.[10,11])|join(".")) }) |
		group_by(.dataset_id) |
		map(reduce .[] as $item (
		    ($variables|map({(.): false})|reduce .[] as $i ({size: 0}; . + $i));
		    . + { dataset_id: $item.dataset_id, size: (.size + $item.size), ($item.variable): true } )) |
		(["dataset_id", "size"] + ($variables|sort)) as $keys | $keys, map([.[ $keys[] ]])[] | @csv'
}

jq 'select(.time_frequency|first != "fx")' CORDEX.json | to_inventory > CORDEX_day.csv
jq 'select(.time_frequency|first == "fx")' CORDEX.json | to_inventory > CORDEX_fx.csv
