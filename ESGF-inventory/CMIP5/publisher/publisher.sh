#!/bin/bash
#PBS -N cmip5
#PBS -l nodes=4:ppn=1
#PBS -l pmem=4Gb
#PBS -q tlustre
#PBS -M cimadevillae@unican.es

set -u

trap exit SIGINT SIGKILL

PROJECT=/oceano/gmeteo/WORK/zequi/ATLAS/ESGF-inventory/
WORKDIR=${PROJECT}/CMIP5/publisher
PYTHONPATH=${PROJECT}/publisher
publisher=${PROJECT}/publisher
cd $WORKDIR

echo $HOSTNAME > nodes
if [ -n "$PBS_NODEFILE" ]; then
    sort -u $PBS_NODEFILE > nodes
fi

# Not before because of PBS_NODEFILE
set -u

hdfs_raw=${WORKDIR}/hdfs/raw
variables='time,x,y,lat,lon,rlat,rlon,lon_bnds,lat_bnds'
drs='.*/([^_]*)_([^_]*)_([^_]*)_([^_]*)_([^_]*)_?(([0-9]+)-([0-9]+))?\.nc'
facets='variable,frequency,model,experiment,ensemble,period,period1,period2'

hdfs_processed=${WORKDIR}/hdfs/processed
group_time='project_id,product,institute_id,model_id,experiment_id,frequency,modeling_realm,table_id_facet,_DRS_ensemble'
drs_hdf="${hdfs_processed}/CMIP5_{product}_{institute_id}_{model_id}_{experiment_id}_{_synthetic_frequency}_{modeling_realm}_{table_id_facet}_{_synthetic__DRS_ensemble}.hdf"

tds_content=../../tds-content
datasetRoot=devel/atlas
ncmls=${tds_content}/public/ethz-snapshot

catalogs=${tds_content}/devel/atlas/ethz-snapshot
root_catalog=${tds_content}/devel/atlas/ethz-snapshot.xml

# todf.py (I've got a copy in $WORK/ethz-snapshot)
parallel --gnu -j4 --slf nodes --workdir ${WORKDIR} "
    grep /{}/ ethz-snapshot.inventory | \
      python ${publisher}/todf.py -v ${variables} --drs \"${drs}\" --facets ${facets} ${hdfs_raw}/{}.hdf" ::: historical rcp26 rcp45 rcp85

# cmip5.py
parallel --gnu -j4 --slf nodes --workdir ${WORKDIR} "
  echo '* cmip5.py on {}' >&2
  PYTHONPATH=${PYTHONPATH} python cmip5.py --lon-180 -d "${drs_hdf}" --group-time ${group_time} {}" ::: ${hdfs_raw}/historical.hdf ${hdfs_raw}/rcp26.hdf ${hdfs_raw}/rcp45.hdf ${hdfs_raw}/rcp85.hdf

# NcMLs
# I use a bad drs but I've to use it for backwards compatibility
rm -rf ${ncmls}
find ${hdfs_processed} -type f | grep -v _mon_ | parallel --gnu --workdir $(pwd) "
    python \"${publisher}\"/jdataset.py -d \"${ncmls}/cmip5/{_DRS_experiment}/{_DRS_experiment}_{_synthetic_frequency}_{_DRS_model}_{_synthetic__DRS_ensemble}.ncml\" -t templates/cmip5.ncml.j2 {}"

# Catalog
ref() {
    echo '  <catalogRef xlink:title="'"$title"'" xlink:href="'$href'" name="">'
    echo '    <dataSize units="bytes">'"$size"'</dataSize>'
    echo '    <date type="modified">'"$last_modified"'</date>'
    echo '  </catalogRef>' 
    echo ''
}

dataset() {
    echo '  <dataset name="'$name'"'
    echo '      ID="'$datasetRoot'/'$basepath'"'
    echo '      urlPath="'$datasetRoot'/'$basepath'">'
    echo '    <metadata inherited="true">'
    echo '      <serviceName>virtual</serviceName>'
    echo '      <dataSize units="bytes">'"$size"'</dataSize>'
    echo '      <date type="modified">'"$last_modified"'</date>'
    echo '    </metadata>'
#    echo '    <netcdf xmlns="http://www.unidata.ucar.edu/namespaces/netcdf/ncml-2.2"'
#    echo '            location="content/'$public'" />'
    echo '  </dataset>'
    echo ''
}

init_catalog() {
    cat <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<catalog name="$1"
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

rm -rf ${catalogs}
find ${ncmls} -type f -name '*.ncml' | sort -V | while read ncml
do
    basepath=${ncml#*public/ethz-snapshot/}
    basename=${ncml##*/}
    name=${basename%.ncml}
    last_modified=$(stat --format='%z' "$ncml")
    size=$(sed -n '/attribute name="size"/{s/[^0-9]//g;p}' $ncml)

    drs=$(echo $name | cut -d_ -f"1")
    drs=${drs//_/\/}

    public="ethz-snapshot/${ncml#${ncmls}/}"
    catalog="${catalogs}/${drs}/catalog.xml"

    # Init catalog if it does not exist
    if [ ! -f "$catalog" ]; then
        mkdir -p ${catalogs}/${drs}
        init_catalog ${name} >${catalog}
    fi

    dataset $ncml >>$catalog
done

init_catalog ETHZ-Snapshot >$root_catalog
echo '  <datasetRoot path="'$datasetRoot'" location="content/ethz-snapshot" />' >>$root_catalog
echo '' >>$root_catalog
find ${catalogs} -type f -name '*.xml' | sort -V | while read catalog
do
    # Close catalog
    echo '</catalog>' >>${catalog}
    echo ${catalog}

    href="ethz-snapshot/${catalog#${catalogs}/}"
    title=${href%/catalog.xml}
    title=${title//\//_}
    size=$(awk '/<dataSize units/{gsub("[^0-9]", ""); sum+=$0}END{print sum}' $catalog)
    last_modified=$(stat -c '%y' $catalog)

    ref >>$root_catalog
done
echo '</catalog>' >>$root_catalog
echo $root_catalog
