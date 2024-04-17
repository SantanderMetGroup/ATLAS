#!/bin/bash
#
# AtlasCDOremappeR_CORDEX.sh
#
# Copyright (C) 2021 Santander Meteorology Group (http://meteo.unican.es)
#
# This work is licensed under a Creative Commons Attribution 4.0 International
# License (CC BY 4.0 - http://creativecommons.org/licenses/by/4.0)

# Title: Interpolation of CORDEX data
# Description:
#   This script interpolates all model outputs from the CORDEX experiment
#   The file to be interpolated should follow the file naming structure:
#   CORDEX-<CORDEX_domain>_<GCM>_<experiment>_<realisation>_<RCM>_<version>_<variable>_<frequency>_<year>.nc4 
#   (e.g. CORDEX-AFR-22_MOHC-HadGEM2-ES_historical_r1i1p1_ICTP-RegCM4-7_v0_tas_monthly_2005.nc4)
#   If the file has a different naming structure, the lines corresponding to the file naming has to be revised (lines 161-163). 
#   The script is based on the "doremap.sc" version 1.0 (allocated version number: 20150503), developed and tested by Mark Savenije (KNMI), Erik van Meijgaard (KNMI) and Andreas Prein (NCAR)
# Author: J. Milovac

# Activate all the necesary libraries to run the script (new version of cdo, nco, netcdf)
# Set the conda enviroment with netcdf, cdo, nco
ulimit -s unlimited
export PATH="path_to_conda"
source activate "enviroment_name" 

#CORDEX domain
export dname=$1

#Variable to interpolate
export var=$2

#interpolation method
export METHOD="con" 

#Define paths to folders to be used
export HOMEDIR=`pwd` 							# remap dir
export SOURCEMASK="$HOMEDIR/CORDEX_MASKS" 				# folder with RCM masks (netcdf files with names containing domain name and RCM name)
export SOURCEGRID="$HOMEDIR/CORDEX_GRIDS" 				# folder with files source_[CORDEX_domain]_[RCM_name].grid
export RAWDIR="full_path_to_raw_files" 			  		# raw files if files to be interpolated are postprocessed. If not, this equals to $INDIR
export WRKDIR="$HOMEDIR/wrkdir/$1/$2" 					# path to folder where interpolation is processed - different for each varname and domain
export OUTPUT_root="$HOMEDIR/cdo_output/$2/$1/cdo/"			# root path of the output
export INDIR="full_path_to_folder_containig_files_to_be_inteporlated"	# path to the folder with files to be interpolated
mkdir -p $WRKDIR
mkdir -p $OUTDIR
mkdir -p $SOURCEGRIDS

# Define destination grid
export dmask="full_path_to_mask/<mask>.nc4" 	# netcdf file - destination mask

#Name of filelists, folderlists and logfiles
export flist_tmp=$WRKDIR/flist_${var}_${dname}_complete.txt
export filelist=$WRKDIR/filelist_${var}_${dname}.txt
export folders=$WRKDIR/folders_${var}_${dname}.txt
export not_interpolated=$WRKDIR/not_interpolated_${var}_${dname}.txt
export modelist=$WRKDIR/models_${var}_${dname}.txt
export logfile=$WRKDIR/logfile_${var}_${dname}.txt

#========================================================================================================================
# ---------------------------------------- BELOW NO CHANGES NECESSARY!!! ------------------------------------------------
# ---------------------------------------- Preparations for the remapping -----------------------------------------------
# -----------------------------------------------------------------------------------------------------------------------
#  NOTE1: name of the output file will be the same as the input. If this is not desired, change the name below
#========================================================================================================================

#Enter working directory
cd $WRKDIR

#Removing file containing not_interpolated files if exists
[ -e $not_interpolated ] && rm $not_interpolated

#Creates a complete list of all files available to interpolate
echo "Creating initial filelist"
[ -e $flist_tmp ]  && rm $flist_tmp
find $INDIR -type f -name '*.nc4'>> $flist_tmp

#Create list of models
echo "Creating list of models"
[ -e $modelist ]  && rm $modelist
while read -r filepath; do
   	fname=`echo $filepath | awk -F"/" '{print $NF}'`
   	domain=`echo $filepath | awk -F"/" '{print $9}'`
   	RCM=`echo $fname | awk -F"_" '{print $5}'`
done < $flist_tmp
cat $modelist | sort | uniq > tmp.txt ; mv tmp.txt $modelist

#Cheking if new files are created in the meanwhile that need to be interpolated
if [ ! -f $filelist ]; then  
	echo "Echo Filelist does not exist"
	cp $flist_tmp $filelist
else
	echo "$filelist already exists, searchin for if there is a difference"
        comm -3 <(sort $flist_tmp) <(sort $filelist) > tmp.txt

	if [[ -s tmp.txt ]] ; then 
		mv tmp.txt $filelist
	else
		echo "thers is no new files to be interpolated, aborting"
		rm tmp.txt
		exit 1
	fi
fi

#Create list of folders
echo "Echo Folderlist does not exist, creating"
[ -e $folders ]  && rm $folders
while read -r filepath; do
   	fname=`echo $filepath | awk -F"/" '{print $NF}'`
   	folder=`echo $filepath | awk -F"$fname" '{print $1}'`
  	echo $folder >> $folders
done < $filelist
cat $folders | sort | uniq > tmp.txt ; mv tmp.txt $folders

#Read folders
while read -r fdir; do
	export domain_name=`echo $fdir | awk -F"/" '{print $9}'`
	export domain=`echo $domain_name | awk -F"-" '{print $1}'`
        export path=`echo $fdir | awk -F"/raw/" '{print $2}'`
	export experiment=`echo $fdir | awk -F"/" '{print $13}'`
  	export OUTPUT=$OUTPUT_root/$path/ #Location where the final files will be located - will follow the same path of the initial files	

	#Make output directory if not existing
	mkdir -p $OUTPUT

	#Domain boundaries for interpolated domain, info taken from https://is-enes-data.github.io/cordex_archive_specifications.pdf
	case $domain in
		AFR) domain_boundaries="-25.25,60.75,-46.25,42.75";;
		ANT) domain_boundaries="-179.75,179.75,-89.75,-55.25";;
		ARC) domain_boundaries="-179.75,179.75,48.75,89.75";;
		SAM) domain_boundaries="-106.25,-16.25,-58.25,18.75";;
		CAM) domain_boundaries="-124.75,-21.75,-19.75,35.25";;
		NAM) domain_boundaries="-171.75,-22.25,12.25,76.25";;
		EUR) domain_boundaries="-44.75,65.25,21.75,72.75";;
		WAS) domain_boundaries="19.25,116.25,-15.75,45.75";;
		EAS) domain_boundaries="62.75,175.75,-18.75,59.25";;
		CAS) domain_boundaries="10.75,140.25,17.75,69.75";;
		AUS) domain_boundaries="88.75,207.25,-53.25,12.75";;
		MED) domain_boundaries="-20.75,51.75,25.25,57.25";;
		MNA) domain_boundaries="-26.75,75.75,-7.25,45.25";;
		MNA) domain_boundaries="-26.75,75.75,-7.25,45.25";;
		SEA) domain_boundaries="89.125,147.125,-15.375,27.3750";;
	esac

	#Additinal info for the simulations on the finer grid
	case $domain_name in
		EUR-11) domain_boundaries="-44.8125,65.1875,21.8125,72.6875";;
		MNA-22) domain_boundaries="-26.625,75.625,-6.875,45.125";;
	esac			

	# DESTINATION GRID INFO
  	if [ -n "$domain_boundaries" ]; then
    		echo "Shrinking the destination domain to fit the source domain"
    		cdo -sellonlatbox,${domain_boundaries} $dmask refmask.nc4
  		cdo griddes refmask.nc4 > destination.grid
	else
  		cdo griddes $dmask > destination.grid
  	fi

	# LOOP over files
	for file in $fdir/*.nc* ; do 
		filename="$(basename -- ${file})" 			# name of the output file - here it is the same as the original file
                GCMmodel=`echo $filename | awk -F"_" '{print $2}'` 	# name of GCM model
   		RCMmodel=`echo $filename | awk -F"_" '{print $5}'` 	# name of RCM model

		# VARIABLE CHECK IN THE FILE 
		vars_in_files=`cdo -showname $file`
		for vname in $vars_in_files; do
			if [ $var == $vname ] ; then
				varname=$var
   				echo "variable is: $varname"
			elif [[ $var == "TXx" ]] && [[ $vname == "tasmax" ]]; then
				varname="tasmax"
   				echo "variable is: $varname"
			elif [[ $var == "TX" ]] && [[ $vname == "tasmax" ]]; then
				varname="tasmax"
   				echo "variable is: $varname"
			elif [[ $var == "meanpr" ]] && [[ $vname == "pr" ]]; then
				varname="pr"
   				echo "variable is: $varname"
			elif [[ $var == "wind" ]] && [[ $vname == "sfcWind" ]]; then
				varname="sfcWind"
   				echo "variable is: $varname"
			elif [[ $var == "spi6" ]] && [[ $vname == "SPI-6" ]]; then
				varname="SPI-6"
   				echo "variable is: $varname"
			elif [[ $var == "spi12" ]] && [[ $vname == "SPI-12" ]]; then
				varname="SPI-12"
   				echo "variable is: $varname"
			elif [[ $var == "ds" ]] && [[ $vname == "CDD" ]]; then
				varname="CDD"
   				echo "variable is: $varname"
			fi
		done

		# If varname is not defined something went wrong, exiting
		if [ -z "$varname" ] ; then
  			echo "Check the variable name in the processed file, not fitting to the asigned argument, exiting"
			exit 1
		fi
			

		# Checking if file already interoolated (if already exists in the output folder)
		if [ ! -f ${OUTPUT}/${filename} ] ; then
    			echo "File $filename in not interpolated, interpolating ..."

			# If new RCM in the loop, delete all what was related to the previous RCM
  			if [ "$RCMmodel_old" != "$RCMmodel" ] ; then
				echo "********************************************"
				echo "changing RCM from $RCMmodel_old to $RCMmodel"
				echo "deleting source.grid file and wheights..."
				[ -f source.grid ] && rm source.grid	
				[ -f weights.nc4 ] && rm weights*.nc4												


				# MASK CHECK - if exists for the RCM and domain or not in the folder ${SOURCEMASK}
 				if [ `ls -1 $SOURCEMASK/*$domain_name*$RCMmodel* 2>/dev/null | wc -l ` -gt 0 ]; then
					export MODELMASK=`ls ${SOURCEMASK}/*$domain_name*$RCMmodel* | sort -V | tail -n 1`
					echo "Mask for $RCMmodel exists"
        				echo "$domain_name/$GCMmodel/$RCMmodel" |& tee -a $logfile
					echo "Mask exists" |& tee -a $logfile 
					export MS_STYLE="FALSE"

					vars_ls="tas tasmin tasmax TXx TX TN TNn huss wind sfcWind sfcWindmax mfrso mrros mrro mrso snw snm uas vas snc snd sic evspsbl hfss hfls"
					for var_ls in $vars_ls ; do
    						if [ $varname == $var_ls ] ; then #if mask exists, and var has LS contrast - TRUE
        						echo "Variable has a strong land-sea contrast and the model mask exists"
        						export MS_STYLE="TRUE"
    						fi
  					done
        				echo "MS_STYLE=$MS_STYLE" |& tee -a $logfile  # print in a log file is LS contract is applied or not
  					echo "*****************MS_STYLE=$MS_STYLE****************"

				else
					echo "Mask for the models $RCMmodel does not exist, no land-sea contrast will be applied"
        				echo "$domain_name/$GCMmodel/$RCMmodel/$experiment"
					echo "Mask does not exist" |& tee -a $logfile 
					export MS_STYLE="FALSE"
				fi

			fi


  			# SOURCE GRID INFO
    			if [ ! -f source.grid ] ; then

				# if source.grid file already exist in the $SOURCEGRID folder copy to the $WRKDIR
				if [ -f $SOURCEGRID/source_${domain_name}_$RCMmodel.grid ] ; then
					echo "Source.grid for source_${domain_name}_$RCMmodel.grid exists, copying"
					#cp $SOURCEGRID/source_${domain_name}_$RCMmodel.grid $WRKDIR/source.grid
					if [ ${domain_name} == "AUS-22" ] || [ ${domain_name} == "AUS-44" ] ; then
						cp $SOURCEGRID/source_${domain_name}cut_$RCMmodel.grid $WRKDIR/source.grid
					elif [ ${domain_name} == "EUR-11" ] && [ ${RCMmodel} == "KNMI-RACMO22E" ] ; then
						cp $SOURCEGRID/source_${domain_name}_$RCMmodel.grid_fix $WRKDIR/source.grid
					elif [ ${domain_name} == "EUR-11" ] && [ ${RCMmodel} == "IPSL-WRF381P" ] ; then
						cp $SOURCEGRID/source_${domain_name}_$RCMmodel.grid_fix $WRKDIR/source.grid
					elif [ ${domain_name} == "EUR-11" ] && [ ${RCMmodel} == "UHOH-WRF361H" ] ; then
						cp $SOURCEGRID/source_${domain_name}_$RCMmodel.grid_fix $WRKDIR/source.grid
					elif [ ${domain_name} == "EUR-11" ] && [ ${RCMmodel} == "SMHI-RCA4" ] ; then
						cp $SOURCEGRID/source_${domain_name}_$RCMmodel.grid_fix $WRKDIR/source.grid
					elif [ ${domain_name} == "EUR-11" ] && [ ${RCMmodel} == "MPI-CSC-REMO2009" ] ; then
						cp $SOURCEGRID/source_${domain_name}_$RCMmodel.grid_fix $WRKDIR/source.grid
					elif [ ${domain_name} == "EUR-11" ] && [ ${RCMmodel} == "GERICS-REMO2015" ] ; then
						cp $SOURCEGRID/source_${domain_name}_$RCMmodel.grid_fix $WRKDIR/source.grid
					else
						cp $SOURCEGRID/source_${domain_name}_$RCMmodel.grid $WRKDIR/source.grid				
					fi

				# if source.grid does not exist in $SOURCEGRID, but $MODELMASK exist
				elif [ -f $MODELMASK ] ; then
					cp $MODELMASK tmp.nc

				# if source.grid in $SOURCEGRID and $MODELMASK do not exist, looking for a raw file in the directory with unprocessed files
				elif [ ! -f $MODELMASK ] ; then
					rawfile=`find $RAWDIR/ -type f -name '*$domain_name*$RCMmodel*.nc' -print -quit`
				 	cp $rawfile tmp.nc

				# if nothing from above - the interpolation will not be done for the specific file
				else 
					echo "   Source.grid for source_${domain_name}_$RCMmodel.grid is missing    " |& tee -a $logfile
					echo "   ********   	   INTERPOLATION CANNOT BE PERFORMED!   ********    " |& tee -a $logfile
					echo "   ***************************************************************    " |& tee -a $logfile
				fi


				if [ -f tmp.nc ] ; then
					# if python script grid_bounds_calc.py exists in $WRKDIR 
					if [ -f $WRKDIR/grid_bounds_calc.py ] ; then 
						python3 $WRKDIR/grid_bounds_calc.py tmp.nc
						rm tmp.nc
					else
						# prepare the file and use "cdo griddes" function
						ncatted -h -a coordinates,sftlf,d,, tmp.nc
   						ncks -v lon,lat -x tmp.nc tmp1.nc
   						cdo griddes tmp1.nc > source.grid
						rm tmp1.nc tmp.nc
					fi
				fi

			else
				echo "Source.grid aready exists, still working with the same RCM=${RCMmodel} and CORDEX domain = ${domain_name}"
			fi

			# Setting the grid info upon the file
			if [ ${domain_name} == "ARC-44" ] ; then
				echo "fixing the issue related to the wron rotated pole in ARC-44 in the CORDEX postprocessed files"
				ncks -C -O -x -v rotated_pole ${file} tmp.nc
   				cdo setgrid,source.grid -selname,${varname} tmp.nc modelData_setgrid.nc ; rm tmp.nc
			else
   				cdo setgrid,source.grid -selname,${varname} ${file} modelData_setgrid.nc
			fi

			#-------------------------------------------------------------------------------------------------
			# INTEPOLATION 
			#-------------------------------------------------------------------------------------------------

			# LAND SEA CONTRAST = TRUE 
 			if [[ $MS_STYLE == "TRUE" ]] ; then

				echo "--- LAND SEA CONTRAST ----"
				echo "Land sea correction included" 	

  				# Setgrid for for the source mask and the model data
   				cdo setgrid,source.grid -selname,sftlf ${MODELMASK} modelMask_setgrid.nc

  				# Checking if mask has values 0-1 or 0-100%
  				maskinfo=`cdo infon ${MODELMASK} | grep sftlf` 
  				maskmax=`echo $maskinfo | awk -F"/" '{print $NF}' | awk -F" " '{print $11}'`
 				if [ $maskmax == "1.0000" ]; then   # Checking if it is 0-1 or 0-100%
   					echo "mask values are binary, from 0 to 1"
  				else
   					echo "mask values are in %, from 0 to 100%"
   					cdo mulc,0.01 modelMask_setgrid.nc tmp.nc ; mv tmp.nc modelMask_setgrid.nc
  				fi

  				# Preparing masks separately for land and sea
   				cdo mulc,-1 -setrtoc,-0.5,0.999,0 -setrtoc,0.5,2,-1 modelMask_setgrid.nc maskland.nc
   				cdo mulc,-1 -setrtoc,0.5,2,0 -setrtoc,-1,0.5,-1 modelMask_setgrid.nc masksea.nc

 
  				# Separating the data into two files - over the sea and over the land; and seting the grid for both files
   				cdo div -selname,${varname} modelData_setgrid.nc -selname,sftlf -setctomiss,0 maskland.nc land.nc  
   				cdo div -selname,${varname} modelData_setgrid.nc -selname,sftlf -setctomiss,0 masksea.nc sea.nc
   				cdo setgrid,source.grid land.nc land_setgrid.nc ; mv land_setgrid.nc land.nc
   				cdo setgrid,source.grid sea.nc sea_setgrid.nc ; mv sea_setgrid.nc sea.nc

  				# Creating weights for the land, sea, and whole domain
 				if [ ! -f weights.nc4 ] ; then
   					cdo gen${METHOD},destination.grid modelData_setgrid.nc  weights.nc4
   					cdo gen${METHOD},destination.grid land.nc  weights_land.nc4
   					cdo gen${METHOD},destination.grid sea.nc  weights_sea.nc4
 				fi

  				# Remapping the data over the land, sea, and whole domain
   				cdo remap,destination.grid,weights_land.nc4 land.nc landr.nc
   				cdo remap,destination.grid,weights_sea.nc4 sea.nc sear.nc 
   				cdo remap,destination.grid,weights.nc4 -selname,${varname} modelData_setgrid.nc unconstrained.nc 

  				# Defining the gaps between the sea and the land
   				cdo ifthenelse -setmisstoc,0 refmask.nc4 landr.nc sear.nc merged.nc
   				cdo setmisstoc,1 -setrtoc,-9999999,9999999,0 merged.nc gaps.nc

  				# Merging the files
   				cdo ifthenelse -selname,${varname} gaps.nc -selname,${varname} unconstrained.nc -selname,${varname} merged.nc final.nc

  			else 

				# LAND SEA CONTRAST = FALSE
				echo "--- NO LAND SEA CONTRAST ----"
				echo "Standard remapping is applied" 	

				# Creating a  weight file if not already created
  				if [ ! -f weights.nc4 ] ; then
     					cdo gen${METHOD},destination.grid modelData_setgrid.nc weights.nc4
  				fi

  				# Remapping
    				cdo remap,destination.grid,weights.nc4 -selname,${varname} modelData_setgrid.nc final.nc

  			fi

			# Finalizing: If the final file is not created, write the info in the log file
    			if [ ! -f final.nc ] ; then 			
				echo "$file not interpolated"
				echo "$file" >> $not_interpolated 
				echo "**********************************************************************"
			else			
				# If interpolated, rename final.nc and moved it to the final destination ${OUTPUT}	
				mv final.nc ${OUTPUT}/${filename} 
				rm *.nc
			fi

			# Keep the name of the RCMmodel from this loop to check if a new RCM coming up in the next loop or not
                	export RCMmodel_old="$RCMmodel" 
		else
			# The interpolated file already exists in the output folder
    			echo "File $file already interpolated, skipping ..."
		fi

 	done # Loop over files in the folder

	# Changing the model and domain, deleting all the files created in the previous loop
	echo "Interpolation of ${folder} completed succefully, moving to the next folder...."
	rm *.nc* *.grid

done < $folders	# Loop over folders

# Sorting the file $not_interpolated contaning info about the files that are not interpolated 
if [[ -f $not_interpolated ]] && [[ -s $not_interpolated  ]] ; then
	cat $not_interpolated | sort | uniq > tmp.txt ; mv tmp.txt $not_interpolated
	echo "******** INTERPOLATION NOT COMPLETED SUCCESSFULLY *************"
	echo "Some files are not interpolated, check the logfile $not_interpolated!"
else
	echo "********INTERPOLATION COMPLETED SUCCESSFULLY*************"
fi
