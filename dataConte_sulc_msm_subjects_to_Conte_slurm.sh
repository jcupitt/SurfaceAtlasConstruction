#!/bin/bash

# Jelena Bozek, 2018

Scripts=/vol/medic01/users/jbozek/scripts_affine_Conte


#set paths to folders
affinedir=/vol/medic01/users/jbozek/MSMtemplate/affineToConte
DATAdir=/vol/dhcp-derived-data/structural-pipeline/dhcp-v2.4/
atlasDir=/vol/medic01/users/jbozek/HCP_standard_mesh_atlases/Conte69/MNINonLinear/fsaverage_LR32k
OutputTemplateFolder=/vol/medic01/users/jbozek/MSMtemplate/subjectsToDataConteALL


outdir=${Scripts}/slurm #location of log files
mkdir -p $outdir/logdir

list=/vol/medic01/users/jbozek/scripts/subjLISTS/subjs_270_ageScan_week.csv # list of subjects


data="sulc" # set data to use sulcal depth map for initialisation of the atlas

for hemi in L R ; do
    while read line ; do

	source=`echo $line | awk '{print $1}'`
	age=`echo $line | awk '{print $2}'`
	week=`echo $line | awk '{print $3}'`
	echo $source

	OutputRegFolder=${OutputTemplateFolder}/${source}
	OutputTempFolder=${OutputRegFolder}/toConte_${source}_${hemi}_iter${iter}
	mkdir -p $OutputTempFolder

	Conf=/vol/medic01/users/jbozek/scripts/configs/config_strain_NEWSTRAIN_SPHERE_LONGITUDINAL_new
	refmesh=${atlasDir}/Conte69.${hemi}.sphere.32k_fs_LR_recentred.surf.gii
	inmesh=${affinedir}/${source}/${source}-Conte69.${hemi}.sphere.AFFINE.surf.gii	

        nativedata=${DATAdir}/surfaces/${source}/workbench/${source}.${hemi}.sulc.native.shape.gii
	refdata=${atlasDir}/Conte69.${hemi}.32k_fs_LR.shape.gii
			
	OutMesh=${source}-Conte69.${hemi}.sphere.init.${data}.surf.gii
	OutData=${source}-Conte69.${hemi}.init.${data}.func.gii

	sbatch  -o ${outdir}/logdir/${source}_${hemi}_${data}_msm.out -e ${outdir}/logdir/${source}_${hemi}_${data}_msm.err -c 1 -p long ${Scripts}/msm_template_to_subjects_iterate.sh $Conf $inmesh $refmesh $nativedata $refdata $OutputRegFolder $OutputTempFolder $OutMesh $OutData $hemi
 
    done < $list

done

