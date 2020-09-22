#!/bin/bash
#PBS -N cmip6
#PBS -l nodes=3:ppn=4
#PBS -q tlustre
#PBS -M cimadevillae@unican.es

#quitando el apply os.splitext
#--drs 'Dproject,Dproduct,Dinstitution,Dmodel,Dexperiment,Densemble,Dtable,Dvariable,Dgrid,version,variable,table,model,experiment,ensemble,grid,period1,period2,extension' --drs-sep '([-a-zA-Z0-9]+)/([-a-zA-Z0-9]+)/([-a-zA-Z0-9]+)/([-a-zA-Z0-9]+)/([-a-zA-Z0-9]+)/([-a-zA-Z0-9]+)/([-a-zA-Z0-9]+)/([-a-zA-Z0-9]+)/([-a-zA-Z0-9]+)/([-a-zA-Z0-9]+)/([-a-zA-Z0-9]+)_([-a-zA-Z0-9]+)_([-a-zA-Z0-9]+)_([-a-zA-Z0-9]+)_([-a-zA-Z0-9]+)_([-a-zA-Z0-9]+)_?([0-9]+)?-?([0-9]+)?'

trap exit SIGINT SIGKILL

export JOBS_PER_NODE=4
export WORKDIR=/oceano/gmeteo/WORK/zequi/atlas-cmip6/data-management/issues/8/publisher
cd $WORKDIR

if [ -n "$PBS_NODEFILE" ]; then
    sort -u $PBS_NODEFILE > nodes
fi

# Not before because of PBS_NODEFILE
set -u

ncs=/oceano/gmeteo/DATA/ESGF/REPLICA/DATA
content=/oceano/gmeteo/WORK/zequi/atlas-cmip6/tds-content
ncmls=${content}/public
catalogs=${content}/devel/atlas

publisher="${WORK}/publisher"
hdfs=hdfs

rm -rf $hdfs/*
mkdir -p $hdfs/{raw,processed}

# Ignore non downloaded or downloaded files with errors
awk -F"=" '/out=/{print "'$ncs'/"$2}' ../inventories/{day,mon,fx}.aria > ../inventories/inventory
parallel --gnu -a ../inventories/inventory -j$JOBS_PER_NODE --slf nodes --wd $WORKDIR "../../../esgf-check {}" > check

# Remove errors from inventory
awk '
/out=/{
    split($0, parts, "=")
    print "'$ncs'/"parts[2]
}
$1=="ERROR"{
    print $3
}' ../inventories/{day,mon,fx}.aria check | sort | uniq -u > inventory

# Inputs file for parallel
awk -F/ '
{
  f=$0
  printf "'$ncs'/%s/%s/%s/%s/%s/%s %s_%s_%s_%s_%s_%s\n", $8, $9, $10, $11, $12, $13, $8, $9, $10, $11, $12, $13
}' inventory | sort -u > inputs

# Dataframes
parallel -a inputs --gnu -j$JOBS_PER_NODE --slf nodes --wd $WORKDIR --joblog joblog --colsep " " "
    echo '* HDF5 for {1}'
    grep {1} inventory | python ${publisher}/todf.py ${hdfs}/raw/{2}.hdf
    echo '* Processing CMIP6 for ${hdfs}/raw/{2}.hdf'
    python ${publisher}/contrib/esgf/cmip6.py --dest ${hdfs}/processed/{_drs_filename}.hdf ${hdfs}/raw/{2}.hdf"

# NcMLs
rm -rf $ncmls/CMIP6
find $hdfs/processed -type f | grep -v 'CESM2-WACCM' | parallel --gnu -j$JOBS_PER_NODE --slf nodes --wd $WORKDIR "echo '* NcML for {}'; python ${publisher}/jdataset.py -t templates/cmip6.ncml.j2 --dest ${ncmls}/{_drs}.ncml {}"

## different template because of time:coordinates
find $hdfs/processed -type f | grep 'CESM2-WACCM' | parallel --gnu -j$JOBS_PER_NODE --slf nodes --wd $WORKDIR "echo '* NcML for {}'; python ${publisher}/jdataset.py -t templates/CESM2-WACCM.cmip6.ncml.j2 --dest ${ncmls}/{_drs}.ncml {}"

# Catalogs
ref() {
    echo '  <catalogRef xlink:title="'"$title"'" xlink:href="'$href'" name="">'
    echo '    <dataSize units="bytes">'"$size"'</dataSize>'
    echo '    <date type="modified">'"$last_modified"'</date>'
    echo '  </catalogRef>' 
    echo ''
}

dataset() {
    echo '  <dataset name="'$name'"'
    echo '      ID="devel/atlas/'$drs'/'$name'"'
    echo '      urlPath="devel/atlas/'$drs'/'$name'">'
    echo '    <metadata inherited="true">'
    echo '      <serviceName>virtual</serviceName>'
    echo '      <dataSize units="bytes">'"$size"'</dataSize>'
    echo '      <date type="modified">'"$last_modified"'</date>'
    echo '    </metadata>'
    echo '    <netcdf xmlns="http://www.unidata.ucar.edu/namespaces/netcdf/ncml-2.2"'
    echo '            location="content/'$public'" />'
    echo '  </dataset>'
    echo ''
}

init_catalog() {
  cat <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<catalog name="$drs"
		xmlns="http://www.unidata.ucar.edu/namespaces/thredds/InvCatalog/v1.0"
		xmlns:xlink="http://www.w3.org/1999/xlink">

  <service name="virtual" serviceType="Compound" base="">
    <service base="/thredds/dodsC/" name="odap" serviceType="OpenDAP"/>
    <service base="/thredds/dap4/" name="dap4" serviceType="DAP4" />
    <service base="/thredds/wcs/" name="wcs" serviceType="WCS" />
    <service base="/thredds/wms/" name="wms" serviceType="WMS" />
    <service base="/thredds/ncss/grid/" name="ncssGrid" serviceType="NetcdfSubset" />
    <service base="/thredds/ncss/point/" name="ncssPoint" serviceType="NetcdfSubset" />
    <service base="/thredds/cdmremote/" name="cdmremote" serviceType="CdmRemote" />
    <service base="/thredds/cdmrfeature/grid/" name="cdmrFeature" serviceType="CdmrFeature" />
    <service base="/thredds/iso/" name="iso" serviceType="ISO" />
    <service base="/thredds/ncml/" name="ncml" serviceType="NCML" />
    <service base="/thredds/uddc/" name="uddc" serviceType="UDDC" />
  </service>
EOF
}

# Remove existing catalogs
rm -rf $catalogs/CMIP6

# Insert datasets into catalogs
find $ncmls/CMIP6 -type f | sort -V | while read ncml
do
    basename=${ncml##*/}
    name=${basename%.ncml}
    last_modified=$(stat --format='%z' "$ncml")
    size=$(sed -n '/attribute name="size"/{s/[^0-9]//g;p}' $ncml)
    
    drs=$(echo $name | cut -d_ -f1-5,7-)
    drs=${drs//_/\/}
    
    public=${ncml#${ncmls}/}
    catalog="${catalogs}/${drs}/catalog.xml"

    if [ ! -f "$catalog" ]; then
        mkdir -p ${catalogs}/${drs}
        init_catalog >${catalogs}/${drs}/catalog.xml
    fi

    dataset >> $catalog
done

# Close catalogs
find $catalogs/CMIP6 -type f | while read catalog
do
    echo '</catalog>' >> $catalog
    echo $catalog
done

# Generate root catalog
root="${catalogs}/cmip6.xml"
cat > ${root} <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<catalog name="CMIP6"
		xmlns="http://www.unidata.ucar.edu/namespaces/thredds/InvCatalog/v1.0"
		xmlns:xlink="http://www.w3.org/1999/xlink">

EOF

find $catalogs -mindepth 3 -type f | sort -V | while read catalog
do
    title=${catalog%/catalog.xml}
    title=${title#*tds-content/devel/atlas/}
    title=${title//\//_}
    size=$(sed -n "/dataSize/{s/[^0-9]//g;p}" $catalog | awk '{sum+=$0}END{print sum}')
    last_modified=$(stat --format='%z' $catalog)
    
    href="${title//_//}/catalog.xml"
    ref >> $root
done

echo '</catalog>' >> $root
echo $root
