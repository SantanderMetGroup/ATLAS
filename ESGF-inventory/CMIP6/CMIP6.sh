#!/bin/bash

query="project=CMIP6 activity_id=CMIP,ScenarioMIP experiment_id=historical,esm-hist,ssp126,ssp245,ssp370,ssp585,ssp460 table_id=Amon,fx frequency=fx,mon variable_id=sftlf,pr,tas,tasmin,tasmax"
fields="master_id,variable,size"

to_inventory() {
	jq --slurp '
		map(. + { dataset_id: (.master_id|split(".")|del(.[6,7])|join(".")),master_id}) |
		group_by(.dataset_id) |
		map(reduce .[] as $item ({variables: []}; {dataset_id: $item.dataset_id, variables: (.variables + $item.variable)}))' | jq -r '
		map({	dataset_id,
				tasmax: .variables|join(" ")|test("\\btasmax\\b"),
				tasmin: .variables|join(" ")|test("\\btasmin\\b"),
				tas: .variables|join(" ")|test("\\btas\\b"),
				pr: .variables|join(" ")|test("\\bpr\\b"),
				sftlf: .variables|join(" ")|test("\\bsftlf\\b")})' | jq -r '
		(map(keys) | add | unique) as $cols |
		map(. as $row | $cols | map($row[.])) as $rows |
		$cols, $rows[] |@csv' 
}

../esgf-search -f $fields $query table_id=Amon,fx frequency=fx,mon | to_inventory > CMIP6Amon.csv
../esgf-search -f $fields $query table_id=day,fx frequency=fx,day | to_inventory > CMIP6.csv
