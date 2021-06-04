#!/bin/bash

frequencies="day"
# no hussmin, dpds, wss
variables="hurs,hursmin,huss,uas,vas,tas,tasmax,ps,psl,tdps,zg"
query="project=CMIP6 frequency=${frequencies} variable=${variables}"

../../esgf-search "${query}" | jq --slurp ' 
	map(. + map_values(arrays|first)) | 
    map(. + {group: (.master_id|split(".")|del(.[6,7])|join("."))} ) |
	group_by(.group) | 
	map({group: map(.group)|first,
		variables: map(.variable)}) |
	{ hurs: false, huss: false, uas: false, vas: false, tas: false, tasmax: false, ps: false, psl: false, tdps: false, zg: false, hursmin: false } as $vars |
	map(. + ([{(.variables[]): true}]|reduce .[] as $i ($vars; . + $i))) |
	map(del(.variables)|del(.crs))' | jq -r '
	(map(keys) | add | unique) as $cols |
	map(. as $row | $cols | map($row[.])) as $rows |
	$cols,$rows[] | @csv' |sort -r > cmip6_FWI_variables.csv
