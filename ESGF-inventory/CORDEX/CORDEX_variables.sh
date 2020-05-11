#!/bin/bash

experiments="historical,evaluation,rcp26,rcp45,rcp85"
frequencies="day,fx"
variables="tas,tasmin,tasmax,pr,sftlf,orog"
query="project=CORDEX product=output experiment=${experiments} time_frequency=${frequencies} variable=${variables}"
inventory="CORDEX_variables.csv"
header="domain,driving_model,experiment,ensemble,rcm_name,rcm_version,group,orog,sftlf,tas,tasmax,tasmin,pr"

echo ${header} > ${inventory}
../esgf-search "${query}" | jq --slurp ' 
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
		domain: map(.domain)|first,
		driving_model: map(.driving_model)|first,
		experiment: map(.experiment)|first,
		ensemble: map(.ensemble)|first,
		rcm_name: map(.rcm_name)|first,
		rcm_version: map(.rcm_version)|first,
		variables: map(.variable)}) |
	{ tas: false, tasmin: false, tasmax: false, pr: false, sftlf: false, orog: false } as $vars |
	map(. + ([{(.variables[]): true}]|reduce .[] as $i ($vars; . + $i))) |
	map(del(.variables)|del(.crs))' | jq -r '
	(map(keys) | add | unique) as $cols |
	map(. as $row | $cols | map($row[.])) as $rows |
	$rows[] | @csv' | awk -F "," 'BEGIN{OFS=","}{print $1,$2,$4,$3,$8,$9,$5,$6,$10,$11,$12,$13,$7}' | sort -t, -k7 >> ${inventory}
