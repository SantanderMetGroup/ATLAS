# The script AtlasCDOremappeR_CMIP6_Omon.sh was used to perform the interpolation of all montlhy CMIP6 ocean monthly data (variables siconc, ph, and tos) data to the common grid at 1 degree resolution.
# To run the script:
#	 
#	    source AtlasCDOremappeR_CMIP6_Omon.sh <variable_name>
#
# Conservative interpolation for CMIP6 ocean model outputs:
# The data are interpolated on 1 degree regular grid, using 1st order conservative remapping. 
#
# The Climate Data Operator (CDO) software is used for the inteprolation.
#
# 2 files needed tp run the interpolation:
#   1. destination_mask - for CMIP6_Omon data land_sea_mask_1degree.nc4 was used
#   2. source_file - a CMPI6_Omon netcdf file to be interpolated
#
#	BASIC interpolation procedure:
#		cdo griddes [destination_mask] > destination.grid
#		cdo cdo gencon,destination.grid [source_file] weights.nc
#		cdo remap,destination.grid,weights.nc -selname,[variable_name] [source_file] file_interpolated.nc
#
#**********************************************************************************************************************************
# Alternative procedure for interpolating CMIP6 ocean model outputs:**
# This procedure was applied to interpolate the CMIP6 outputs from the ocean models that have irregular grids which crashed due to lack of informations when using the basic conservative interpolation described above.
# The data for the crashed models were interpolated on the finer grid (0.5 degree - 360x720) using distance-weighted average remapping (remapdis) in order to get the data on the regular grid. The finer grid was chosen in order to 
# lose as less information as possible.
# Files used for this step:
#   1. destination_mask_05 - land_sea_mask_05degree.nc4
#   2. destination_mask_1  - land_sea_mask_1degree.nc4
#   3. source_file - a CMPI6_Omon netcdf file to be interpolated

#	ALTERNATIVE interpolation procedure:
#		cdo griddes [destination_mask_05] > destination_05degree.grid
#		cdo griddes [destination_mask_1] > destination_1degree.grid
#		cdo remapdis,destination_05degree.grid [source_file] intermediate_file.nc
#		cdo gencon,destination_1degress.grid intermediate_file.nc weights.nc
#		cdo remap,destination_1degress.grid,weights.nc -selname,tos intermediate_file.nc file_interpolated.nc
#
#**********************************************************************************************************************************
#
# NOTE:
# The script also performs final masking of all the interpolated data to a common land-sea mask if wanted.
# In that case, additional information on the full path to the common land-sea mask needs to be provided by a user. 
# For ATLAS land_sea_mask_1degree.nc4 was use for the final masking.
#**********************************************************************************************************************************


#!/bin/bash

# Activate all the necesary libraries to run the script (new version of cdo, nco, netcdf)
# Set the conda enviroment with netcdf, cdo, nco
ulimit -s unlimited
export PATH="path_to_conda"
source activate "enviroment_name"

#****************************************************************
# -------------------- To be adjusted by a user -----------------
#****************************************************************

#***  Initialization ***

# Interpolation method (con, dis, nn, bil )
export METHOD="con"  	

# Define the experiment (CMIP5, CMIP6)
export experiment="CMIP6"  

# Final masking: If a final mask land-sea mask to be applied to all data, for the sake of comparability
export final_masking="True"
export mask_constant=0 # if binar 0 is for sea - keeping data over the sea and masking the land (=1)

#Define the variables to interpolate
export varname=$1 # "siconc ph tos"

#Define paths
export HOMEDIR=`pwd` 
export SOURCEGRIDS="$HOMEDIR/CMIP6_GRIDS"
export WRKDIR=$HOMEDIR/$varname
export INDIR="full_path_to_folder_containing_data_to_be_interpolated"
export OUTDIR="full_path_to_output_folder" 
mkdir -p $WRKDIR
mkdir -p $SOURCEGRIDS
mkdir -p $OUTDIR

#Define filelist and folderlist names and location
export filelist=$HOMEDIR/filelist_${varname}.txt
export folders=$HOMEDIR/folders_${varname}.txt
export logfile=$WRKDIR/${varname}_remaplog.log
[ -e $logfile ] && rm $logfile

# Define destination grids
export dmask="$HOMEDIR/land_sea_mask_1degree.nc4" 		# destination grid
export dmask_int="$HOMEDIR/land_sea_mask_05degree.nc4"		# destination higher res grid, for an intermediate step for remapdis 
export final_mask="$HOMEDIR/land_sea_mask_1degree_binary.nc4"	# mask for final masking of the data


#****************************************************************
# -------------------- No adjustement necessary -----------------
#****************************************************************

#***  Generating filelist and foldelist ***
cd ${WRKDIR}

# Create list folder containg files to be interpolated 
if [ ! -e $folders ] ; then
	find $INDIR -type f -name "$varname*.nc" >> $filelist

	# Create list of folders
	echo "Creating a foldelist"
	[ -e $folders ] && rm $folders
	while read -r filepath; do
   		fname=`echo $filepath | awk -F"/" '{print $NF}'`
   		folder=`echo $filepath | awk -F"$fname" '{print $1}'`
  		echo $folder >> $folders
	done < $filelist
	cat $folders | sort | uniq > tmp.txt ; mv tmp.txt $folders
fi


# Generating destination.grid 
cdo griddes $dmask > $WRKDIR/destination.grid
export dgrid="$WRKDIR/destination.grid"
cdo griddes $dmask_int > $WRKDIR/destination_intemediate.grid
export dgrid_int="$WRKDIR/destination_intemediate.grid"


# Reading list of folders
while read -r folder; do
    outpath=`echo $folder | awk -F"/${experiment}/" '{print $2}'`
    OUTPUT=$OUTDIR/$outpath
    mkdir -p $OUTPUT

    # For each file in the folder
    for filepath in $folder/${varname}_*.nc ; do
	filename=`echo $filepath | awk -F"/" '{print $NF}'`
   	GCM=`echo $filename | awk -F"_" '{print $3}'`
   	esemble=`echo $filename | awk -F"_" '{print $5}'`
   	grid=`echo $filename | awk -F"_" '{print $6}'`	
   	
	echo "Working on the file: $filename"

	When changing to a new GCM, deleting created weights and source.grid
	if [[  $GCM_old != $GCM ]]; then
		[ -e weights.nc ] && rm weights.nc
		[ -e source.grid ] && mv source.grid $SOURCEGRIDS/source_${varname}_${GCM}_${grid}.grid
	fi

	# Fix for GFDL-ESM GCM var siconc: deleting unreadable vars (not necessary) causing int. to crash
	if [ ${GCM} == "GFDL-ESM4" ] && [ ${varname} == "siconc" ]; then
		[ -e tmp_file.nc ] && rm tmp_file.nc
		ncks -x -v GEOLAT,GEOLON $filepath tmp_file.nc
		MODELDATA=tmp_file.nc
	elif [ ${GCM} == "BCC-CSM2-MR" ] && [ ${experiment} == "CMIP6" ]; then
		[ -e tmp_file.nc ] && rm tmp_file.nc
		cp $filepath tmp.nc
		ncatted -h -a coordinates,${varname},d,, tmp.nc
		ncks -x -v longitude,latitude tmp.nc tmp_file.nc ; rm tmp.nc
		MODELDATA=tmp_file.nc
	else
		if [ $varname == "ph" ] ; then
			[ -e tmp_file.nc ] && rm tmp_file.nc
			if [ ${GCM} == "IPSL-CM6A-LR" ] ; then
				level="olevel"
			else 
				level="lev"
			fi 
			ncks -d $level,0 $filepath tmp_file.nc
			MODELDATA=tmp_file.nc
		else
			[ -e tmp_file.nc ] && rm tmp_file.nc
			MODELDATA=$filepath
		fi
	fi

	# Creating source.grid file
	[ -e source.grid ] && rm source.grid
	cdo griddes ${MODELDATA} > source.grid 

	# Setting the grid info on the file; IPSL had problems with the grid for the future runs - creates a generic grid
	[ -e source.grid ] && rm source.grid
	if [  ${GCM} == "IPSL-CM6A-LR" ] && [  ${experiment} == "CMIP6" ]; then
		echo "copying source.grid"
		cp $SOURCEGRIDS/source_${varname}_${GCM}_${grid}.grid ${WRKDIR}/source.grid
 		ncks -C -O -x -v area ${MODELDATA} temporary.nc
   		cdo setgrid,source.grid temporary.nc modelData_setgrid.nc ; rm temporary.nc
	else
		cdo griddes ${MODELDATA} > source.grid 
		cdo setgrid,source.grid -selname,${varname} ${MODELDATA} modelData_setgrid.nc 
	fi  	

	# Generating weights
	[ -e weights.nc ] && rm weights.nc
	cdo gen${METHOD},${dgrid} modelData_setgrid.nc weights.nc 

	# If wights are succefully genereted, direct conservative remapping will be done, othervise an alternative method will be applied
	# For GCMs="CanESM5","CanESM5","BCC-CSM2-MR" alternative remaping will be done, as missing values at the north pole appears
	if [ -f weights.nc ] && [ ${GCM} != "CanESM5" ] && [ ${GCM} != "CanESM5" ] && [ ${GCM} != "BCC-CSM2-MR" ] ; then
		echo "Direct conservative interpolation"
   		cdo remap,${dgrid},weights.nc -selname,${varname} modelData_setgrid.nc final.nc 
		mv final.nc $OUTPUT/${filename}_i
		[ -e $OUTPUT/${filename}_i ] && echo "Conservative method: ${GCM}_${grid}_${esemble}" >> $logfile
	else
		# If wights are not genereted, an alternative method with with distant weighting int method as an intermediate step will be applied
		echo "Alternative intepolation"
		cdo remapdis,${dgrid_int} modelData_setgrid.nc intermediate_file.nc 					# Distant weighting int method to a finer 0.5 degree grid
 	    	cdo gen${METHOD},${dgrid} intermediate_file.nc weights.nc						# Generating weights with con remapping of the intermediate file to 1 degree regular grid
		cdo remap,${dgrid},weights.nc -selname,${varname} intermediate_file.nc final.nc 			# Conservative remapping
   		mv final.nc $OUTPUT/${filename}_i									# Filenaming and placing the file to the final location
		[ -e intermediate_file.nc ] && rm intermediate_file.nc
		[ -e $OUTPUT/${filename}_i ] && echo "Alternative method: ${GCM}_${grid}_${esemble}" >> $logfile	# Write the info on the remapping method applied into a log file

	fi

	# If the final file is not created after all above, then something went wrong. Writing an info in the log file.
	if [ ! -f $OUTPUT/${filename}_i ]; then
		# Interpolation not done, write the info into the log file
 		echo "Not interpolated: ${GCM}_${grid}_${esemble}" >> $logfile	
							
	elif [ -f $OUTPUT/${filename}_i ] &&  [ $final_masking == "True" ] ; then
		# Interpolation done, performing final masking if set to true
		cdo -ifthen -eqc,$mask_constant $final_mask $OUTPUT/${filename}_i $OUTPUT/${filename} ; rm $OUTPUT/${filename}_i 
	
	else
		# Interpolation done, renaming the file and moving it to the final destiantion
		mv $OUTPUT/${filename}_i $OUTPUT/${filename}										
	fi

 	# Keep the name of the GCM from this loop to check if a new GCM coming up in the next loop or not
	export GCM_old=${GCM}	
	
   done 	# Closing file loop within a folder

done < $folders # Closing the reading loop over the list of folders

# Final sorting alphabetically the log file containing the info on the interpolated and noninterpolated GCMs, and the methods applied
cat $logfile | sort | uniq > tmp.txt ; mv tmp.txt $logfile
