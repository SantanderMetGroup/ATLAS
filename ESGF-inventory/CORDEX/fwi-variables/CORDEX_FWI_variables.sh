#!/bin/bash

frequencies="day"
# no hursmin, hussmin, tdps, dpds, wss
variables="hurs,huss,uas,vas,tas,tasmax,ps,psl"

../../esgf-search project=CORDEX product=output time_frequency=${frequencies} variable=${variables} | jq --slurp ' 
	map(. + map_values(arrays|first)) | 
	map(. + {
		group: [
			.project,
			.product,
			.domain,
			.institute,
			.driving_model,
			.experiment,
			.ensemble,
			.rcm_name,
			.rcm_version,
			.time_frequency]|join(".")}) | 
	group_by(.group) | 
	map({group: map(.group)|first,
		variables: map(.variable)}) |
	{ hurs: false, huss: false, uas: false, vas: false, tas: false, tasmax: false, ps: false, psl: false } as $vars |
	map(. + ([{(.variables[]): true}]|reduce .[] as $i ($vars; . + $i))) |
	map(del(.variables)|del(.crs))' | jq -r '
	(map(keys) | add | unique) as $cols |
	map(. as $row | $cols | map($row[.])) as $rows |
	$cols,$rows[] | @csv' |sort -r > cordex_FWI_variables.csv
