#!/bin/bash

variables="sftlf,pr,tas,tasmin,tasmax,psl"
query="project=CMIP6 activity_id=CMIP,ScenarioMIP experiment_id=historical,esm-hist,ssp126,ssp245,ssp370,ssp585,ssp460 variable_id=${variables}"
fields="master_id,variable,size"

to_inventory() {
	jq -r --slurp --arg variables "${variables}" '
		map(. + { dataset_id: (.master_id|split(".")|del(.[6,7])|join(".")),master_id}) |
		group_by(.dataset_id) |
		map(reduce .[] as $item (
		    ($variables|split(",")|map({(.): false})|reduce .[] as $i ({size: 0}; . + $i));
		    . + { dataset_id: $item.dataset_id, size: (.size + $item.size), ($item.variable|first): true } )) |
		(["dataset_id", "size"] + ($variables|split(",")|sort)) as $keys | $keys, map([.[ $keys[] ]])[] | @csv'
}

../esgf-search -i "esgf-node.llnl.gov" -f $fields $query table_id=Amon,fx frequency=fx,mon | to_inventory > CMIP6Amon.csv
../esgf-search -i "esgf-node.llnl.gov" -f $fields $query table_id=day,fx frequency=fx,day | to_inventory > CMIP6day.csv
