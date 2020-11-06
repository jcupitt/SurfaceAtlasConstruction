#!/bin/bash

# run with eg.:
# 
#   ./msm_template_to_subjects_iterate.sh 12 \
#       $codedir/config/config_strain_NEWSTRAIN_SPHERE_LONGITUDINAL_new \
#       inmesh \
#       refmesh \
#       indata \
#       refdata \
#       out_dir \
#       out_mesh \
#       out_data \
#       hemi \
#       output \
#       transmesh
#
# the first number is the job id, usually issued by condor etc., and is used
# to generate filenames unique to this task
# 
# last two args optional

jid=$1 
shift
codedir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $codedir/config/paths.sh

# last two optional
if [ $# -lt 8 ]; then
  echo "usage: $0 jid ..."
  exit 1
fi

set -x
set -e

conf=$1
inmesh=$2
refmesh=$3 
indata=$4 
refdata=$5
out_dir=$6
out_mesh=$7
out_data=$8
hemi=$9
output=${10}
transmesh=${11}

# 1. MSM writes files to outdir
# 2. it will keep adding + signs to log filename to get a unique name, but 
#    this will not work reliably on NFS since file create is not atomic
# 3. therefore we must run in /tmp and copy the result to NFS on completion
tmp_dir=/tmp/msm_template_to_subjects_iterate.$jid.$$
rm -rf $tmp_dir
mkdir -p $tmp_dir
cd $tmp_dir

run echo "### Doing nonlinear MSM  ###"

if [ -e "$transmesh" ] ; then
  run echo "transmesh exists"
  run msm \
    --levels=3 \
    --conf=${conf} \
    --inmesh=$inmesh \
    --refmesh=$refmesh \
    --indata=$indata \
    --refdata=$refdata \
    --out=$tmp_dir/$hemi. \
    --verbose \
    --trans=$transmesh

else 
  run echo "no trans mesh"
  run msm \
    --levels=3 \
    --conf=$conf \
    --inmesh=$inmesh \
    --refmesh=$refmesh \
    --indata=$indata \
    --refdata=$refdata \
    --out=$tmp_dir/$hemi. \
    --verbose 

fi

mkdir -p $out_dir
cp $tmp_dir/$hemi.sphere.reg.surf.gii $out_dir/$out_mesh
cp $tmp_dir/$hemi.transformed_and_reprojected.func.gii $out_dir/$out_data
echo "done with msm"
echo "output mesh is $out_mesh"
echo ""

if [ -e "$transmesh" ] ; then
  run echo "resample output data"
  run msmresample $out_dir/$out_mesh $output \
    -project $refmesh \
    -labels $indata \
    -adap_bary
fi
