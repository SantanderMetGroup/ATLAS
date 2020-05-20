#!/bin/bash

fields="master_id,variable,size,table_id"
index="esgf-index1.ceda.ac.uk"

to_inventory() {
	jq -r --slurp '
		map(. + { dataset_id: (.master_id|split(".")|del(.[7])|join(".")),master_id}) |
		(map(.variable|first)|unique) as $variables |
		group_by(.dataset_id) |
		map(reduce .[] as $item (
		    ($variables|map({(.): false}) | reduce .[] as $i ({size: 0, variables: []}; . + $i));
		    . + {
					dataset_id: $item.dataset_id,
					size: (.size + $item.size),
					variables: (.variables + $item.variable),
					($item.variable|first): true
				})) |
		(["dataset_id", "size"] + ($variables|sort)) as $keys | $keys, map([.[ $keys[] ]])[] | @csv'
}

one_run() {
  jq --slurp '
    map(. + {
		dataset_id: (.master_id|split(".")|del(.[7])|join(".")),
		dataset_run: (.master_id|split(".")|del(.[5,7])|join(".")) }) |
    group_by(.dataset_id) |
    map({   
        dataset_id: .[0].dataset_id,
        dataset_run: .[0].dataset_run,
        nvariables: length,
        run: (.[0].master_id|split(".")[5]|sub("r";"")|gsub("[ipf]";".")|split(".")|map(tonumber)),
        datasets: .}) |
    group_by(.dataset_run) |
    map({
        dataset_run: .[0].dataset_run,
        runs: .}) |
    map(.runs |= sort_by(-.nvariables, .run)[0]) |
    .[].runs.datasets[]|del(.dataset_id, .dataset_run)'
}

../esgf-search -i "$index" -f $fields selection > CMIP6.json

jq 'select(.table_id|first == "Amon")' CMIP6.json | to_inventory > all_runs/CMIP6_mon.csv
jq 'select(.table_id|first == "day")' CMIP6.json | to_inventory > all_runs/CMIP6_day.csv
jq 'select(.table_id|first == "fx")' CMIP6.json | to_inventory > all_runs/CMIP6_fx.csv

jq 'select(.table_id|first == "Amon")' CMIP6.json | one_run | to_inventory > one_run/CMIP6_mon.csv
jq 'select(.table_id|first == "day")' CMIP6.json | one_run | to_inventory > one_run/CMIP6_day.csv
jq 'select(.table_id|first == "fx")' CMIP6.json | one_run | to_inventory > one_run/CMIP6_fx.csv
