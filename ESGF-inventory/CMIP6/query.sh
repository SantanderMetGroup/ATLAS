#!/bin/bash

BASE_URL='https://esgf-data.dkrz.de/esg-search/search?format=application%2Fsolr%2Bjson&latest=true&replica=false&type=Dataset'
QUERIES="project=CMIP6&activity_id=CMIP,ScenarioMIP&experiment_id=historical,esm-hist,ssp126,ssp245,ssp370,ssp585,ssp460&table_id=Amon,fx&frequency=fx,mon&variable_id=sftlf,pr,tas,tasmin,tasmax|cmip6-mon.csv
project=CMIP6&activity_id=CMIP,ScenarioMIP&experiment_id=historical,esm-hist,ssp126,ssp245,ssp370,ssp585,ssp460&table_id=day,fx&frequency=day,fx&variable_id=sftlf,pr,tas,tasmin,tasmax|cmip6-day.csv"

FIELDS="fields=master_id,variable,size"
FACETS="facets=activity_id,source_id,institution_id,source_type,nominal_resolution,experiment_id,variant_label,grid_label,table_id,frequency,realm,variable_id"

LIMIT=10000

# $1 - query
query_esgf() {
	local i=0
	local end=$(curl -s "${BASE_URL}&${1}&limit=0" | jq '.response.numFound')
	local pending=$end

	while [ $pending -gt 0 ]; do
    	        local current=$(expr $i \* $LIMIT)
		local url="${BASE_URL}&${FIELDS}&${1}&limit=${LIMIT}&offset=${current}&${FACETS}"

		echo "Pending: ${pending}, i=${i}" >&2
		echo $url >&2
		curl -s "$url" | jq '.response.docs|.[]'
		
		pending=$(expr $pending - $LIMIT)
		let i=i+1
	done
}

for q in $QUERIES
do
	dest="${q##*|}"
	query_esgf "${q%|*}" | jq --slurp 'map(. + { dataset_id: (.master_id|split(".")|del(.[6,7])|join(".")),master_id})    | group_by(.dataset_id)       | map(   reduce .[] as $item ({variables: []}; {dataset_id: $item.dataset_id, variables: (.variables + $item.variable)}  )   )'  |jq -r 'map({dataset_id, tasmax: .variables|join(" ")|test("\\btasmax\\b"), tasmin: .variables|join(" ")|test("\\btasmin\\b"), tas: .variables|join(" ")|test("\\btas\\b"), pr: .variables|join(" ")|test("\\bpr\\b"), sftlf: .variables|join(" ")|test("\\bsftlf\\b")})' | jq -r '(map(keys) | add | unique) as $cols   |     map(. as $row | $cols | map($row[.])) as $rows  |   $cols, $rows[]  |@csv' > ${dest}
done