#!/bin/bash
# Requires GDAL installed
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
