#!/bin/bash
#
# AtlasCDOremappeR_CMIP6_Omon.sh
#
# Copyright (C) 2021 Santander Meteorology Group (http://meteo.unican.es)
#
# This work is licensed under a Creative Commons Attribution 4.0 International
# License (CC BY 4.0 - http://creativecommons.org/licenses/by/4.0)

# Title: Interpolation of montlhy CMIP6 ocean data
# Description:
#   AtlasCDOremappeR_CMIP6_Omon.sh interpolates montlhy CMIP6 ocean data (variables siconc, ph,
#   and tos) to the common 1-degree-resolution grid (./reference-grids/land_sea_mask_1degree_binary.nc4).  
#   To run the script:
#  	 
#  	    source AtlasCDOremappeR_CMIP6_Omon.sh <variable_name>
#
#   The script performs: 
#   1. Conservative interpolation for CMIP6 ocean model outputs:
#
#   	The data are interpolated on the 1-degree-resolution grid, using 1st order conservative remapping. 
#
#   	The Climate Data Operator (CDO) software is used for the interpolation.
#
#   	2 files needed tp run the interpolation:
#     		1. destination_mask - for CMIP6_Omon data ./reference-grids/land_sea_mask_1degree.nc4 was used
#     		2. source_file - a CMPI6_Omon netcdf file to be interpolated
#
#  	Conservative interpolation workflow:
#  		cdo griddes [destination_mask] > destination.grid
#  		cdo cdo gencon,destination.grid [source_file] weights.nc
#  		cdo remap,destination.grid,weights.nc -selname,[variable_name] [source_file] file_interpolated.nc
#
#
#   2. Alternative procedure for interpolating CMIP6 ocean model outputs:
#
#   	This procedure interpolates the CMIP6 outputs from the ocean models that have irregular grids which crashed due to lack of informations
#   	when using the conservative interpolation described above. The data for the crashed models are interpolated on the finer grid (0.5 degree) 
#	using distance-weighted average remapping (remapdis) in order to get the data on the regular grid and to lose as less information as possible.
#   	
#	Files used for this step:
#     		1. destination_mask_05 - ./reference-grids/land_sea_mask_05degree.nc4
#     		2. destination_mask_1  - ./reference-grids/land_sea_mask_1degree.nc4
#     		3. source_file - a CMPI6_Omon netcdf file to be interpolated
#
#  	Alternative interpolation procedure:
#  		cdo griddes [destination_mask_05] > destination_05degree.grid
#  		cdo griddes [destination_mask_1] > destination_1degree.grid
#  		cdo remapdis,destination_05degree.grid [source_file] intermediate_file.nc
#  		cdo gencon,destination_1degress.grid intermediate_file.nc weights.nc
#  		cdo remap,destination_1degress.grid,weights.nc -selname,tos intermediate_file.nc file_interpolated.nc
#
#   
#   NOTE:
#   The script also performs (optionaly) final masking of the interpolated data to a
#   common land-sea mask. If performed, the full path to the common land-sea mask needs to be provided by a user.  
#   In Atlas for the final masking ./reference-grids/land_sea_mask_1degree.nc4 was used as the common land-sea mask.
# Author: J. Milovac

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
	[ -e $filelist ] && rm $filelist
	find $INDIR -type f -name "$varname*.nc" >> $filelist

	# Create list of folders
	echo "Creating a foldelist"
	while read -r filepath; do
   		fname=`echo $filepath | awk -F"/" '{print $NF}'`
   		folder=`echo $filepath | awk -F"$fname" '{print $1}'`
  		echo $folder >> $folders
	done < $filelist
	cat $folders | sort | uniq > tmp.txt ; 
	mv tmp.txt $folders ; rm $filelist
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

	# When changing to a new GCM, deleting created weights and source.grid
	if [[  $GCM_old != $GCM ]]; then
		[ -e weights.nc ] && rm weights.nc
		[ -e source.grid ] && mv source.grid $SOURCEGRIDS/source_${varname}_${GCM}_${grid}.grid
	fi
	
	# Making quick fixes for the files to be interpolated 
	# (e.g. for GFDL-ESM siconc deletes unnecessary grid info - GEOLAT,GEOLON,
	# and for ph variabels extracts only the first level data)
	if [ ${GCM} == "GFDL-ESM4" ] && [ ${varname} == "siconc" ]; then
		[ -e tmp_file.nc ] && rm tmp_file.nc
		ncks -x -v GEOLAT,GEOLON $filepath tmp_file.nc
		MODELDATA=tmp_file.nc
	elif [ $varname == "ph" ] ; then
		level="lev"			
		if [ ${GCM} == "IPSL-CM6A-LR" ] ; then
			level="olevel"
		fi 
		[ -e level_file.nc ] && rm level_file.nc
		ncks -d $level,0 $filepath level_file.nc 
		MODELDATA=level_file.nc
	else
		MODELDATA=$filepath
	fi

	# Setting grid information where necessary 
	# For GCMs=CanESM5,MRI-ESM2-0,CAMS-CSM1,BCC-CSM2-MR,IPSL-CM6A-LR,NorESM2-MM setgriding grid it not working,
	# since nvertex not defined, and for the succesful interpolation not necessary
	if [[ ! ${GCM} =~ ^(CanESM5|MRI-ESM2-0|CAMS-CSM1|BCC-CSM2-MR|IPSL-CM6A-LR|NorESM2-MM)$ ]] ; then

		# Creating source.grid file
		[ -e source.grid ] && rm source.grid
		cdo griddes ${MODELDATA} > source.grid 

		# Setting the grid info upon the file
		[ -e modelData_setgrid.nc ] && rm modelData_setgrid.nc
		cdo setgrid,source.grid -selname,${varname} ${MODELDATA} modelData_setgrid.nc

		# modelData_setgrid.nc will be interpolated if created successfully 
		if [ -f modelData_setgrid.nc ]; then
			working_file=modelData_setgrid.nc
		else
			working_file=$MODELDATA
		fi
	
	elif [  ${GCM} == "IPSL-CM6A-LR" ] && [  ${experiment} == "CMIP6" ]; then
		[ -e tmp.nc ] && rm tmp.nc
		# Removing extra variable "area" from the files for IPSL-CM6A-LR GCM
 		ncks -C -O -x -v area ${MODELDATA} tmp.nc
		working_file=tmp.nc

	else
		working_file=$MODELDATA

	fi 	

	# Generating weights
	[ -e weights.nc ] && rm weights.nc
	cdo gen${METHOD},${dgrid} modelData_setgrid.nc weights.nc 

	# If wights are succefully genereted, direct conservative remapping will be done, othervise an alternative method will be applied
	# Exeptions: CanESM5, MRI-ESM2-0, CAMS-CSM1, BCC-CSM2-MR, NorESM2-MM - for these GCMS the alternative remaping will be done, 
	# because of the missing values at the north pole that appear when direct conservative remaping is done
	# IPSL-CM6A-LR has irregular grid and the direct conservative remapping crashes
	if [ -f weights.nc ] && [[ ! ${GCM} =~ ^(CanESM5|MRI-ESM2-0|CAMS-CSM1|BCC-CSM2-MR|IPSL-CM6A-LR|NorESM2-MM)$ ]] ; then 
		echo "Direct conservative interpolation"

   		cdo remap,${dgrid},weights.nc -selname,${varname} $working_file final.nc 

		mv final.nc $OUTPUT/${filename}_i
		[ -e $OUTPUT/${filename}_i ] && echo "Conservative method: ${GCM}_${grid}_${esemble}" >> $logfile
	else
		# If wights are not genereted, an alternative method with with distant weighting int method as an intermediate step will be applied
		echo "Alternative intepolation"

		[ -e intermediate_file.nc ] && rm intermediate_file.nc
		cdo remapdis,${dgrid_int} $working_file intermediate_file.nc 						# Distant weighting int method to a finer 0.5 degree grid

		[ -e weights.nc ] && rm weights.nc
 	    	cdo gen${METHOD},${dgrid} intermediate_file.nc weights.nc						# Generating weights with remapcon of the intermediate file to 1 degree regular grid
		cdo remap,${dgrid},weights.nc -selname,${varname} intermediate_file.nc final.nc 			# Conservative remapping

   		mv final.nc $OUTPUT/${filename}_i									# Filenaming and placing the file to the final location	
		[ -e $OUTPUT/${filename}_i ] && echo "Alternative method: ${GCM}_${grid}_${esemble}" >> $logfile	# Write the info on the remapping method into a log file

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
