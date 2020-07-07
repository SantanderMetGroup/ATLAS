#!/bin/bash

set -e

ncs=/oceano/gmeteo/WORK/PROYECTOS/2020_C3S_34d/synda/data/cordex
logs=logs
destination=../tds-content
ncmls=${destination}/public
catalogs=${destination}/devel/atlas

mkdir -p logs

# Just for testing purposes
ncmls=tmp/tds-content/public
catalogs=tmp/tds-content/devel/atlas
find $ncs -type f | sed 200q | python ncml.py --adapter CordexNcmlAdapter --dest $ncmls

#find $ncs -type f | python ncml.py --adapter CordexNcmlAdapter --dest $ncmls

find $ncmls -type f | python catalog.py --adapter CordexCatalogAdapter --dest $catalogs
find $catalogs -mindepth 2 -type f | python catalog.py --adapter CordexCatalogAdapter --root --dest ${catalogs}/cordex/catalog.xml
