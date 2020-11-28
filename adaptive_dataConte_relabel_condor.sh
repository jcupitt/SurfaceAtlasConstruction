#!/bin/bash

# run with eg.:
#   ./adaptive_dataConte_relabel_condor.sh 6

set -e

codedir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $codedir/config/paths.sh
script=adaptive_dataConte_relabel

iter=$1
condor_spec=$outdir/tmp/$script.$$.condor
in_dir=$outdir/adaptive_subjectsToDataConteALL

if (( iter < 0 )); then
  echo "iter must be greater than or equal to 0"
  exit 1
fi

mkdir -p $outdir/tmp
mkdir -p $outdir/logs

echo generating tmp/$(basename $condor_spec) ...
echo "# condor submit file for $script.py" > $condor_spec 
echo -n "# " >> $condor_spec 
date >> $condor_spec 
cat >> $condor_spec <<EOF
Executable = $codedir/workbench.sh
Universe   = vanilla
Log        = $outdir/logs/\$(Process).condor.$script.log
error      = $outdir/logs/\$(Process).condor.$script.err
EOF

for hemi in L R; do
  for week in {28..44}; do
    out_file=week$week.iter$iter.curv.$hemi.AVERAGE.shape.gii

		if [ $hemi == L ]; then 	
      structure=CORTEX_LEFT			
		elif [ $hemi == R ]; then  
      structure=CORTEX_RIGHT
		fi

    echo "" >> $condor_spec
    echo "arguments = \$(Process) \
      -set-structure $in_dir/$out_file ${structure} " >> $condor_spec
    echo "Queue" >> $condor_spec
  done
done

condor_submit $condor_spec
