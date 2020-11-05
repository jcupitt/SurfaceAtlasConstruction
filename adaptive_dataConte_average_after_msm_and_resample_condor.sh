#!/bin/bash

# Jelena Bozek, 2018

# average using adaptive kernel weighting for iter=0; averages cortical 
# features sulc and curv

# run with eg.:
#   ./adaptive_dataConte_average_after_msm_and_resample_condor.sh 

set -e

codedir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $codedir/config/paths.sh
script=adaptive_dataConte_average_after_msm_and_resample

to_process=$1
condor_spec=$outdir/tmp/$script.$$.condor
in_dir=$outdir/subjectsToDataConteALL
out_base=$outdir/adaptive_subjectsToDataConteALL

mkdir -p $outdir/tmp
mkdir -p $outdir/logs
mkdir -p $out_base

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

for data in "curv" "sulc" ; do
	for hemi in L R; do
		for week in {28..44}; do
      kernel=adaptive
      sigma=1 # 0.25 0.5 0.75 1

      weights=$codedir/config/weights/w$week.csv
      out_file=week$week.init.$data.$hemi.AVERAGE.shape.gii

      # has this job completed previously? test for the existence of the final
      # file the script makes
      if [ -f $out_base/$out_file ]; then
        continue
      fi

      echo "" >> $condor_spec
      echo "arguments = \$(Process) $codedir/dataConte_average_after_msm.py \
        $in_dir \
        $weights \
        $hemi \
        $out_base \
        $out_file \
        $data" >> $condor_spec
      echo "Queue" >> $condor_spec
    done
  done
done 

condor_submit $condor_spec
