#!/bin/bash

BASE_URL='https://esgf-data.dkrz.de/esg-search/search?format=application%2Fsolr%2Bjson&latest=true&replica=false&type=Dataset'
QUERIES="project=CORDEX&experiment=historical,evaluation,rcp26,rcp45,rcp85&variable=tas&time_frequency=day"

FIELDS="fields=master_id,driving_model,rcm_name,size"
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
	echo "Driving model,RCM,master_id,size" > models.csv
	query_esgf "${q}" | jq --slurp 'map({driving_model: .driving_model|first, rcm: .rcm_name|first, master_id, size})' | jq -r '(map(keys) | add | unique) as $cols | map(. as $row | $cols | map($row[.])) as $rows  |   $cols, $rows[]  |@csv' | awk -F "," 'BEGIN{OFS=","}{print $1,$3,$2,$4}' | sort >> models.csv
done
