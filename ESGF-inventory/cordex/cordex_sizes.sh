#!/bin/bash

source ../esgf.sh

experiments="historical,evaluation,rcp26,rcp45,rcp85"
frequencies="day,fx"

echo -n 'All CORDEX: '
query_esgf "project=CORDEX&product=output&experiment=${experiments}&time_frequency=${frequencies}" 2>/dev/null | jq --slurp 'map(.size)|add' | numfmt --to=iec

echo -n 'Variables tas: '
query_esgf "project=CORDEX&product=output&experiment=${experiments}&time_frequency=${frequencies}&variable=tas" 2>/dev/null | jq --slurp 'map(.size)|add' | numfmt --to=iec

echo -n 'EUR domains (11,22,44): '
query_esgf "project=CORDEX&product=output&experiment=${experiments}&time_frequency=${frequencies}&domain=EUR11,EUR-22,EUR-44" 2>/dev/null | jq --slurp 'map(.size)|add' | numfmt --to=iec
