#!/bin/bash

# Jelena Bozek, 2018

#set -x


Scripts=/vol/medic01/users/jbozek/scripts_affine_Conte
MSMbin=/vol/medic01/users/jbozek/MSM 
WBdir=/vol/medic01/users/jbozek/workbench/exe_linux64
MIRTKdir=/vol/dhcp-derived-data/binaries/ubuntu-14/mirtk/dhcp-v1/bin

OutputTemplateFolder=/vol/medic01/users/jbozek/MSMtemplate/adaptive_subjectsToDataConteALL
dofDir=${OutputTemplateFolder}/dofdir
vtkDir=${OutputTemplateFolder}/vtk

mkdir -p $vtkDir

outdir=${Scripts}/slurm #adaptive_slurm
mkdir -p $outdir/logdir

iter=30 # set the final iteration
kernel=adaptive
sigma=1

for hemi in  L R ; do #
    for surf in very_inflated midthickness white pial  sphere inflated ; do
	
	if [ $hemi = "L" ] ;   then  Structure="CORTEX_LEFT"			
	elif [ $hemi = "R" ] ; then  Structure="CORTEX_RIGHT" ; fi
	echo $surf
	
	for week in {36..44} ; do
	    echo $week

	    weights=/vol/medic01/users/jbozek/new_weights/results/etc-${kernel}/kernel_sigma=${sigma}/weights_t=${week}.csv

	    sbatchFileAvg=${Scripts}/batchSlurm/removeAff_File_${week}_iter${iter}_${hemi}.sbatch
	    
	    echo "#!/bin/bash" > $sbatchFileAvg
	    echo "#SBATCH -J ${hemi}${iter}DIST${data} " >> $sbatchFileAvg 
	    echo "#SBATCH -c 1 " >> $sbatchFileAvg 
	    echo "#SBATCH -p short " >> $sbatchFileAvg
	    echo "#SBATCH --mem-per-cpu=2000 " >> $sbatchFileAvg
	    echo "#SBATCH -o ${outdir}/logdir/removeAff_week${week}_iter${iter}_${hemi}_${data}.out" >> $sbatchFileAvg
	    echo "#SBATCH -e ${outdir}/logdir/removeAff_week${week}_iter${iter}_${hemi}_${data}.err" >> $sbatchFileAvg

	    while read line ; do
		source=`echo $line | awk '{print $1}'`

		OutputRegFolder=${OutputTemplateFolder}/${source}_week${week}

		# convert matrix into dof file
		output_neonatal_anat_affine_aligned=${OutputRegFolder}/${source}-Conte69.${hemi}.dedrift.${surf}.iter${iter}_affine
	
		mkdir -p $dofDir/$week

		echo " ${MIRTKdir}/mirtk convert-dof ${output_neonatal_anat_affine_aligned}_affinewarp.txt $dofDir/$week/${source}-Conte69.${hemi}.dedrift.${surf}.iter${iter}_affine_affinewarp.dof -input-format aladin " >> $sbatchFileAvg

	    done < $weights

	    # average dofs
	    echo " ${MIRTKdir}/mirtk average-dofs ${OutputTemplateFolder}/week${week}_dedrift.dof -v -all -invert -norigid -dofdir  $dofDir/$week -dofnames $weights -prefix '' -suffix -Conte69.${hemi}.dedrift.${surf}.iter${iter}_affine_affinewarp.dof " >> $sbatchFileAvg


	    # apply new dof to averaged mesh
	    # convert everything to .vtk and apply dof to vtks; when obtaining new average, set the structure
	    echo " ${MIRTKdir}/mirtk convert-pointset ${OutputTemplateFolder}/week${week}.iter${iter}.${surf}.${hemi}.dedrift.AVERAGE.surf.gii ${vtkDir}/week${week}.iter${iter}.${surf}.${hemi}.dedrift.AVERAGE.surf.vtk " >> $sbatchFileAvg


	    echo " ${MIRTKdir}/mirtk transform-points  ${vtkDir}/week${week}.iter${iter}.${surf}.${hemi}.dedrift.AVERAGE.surf.vtk ${vtkDir}/week${week}.iter${iter}.${surf}.${hemi}.dedrift.AVERAGE_removedAffine.surf.vtk -dofin ${OutputTemplateFolder}/week${week}_dedrift.dof " >> $sbatchFileAvg

	    echo " ${MIRTKdir}/mirtk convert-pointset ${vtkDir}/week${week}.iter${iter}.${surf}.${hemi}.dedrift.AVERAGE_removedAffine.surf.vtk ${OutputTemplateFolder}/week${week}.iter${iter}.${surf}.${hemi}.dedrift.AVERAGE_removedAffine.surf.gii " >> $sbatchFileAvg


	    echo " ${WBdir}/wb_command -set-structure  ${OutputTemplateFolder}/week${week}.iter${iter}.${surf}.${hemi}.dedrift.AVERAGE_removedAffine.surf.gii  ${Structure} " >> $sbatchFileAvg

	    #recentre the sphere
	    if [ "$surf" == "sphere" ] ; then
		echo " ${WBdir}/wb_command -surface-modify-sphere ${OutputTemplateFolder}/week${week}.iter${iter}.${surf}.${hemi}.dedrift.AVERAGE_removedAffine.surf.gii 100 ${OutputTemplateFolder}/week${week}.iter${iter}.${surf}.${hemi}.dedrift.AVERAGE_removedAffine.surf.gii -recenter " >> $sbatchFileAvg
	    fi

	    sbatch  $sbatchFileAvg 
	done
    done
done



