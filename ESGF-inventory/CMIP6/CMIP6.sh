#!/bin/bash

fields="master_id,variable,size,table_id"
variables=$(awk -F"=" '/variable_id/{print $2}' selection | paste -sd,)
index="esgf-index1.ceda.ac.uk"

to_inventory() {
	jq -r --slurp --arg variables "${variables}" '
		map(. + { dataset_id: (.master_id|split(".")|del(.[6,7])|join(".")),master_id}) |
		group_by(.dataset_id) |
		map(reduce .[] as $item (
		    ($variables|split(",")|map({(.): false}) | reduce .[] as $i ({size: 0, variables: []}; . + $i));
		    . + {
					dataset_id: $item.dataset_id,
					size: (.size + $item.size),
					variables: (.variables + $item.variable),
					($item.variable|first): true
				})) |
		map(select( ((.variables|length == 1) and (.variables[0] == "sftlf"))|not )) |
		(["dataset_id", "size"] + ($variables|split(",")|sort)) as $keys | $keys, map([.[ $keys[] ]])[] | @csv'
}

../esgf-search -i "$index" -f $fields selection > CMIP6.json

jq 'select((.table_id|first == "Amon") or (.table_id|first == "fx"))' CMIP6.json | to_inventory > CMIP6_mon.csv
jq 'select((.table_id|first == "day") or (.table_id|first == "fx"))' CMIP6.json | to_inventory > CMIP6_day.csv
