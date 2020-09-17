#!/bin/bash

set -u

trap exit SIGINT SIGKILL

esgf_utils="../esgf-utils"
variables=$(awk 'BEGIN{FS="="} /variable=/{print $2}' selection | paste -sd ",")

# first I group by checksum to pick only one replica of every file
# I could group by instance_id but that field often contains bad data... (I hope checksums are OK)
# DON'T use select(.replica|not) because some files are published only as replicas and original was removed
# DON'T use (map(.variable|first)|unique) as $variables, the .variable field often contains bad data
to_inventory() {
    jq -r --slurp --arg selection_variables $variables '
        group_by(.checksum) | map(sort_by(.replica)|first) |
        map(select(.title|split("_")[0] == ($selection_variables|split(",")[]))) |
        (map(.title|split("_")[0])|unique) as $variables |

        map(. + { parts: (.master_id|split("."))}) |
        map(. + { dataset_id: ( if .parts|length == 10 then .parts[:8]|join(".") else .parts[:9]|join(".") end )}) |
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

xargs -a ${esgf_utils}/indexnodes -I{} ${esgf_utils}/esgf-search -i "{}" selection > CMIP5.json

jq 'select(.variable[] == ["tos", "o2", "ph"][])' CMIP5.json | to_inventory > CMIP5_Omon.csv
jq 'select(.time_frequency|first == "day")' CMIP5.json | to_inventory > CMIP5_day.csv
jq 'select(.time_frequency|first == "fx")' CMIP5.json | to_inventory > CMIP5_fx.csv
