#!/bin/bash

#SBATCH --job-name=atlas-eur11-ncmls
#SBATCH --ntasks=16
#SBATCH --ntasks-per-node=16
#SBATCH --reservation=meteo_16

trap exit SIGINT SIGKILL

export JOBS_PER_NODE=16
export PROJECT=/gpfs/users/ecimadevilla/atlas/ESGF-inventory
export WORKDIR=${PROJECT}/CORDEX/EUR-11
cd $WORKDIR

# Not before because of SLURM_NODELIST
set -u

publisher="${PROJECT}/publisher"
tds_content="${PROJECT}/tds-content"
root="/gpfs/projects/meteo/DATA/CORDEX/synda"

nc_inventory=inventory_nc
facets="root,Dproject,Dproduct,Ddomain,Dinstitute,Dmodel,Dexperiment,Densemble,Drcm,Drcm_version,Dfrequency,Dvariable,version,variable,domain,model,experiment,ensemble,rcm,rcm_version,frequency,period,period1,period2"
drs="(.*)/([^/]+)/([^/]+)/([^/]+)/([^/]+)/([^/]+)/([^/]+)/([^/]+)/([^/]+)/([^/]+)/([^/]+)/([^/]+)/v([^/]+)/([^_]+)_([^_]+)_([^_]+)_([^_]+)_([^_]+)_([^_]+)_([^_]+)_([^_]+)_?(([0-9]+)-([0-9]+))?\.nc"
coordinates="time,x,lon,rlon,lon_bnds,y"
facets_numeric="version,period1,period2"

hdfs_raw=inventory_raw
hdfs_inventory=inventory_hdfs
hdfs="${WORKDIR}/hdfs/CORDEX_{_DRS_Dproduct}_{_DRS_domain}_{_DRS_model}_{_DRS_experiment}_{_DRS_ensemble}_{_DRS_rcm}_{_DRS_rcm_version}_day.hdf"

ncmls_inventory=inventory_ncmls
ncmls="/gpfs/external/IPCC/OCEANO_BACKUP/oceano/gmeteo/WORK/PROYECTOS/2020_C3S_34d/tds/content/thredds/public/cordex/output/{_DRS_domain}/{_DRS_Dinstitute}/{_DRS_model}/{_DRS_experiment}/{_DRS_rcm}/{_DRS_rcm_version}/{_DRS_Dfrequency}/CORDEX_{_DRS_Dproduct}_{_DRS_domain}_{_DRS_model}_{_DRS_experiment}_{_DRS_ensemble}_{_DRS_rcm}_{_DRS_rcm_version}_{_DRS_Dfrequency}.ncml"
template="${WORKDIR}/cordex.ncml.j2"

# todf.py
find datasets -type f | parallel --gnu --group -j$JOBS_PER_NODE --workdir ${WORKDIR} "
  echo '* todf.py on  {}' >&2
  python -W ignore ${publisher}/todf.py -f {} \
    --drs \"$drs\" \
    -v $coordinates \
    --facets $facets \
    --facets-numeric $facets_numeric \
    ${hdfs}" | tee ${hdfs_raw}

# cordex.py
parallel --gnu --group -a ${hdfs_raw} -j$JOBS_PER_NODE --workdir ${WORKDIR} "
  echo '* cordex.py on {}' >&2
  PYTHONPATH=${publisher} python cordex.py {} {}" | tee ${hdfs_inventory}

# jdataset.py
parallel --gnu --group -a ${hdfs_inventory} -j$JOBS_PER_NODE --workdir ${WORKDIR} "
  echo '* jdataset.py on {}' >&2
  python ${publisher}/jdataset.py -t $template -d \"${ncmls}\" {}" | tee ${ncmls_inventory}
