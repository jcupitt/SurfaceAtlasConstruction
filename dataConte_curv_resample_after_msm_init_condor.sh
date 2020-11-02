#!/bin/bash

# run with eg.:
#   ./affine_to_Conte_condor.sh config/subjects.tsv

set -e

codedir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $codedir/config/paths.sh
script=dataConte_curv_resample_after_msm_init

to_process=$1
condor_spec=$outdir/tmp/$script.$$.condor

mkdir -p $outdir/tmp
mkdir -p $outdir/logs

echo generating tmp/$(basename $condor_spec) ...
echo "# condor submit file for $script.sh" > $condor_spec 
echo -n "# " >> $condor_spec 
date >> $condor_spec 
cat >> $condor_spec <<EOF
Executable = $script.sh 
Universe   = vanilla
Log        = $outdir/logs/\$(Process).condor.$script.log
error      = $outdir/logs/\$(Process).condor.$script.err
EOF

while IFS='' read -r line || [[ -n "$line" ]]; do
  columns=($line)
  scan=${columns[0]}
  age=${columns[1]}

  # skip lines in to_process which are not image specs
  if ! [[ $scan =~ (CC.*)-(.*) ]]; then
    continue
  fi
  subject=${BASH_REMATCH[1]}
  session=${BASH_REMATCH[2]}

  for hemi in L R; do
    # has this job completed previously? test for the existence of the final
    # file the script makes
    out_data=$outdir/subjectsToDataConteALL/$scan/$scan-Conte69.L.init.curv.func.gii
    if [ -f $out_data ]; then
      continue
    fi

    echo "" >> $condor_spec
    echo "arguments = \$(Process) $scan $age $hemi" >> $condor_spec
    echo "Queue" >> $condor_spec
  done
done < $to_process

condor_submit $condor_spec
