#!/bin/bash

experiments="historical,rcp26,rcp45,rcp85"
query="project=CMIP5 variable=o2,ph time_frequency=mon experiment=${experiments}"

echo 'instance_id,o2,ph,size' > CMIP5Omon.csv
../esgf-search "${query}" | jq --slurp '
	{o2: false, ph: false} as $vars |
	map({instance_id, size, variables: .variable}) |
	map(. + ([{(.variables[]): true}]|reduce .[] as $i ($vars; . + $i))) |
	map({instance_id, size, o2, ph}) |
	sort_by(.instance_id)' | jq -r '
	(map(keys) | add | unique) as $cols |
	map(. as $row | $cols | map($row[.])) as $rows |
	$rows[] | @csv' >> CMIP5Omon.csv
