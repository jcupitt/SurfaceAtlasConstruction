#!/bin/bash

# Jelena Bozek, 2018

#average using adaptive kernel weigthing for iter=0 ; averages cortical features sulc and curv

Scripts=/vol/medic01/users/jbozek/scripts_affine_Conte

outdir=${Scripts}/slurm
mkdir -p $outdir/logdir

list=/vol/medic01/users/jbozek/scripts/subjLISTS/subjs_270_ageScan_week.csv

iter=0

jobs="SLURM" 
for data in "curv" "sulc" ; do
    for kernel in adaptive ; do
	for sigma in 1 ; do # 0.25 0.5 0.75 1 ; do
	    for hemi in  L R ; do
		for week in  {36..44} ; do

		    dirConte=/vol/medic01/users/jbozek/MSMtemplate/affineToConte
		    weights=/vol/medic01/users/jbozek/new_weights/results/etc-${kernel}/kernel_sigma=${sigma}/weights_t=${week}.csv
		    OutputTemplateFolder=/vol/medic01/users/jbozek/MSMtemplate/subjectsToDataConteALL

		    outfilename="week${week}.init.${data}.${hemi}.AVERAGE.shape.gii"
		    OutFolder=/vol/medic01/users/jbozek/MSMtemplate/adaptive_subjectsToDataConteALL

		    sbatch  -o ${outdir}/logdir/${week}_init_${hemi}_avg_${data}.out -e ${outdir}/logdir/${week}_init_${hemi}_avg_${data}.err -c 1 --mem=2G -p short ${Scripts}/dataConte_average_after_msm.py $OutputTemplateFolder $weights $hemi $OutFolder  $outfilename $data $list

		done
	    done
	done
    done
done


