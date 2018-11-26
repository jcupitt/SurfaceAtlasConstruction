#!/bin/bash

# Jelena Bozek, 2018

# script registers all cases to the Conte69_fs_LR template which is setting a convention for the initial template; this also helps to encourage the L/R correspondence

Scripts=/vol/medic01/users/jbozek/scripts_affine_Conte

outdir=${Scripts}/affine
mkdir -p $outdir/logdir

type=AFFINEtoConte

list=/vol/medic01/users/jbozek/scripts/subjLISTS/subjs_270_ageScan_week.csv

for hemi in L R ; do
while read line ; do

    source=`echo $line | awk '{print $1}'`
    age=`echo $line | awk '{print $2}'`
    week=`echo $line | awk '{print $3}'`
    echo $source

    sbatch  -o ${outdir}/logdir/${source}_${hemi}_${type}.out -e  ${outdir}/logdir/${source}_${hemi}_${type}.err -c 1 -p long ${Scripts}/affine_to_Conte.sh $source $week $hemi


done < $list

done

    

