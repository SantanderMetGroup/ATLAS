#! /bin/bash 

###############################################################################################################################################################
#
# The script uses:
# netcdf and cdo (tested for the cdo versions above 1.9)
# Contanct: milovacj@unican.es
#
#==============================================================================================================================================================
#
# List of the CORDEX domains on which the script has been tested and correposnding domain_boundaries:
# AFR44	"-25.25,60.75,-46.25,42.75"
# EUR44	"-44.75,65.25,21.75,72.75"	
# NAM44 "-171.75,-22.25,12.25,76.25"
# NAM22 "-171.75,-22.25,12.25,76.25"
# WAS44 "19.25,116.25,-15.75,45.75"
# WAS22 "19.25,116.25,-15.75,45.75"
# ANT44 "-179.75,179.75,-89.75,-55.25"
#
#==============================================================================================================================================================
#
# CORDEX simulations with non-rotated projections:
# EUR44: ALADIN52, ALADIN53, ALARO-0
# NAM22: NCAR-WRF, NCAR-WRFH, NCAR-RegCM4
# NAM44: NCAR-WRF, NCAR-RegCM4
#
# For the files with non-rotated projections (often the Lambert Conformal Conical - LCC projections) that lack information, a python script that calculates grid corners has to be executed. A file with those vertices are used to create a source.grid file for a specific RCM. When doing this, the source.grid file has to be named in a specific way, so the script can recognise the file. The naming format of a source.grid file is:  
# source.grid_<domain>_<source model> (e.g. source.grid_NAM22_NCAR-WRF)
#
#--------------------------------------------------------------------------------------------------------------------------------------------------------------
#
# Simulations where postpocessed files lack information on the grid:
# EUR44: RegCM4
# WAS22: RegCM4
# WAS44: RegCM4
# NAM22: CCCma-CanRCM4,OURANOS-CRCM5,UQAM-CRCM5
# NAM44: CCCma-CanRCM4,OURANOS-CRCM5,UQAM-CRCM5,DMI-HIRHAM5
# 
# In this case, when a postprocessed file lack information and if a source.grid file for a specific RCM does not exist in the working directory, the script looks for a original file from which the grid info witll be taken. The file will be fixed (using nco commands: ncatted -h -a coordinates,${varname},d,, ${ORIGINAL_DATA});  ncks -v lon,lat -x ${ORIGINAL_DATA} tmp_file), and the source.grid will be created (cdo griddes tmp_file > source.grid)
#
#==============================================================================================================================================================
#
# Land-sea contract is taken from the doremap.sc version number allocated 20150503, and developed and tested 2014/2015 by the people: Andreas Prein (NCAR), Mark Savenije (KNMI), Erik van Meijgaard (KNMI)
# The orography correction, which is also a part of the doremap.sc script is not taken into account, since most of the source and destinations files lack the orography file necessary for doint this correction
#
###############################################################################################################################################################


###############################################################
#      	      CHANGE AND ADAPT TO YOUR REQUIREMENTS:		
###############################################################


#activate all the necesary libraries to run the script (new version of cdo, nco, netcdf)
 source activate cdo-new 

#interpolation method (con, nn, bil )
 export METHOD="con"  		

#Define the name of the source doman
export domain_name="ANT44"

#Define "lonmin,lonmax,latmin,latmax" if the destination mask covers bigger area then the source domain. If this is 
#defined, the in the preparatory steps the destination grid will be shrinked to fit better the source grid
export domain_boundaries="-179.75,179.75,-89.75,-55.25"

#Define the destination mask and creating the info file on the destination grid
 export DESTMASK="/oceano/gmeteo/WORK/PROYECTOS/2018_IPCC/INTERPOLATION/prueba_yo/WRKDIR/land_sea_mask_05degree.nc4"									

#Define the variables to interpolate
 export variables=( "spi6" "spi12" "pr" "tas" )

#Loop over variables - each file conatins one variable
for var in "${variables[@]}"; do 
  if [ $var == "spi6" ]; then
    export varname="SPI-6"
    echo "varname=$varname"
  elif [ $var == "spi12" ]; then 
    export varname="SPI-12"
    echo "varname=$varname"
  else
    export varname=$var
    echo "varname=$varname"
  fi
  export WRKDIR="<path to a working directory>"
  export INPUT="<full path to directory with files to be interpolated>"  
  export OUTPUT="<full path to the location where the interpolated files will be written>" 						
  export INMASKS="<full path of the location with masks for the source RCMs>"	 
  export ORIG_INPUT="<full path of the location where non-processed files are located, directly form ESGF>" # necessary for the files lacking grid info, e.g. for RegCM4 
	
 if ! [ -d $OUTPUT ]; then
  mkdir -p $OUTPUT
 fi
																
###############################################################
#		  NO CANGES NECESSARY!!! 		
###############################################################


#================================================================
#		 Prepartions for the remapping 
#================================================================

 cd $WRKDIR

# sorting all the necessary info on the destination domain
  if [ -n "$domain_boundaries" ]; then
    echo "Shrinking the destination domain to fit the source domain"
    cdo -sellonlatbox,${domain_boundaries} $DESTMASK refmask.nc4
  else
    cp $DESTMASK refmask.nc4
  fi
  cdo griddes refmask.nc4 > destination.grid

# Creating a filelist, and reading all the existing models
 if [ ! -f models ]; then
  filelist=`ls ${INPUT}/*${domain_name}*_${var}_*.n* > filelist.txt`
  while read -r line; do
   RCMmodel=`echo $line | awk -F"/" '{print $NF}' | awk -F"_" '{print $5}'`
   printf "$RCMmodel\n">>models_all.txt
  done < "filelist.txt"

# Creating a list of the models
  sort -u models_all.txt > models
  rm models_all.txt
 fi
 cat models

##---- Loop over all models ----
 cat models | while read model; do
 echo "working on the source model $model"

# Checking if the mask for the source model exists
    if [ `ls -1 ${INMASKS}/"CORDEX*${domain_name}*$model*_mask_*.n*" 2>/dev/null | wc -l ` -gt 0 ]; then
      export MODELMASK=`ls ${INMASKS}/"CORDEX*${domain_name}*$model*_mask_*.n*" | sort -V | tail -n 1`
      echo "Mask for $model exists"
      echo $MODELMASK
    elif [ `ls -1 ${INMASKS}/"sftlf*${domain_name}*$model*.n*" 2>/dev/null | wc -l ` -gt 0 ]; then
      export MODELMASK=`ls ${INMASKS}/"sftlf*${domain_name}*$model*.n*" | sort -V | tail -n 1`
      echo "Mask for $model exists"
      echo $MODELMASK
    else
      echo "Mask for the models $model does not exist, no land-sea contrast will be applied"
    fi


#Loop over files
 for filename in ${INPUT}/*${domain_name}*$model*_${var}*.nc4 ; do 
    export MODELDATA=$filename
    newfilename="$(basename -- ${filename})"
    echo "Working on the file: $newfilename"


#================================================================
#			 Creating a source.grid 
#================================================================
# If a source.grid does not exist in the working folder
 if [ ! -f source.grid ]; then

# If a source.grid already created and exists in the folder for the source model, the file will be taken as a source.grid for the interpolation
 if [ -f source.grid_${domain_name}_${model} ]; then
   echo "source.grid_${domain_name}_${model} exists, copying ..."
   cp source.grid_${domain_name}_${model} source.grid
 fi

# If a orginal CORDEX file id defind then the info is gathered from that file:
  if [ `ls -1 ${ORIG_INPUT}/${var}*${domain_name}*$model*.n* 2>/dev/null | wc -l ` -gt 0 ]; then
    echo "The projection info missing in the processing files, original data set required"
    export ORIGINAL_DATA=`ls ${ORIG_INPUT}/${varname}*${domain_name}*${model}*.nc | sort -V | tail -n 1`
    echo "Extracting info from $ORIGINAL_DATA, and fixing the projection information"
    cp ${ORIGINAL_DATA} tmp_file1
    ncatted -h -a coordinates,${varname},d,, tmp_file1
    ncks -v lon,lat -x tmp_file1 tmp_file2
    cdo griddes tmp_file2 > source.grid
    rm tmp_file1 tmp_file2
  else 
# Othewise directly from the processed file:
    cdo griddes ${MODELDATA} > source.grid
    gridtype=`sed -n '/gridtype/p' source.grid` 
   if [[ $gridtype != *"lonlat"* ]] && [[ $gridtype != *"gaussian"* ]] && [[ $gridtype != *"curvilinear"* ]] && [[ $gridtype != *"unstructured"* ]] ; then
     echo "the gridtype is not defined correctly, fixing..."
     rotated=$(cat source.grid | grep -c "rotated_pole")
    if [ $rotated -eq 1 ]; then
     echo "The grid is rotated - renaming the gridtype from projection to latlon "
     sed -i '/gridtype*/c\gridtype  = lonlat' source.grid
    else
     echo "gridtype in the source.grid is wrong, check and change it before rerunning the script!"
     exit 1
    fi
   fi
  fi

# Correction in the source.grid file for the AFR44 domain 
  if [ ${domain_name}="AFR44" ]; then
    find . -name "source.grid" -print | xargs sed -i 's|grid_north_pole_longitude = "0.0"|grid_north_pole_longitude = "180.0"|g'
  fi
fi

#================================================================
# 	 Conservation remapping 
#================================================================

##--- LAND SEA CONTRAST ----

# List of variables with strong land_sea contrast
  export Varlist_strong_land_sea_contrast=( tas tasmin tasmax huss sfcWind sfcWindmax mfrso mrros mrro mrso snw snm uas vas snc snd sic evspsbl hfss hfls )
  for var_ls in $Varlist_strong_land_sea_contrast; do
    if [[ "$var" == "$var_ls" ]] && [[ -f "$MODELMASK" ]]; then
        echo "Variable has a strong land-sea contrast and the model mask exists"
        export MS_STYLE="TRUE"     
    else
        echo "Variable does not have a strong land-sea contrast"
        export MS_STYLE="FALSE"
    fi
  done

  echo "*****************MS_STYLE=$MS_STYLE****************"

##--- IF LAND SEA CONTRAST ----
 if [ "$MS_STYLE" == "TRUE" ]; then
  echo "Land sea contract is included"
  # Setgrid for for the source mask and the model data
   cdo setgrid,source.grid -selname,sftlf ${MODELMASK} modelMask_setgrid.nc
   cdo setgrid,source.grid -selname,${varname} ${MODELDATA} modelData_setgrid.nc

  # Creating a mask for sea and a mask for the land
  maskinfo=`cdo infon ${MODELMASK} | grep sftlf` 
  maskmax=`echo $maskinfo | awk -F"/" '{print $NF}' | awk -F" " '{print $11}'`
  # Checking if it is 0-1 or 0-100%
  if [ $maskmax == "1.0000" ]; then   # Checking if it is 0-1 or 0-100%
   echo "mask values are binary, from 0 to 1"
   cdo mulc,-1 -setrtoc,-0.5,0.999,0 -setrtoc,0.999,2,-1 modelMask_setgrid.nc maskland.nc
   cdo mulc,-1 -setrtoc,0.001,2,0 -setrtoc,-1,0.001,-1 modelMask_setgrid.nc masksea.nc
  else
   echo "mask values are in %, from 0 to 100%"
   cdo mulc,-1 -setrtoc,-50,99.9,0 -setrtoc,99.9,200,-1 modelMask_setgrid.nc maskland.nc
   cdo mulc,-1 -setrtoc,1,200,0 -setrtoc,-100,1,-1 modelMask_setgrid.nc masksea.nc
  fi

  # Separating the data into the two files, over the sea and over the land; and setting the grid for botfiles, just in case
   cdo div -selname,${varname} modelData_setgrid.nc -selname,sftlf -setctomiss,0 maskland.nc land.nc  
   cdo div -selname,${varname} modelData_setgrid.nc -selname,sftlf -setctomiss,0 masksea.nc sea.nc
   cdo setgrid,source.grid land.nc land_setgrid.nc
   cdo setgrid,source.grid sea.nc sea_setgrid.nc
   mv land_setgrid.nc land.nc
   mv sea_setgrid.nc sea.nc

  # Creating weights for the land, sea, and complete data sets
 if [ ! -f weights.nc ] ; then
   cdo gen${METHOD},destination.grid modelData_setgrid.nc weights.nc
   cdo gen${METHOD},destination.grid land.nc  weights_land.nc
   cdo gen${METHOD},destination.grid sea.nc   weights_sea.nc
 fi

  # Remapping the data over the land, sea, and complete
   cdo remap,destination.grid,weights_land.nc land.nc landr.nc
   cdo remap,destination.grid,weights_sea.nc  sea.nc sear.nc 
   cdo remap,destination.grid,weights.nc -selname,${varname} modelData_setgrid.nc unconstrained.nc 

  # Defining the gaps between the sea and the land
   cdo ifthenelse -setmisstoc,0 refmask.nc4 landr.nc sear.nc merged.nc
   cdo setmisstoc,1 -setrtoc,-9999999,9999999,0 merged.nc gaps.nc

  # Merging all the files
   cdo ifthenelse -selname,${varname} gaps.nc -selname,${varname} unconstrained.nc -selname,${varname} merged.nc final.nc

  else 

##--- IF NOT LAND SEA CONTRAST ----

  echo "standard remapping is applied"
  # Setting the grid info in the file
  cdo setgrid,source.grid -selname,${varname} ${MODELDATA} modelData_setgrid.nc
  if [ ! -f weights.nc ] ; then
  # Creating a  weight file
    cdo gen${METHOD},destination.grid modelData_setgrid.nc weights.nc
  fi
  # Remapping
    cdo remap,destination.grid,weights.nc -selname,${varname} modelData_setgrid.nc final.nc

  fi

##--- The script for the conservation remapping finished ----

#================================================================
#	 Finish: moving and renaming files, loop endings
#================================================================
 
    mv final.nc ${OUTPUT}/${newfilename}	    			#Renaming the file and moving the file to the output folder
 done 							 		#End of the loop over files 
    rm *.nc source.grid 						#Deleting all the files related to a specific model
 done 							  		#End of the loop over models
    rm models filelist.txt			        		#Removing the model list and filelist, for creating a new one for the new variable
    mv models ${var}_models
    cd $OUTPUT
    rename ${domain_name} ${domain_name}i *.nc4			 	#Renaming all the files - adding i to the ${domain_name}
    echo "Interpolation of ${var} completed succefully*"
    cd $WRKDIR
 done 							  		#End of the loop over variables 
    echo "**************INTERPOLATION COMPLETED SUCCESSFULLY*******************"







