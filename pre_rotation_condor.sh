#!/bin/bash

# run with eg.:
#   ./pre_rotation_condor.sh config/subjects.tsv

set -e

codedir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $codedir/config/paths.sh

to_process=$1
condor_spec=$outdir/tmp/pre_rotation.$$.condor

mkdir -p $outdir/tmp
mkdir -p $outdir/logs

echo generating tmp/$(basename $condor_spec) ...
echo "# condor submit file for pre_rotation.sh" > $condor_spec 
echo -n "# " > $condor_spec 
date >> $condor_spec 
cat >> $condor_spec <<EOF
  Executable = pre_rotation.sh
  Universe   = vanilla
  Log        = $outdir/logs/\$(Process).condor.pre_rotation.log
  error      = $outdir/logs/\$(Process).condor.pre_rotation.err
EOF

while IFS='' read -r line || [[ -n "$line" ]]; do
  columns=($line)
  scan=${columns[0]}
  age=${columns[1]}

  if ! [[ $scan =~ (CC.*)-(.*) ]]; then
    continue
  fi

  for hemi in L R; do
    echo "arguments = $scan $age $hemi" >> $condor_spec
    echo "Queue" >> $condor_spec
    echo "" >> $condor_spec
  done
done < $to_process

condor_submit $condor_spec
