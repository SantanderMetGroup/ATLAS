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

# Generate csv inventories, one invetory per time_frequency
jq 'select(.replica|not)|select(.time_frequency|first != "fx")' CORDEX.json | to_inventory > CORDEX_day.csv
jq 'select(.replica|not)|select(.time_frequency|first == "fx")' CORDEX.json | to_inventory > CORDEX_fx.csv

# We only want to download specific domains and variables
domains='["SAM-20","SAM-44","SAM-22","CAM-44","CAM-22","NAM-11","NAM-22","NAM-44","AFR-22","AFR-44","WAS-22","WAS-44","EAS-22","EAS-44","CAS-22","CAS-44","AUS","AUS-22","AUS-44","ANT-44","ARC-44","SEA-22","MNA-22","MNA-44"]'
variables='["pr","tas","tasmax","tasmin","huss","scfWind","sftlf","orog"]'

# ../esgf-metalink < CORDEX.json > metalink # This would generate the metalink for all files in inventory
jq --argjson variables $variables --argjson domains $domains '
  select(.variable|first|IN($variables[])) |
  select(.domain|first|IN($domains[]))' CORDEX.json | ../esgf-metalink > metalink

# We create a directory to hold all metalinks
mkdir -p metalinks

# Data from esg-dn1.ru.ac.th is commercial
sed -n '1{p}; ${p}; /<file name/{h;n}; H; /<\/file>/{x; /esg-dn1.ru.ac.th/{p}}' metalink > metalinks/esg-dn1.ru.ac.th.metalink

# Data from esgf-ictp.hpc.cineca.it has incorrect size on the server so we remove <size> element from metalink
sed -n '1{p}; ${p}; /<file name/{h;n}; H; /<\/file>/{x; /esgf-ictp.hpc.cineca.it/{s|<size>.*</size>||;p}}' metalink > metalinks/esgf-ictp.hpc.cineca.it.metalink

# Remove all previous cases from general metalink
sed -n '1{p}; ${p}; /<file name/{h;n}; /\(esg-dn1.ru.ac.th\|esgf-ictp.hpc.cineca.it\)/,/<\/file>/{x;d}; H; /<\/file>/{x;p}' metalink > metalinks/all.metalink
