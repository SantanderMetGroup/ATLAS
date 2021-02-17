#!/usr/bin/env python

import os
import sys
import numpy as np
import pandas as pd

import esgf as esgf

source = sys.argv[1]
dest = sys.argv[2]

df = pd.read_pickle(source)
df = esgf.get_latest_versions(df, '_DRS_variable', '_DRS_version')

# Use this flag to identificate file that require explicit time values in ncml
df[('GLOBALS', '_require_custom_time')] = False

# Use this flag to identificate file that require explicit time values in ncml with start increment
df[('GLOBALS', '_require_increment_time')] = False

# Be sure that df has tracking_id column
if not (('GLOBALS', 'tracking_id') in df.columns):
    df[('GLOBALS', 'tracking_id')] = None

# Add institute to RCMModelName (institute-rcm)
for r in df.index:
    if df.loc[r, ('GLOBALS', '_DRS_Dinstitute')] not in df.loc[r, ('GLOBALS', '_DRS_rcm')]:
        df.loc[r, ('GLOBALS', '_DRS_rcm')] = \
            '-'.join([df.loc[r, ('GLOBALS', '_DRS_Dinstitute')], df.loc[r, ('GLOBALS', '_DRS_rcm')]])

# If different time units, explicit time is required
if len(df[('time', 'units')].dropna().unique()) > 1:
    df[('GLOBALS', '_require_custom_time')] = True

df = esgf.fix_time_values(df, '_DRS_variable', '_DRS_variable')

# for time variables check if time coordinates differ (the ncml will decide if to create multiple time coordinates)
no_fx = df[('GLOBALS', '_DRS_frequency')] != 'fx'
times = df.loc[no_fx].groupby([('GLOBALS', '_DRS_variable')]).apply(
    lambda g: g[('time', '_values')]).groupby(level=0).apply(
    lambda g: np.sort(np.concatenate(g)))
times0 = times.iloc[0]
timesd = {variable: np.array_equal(times0, a) for variable,a in times.iteritems()}
df.loc[no_fx, ('GLOBALS', '_time_same_coordinate')] = df.loc[no_fx, ('GLOBALS', '_DRS_variable')].map(timesd)

# move fx values to the end, preventing jdataset.py choose them for DRS expansion
df = df.sort_values(by=[('GLOBALS', '_DRS_ensemble')], ascending=False)

D = dict(df[~df[('GLOBALS', '_DRS_variable')].isin(esgf.vars_fx)]['GLOBALS'].iloc[0])
path = os.path.abspath(dest.format(**D))

os.makedirs(os.path.dirname(path), exist_ok=True)
df.to_pickle(path)
print(path)
