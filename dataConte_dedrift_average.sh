#!/bin/bash

# Jelena Bozek, 2018

#set -x

# run with eg.:
#   ./dataConte_dedrift_condor.sh 7
# where 7 is the final iter
# uses config/weights to get the set of scans to process

codedir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $codedir/config/paths.sh
script=dataConte_dedrift_average

mkdir -p $outdir/tmp
mkdir -p $outdir/logs

# these don't change
data="curv"
iter=$1
if (( iter < 1 )); then
  echo "iter must be greater than or equal to 1"
  exit 1
fi

for hemi in L R; do  #R ; do
  for surf in very_inflated midthickness white pial sphere inflated; do
    for week in {28..44}; do
      echo processing hemi $hemi, surf $surf, week $week ...

      weights=$codedir/config/weights/w${week}.csv
      n_to_process=0
      n_missing_prior=0

		  surfs_anat=""

      while IFS='' read -r line || [[ -n "$line" ]]; do
        (( n_to_process += 1 ))

        columns=($line)
        scan=${columns[0]}
        weight=${columns[1]}

        # missing prior?
        output_anatomy_resampled_base=$outdir/adaptive_subjectsToDataConteALL/${scan}_week$week/$scan-Conte69.$hemi.dedrift.$surf.iter${iter}_final
        if [ ! -f ${output_anatomy_resampled_base}_anatresampled.surf.gii ]; then
          (( n_missing_prior += 1 ))
          continue
        fi

		    surfs_anat="$surfs_anat -surf ${output_anatomy_resampled_base}_anatresampled.surf.gii -weight $weight "

      done < $weights;

      echo $n_missing_prior missing priors
      echo $n_to_process to average

		  run wb_command -surface-average \
        $outdir/adaptive_subjectsToDataConteALL/week$week.iter$iter.$surf.$hemi.dedrift.AVERAGE.surf.gii \
        $surfs_anat

      if [ $hemi == L ]; then 	
        structure=CORTEX_LEFT			
      elif [ $hemi == R ]; then  
        structure=CORTEX_RIGHT
      fi

		  run wb_command \
        -set-structure $outdir/adaptive_subjectsToDataConteALL/week$week.iter$iter.$surf.$hemi.dedrift.AVERAGE.surf.gii $structure

    done
  done 
done

