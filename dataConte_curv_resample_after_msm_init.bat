#!/bin/bash

# Jelena Bozek, 2018

# this script resamples curvature after initial registration using sulcal depth
MSMbin=/vol/medic01/users/jbozek/MSM
Scripts=/vol/medic01/users/jbozek/scripts_affine_Conte

outdir=${Scripts}/slurm

mkdir -p $outdir/logdir
type="curv_resample_init"

list=/vol/medic01/users/jbozek/scripts/subjLISTS/subjs_270_ageScan_week.csv

OutputTemplateFolder=/vol/medic01/users/jbozek/MSMtemplate/subjectsToDataConteALL
DATAdir=/vol/dhcp-derived-data/structural-pipeline/dhcp-v2.4/
atlasDir=/vol/medic01/users/jbozek/HCP_standard_mesh_atlases/Conte69/MNINonLinear/fsaverage_LR32k

for hemi in L R ; do 
    while read line ; do

	source=`echo $line | awk '{print $1}'`
	age=`echo $line | awk '{print $2}'`
	week=`echo $line | awk '{print $3}'`
	echo $source
	
	registered_sphere=${OutputTemplateFolder}/${source}/${source}-Conte69.${hemi}.sphere.init.sulc.surf.gii
	sphereConte=${atlasDir}/Conte69.${hemi}.sphere.32k_fs_LR_recentred.surf.gii

	sbatch  -o ${outdir}/logdir/${source}_${hemi}_${type}.out -e ${outdir}/logdir/${source}_${hemi}_${type}.err -c 1 --mem=2G -p short --wrap="${MSMbin}/msmresample $registered_sphere ${OutputTemplateFolder}/${source}/${source}-Conte69.${hemi}.init.curv -labels $DATAdir/surfaces/${source}/workbench/${source}.$hemi.curvature.native.shape.gii -project $sphereConte -adap_bary  "


    done < $list

done


