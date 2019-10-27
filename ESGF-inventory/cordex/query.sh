#!/bin/bash

BASE_URL='https://esgf-data.dkrz.de/esg-search/search?format=application%2Fsolr%2Bjson&latest=true&replica=false&type=Dataset'
QUERIES="project=CORDEX&experiment=historical,rcp26,rcp45,rcp85&domain=WAS-44,SAM-44|experiments.csv"

FIELDS="fields=master_id,experiment,size"
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
	query_esgf "${q%|*}" | jq --slurp 'map(. + { group: (.master_id|split(".")|del(.[5,10])|join(".")),master_id})    | group_by(.group)       | map(   reduce .[] as $item ({experiments: []}; {group: $item.group, experiments: (.experiments + $item.experiment)}  )   )'  |jq -r 'map({group, historical: .experiments|join(" ")|test("\\bhistorical\\b"), rcp26: .experiments|join(" ")|test("\\brcp26\\b"), rcp45: .experiments|join(" ")|test("\\brcp45\\b"), rcp85: .experiments|join(" ")|test("\\brcp85\\b")})' | jq -r '(map(keys) | add | unique) as $cols   |     map(. as $row | $cols | map($row[.])) as $rows  |   $cols, $rows[]  |@csv' > ${dest}
done
