#!/bin/bash

experiments="historical,evaluation,rcp26,rcp45,rcp85"
frequencies="day,fx"

echo -n 'All CORDEX: '
../esgf-search --fields size project=CORDEX product=output experiment=${experiments} time_frequency=${frequencies} 2>/dev/null | jq --slurp 'map(.size)|add' | numfmt --to=iec

echo -n 'Variables tas: '
../esgf-search --fields size project=CORDEX product=output experiment=${experiments} time_frequency=${frequencies} variable=tas 2>/dev/null | jq --slurp 'map(.size)|add' | numfmt --to=iec

echo -n 'EUR domains (11,22,44): '
../esgf-search --fields size project=CORDEX product=output experiment=${experiments} time_frequency=${frequencies} domain=EUR-11,EUR-22,EUR-44 2>/dev/null | jq --slurp 'map(.size)|add' | numfmt --to=iec
