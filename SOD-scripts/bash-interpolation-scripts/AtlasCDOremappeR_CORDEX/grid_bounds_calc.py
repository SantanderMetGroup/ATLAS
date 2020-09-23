import os
import xarray as xa
import numpy as np

# python script to be run by "python3 grid_bouds_calc.py" 
# script to create an intermediate grid necessary when you want to interpolate with cdo remapcon netcdf 
# files on a Lambert projection starting grid 

# To be changed: fpath and fname = input a netcdf file on the Lambert grid of the files you want to interpolate
# Output: grid_nlonxnlat_latlon_bounds 

def calc_vertices(lons, lats, write_to_file=False, filename=None):
    """
    Estimate the cell boundaries from the cell location of regular grids

    Parameters
    ----------
    lons, lats: arrays
        Longitude and latitude values
    write_to_file: bool
        If True lat/lon information, including vertices, is written to file
        following the structure given by cdo commmand 'griddes'
    filename: str
        Name of text file for the grid information. Only used if write_to_file
        is True. If not provided, a default name will be used.

    Returns
    -------
    lon_bnds, lat_bnds: arrays
        Arrays of dimension [nlat, nlon, 4] containing cell boundaries of each
        gridcell in lons and lats
    """

    # Dimensions lats/lons
    nlon = lons.shape[1]
    nlat = lats.shape[0]

    # Rearrange lat/lons
    lons_row = lons.flatten()
    lats_row = lats.flatten()

    # Allocate lat/lon corners
    lons_cor = np.zeros((lons_row.size*4))
    lats_cor = np.zeros((lats_row.size*4))

    lons_crnr = np.empty((lons.shape[0]+1, lons.shape[1]+1))
    lons_crnr[:] = np.nan
    lats_crnr = np.empty((lats.shape[0]+1, lats.shape[1]+1))
    lats_crnr[:] = np.nan

    # -------- Calculating corners --------- #

    # Loop through all grid points except at the boundaries
    for lat in range(1, lons.shape[0]):
        for lon in range(1, lons.shape[1]):
            # SW corner for each lat/lon index is calculated
            lons_crnr[lat, lon] = (lons[lat-1, lon-1] + lons[lat, lon-1] +
                                   lons[lat-1, lon] + lons[lat, lon])/4.
            lats_crnr[lat, lon] = (lats[lat-1, lon-1] + lats[lat, lon-1] +
                                   lats[lat-1, lon] + lats[lat, lon])/4.

    # Grid points at boundaries
    lons_crnr[0, :] = lons_crnr[1, :] - (lons_crnr[2, :] - lons_crnr[1, :])
    lons_crnr[-1, :] = lons_crnr[-2, :] + (lons_crnr[-2, :] - lons_crnr[-3, :])
    lons_crnr[:, 0] = lons_crnr[:, 1] + (lons_crnr[:, 1] - lons_crnr[:, 2])
    lons_crnr[:, -1] = lons_crnr[:, -2] + (lons_crnr[:, -2] - lons_crnr[:, -3])

    lats_crnr[0, :] = lats_crnr[1, :] - (lats_crnr[2, :] - lats_crnr[1, :])
    lats_crnr[-1, :] = lats_crnr[-2, :] + (lats_crnr[-2, :] - lats_crnr[-3, :])
    lats_crnr[:, 0] = lats_crnr[:, 1] - (lats_crnr[:, 1] - lats_crnr[:, 2])
    lats_crnr[:, -1] = lats_crnr[:, -2] + (lats_crnr[:, -2] - lats_crnr[:, -3])

    # ------------ DONE ------------- #

    # Fill in counterclockwise and rearrange
    count = 0
    for lat in range(lons.shape[0]):
        for lon in range(lons.shape[1]):

            lons_cor[count] = lons_crnr[lat, lon]
            lons_cor[count+1] = lons_crnr[lat, lon+1]
            lons_cor[count+2] = lons_crnr[lat+1, lon+1]
            lons_cor[count+3] = lons_crnr[lat+1, lon]

            lats_cor[count] = lats_crnr[lat, lon]
            lats_cor[count+1] = lats_crnr[lat, lon+1]
            lats_cor[count+2] = lats_crnr[lat+1, lon+1]
            lats_cor[count+3] = lats_crnr[lat+1, lon]

            count += 4

    lons_bnds = lons_cor.reshape(nlat, nlon, 4)
    lats_bnds = lats_cor.reshape(nlat, nlon, 4)

    if write_to_file:
        _write_grid_info(lons_row, lons_cor, lats_row, lats_cor,
                         nlon, nlat, filename=filename)

    return lons_bnds, lats_bnds


def _write_grid_info(lons_row, lons_cor, lats_row, lats_cor, nlon, nlat,
                     filename):
    """
    Write grid info to file
    """

    print("Writing grid info to disk ...")

    if filename is None:
        from datetime import datetime
        dtime = datetime.now().strftime('%Y-%m-%dT%H%M%S')
        fname = './grid_{}x{}_latlon_bounds_{}'.format(nlon, nlat, dtime)

    lt_row = np.array_split(lats_row, np.ceil(lats_row.size/6).astype(np.int))
    lt_row_str = "\n".join([" ".join(str(item) for item in arr)
                            for arr in lt_row])
    lt_cor = np.array_split(lats_cor, np.ceil(lats_cor.size/6).astype(np.int))
    lt_cor_str = "\n".join([" ".join(str(item) for item in arr)
                            for arr in lt_cor])
    ln_row = np.array_split(lons_row, np.ceil(lons_row.size/6).astype(np.int))
    ln_row_str = "\n".join([" ".join(str(item) for item in arr)
                            for arr in ln_row])
    ln_cor = np.array_split(lons_cor, np.ceil(lons_cor.size/6).astype(np.int))
    ln_cor_str = "\n".join([" ".join(str(item) for item in arr)
                            for arr in ln_cor])

    grid_txt = ("#\n# gridID 0\n#\ngridtype  = curvilinear\ngridsize  = {}\n"
                "xname     = lon\nxlongname = longitude\nxunits    = "
                "degrees_east\nyname     = lat\nylongname = latitude\nyunits"
                "    = degrees_north\nxsize     = {}\nysize     = {}\nxvals "
                "    =\n{}\nxbounds     =\n{}\nyvals     =\n{}\nybounds     "
                "=\n{}".format(
                    lons.size, lons.shape[1], lons.shape[0],
                    ln_row_str, ln_cor_str, lt_row_str, lt_cor_str))

    # Write to file
    with open(fname, 'w') as outfile:
        outfile.write(grid_txt)


# Settings

# If to write grid description text file
write_griddes_file = True
griddes_file_name = None

fpath = '/oceano/gmeteo/WORK/PROYECTOS/2018_IPCC/INTERPOLATION/prueba_yo/EUROPE/data/'
fname = 'tas_EUR-44_CNRM-CERFACS-CNRM-CM5_historical_r1i1p1_HMS-ALADIN52_v1_day_19501201-19501231.nc'


file_in = os.path.join(fpath, fname)
nc = xa.open_dataset(file_in)

# Input latitudes and longitudes
lons = nc.lon.values
lats = nc.lat.values

# Calculate grid vertices
lon_bnds, lat_bnds = calc_vertices(lons, lats, write_griddes_file,
                                   griddes_file_name)

ds = xa.Dataset({'lat_bnds': (['y', 'x', 'nv'], lat_bnds),
                 'lon_bnds': (['y', 'x', 'nv'], lon_bnds)},
                coords={'vertices': (['nv', ], range(4))})

# Merge data sets
nc_add = nc.merge(ds)

# Add 'bounds' attributes to lat/lon
nc_add.lon.attrs['bounds'] = 'lon_bnds'
nc_add.lat.attrs['bounds'] = 'lat_bnds'

# Write to disk
nc_add.to_netcdf('./file_out')
