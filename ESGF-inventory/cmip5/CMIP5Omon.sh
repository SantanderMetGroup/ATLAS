#!/bin/bash

source ../esgf.sh

experiments="historical,rcp26,rcp45,rcp85"
query="project=CMIP5&variable=o2,ph&time_frequency=mon&experiment=${experiments}"
inventory="CMIP5Omon_$(date +%Y-%m-%d).csv"

echo 'instance_id,size,o2,ph' > ${inventory}
query_esgf "${query}" | jq --slurp '
	{o2: false, ph: false} as $vars |
	map({instance_id, size, variables: .variable}) |
	map(. + ([{(.variables[]): true}]|reduce .[] as $i ($vars; . + $i))) |
	map({instance_id, size, o2, ph}) |
	sort_by(.instance_id)' | jq -r '
	(map(keys) | add | unique) as $cols |
	map(. as $row | $cols | map($row[.])) as $rows |
	$rows[] | @csv' >> ${inventory}
