#!/bin/bash

# Jelena Bozek, 2018

#set -x

# resample and average data (sulc, myelin, thickness) for the final template
# check and change paths to features, especially thickness which was not located in the same folder as sulc and myelin due to changes in the dHCP structural pipeline (that influenced thickness) during atlas construction


Scripts=/vol/medic01/users/jbozek/scripts_affine_Conte
MSMbin=/vol/medic01/users/jbozek/MSM 
WBdir=/vol/medic01/users/jbozek/workbench/exe_linux64

DATAdir=/vol/dhcp-derived-data/structural-pipeline/dhcp-v2.4
atlasDir=/vol/medic01/users/jbozek/HCP_standard_mesh_atlases/Conte69/MNINonLinear/fsaverage_LR32k

OutputTemplateFolder=/vol/medic01/users/jbozek/MSMtemplate/adaptive_subjectsToDataConteALL
list=/vol/medic01/users/jbozek/scripts/subjLISTS/subjs_270_ageScan_week.csv

outdir=${Scripts}/slurm

kernel=adaptive
sigma=1

iter=30

for hemi in L R ; do 
    if [ $hemi = "L" ] ; then 	Structure="CORTEX_LEFT"			
    elif [ $hemi = "R" ] ; then  Structure="CORTEX_RIGHT" ;  fi
    for data in   sulc thickness MyelinMap ; do  
	echo $data
	for week in {36..44} ; do 
	    echo $week

	    weights=/vol/medic01/users/jbozek/new_weights/results/etc-${kernel}/kernel_sigma=${sigma}/weights_t=${week}.csv

	    arrayjobID=0
	    sbatchFile=${Scripts}/batchSlurm/resample_${week}_iter${iter}_${hemi}_${data}.sbatch
	    dataFile=${OutputTemplateFolder}/scripts/resample_${data}_${hemi}_iter${iter}_week${week}_input

	    echo "#!/bin/bash" > $sbatchFile
	    echo "#SBATCH -J ${hemi}${iter}RES${data} " >> $sbatchFile 
	    echo "#SBATCH -c 1 " >> $sbatchFile 
	    echo "#SBATCH -p short " >> $sbatchFile
	    echo "#SBATCH --mem-per-cpu=2000 " >> $sbatchFile
	    echo "#SBATCH -o ${outdir}/logdir/resample_week${week}_iter${iter}_${hemi}_${data}_%A_%a.out" >> $sbatchFile
	    echo "#SBATCH -e ${outdir}/logdir/resample_week${week}_iter${iter}_${hemi}_${data}_%A_%a.err" >> $sbatchFile

	    while read line ; do
		source=`echo $line | awk '{print $1}'`		

		if [ "$data" = "sulc" ] ; then
		    nativedata=${DATAdir}/surfaces/${source}/workbench/${source}.${hemi}.sulc.native.shape.gii
		elif [ "$data" = "thickness" ] ; then
		    nativedata=${OutputTemplateFolder}/thickness/${source}.${hemi}.${data}.resampled.func.gii
		    #nativedata=${DATAdir}/surfaces/${source}/workbench/${source}.${hemi}.thickness.native.shape.gii
		elif [ "$data" = "MyelinMap" ] ; then
		    nativedata=${DATAdir}/surfaces/${source}/workbench/${source}.${hemi}.MyelinMap.native.func.gii	    
		fi

		registered_sphere=${OutputTemplateFolder}/${source}_week${week}/${source}-Conte69.${hemi}.sphere.dedrift.curv.iter${iter}.surf.gii 
		sphereConte=${atlasDir}/Conte69.${hemi}.sphere.32k_fs_LR_recentred.surf.gii

		dataResampled=${OutputTemplateFolder}/${source}_week${week}/${source}.${hemi}.${data}.iter${iter}.resampled

        
		arrayjobID=`echo " $arrayjobID + 1 " | bc`	       
		#create sbatch file to submit in an array
		echo "#!/bin/bash" > ${dataFile}${arrayjobID}.sh
		echo "${MSMbin}/msmresample $registered_sphere $dataResampled -labels $nativedata -project $sphereConte -adap_bary" >> ${dataFile}${arrayjobID}.sh
		chmod a+x ${dataFile}${arrayjobID}.sh

		# output ${dataResampled}.func.gii
	    done < $weights
	    
	    echo ${dataFile}'$SLURM_ARRAY_TASK_ID'".sh" >> $sbatchFile
	    jobidResample=`sbatch --array=1-$arrayjobID $sbatchFile  | sed 's/Submitted batch job //g'`
		    
	    # averaging
	    outfilename="week${week}.iter${iter}.${data}.${hemi}.AVERAGE.shape.gii"
	    
	    jobidAvdCurv=`sbatch -d $jobidResample  -J ${iter}AVG${week}${hemi}${data} -o ${outdir}/logdir/dataAVG_${week}_iter${iter}_${hemi}_avg_${data}.out -e ${outdir}/logdir/dataAVG_${week}_iter${iter}_${hemi}_avg_${data}.err -c 1 --mem=2G -p short ${Scripts}/average_data_after_reverse_msm_and_resampling.py $OutputTemplateFolder $weights $hemi  $outfilename $data $list $iter $week | sed 's/Submitted batch job //g'`
	    #${Scripts}/average_data_after_reverse_msm_and_resampling.py $OutputTemplateFolder $weights $hemi  $outfilename $data $list $iter $week
	    jobidStructure=`sbatch  -d $jobidAvdCurv -J ${iter}STR${week}${hemi}${data} -o ${outdir}/logdir/struct_${week}_iter${iter}_${hemi}_avg_${data}.out -e ${outdir}/logdir/struct_${week}_iter${iter}_${hemi}_avg_${data}.err -c 1 --mem=2G -p short  --wrap="${WBdir}/wb_command -set-structure $OutputTemplateFolder/$outfilename ${Structure} " | sed 's/Submitted batch job //g'`
	    #${WBdir}/wb_command -set-structure $OutputTemplateFolder/$outfilename ${Structure}
	done 
    done
done


