#!/bin/bash

# Jelena Bozek, 2018

#set -x

Scripts=/vol/medic01/users/jbozek/scripts_affine_Conte
WBdir=/vol/medic01/users/jbozek/workbench/exe_linux64

outdir=${Scripts}/adaptive_slurm
mkdir -p $outdir/logdir

list=/vol/medic01/users/jbozek/scripts/subjLISTS/subjs_270_ageScan_week.csv


affinedir=/vol/medic01/users/jbozek/MSMtemplate/affineToConte
DATAdir=/vol/dhcp-derived-data/structural-pipeline/dhcp-v2.4/
atlasDir=/vol/medic01/users/jbozek/HCP_standard_mesh_atlases/Conte69/MNINonLinear/fsaverage_LR32k

jobs="SLURM"
data="curv"

iter=0

mkdir -p ${Scripts}/adaptive_batchSlurm

for kernel in adaptive ; do # adaptive fixed; do
    for sigma in 1 ; do # 0.25 0.5 0.75 1 ; do
	for hemi in  L R ; do
	    for week in  {36..44} ; do
		jobhold=""
		weights=/vol/medic01/users/jbozek/new_weights/results/etc-${kernel}/kernel_sigma=${sigma}/weights_t=${week}.csv
		allJobs=""	
	    	subjInweight=""
		arrayjobID=0
		sbatchFile=${Scripts}/batchSlurm/msmFile_${week}_iter${iter}.sbatch
	
		echo "#!/bin/bash" > $sbatchFile
		echo "#SBATCH -J ${hemi}${iter}MSM${data} " >> $sbatchFile 
		echo "#SBATCH -c 1 " >> $sbatchFile 
		echo "#SBATCH -p long " >> $sbatchFile 
		echo "#SBATCH -o ${outdir}/logdir/iter${iter}_${hemi}_${data}_msm%A_%a.out  " >> $sbatchFile
		echo "#SBATCH -e ${outdir}/logdir/iter${iter}_${hemi}_${data}_msm%A_%a.err" >> $sbatchFile

		while read line ; do

		    source=`echo $line | awk '{print $1}'`
		    age=`echo $line | awk '{print $2}'`

		    # if subject is in the weights file, continue with registration and resampling
		    subjInweight=`grep $source $weights`
		    if [ "x$subjInweight" != "x" ] ; then

			InputTemplateFolder=/vol/medic01/users/jbozek/MSMtemplate/subjectsToDataConteALL # folder with sulc results
			OutputTemplateFolder=/vol/medic01/users/jbozek/MSMtemplate/adaptive_subjectsToDataConteALL
			OutputRegFolder=${OutputTemplateFolder}/${source}_week${week}
			OutputTempFolder=${OutputRegFolder}/toConte_${source}_${hemi}_iter${iter}
			mkdir -p $OutputTempFolder

			mkdir -p ${OutputTemplateFolder}/scripts
			dataFile=${OutputTemplateFolder}/scripts/${hemi}_iter${iter}_week${week}_input

			Conf=/vol/medic01/users/jbozek/scripts/configs/config_strain_NEWSTRAIN_SPHERE_LONGITUDINAL_new
			refmesh=${atlasDir}/Conte69.${hemi}.sphere.32k_fs_LR_recentred.surf.gii
			inmesh=${affinedir}/${source}/${source}-Conte69.${hemi}.sphere.AFFINE.surf.gii

			transmesh=${InputTemplateFolder}/${source}/${source}-Conte69.${hemi}.sphere.init.sulc.surf.gii
			
			if [ $data = 'curv' ] ; then
			    nativedata=${DATAdir}/surfaces/${source}/workbench/${source}.${hemi}.curvature.native.shape.gii
			    refdata=${OutputTemplateFolder}/week${week}.init.${data}.${hemi}.AVERAGE.shape.gii 
			else
			    nativedata=${DATAdir}/surfaces/${source}/workbench/${source}.${hemi}.sulc.native.shape.gii
			    refdata=${OutputTemplateFolder}/week${week}.init.${data}.${hemi}.AVERAGE.shape.gii 
			fi			

			OutMesh=${source}-Conte69.${hemi}.sphere.${data}.iter${iter}.surf.gii
			OutData=${source}-Conte69.${hemi}.${data}.iter${iter}.func.gii

			outputResampled=${OutputRegFolder}/${source}.${hemi}.curv.iter${iter}.resampled #base name for the resampled data

			# does msm and resampling of the data
			#create sbatch file to submit in an array
			echo "#!/bin/bash" > ${dataFile}${arrayjobID}.sh
			echo "${Scripts}/msm_template_to_subjects_iterate.sh $Conf $inmesh $refmesh $nativedata $refdata $OutputRegFolder $OutputTempFolder $OutMesh $OutData $hemi $outputResampled $transmesh" >> ${dataFile}${arrayjobID}.sh
			chmod a+x ${dataFile}${arrayjobID}.sh

			arrayjobID=`echo " $arrayjobID + 1 " | bc`
	        
		    fi
		done < $list

		echo ${dataFile}'$SLURM_ARRAY_TASK_ID'".sh" >> $sbatchFile


		jobidMSM=`sbatch  $jobhold  --array=0-$arrayjobID $sbatchFile  | sed 's/Submitted batch job //g'`
		
		outfilename="week${week}.iter${iter}.${data}.${hemi}.AVERAGE.shape.gii"

		jobidAvdCurv=`sbatch  -d $jobidMSM -J ${iter}AVG${week}${hemi}${data} -o ${outdir}/logdir/${week}_iter${iter}_${hemi}_avg_${data}.out -e ${outdir}/logdir/${week}_iter${iter}_${hemi}_avg_${data}.err -c 1 --mem=2G -p short ${Scripts}/average_data_after_reverse_msm_and_resampling.py $OutputTemplateFolder $weights $hemi  $outfilename $data $list $iter $week | sed 's/Submitted batch job //g'`


		if [ $hemi = "L" ] ; then 	Structure="CORTEX_LEFT"			
		elif [ $hemi = "R" ] ; then  Structure="CORTEX_RIGHT"
		fi

		jobidStructure=`sbatch  -d $jobidAvdCurv -J ${iter}STR${week}${hemi}${data} -o ${outdir}/struct${week}_iter${iter}_${hemi}_${data}.out -e ${outdir}/struct${week}_iter${iter}_${hemi}_${data}.err -c 1 --mem=2G -p short  --wrap="${WBdir}/wb_command -set-structure $OutputTemplateFolder/$outfilename ${Structure} " | sed 's/Submitted batch job //g'`

	    done
	done
    done
done


