(atlasCDOremappeR)=
# AtlasCDOremappeR for CORDEX RCM simulations

The script **AtlasCDOremappeR_CORDEX.sh** interpolates of the CORDEX data to the common 0.5 degree **grid** (reference-grids/land_sea_mask_05degree.nc4). 

To run the script:
 	
     source AtlasCDOremappeR_CORDEX.sh <CODEX domain name> <variable name>

**Data necessary** to run the interpolation of the CODEX data:
1. CORDEX files
2. Destination land-sea map to which the raw CORDEX files will be interpolated
3. Information on the source grid (txt file that defines a grid of the CORDEX data)- optional
4. Land-sea mask of the raw CODEX data - optional

The script has **4 steps**:
1. Preparations for the remapping - collecting info on the destination grid and creating neccesary files
2. Finding source.grid file – if not find, then the script creates it
3. Script looks for land-sea mask of the corresponding CORDEX model - If found, then land-sea correction will be applied.If not, then basic conservation remapping will be done.
4. Renaming files and moving them to the final output

**NOTE**: source.grid files for all the grids from RCMs from the CORDEX experiment interpolated for Atlas are available [here](https://sandbox.zenodo.org/record/870510).

