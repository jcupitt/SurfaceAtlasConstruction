#!/bin/bash

# Jelena Bozek, 2018

# script registers all cases to the Conte69_fs_LR template which is setting
# a convention for the initial template; this also helps to encourage the
# L/R correspondence

codedir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $codedir/config/paths.sh

type=AFFINEtoConte

for hemi in L R ; do
  while IFS='' read -r line || [[ -n "$line" ]]; do
    columns=($line)
    source=${columns[0]}
    age=${columns[1]}
    week=${columns[2]}
    echo $source

    sbatch \
      -o $outdir/logdir/${source}_${hemi}_${type}.out \
      -e $outdir/logdir/${source}_${hemi}_${type}.err \
      -c 1 -p long \
      $scripts/affine_to_Conte.sh $source $week $hemi
  done < $to_process
done

    

