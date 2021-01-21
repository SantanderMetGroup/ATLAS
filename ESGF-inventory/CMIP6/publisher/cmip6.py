#!/usr/bin/env python

import os
import sys
import re
import numpy as np
import pandas as pd
import netCDF4
import cftime

import esgf

_help = '''Usage:
    cmip6.py [OPTIONS] DATAFRAME

Options:
    -h, --help                      Show this message and exit.
    -d, --dest DESTINATION          Destination for HDF5 files (default is working directory).

    --variable-col VARIABLE         Column name where the variable is found (default is _DRS_variable).
    --latest VERSION_COLUMN         Column name to identify latest versions.

    --grid-label-col COLUMN         Column that identifies grid_label.
    --filter-grid-labels FACETS     Comma separated facets that group when filtering grid labels.

    --group-time FACETS             Comma separated facets that group time periods of variables.
    --group-fx FACETS               Comma separated facets that, given a group grouped by --group-time, return it's fxs.
'''

# files that need to be removed because they are incorrectly duplicated in ESGF
# or have bad periods in filename or whatever
TO_DROP = [
'/oceano/gmeteo/DATA/ESGF/REPLICA/DATA/CMIP6/CMIP/NCAR/CESM2-WACCM/historical/r1i1p1f1/day/psl/gn/v20190227/psl_day_CESM2-WACCM_historical_r1i1p1f1_gn_18500101-20150101.nc',
'/oceano/gmeteo/DATA/ESGF/REPLICA/DATA/CMIP6/CMIP/NCAR/CESM2/historical/r1i1p1f1/day/psl/gn/v20190308/psl_day_CESM2_historical_r1i1p1f1_gn_18500101-20150101.nc',
'/oceano/gmeteo/DATA/ESGF/REPLICA/DATA/CMIP6/ScenarioMIP/CCCR-IITM/IITM-ESM/ssp126/r1i1p1f1/day/pr/gn/v20200915/pr_day_IITM-ESM_ssp126_r1i1p1f1_gn_20950101-20981231.nc',
'/oceano/gmeteo/DATA/ESGF/REPLICA/DATA/CMIP6/ScenarioMIP/CCCR-IITM/IITM-ESM/ssp126/r1i1p1f1/day/psl/gn/v20200915/psl_day_IITM-ESM_ssp126_r1i1p1f1_gn_20950101-20981231.nc',
'/oceano/gmeteo/DATA/ESGF/REPLICA/DATA/CMIP6/ScenarioMIP/CCCR-IITM/IITM-ESM/ssp126/r1i1p1f1/day/tas/gn/v20200915/tas_day_IITM-ESM_ssp126_r1i1p1f1_gn_20950101-20981231.nc',
'/oceano/gmeteo/DATA/ESGF/REPLICA/DATA/CMIP6/ScenarioMIP/CCCR-IITM/IITM-ESM/ssp126/r1i1p1f1/day/tasmax/gn/v20200915/tasmax_day_IITM-ESM_ssp126_r1i1p1f1_gn_20950101-20981231.nc',
'/oceano/gmeteo/DATA/ESGF/REPLICA/DATA/CMIP6/ScenarioMIP/CCCR-IITM/IITM-ESM/ssp126/r1i1p1f1/day/tasmin/gn/v20200915/tasmin_day_IITM-ESM_ssp126_r1i1p1f1_gn_20950101-20981231.nc',
'/oceano/gmeteo/DATA/ESGF/REPLICA/DATA/CMIP6/ScenarioMIP/KIOST/KIOST-ESM/ssp126/r1i1p1f1/day/tasmax/gr1/v20191202/tasmax_day_KIOST-ESM_ssp126_r1i1p1f1_gr1_20150101-20151231.nc',
"/oceano/gmeteo/DATA/ESGF/REPLICA/DATA/CMIP6/ScenarioMIP/NCC/NorESM2-LM/ssp126/r1i1p1f1/day/pr/gn/v20191108/pr_day_NorESM2-LM_ssp126_r1i1p1f1_gn_20310101-20401230.nc",
"/oceano/gmeteo/DATA/ESGF/REPLICA/DATA/CMIP6/ScenarioMIP/NCC/NorESM2-LM/ssp126/r1i1p1f1/day/pr/gn/v20191108/pr_day_NorESM2-LM_ssp126_r1i1p1f1_gn_20610101-20701230.nc",
"/oceano/gmeteo/DATA/ESGF/REPLICA/DATA/CMIP6/ScenarioMIP/NCC/NorESM2-LM/ssp126/r1i1p1f1/day/pr/gn/v20191108/pr_day_NorESM2-LM_ssp126_r1i1p1f1_gn_20810101-20901230.nc",
"/oceano/gmeteo/DATA/ESGF/REPLICA/DATA/CMIP6/ScenarioMIP/NCC/NorESM2-LM/ssp126/r1i1p1f1/day/psl/gn/v20191108/psl_day_NorESM2-LM_ssp126_r1i1p1f1_gn_20310101-20401230.nc",
"/oceano/gmeteo/DATA/ESGF/REPLICA/DATA/CMIP6/ScenarioMIP/NCC/NorESM2-LM/ssp126/r1i1p1f1/day/psl/gn/v20191108/psl_day_NorESM2-LM_ssp126_r1i1p1f1_gn_20610101-20701230.nc",
"/oceano/gmeteo/DATA/ESGF/REPLICA/DATA/CMIP6/ScenarioMIP/NCC/NorESM2-LM/ssp126/r1i1p1f1/day/psl/gn/v20191108/psl_day_NorESM2-LM_ssp126_r1i1p1f1_gn_20810101-20901230.nc",
"/oceano/gmeteo/DATA/ESGF/REPLICA/DATA/CMIP6/ScenarioMIP/NCC/NorESM2-LM/ssp126/r1i1p1f1/day/tas/gn/v20191108/tas_day_NorESM2-LM_ssp126_r1i1p1f1_gn_20310101-20401230.nc",
"/oceano/gmeteo/DATA/ESGF/REPLICA/DATA/CMIP6/ScenarioMIP/NCC/NorESM2-LM/ssp126/r1i1p1f1/day/tas/gn/v20191108/tas_day_NorESM2-LM_ssp126_r1i1p1f1_gn_20610101-20701230.nc",
"/oceano/gmeteo/DATA/ESGF/REPLICA/DATA/CMIP6/ScenarioMIP/NCC/NorESM2-LM/ssp126/r1i1p1f1/day/tas/gn/v20191108/tas_day_NorESM2-LM_ssp126_r1i1p1f1_gn_20810101-20901230.nc",
"/oceano/gmeteo/DATA/ESGF/REPLICA/DATA/CMIP6/ScenarioMIP/NCC/NorESM2-LM/ssp126/r1i1p1f1/day/tasmax/gn/v20191108/tasmax_day_NorESM2-LM_ssp126_r1i1p1f1_gn_20310101-20401230.nc",
"/oceano/gmeteo/DATA/ESGF/REPLICA/DATA/CMIP6/ScenarioMIP/NCC/NorESM2-LM/ssp126/r1i1p1f1/day/tasmax/gn/v20191108/tasmax_day_NorESM2-LM_ssp126_r1i1p1f1_gn_20610101-20701230.nc",
"/oceano/gmeteo/DATA/ESGF/REPLICA/DATA/CMIP6/ScenarioMIP/NCC/NorESM2-LM/ssp126/r1i1p1f1/day/tasmax/gn/v20191108/tasmax_day_NorESM2-LM_ssp126_r1i1p1f1_gn_20810101-20901230.nc",
"/oceano/gmeteo/DATA/ESGF/REPLICA/DATA/CMIP6/ScenarioMIP/NCC/NorESM2-LM/ssp126/r1i1p1f1/day/tasmin/gn/v20191108/tasmin_day_NorESM2-LM_ssp126_r1i1p1f1_gn_20310101-20401230.nc",
"/oceano/gmeteo/DATA/ESGF/REPLICA/DATA/CMIP6/ScenarioMIP/NCC/NorESM2-LM/ssp126/r1i1p1f1/day/tasmin/gn/v20191108/tasmin_day_NorESM2-LM_ssp126_r1i1p1f1_gn_20610101-20701230.nc",
"/oceano/gmeteo/DATA/ESGF/REPLICA/DATA/CMIP6/ScenarioMIP/NCC/NorESM2-LM/ssp126/r1i1p1f1/day/tasmin/gn/v20191108/tasmin_day_NorESM2-LM_ssp126_r1i1p1f1_gn_20810101-20901230.nc",
]

def filter_grid_labels(df, grid_label, facets):
    def gridlabel_to_int(label):
        if label == "gn":
            return 0
        elif label == "gr":
            return 1
        else:
            # priority gn > gr > gr1 > gr2 > ...., 0 is greatest priority
            return int(re.sub("[^0-9]", "", label)) + 1

    df[('GLOBALS', 'ngrid_label')] = df[('GLOBALS', grid_label)].apply(gridlabel_to_int)
    unique_grid_labels = []
    how_to_group = [('GLOBALS', f) for f in facets.split(',')]

    for _,group in df.groupby(how_to_group):
        unique_grid_labels.append(group.nlargest(1, ('GLOBALS', 'ngrid_label'), keep='all'))

    return pd.concat(unique_grid_labels)

def clean(df):
    df[('GLOBALS', 'filename')] = df[('GLOBALS', 'localpath')].apply(lambda x: os.path.basename(x))

    # KACE-1-0-G monthly datasets have got 'frequency=day' in global attributes
    kace_1_0_g_mon = ((df[('GLOBALS', '_DRS_model')] == 'KACE-1-0-G') & (df[('GLOBALS', '_DRS_table')] == 'Amon'))
    df.loc[kace_1_0_g_mon, ('GLOBALS', 'frequency')] = 'mon'

    return df

def parse_args(argv):
    args = {
        'dest': os.path.join(os.getcwd(), 'unnamed.hdf'),
        'dataframe': None,
        'variable_col': '_DRS_variable',
        'latest': None,
        'group_time': 'mip_era,activity_id,institution_id,model_id,experiment_id,variant_label,table_id,grid_label',
        'group_fx': 'mip_era,activity_id,institution_id,model_id,experiment_id,variant_label,grid_label',
        'grid_label_col': 'grid_label',
        'filter_grid_labels': None,
    }

    arguments = len(sys.argv) - 1
    position = 1
    while arguments >= position:
        if sys.argv[position] == '-h' or sys.argv[position] == '--help':
            print(_help)
            sys.exit(1)
        elif sys.argv[position] == '-d' or sys.argv[position] == '--dest':
            args['dest'] = sys.argv[position+1]
            position+=2
        elif argv[position] == '--variable-col':
            args['variable_col'] = argv[position+1]
            position+=2
        elif argv[position] == '--group-time':
            args['group_time'] = argv[position+1]
            position+=2
        elif argv[position] == '--group-fx':
            args['group_fx'] = argv[position+1]
            position+=2
        elif argv[position] == '--latest':
            args['latest'] = argv[position+1]
            position+=2
        elif argv[position] == '--filter-grid-labels':
            args['filter_grid_labels'] = argv[position+1]
            position+=2
        elif argv[position] == '--grid-label-col':
            args['grid_label_col'] = argv[position+1]
            position+=2
        else:
            args['dataframe'] = sys.argv[position]
            position+=1

    return args

if __name__ == '__main__':
    args = parse_args(sys.argv)

    if args['dataframe'] is None:
        print(_help)
        sys.exit(1)

    df = pd.read_pickle(args['dataframe'])
    # If only fx, quit
    if len(df[df[('GLOBALS', '_DRS_table')] != 'fx']) == 0:
        sys.exit(0)

    df = df[~df[('GLOBALS', 'localpath')].isin(TO_DROP)]
    df = clean(df)

    # Use this to check if ncml needs to define custom time coordinate
    df[('GLOBALS', '_require_custom_time')] = False

    # cesm2-waccm historical ends in january 2015 instead of december 2014
    subset = ((df[('GLOBALS', '_DRS_model')] == 'CESM2-WACCM') &
              (df[('GLOBALS', '_DRS_period2')].fillna(0).astype(int).astype(str).str.endswith('0101')))
    df.loc[subset, ('time', '_values')] = df.loc[subset,  ('time', '_values')].apply(lambda x: x[:-1])
    df.loc[subset, ('_d_time', 'size')] = df.loc[subset, ('_d_time', 'size')] - 1
    df.loc[subset, ('GLOBALS', '_require_custom_time')] = True

    # cesm2 ssp* ends in 2101-01-01 instead of 2100-12-31
    subset = ((df[('GLOBALS', '_DRS_model')] == 'CESM2') &
              (df[('GLOBALS', '_DRS_period2')].fillna(0).astype(int).astype(str).str.endswith('0101')))
    df.loc[subset, ('time', '_values')] = df.loc[subset,  ('time', '_values')].apply(lambda x: x[:-1])
    df.loc[subset, ('_d_time', 'size')] = df.loc[subset, ('_d_time', 'size')] - 1
    df.loc[subset, ('GLOBALS', '_require_custom_time')] = True

    # /oceano/gmeteo/WORK/zequi/ATLAS/ESGF-inventory/tds-content/public/CMIP6/ScenarioMIP/NCAR/CESM2-WACCM/ssp585/day/CMIP6_ScenarioMIP_NCAR_CESM2-WACCM_ssp585_r1i1p1f1_day.ncml
    # drop files from 2100 onward because they repeat a time step that breaks time step = 1
    subset = ((df[('GLOBALS', '_DRS_model')] == 'CESM2-WACCM') &
              (df[('GLOBALS', '_DRS_experiment')] == 'ssp585') &
              (df[('GLOBALS', '_DRS_table')] == 'day') &
              (df[('GLOBALS', '_DRS_period1')] > 20950101))
    df = df[~subset]

    if args['filter_grid_labels'] is not None:
        df = filter_grid_labels(df, args['grid_label_col'], args['filter_grid_labels'])

    if args['latest'] is not None:
        df = esgf.get_latest_versions(df, args['group_time'], args['latest'])

    if ('lon', '_values') in df.columns:
        df[('lon', '_values')] = df[('lon', '_values')].apply(
            lambda a: np.where(a>=180, a-360, a))
#    if ('lon_bnds', '_values') in df.columns:
#        nans = df[('lon_bnds', '_values')].isna()
#        df.loc[~nans, ('lon_bnds', '_values')] = df.loc[~nans, ('lon_bnds', '_values')].apply(
#            lambda a: np.ravel(a-180))

    # Report missing files in time series
    #esgf.test_missing_nc(df[df[('GLOBALS', '_DRS_Dfrequency')] != 'fx'], group_latest_versions)

    # Set same calendar for time values
    df = esgf.fix_time_values(df, args['group_time'], args['variable_col'])

    # some datasets report sub-daily data,
    # not an error but climate4r uses time in seconds to detect daily data (I think)
    time_diff = df[('time', '_values')].apply(
        lambda a: len(np.unique(np.diff(a))) != 1 if not np.isnan(a).all() else False)
    subset = ((df[('GLOBALS', '_DRS_Dtable')] == 'day') & (time_diff))
    df.loc[subset, ('time', '_values')] = (
        df.loc[subset, ('time', '_values')].apply(lambda a: np.arange(a[0], a[0]+len(a))))

    how_to_group = [('GLOBALS', facet) for facet in args['group_time'].split(',')]
    time_groups = df[~df[('GLOBALS', args['variable_col'])].isin(esgf.vars_fx)].groupby(how_to_group)
    for name, group in time_groups:
        # Fix the following issue:
        ## <netcdf location="/oceano/gmeteo/DATA/ESGF/REPLICA/DATA/CMIP6/ScenarioMIP/NCC/NorESM2-LM/ssp126/r1i1p1f1/day/tasmax/gn/v20191108/tasmax_day_NorESM2-LM_ssp126_r1i1p1f1_gn_20310101-20401231.nc" ncoords="3650" />
        ## <netcdf location="/oceano/gmeteo/DATA/ESGF/REPLICA/DATA/CMIP6/ScenarioMIP/NCC/NorESM2-LM/ssp126/r1i1p1f1/day/tasmax/gn/v20191108/tasmax_day_NorESM2-LM_ssp126_r1i1p1f1_gn_20310101-20401230.nc" ncoords="3649" />
        group = group.sort_values(
            by=[('GLOBALS', args['variable_col']), ('GLOBALS', '_DRS_period1')]).drop_duplicates(
            subset=[('GLOBALS', args['variable_col']), ('GLOBALS', '_DRS_period1')],
            keep='last')

#        # for time group check if time coordinates differ (the ncml will decide if to create multiple time coordinates)
#        group[('GLOBALS', '_time_same_coordinate')] = esgf.time_same_coordinate(
#            group,
#            ('GLOBALS', '_DRS_variable'),
#            ('time', '_values'))
        group[('GLOBALS', '_time_same_coordinate')] = False

        # include corresponding fx variables
        d = dict(zip(args['group_time'].split(','), name))
        filter_dict = {k: d[k] for k in args['group_fx'].split(',')} 
        all_fxs = df[df[('GLOBALS', args['variable_col'])].isin(esgf.vars_fx)]
        group_fxs = all_fxs.loc[(df['GLOBALS'][filter_dict.keys()] == pd.Series(filter_dict)).all(axis=1)]

        # this would be the full dataset
        dataset = (pd.concat([group, group_fxs])
                     .sort_values(by=[('GLOBALS', args['variable_col']), ('GLOBALS', 'localpath')])
                     .reset_index(drop=True))

        # "synthetic" columns: substitute fx's facets (eg: ensemble=r0i0p0, frequency=fx, ...) by it's time value
        list_time = args['group_time'].split(',')
        list_fx = args['group_fx'].split(',')
        l = [facet for facet in list_time if facet not in list_fx]
        for facet in l:
            synthetic_facet = '_synthetic' + facet
            dataset[('GLOBALS', synthetic_facet)] = d[facet]

        D = dict(dataset[~dataset[('GLOBALS', args['variable_col'])].isin(esgf.vars_fx)]['GLOBALS'].iloc[0])
        path = os.path.abspath(args['dest'].format(**D))

        path = esgf.render(dataset, path)
        print(path)
