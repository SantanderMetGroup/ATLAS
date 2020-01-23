BASE_URL='https://esgf-data.dkrz.de/esg-search/search?format=application%2Fsolr%2Bjson&latest=true&replica=false&type=Dataset'
FIELDS="fields=project,product,domain,institute,driving_model,experiment,ensemble,rcm_name,rcm_version,time_frequency,variable,master_id,size,instance_id,url"
LIMIT=10000

# errors
INVALID_HTTP_REQUEST=6
NO_RESULTS=7

print_err() {
    echo "$1" >&2
}

# $1 - query
query_esgf() {
    if ! curl -f -s "${BASE_URL}&${1}&limit=0"&>/dev/null; then
        print_err "Query: ${BASE_URL}&${1}&limit=0"
        print_err 'HTTP invalid request. Exiting...'
        exit "$INVALID_HTTP_REQUEST"
    fi

	local i=0
	local end=$(curl -s "${BASE_URL}&${1}&limit=0" | jq '.response.numFound')
	local pending=$end

    if [ "$end" -eq 0 ]; then
        print_err "No results found. Query: ${BASE_URL}&${1}&limit=0"
        exit "$NO_RESULTS"
    fi

	while [ $pending -gt 0 ]; do
        local current=$(expr $i \* $LIMIT)
		local url="${BASE_URL}&${FIELDS}&${1}&limit=${LIMIT}&offset=${current}"

		print_err "Pending: ${pending}, i=${i}, URL=${url}"
		curl -s "$url" | jq '.response.docs|.[]'
		
		pending=$(expr $pending - $LIMIT)
		let i=i+1
	done
}
