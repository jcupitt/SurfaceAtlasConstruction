#!/bin/bash

# run with eg.:
#   ./adaptive_dataConte_average_after_reverse_msm_and_resampling_condor.sh 0

set -e

codedir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $codedir/config/paths.sh
script=average_data_after_reverse_msm_and_resampling

iter=$1
condor_spec=$outdir/tmp/$script.$$.condor
in_dir=$outdir/adaptive_subjectsToDataConteALL

mkdir -p $outdir/tmp
mkdir -p $outdir/logs

echo generating tmp/$(basename $condor_spec) ...
echo "# condor submit file for $script.py" > $condor_spec 
echo -n "# " >> $condor_spec 
date >> $condor_spec 
cat >> $condor_spec <<EOF
Executable = $codedir/python.sh
Universe   = vanilla
Log        = $outdir/logs/\$(Process).condor.$script.log
error      = $outdir/logs/\$(Process).condor.$script.err
EOF

for hemi in L R; do
  for week in {28..44}; do
    weights=$codedir/config/weights/w$week.csv
    out_file=week$week.iter$iter.curv.$hemi.AVERAGE.shape.gii

    # has this job completed previously? test for the existence of the final
    # file the script makes
    if [ -f $in_dir/$out_file ]; then
      continue
    fi

    echo "" >> $condor_spec
    echo "arguments = \$(Process) $codedir/$script.py \
      $in_dir \
      $weights \
      $hemi  \
      $out_file \
      curv \
      $iter \
      $week " >> $condor_spec
    echo "Queue" >> $condor_spec
  done
done

condor_submit $condor_spec
