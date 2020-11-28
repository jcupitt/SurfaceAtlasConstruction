#!/bin/bash

# Jelena Bozek, 2018

# run with eg.:
#   ./adaptive_dataConte_average_and_relabel.sh 7
# uses config/weights to get the set of scans to process

codedir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
jid=12
source $codedir/config/paths.sh

iter=$1
if (( iter < 1 )); then
  echo "iter must be greater than or equal to 1"
  exit 1
fi

for week in {28..44}; do
  for hemi in L R; do
    weights=$codedir/config/weights/w${week}.csv
    surfaces_to_average=""
    n_missing_surfaces=0

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

      # have we been able to make a mesh for this scan?
      output_anatomy_resampled=$outdir/adaptive_subjectsToDataConteALL/${scan}_week$week/$scan-Conte69.$hemi.sphere.iter${iter}_final_anatresampled.surf.gii

      if [ ! -f $output_anatomy_resampled ]; then
        (( n_missing_surfaces += 1 ))
        continue
      fi

		  surfaces_to_average="$surfaces_to_average -surf $output_anatomy_resampled -weight $weight "
    done < $weights

    if [ $n_missing_surfaces -gt 0 ]; then
      echo "missing surfaces: $n_missing_surfaces"
    fi

    run wb_command -surface-average \
      $outdir/adaptive_subjectsToDataConteALL/week${week}.iter${iter}.sphere.${hemi}.AVERAGE.surf.gii \
      ${surfaces_to_average}

    if [ $hemi == L ]; then 	
      structure=CORTEX_LEFT			
    elif [ $hemi == R ]; then  
      structure=CORTEX_RIGHT
    fi

		run wb_command -set-structure \
      $outdir/adaptive_subjectsToDataConteALL/week${week}.iter${iter}.sphere.${hemi}.AVERAGE.surf.gii \
      $structure

  done
done

