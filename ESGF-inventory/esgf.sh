BASE_URL='https://esgf-data.dkrz.de/esg-search/search?format=application%2Fsolr%2Bjson&latest=true&replica=false&type=Dataset'
FIELDS="fields=project,product,domain,institute,driving_model,experiment,ensemble,rcm_name,rcm_version,time_frequency,variable,master_id,size,instance_id"
LIMIT=10000

# $1 - query
query_esgf() {
    if ! curl -f -s "${BASE_URL}&${1}&limit=0"&>/dev/null; then
        echo 'HTTP invalid request. Exiting...' >&2
    fi

	local i=0
	local end=$(curl -s "${BASE_URL}&${1}&limit=0" | jq '.response.numFound')
	local pending=$end

	while [ $pending -gt 0 ]; do
        local current=$(expr $i \* $LIMIT)
		local url="${BASE_URL}&${FIELDS}&${1}&limit=${LIMIT}&offset=${current}"

		echo "Pending: ${pending}, i=${i}" >&2
		echo $url >&2
		curl -s "$url" | jq '.response.docs|.[]'
		
		pending=$(expr $pending - $LIMIT)
		let i=i+1
	done
}

