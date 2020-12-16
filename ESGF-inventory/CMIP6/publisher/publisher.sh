#!/bin/bash
#PBS -N cmip6
#PBS -l nodes=3:ppn=1
#PBS -l pmem=4Gb
#PBS -q tlustre
#PBS -M cimadevillae@unican.es

trap exit SIGINT SIGKILL

export PROJECT=/oceano/gmeteo/WORK/zequi/ATLAS/ESGF-inventory
export PYTHONPATH=${PROJECT}/publisher
export JOBS_PER_NODE=1
export WORKDIR=${PROJECT}/CMIP6/publisher

publisher="${PROJECT}/publisher"
tds_content="${PROJECT}/tds-content"
template="${WORKDIR}/templates/cmip6.ncml.j2"

nc_inventory=${WORKDIR}/inventory
raw_inventory=${WORKDIR}/inventory_raw
hdfs_raw="${WORKDIR}/hdfs/raw/CMIP6_{_DRS_Dactivity}_{_DRS_Dinstitute}_{_DRS_model}_{_DRS_experiment}_{_DRS_ensemble}.hdf"
facets="root,Dproject,Dactivity,Dinstitute,Dmodel,Dexperiment,Densemble,Dtable,Dvariable,Dgrid_label,version,variable,table,model,experiment,ensemble,grid_label,period,period1,period2"
drs="(.*)/([^/]+)/([^/]+)/([^/]+)/([^/]+)/([^/]+)/([^/]+)/([^/]+)/([^/]+)/([^/]+)/v([^/]+)/([^_]+)_([^_]+)_([^_]+)_([^_]+)_([^_]+)_([^_]+)_?(([0-9]+)-([0-9]+))?\.nc"
coordinates="time,x,lon,rlon,lon_bnds,y,i,j,latitude,longitude"
facets_numeric="version,period1,period2"

processed_inventory=inventory_processed
group_grid_label="_DRS_Dproject,_DRS_Dactivity,_DRS_Dinstitute,_DRS_model,_DRS_experiment,_DRS_ensemble,_DRS_Dtable"
group_time="_DRS_Dproject,_DRS_Dactivity,_DRS_Dinstitute,_DRS_model,_DRS_experiment,_DRS_ensemble,_DRS_Dtable,_DRS_grid_label"
group_fx="_DRS_Dproject,_DRS_Dactivity,_DRS_Dinstitute,_DRS_model,_DRS_experiment,_DRS_ensemble,_DRS_grid_label"
hdfs_processed="${WORKDIR}/hdfs/processed/CMIP6_{_DRS_Dactivity}_{_DRS_Dinstitute}_{_DRS_model}_{_DRS_experiment}_{_DRS_ensemble}_{_synthetic_DRS_Dtable}.hdf" 

ncmls_inventory=inventory_ncmls
ncmls="${tds_content}/public/CMIP6/{_DRS_Dactivity}/{_DRS_Dinstitute}/{_DRS_model}/{_DRS_experiment}/{_synthetic_DRS_Dtable}/CMIP6_{_DRS_Dactivity}_{_DRS_Dinstitute}_{_DRS_model}_{_DRS_experiment}_{_DRS_ensemble}_{_synthetic_DRS_Dtable}.ncml"

catalogs="${tds_content}/devel/atlas"
namespace="devel/atlas"
root_catalog="${catalogs}/cmip6.xml"

cd $WORKDIR

echo $HOSTNAME > nodes
if [ -n "$PBS_NODEFILE" ]; then
    sort -u $PBS_NODEFILE > nodes
fi

# Not before because of PBS_NODEFILE
set -u

find /oceano/gmeteo/DATA/ESGF/REPLICA/DATA/CMIP6 -mindepth 5 -maxdepth 5 -type d > directories

# todf.py
parallel --gnu -a directories -j$JOBS_PER_NODE --slf nodes --wd $WORKDIR "
    if grep -q -F {} ${nc_inventory} ; then
        echo '* todf.py on directory {}' >&2
        grep -F {} ${nc_inventory} | python -W ignore ${publisher}/todf.py \
            --drs \"$drs\" \
            -v $coordinates \
            --facets $facets \
            --facets-numeric $facets_numeric \
            ${hdfs_raw}
    fi" | tee ${raw_inventory}

# cmip6.py
parallel --gnu -a ${raw_inventory} -j$JOBS_PER_NODE --slf nodes --wd $WORKDIR "
    echo '* cmip6.py on {}' >&2
    PYTHONPATH=${PYTHONPATH} python cmip6.py \
        --filter-grid-labels ${group_grid_label} \
        --grid-label-col _DRS_grid_label \
        --latest _DRS_version \
        --group-time ${group_time} \
        --group-fx ${group_fx} \
        --dest ${hdfs_processed} {}" | tee ${processed_inventory}

# jdataset.py
parallel --gnu -a ${processed_inventory} -j$JOBS_PER_NODE --slf nodes --wd $WORKDIR "
    echo '* jdataset on {}' >&2
    python -W ignore ${publisher}/jdataset.py -t templates/cmip6.ncml.j2 --dest ${ncmls} {}" | tee ${ncmls_inventory}

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

# Insert datasets into catalogs
sort -V ${ncmls_inventory} | while read ncml
do
    basename=${ncml##*/}
    name=${basename%.ncml}
    last_modified=$(stat --format='%z' "$ncml")
    size=$(sed -n '/attribute name="size"/{s/[^0-9]//g;p}' $ncml)
    
    drs=$(echo $name | cut -d_ -f1-5,7-)
    drs=${drs//_/\/}
    
    public=${ncml#${tds_content}/public}
    catalog="${catalogs}/${drs}/catalog.xml"

    # Init catalog if it does not exist
    if [ ! -f "$catalog" ]; then
        mkdir -p ${catalogs}/${drs}
        init_catalog ${drs//\//_} >${catalogs}/${drs}/catalog.xml
    else
        # Remove dataset if it exists and </catalog> tag
        sed -i -n '/<dataset name="'$name'"/,/<\/dataset>/!{p}' $catalog
        sed -i '/^<\/catalog>$/d' $catalog
    fi

    dataset >> $catalog
done

# Close catalogs
find ${catalogs}/CMIP6 -type f | while read catalog
do
    if ! grep -q -F '</catalog>' $catalog ; then
        echo '</catalog>' >> $catalog
    fi
    # Remove contiguous blank lines
    sed -i '/^$/N;/^\n$/D' $catalog
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

find ${catalogs}/CMIP6 -mindepth 3 -type f | sort -V | while read catalog
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
