#!/bin/bash

set -u

trap exit SIGINT SIGKILL

esgf_utils="../esgf-utils"

#fields="master_id,variable,size,table_id,id,instance_id,url,checksum,checksum_type,replica"

# first I group by checksum to pick only one replica of every file
# I could group by instance_id but that field often contains bad data... (I hope checksums are OK)
# DON'T use select(.replica|not) because some files are published only as replicas and original was removed
to_inventory() {
    jq -r --slurp '
        group_by(.checksum) | map(sort_by(.replica)|first) |
        map(. + { dataset_id: (.master_id|split(".")[:9]|del(.[7])|join(".")),master_id}) |
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
        dataset_id: (.master_id|split(".")[:9]|del(.[7])|join(".")),
        dataset_run: (.master_id|split(".")[:9]|del(.[5,7])|join(".")) }) |
    group_by(.dataset_id) |
    map({dataset_id: .[0].dataset_id,
        dataset_run: .[0].dataset_run,
        nvariables: map(.variable|first)|unique|length,
        run: (.[0].dataset_id|split(".")[5]|sub("r";"")|gsub("[ipf]";".")|split(".")|map(tonumber)),
        datasets: .}) |
    group_by(.dataset_run) |
    map({
        dataset_run: .[0].dataset_run,
        runs: .}) |
    map(.runs |= sort_by(-.nvariables, .run)[0]) |
    .[].runs.datasets[]|del(.dataset_id, .dataset_run)'
}

xargs -a ${esgf_utils}/indexnodes -I{} ${esgf_utils}/esgf-search -i "{}" selection | jq -c '.' > CMIP6.json

jq 'select((.table_id|first == "Amon") and (.variable|first == ("pr", "tas" ,"tasmin", "tasmax", "psl", "sfcWind")))' CMIP6.json | to_inventory > CMIP6_mon.csv
jq 'select(.table_id|first == "day")' CMIP6.json | to_inventory > CMIP6_day.csv
jq 'select(.table_id|first == "fx")' CMIP6.json | to_inventory > CMIP6_fx.csv

# oceanic variables
jq 'select(.variable|first == ("tos", "ph", "o2"))' CMIP6.json | to_inventory > CMIP6_Omon.csv
jq 'select(.variable|first == "siconc")' CMIP6.json | to_inventory > CMIP6_SImon.csv
