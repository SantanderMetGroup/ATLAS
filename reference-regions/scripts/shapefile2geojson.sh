#!/bin/bash
#
# shapefile2geojson.sh
#
# Copyright (C) 2021 Santander Meteorology Group (http://meteo.unican.es)
#
# This work is licensed under a Creative Commons Attribution 4.0 International
# License (CC BY 4.0 - http://creativecommons.org/licenses/by/4.0)

# Title: Convert shapefiles into geojson
# Description: Convert shapefiles into geojson. Requires GDAL
# Author: M. Garcia-Diez 

#
# Monsoons
#
izipfile="../monsoons_shapefile.zip"
tempdir="/tmp/monsoons/"
unzip ${izipfile} -d ${tempdir}
ifile="${tempdir}"
ofile="../monsoons_regions.geojson"
# Use -segmentize to add extra points between the vertices of the polygons
echo "Transforming ${ifile} to ${ofile}"
ogr2ogr -f "GeoJSON" ${ofile}  ${ifile}
#
# Small islands
#
izipfile="../small-islands_shapefile.zip"
tempdir="/tmp/small_islands/"
unzip ${izipfile} -d ${tempdir}
ifile="${tempdir}"
ofile="../small_islands_regions.geojson"
# Use -segmentize to add extra points between the vertices of the polygons
echo "Transforming ${ifile} to ${ofile}"
ogr2ogr -segmentize 2.5 -f "GeoJSON" ${ofile}  ${ifile}
