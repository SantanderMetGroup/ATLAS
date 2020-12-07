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

find selections -type f -name '*.selection' -printf "%f\n" | while read f
do
    xargs -a ${esgf_utils}/indexnodes -I{} ${esgf_utils}/esgf-search -i "{}" selections/${f} | jq -c '.' > ${f/%selection/json}
done

databases="CMIP6_fx.json CMIP6_ocean_mon.json CMIP6_atmos_mon.json CMIP6_land_mon.json CMIP6_seaIce_mon.json"
for f in ${databases}
do
    to_inventory < ${f} > ${f/%json/csv}
    ${esgf_utils}/esgf-aria2c < ${f} > publisher/${f/%json/aria}
done

# This is needed to filter from ../CMIP6_day_1run.csv
awk -F, '
NR>1 && NF>2 {
  gsub("\"", "", $1)
  sub("\\.(gn|gr|gr[0-9]+)$", "", $1)
  printf("%s\n", $1)
}' CMIP6_day_1run.csv > master_ids

# For daily and tos (monthly) we want to filter as specified in ../CMIP6_day_1run.csv
jq --rawfile master_ids master_ids '
    ($master_ids|split("\n")[0:-1]) as $master_ids_list |
    select( (.master_id|split(".")[:6]|join(".")) == $master_ids_list[] )' CMIP6_atmos_day.json | ${esgf_utils}/esgf-aria2c > CMIP6_atmos_day.aria
