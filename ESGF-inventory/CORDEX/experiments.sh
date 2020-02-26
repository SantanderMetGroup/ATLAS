#!/bin/bash

fields="master_id,experiment,size"

../esgf-search -f $fields project=CORDEX experiment=historical,evaluation,rcp26,rcp45,rcp85 domain=WAS-44,SAM-44 | jq --slurp '
	map(. + { group: (.master_id|split(".")|del(.[5,10])|join(".")),master_id}) |
	group_by(.group) |
	map(reduce .[] as $item ({experiments: []}; {group: $item.group, experiments: (.experiments + $item.experiment)}))' | jq -r '
	map({	group,
			historical: .experiments|join(" ")|test("\\bhistorical\\b"), 
			rcp26: .experiments|join(" ")|test("\\brcp26\\b"),
			rcp45: .experiments|join(" ")|test("\\brcp45\\b"),
			rcp85: .experiments|join(" ")|test("\\brcp85\\b"),
			evaluation: .experiments|join(" ")|test("\\bevaluation\\b")})' | jq -r '
	(map(keys) | add | unique) as $cols |
	map(. as $row | $cols | map($row[.])) as $rows |
	$cols, $rows[] | @csv' | awk -F "," 'BEGIN{OFS=","}{print $2,$3,$1,$4,$5,$6}' >	experiments.csv
