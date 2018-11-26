#!/bin/bash

# Jelena Bozek, 2018

#set -x

Scripts=/vol/medic01/users/jbozek/scripts_affine_Conte
MSMbin=/vol/medic01/users/jbozek/MSM 
WBdir=/vol/medic01/users/jbozek/workbench/exe_linux64

outdir=${Scripts}/slurm #adaptive_slurm
mkdir -p $outdir/logdir

list=/vol/medic01/users/jbozek/scripts/subjLISTS/subjs_270_ageScan_week.csv

affinedir=/vol/medic01/users/jbozek/MSMtemplate/affineToConte
DATAdir=/vol/dhcp-derived-data/structural-pipeline/dhcp-v2.4
atlasDir=/vol/medic01/users/jbozek/HCP_standard_mesh_atlases/Conte69/MNINonLinear/fsaverage_LR32k

OutputTemplateFolder=/vol/medic01/users/jbozek/MSMtemplate/adaptive_subjectsToDataConteALL

data="curv"
kernel=adaptive
sigma=1

AFFINE=""  # set to "YES" if you also want to generate anatomical average after affine registration
for iter in 30 ; do # set to the final iteration for which you want to compute the average sphere
    prevIter=`echo " $iter - 1 " | bc` 

    for hemi in L R ; do  #R ; do
	for surf in  sphere ; do  # white inflated pial very_inflated
	
	    if [ $hemi = "L" ] ;   then  Structure="CORTEX_LEFT"			
	    elif [ $hemi = "R" ] ; then  Structure="CORTEX_RIGHT" ;  fi
	    echo $surf

	    for week in {36..44} ; do
		jobhold=""
		surfsAnat=""
		echo $week

		arrayjobID=0
		sbatchFile=${Scripts}/batchSlurm/anatFile_beforeDrift_${week}_iter${iter}_${hemi}_${surf}.sbatch
		mkdir -p ${OutputTemplateFolder}/scripts
		dataFile=${OutputTemplateFolder}/scripts/averageBeforeDedrift_${hemi}_iter${iter}_week${week}_${surf}_input

		echo "#!/bin/bash" > $sbatchFile
		echo "#SBATCH -J ${week}${hemi}${iter}${surf} " >> $sbatchFile 
		echo "#SBATCH -c 1 " >> $sbatchFile 
		echo "#SBATCH -p long " >> $sbatchFile
		echo "#SBATCH --mem-per-cpu=2000 " >> $sbatchFile
		echo "#SBATCH -o ${outdir}/logdir/individualAvg_week${week}_iter${iter}_${hemi}_${surf}_%A_%a.out" >> $sbatchFile
		echo "#SBATCH -e ${outdir}/logdir/individualAvg_week${week}_iter${iter}_${hemi}_${surf}_%A_%a.err" >> $sbatchFile

		weights=/vol/medic01/users/jbozek/new_weights/results/etc-${kernel}/kernel_sigma=${sigma}/weights_t=${week}.csv

		while read line ; do
		    source=`echo $line | awk '{print $1}'`		    
		    weight=`grep $source $weights | awk '{print $2}'`
		   
		    sphereConte=${atlasDir}/Conte69.${hemi}.sphere.32k_fs_LR_recentred.surf.gii
		    anatConte=${atlasDir}/Conte69.${hemi}.${surf}.32k_fs_LR.surf.gii    		   

		    arrayjobID=`echo " $arrayjobID + 1 " | bc`

		    #create sbatch file to submit in an array
		    echo "#!/bin/bash" > ${dataFile}${arrayjobID}.sh

		    # do the nonlinear final anatomy, after iter=$iter
		    registered_sphere=${OutputTemplateFolder}/${source}_week${week}/${source}-Conte69.${hemi}.sphere.${data}.iter${iter}.surf.gii  
		    
		    original_anatomy=$DATAdir/surfaces/${source}/workbench/${source}.$hemi.$surf.native.surf.gii

		    output_neonatal_anat_affine_aligned=${OutputTemplateFolder}/${source}_week${week}/${source}-Conte69.${hemi}.${surf}.iter${iter}_affine
		    output_anatomy_resampled=${OutputTemplateFolder}/${source}_week${week}/${source}-Conte69.${hemi}.${surf}.iter${iter}_resampled
		    output_anatomy_resampled_base=${OutputTemplateFolder}/${source}_week${week}/${source}-Conte69.${hemi}.${surf}.iter${iter}_final
	

		    echo "${MSMbin}/msmapplywarp ${registered_sphere} $output_anatomy_resampled -anat  $sphereConte  $anatConte" >> ${dataFile}${arrayjobID}.sh
		    echo "${MSMbin}/msmapplywarp  $original_anatomy $output_neonatal_anat_affine_aligned -deformed ${output_anatomy_resampled}_anatresampled.surf.gii  -original $original_anatomy -affine -writeaffine" >> ${dataFile}${arrayjobID}.sh

		    echo "${MSMbin}/msmapplywarp $sphereConte $output_anatomy_resampled_base  -anat ${registered_sphere} ${output_neonatal_anat_affine_aligned}_warp.surf.gii" >> ${dataFile}${arrayjobID}.sh
		    chmod a+x ${dataFile}${arrayjobID}.sh

		    surfsAnat="$surfsAnat -surf ${output_anatomy_resampled_base}_anatresampled.surf.gii -weight $weight "


		done  < $weights

		echo ${dataFile}'$SLURM_ARRAY_TASK_ID'".sh" >> $sbatchFile
		jobidWarp=`sbatch  $jobhold --array=1-$arrayjobID $sbatchFile  | sed 's/Submitted batch job //g'`
				
		# average 
		jobAvg=`sbatch -d $jobidWarp -J avg${week}${hemi}${surf} -o ${outdir}/logdir/avg_before_dedrift_${week}_iter${iter}_${hemi}_${surf}.out -e ${outdir}/logdir/avg_before_dedrift_${week}_iter${iter}_${hemi}_${surf}.err -c 1 --mem=2G -p short  --wrap="${WBdir}/wb_command -surface-average ${OutputTemplateFolder}/week${week}.iter${iter}.${surf}.${hemi}.AVERAGE.surf.gii ${surfsAnat}" | sed 's/Submitted batch job //g'`
		jobStr=`sbatch  -d $jobAvg -J str${week}${hemi}${surf} -o ${outdir}/logdir/str_before_dedrift_${week}_iter${iter}_${hemi}_${surf}.out -e ${outdir}/logdir/str_before_dedrift_${week}_iter${iter}_${hemi}_${surf}.err -c 1 --mem=2G -p short  --wrap="${WBdir}/wb_command -set-structure  ${OutputTemplateFolder}/week${week}.iter${iter}.${surf}.${hemi}.AVERAGE.surf.gii  ${Structure}" | sed 's/Submitted batch job //g'`
	    done
	done
    done
done


