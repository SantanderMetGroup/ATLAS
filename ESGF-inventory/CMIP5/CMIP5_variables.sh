#!/bin/bash

query="project=CMIP5 experiment=historical,rcp26,rcp45,rcp85 time_frequency=fx,day variable=pr,tas,tasmax,tasmin,sftlf"
fields="master_id,variable,size"

../esgf-search -f $fields $query | jq --slurp -r '
	map({	master_id,
			tasmax: .variable|join(" ")|test("\\btasmax\\b"),
			tasmin: .variable|join(" ")|test("\\btasmin\\b"),
			tas: .variable|join(" ")|test("\\btas\\b"),
			pr: .variable|join(" ")|test("\\bpr\\b"),
			sftlf: .variable|join(" ")|test("\\bsftlf\\b")})' | jq -r '
	(map(keys) | add | unique) as $cols |
	map(. as $row | $cols | map($row[.])) as $rows |
	$cols, $rows[]  |@csv' > cmip5_variables.csv
