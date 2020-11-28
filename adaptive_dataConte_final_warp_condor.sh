#!/bin/bash

# Jelena Bozek, 2018

# run with eg.:
#   ./adaptive_dataConte_average_before_dedrift_condor.sh 7
# where "7" is the iteration number 
# uses config/weights to get the set of scans to process

codedir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $codedir/config/paths.sh
script=adaptive_dataConte_final_warp_condor

iter=$1
condor_spec=$outdir/tmp/$script.$$.condor

mkdir -p $outdir/tmp
mkdir -p $outdir/logs

echo generating tmp/$(basename $condor_spec) ...
echo "# condor submit file for $script " > $condor_spec 
echo -n "# " >> $condor_spec 
date >> $condor_spec 
cat >> $condor_spec <<EOF
Executable = $codedir/msmapplywarp.sh
Universe   = vanilla
Log        = $outdir/logs/\$(Process).condor.$script.log
error      = $outdir/logs/\$(Process).condor.$script.err
EOF

# these don't change
data="curv"
if (( iter < 1 )); then
  echo "iter must be greater than or equal to 1"
  exit 1
fi

n_to_process=0
n_missing_prior=0
n_previously_completed=0
n_submitted=0

for week in {28..44}; do
  weights=$codedir/config/weights/w${week}.csv

  while IFS='' read -r line || [[ -n "$line" ]]; do
    columns=($line)
    scan=${columns[0]}
    weight=${columns[1]}

    # skip lines which are not image specs
    if ! [[ $scan =~ (CC.*)-(.*) ]]; then
      continue
    fi
    subject=${BASH_REMATCH[1]}
    session=${BASH_REMATCH[2]}

    for hemi in L R; do
      (( n_to_process += 1 ))

      # missing prior?
      registered_sphere=$outdir/adaptive_subjectsToDataConteALL/${scan}_week$week/$scan-Conte69.$hemi.sphere.${data}.iter${iter}.surf.gii  
			if [ ! -f $registered_sphere ]; then
        (( n_missing_prior += 1 ))
        continue
      fi

      # has this job completed previously? 
      output_anatomy_resampled_base=$outdir/adaptive_subjectsToDataConteALL/${scan}_week$week/$scan-Conte69.$hemi.sphere.iter${iter}_final

      if [ -f ${output_anatomy_resampled_base}_anatresampled.surf.gii ]; then
        (( n_previously_completed += 1 ))
        continue
      fi

      (( n_submitted += 1 ))
      echo "" >> $condor_spec
      echo "arguments = \$(Process) \
        $scan \
        $week \
        $iter \
        $hemi \
        $weight " >> $condor_spec
      echo "Queue" >> $condor_spec

    done
  done < $weights
done

if [ $n_to_process -gt 0 ]; then
  echo "scans to process: $n_to_process"
fi
if [ $n_missing_prior -gt 0 ]; then
  echo "skipped due to missing prior iterations: $n_missing_prior"
fi
if [ $n_previously_completed -gt 0 ]; then
  echo "previously completed: $n_previously_completed"
fi
if [ $n_submitted -gt 0 ]; then
  echo "submitted: $n_submitted"
fi

if [ $n_submitted -gt 0 ]; then
  condor_submit $condor_spec
fi
