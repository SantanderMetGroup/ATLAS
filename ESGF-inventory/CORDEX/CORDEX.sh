#!/bin/bash

../esgf-search -i "esgf-node.llnl.gov" selection > CORDEX.json

to_inventory() {
	jq -r --slurp '
		map(. + map_values(arrays|first)) |
		(map(.variable)|unique) as $variables |
	
		map(. + { dataset_id: (.dataset_id|split("|")[0]|split(".")|del(.[10,11])|join(".")) }) |
		group_by(.dataset_id) |
		map(reduce .[] as $item (
		    ($variables|map({(.): false})|reduce .[] as $i ({size: 0}; . + $i));
		    . + { dataset_id: $item.dataset_id, size: (.size + $item.size), ($item.variable): true } )) |
		(["dataset_id", "size"] + ($variables|sort)) as $keys | $keys, map([.[ $keys[] ]])[] | @csv'
}

jq 'select(.replica|not)|select(.time_frequency|first != "fx")' CORDEX.json | to_inventory > CORDEX_day.csv
jq 'select(.replica|not)|select(.time_frequency|first == "fx")' CORDEX.json | to_inventory > CORDEX_fx.csv

# We only want to download specific domains and variables
domains='["SAM-20","SAM-44","SAM-22","CAM-44","CAM-22","NAM-11","NAM-22","NAM-44","AFR-22","AFR-44","WAS-22","WAS-44","EAS-22","EAS-44","CAS-22","CAS-44","AUS","AUS-22","AUS-44","ANT-44","ARC-44","SEA-22","MNA-22","MNA-44"]'
variables='["pr","tas","tasmax","tasmin","huss","scfWind","sftlf","orog"]'

jq --argjson variables $variables --argjson domains $domains '
  select(.variable|first|IN($variables[])) |
  select(.domain|first|IN($domains[]))' CORDEX.json | ../esgf-metalink > metalink
