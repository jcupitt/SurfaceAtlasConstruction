#!/bin/bash

# Jelena Bozek, 2018

# run with eg.:
#   ./dataConte_curv_resample_after_msm_init.sh 12 CC00507XX12-148202 42 L

jid=$1 
codedir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $codedir/config/paths.sh

if [ $# -ne 4 ]; then
  echo "usage: $0 jid scan week hemi"
  exit 1
fi

scan=$2 
week=$3
hemi=$4

if ! [[ $scan =~ (CC.*)-(.*) ]]; then
  echo "bad scan $scan"
  exit 1
fi
subject=${BASH_REMATCH[1]}
session=${BASH_REMATCH[2]}

if ! [[ $hemi =~ L|R ]]; then
  echo "bad hemi $hemi"
  exit 1
fi
if [[ $hemi = L ]]; then
  hemi_name=left
else
  hemi_name=right
fi

mkdir -p $outdir/logdir

out_base_dir=$outdir/subjectsToDataConteALL/$scan

# Jelena had Conte69.${hemi}.sphere.32k_fs_LR_recentred.surf.gii, but we only
# have this available :(
ref_mesh=$conte_atlas_dir/Conte69.$hemi.sphere.32k_fs_LR.surf.gii

run msmresample \
  $out_base_dir/$scan-Conte69.$hemi.sphere.init.sulc.surf.gii \
  $out_base_dir/$scan-Conte69.$hemi.init.curv \
  -labels $struct_pipeline_dir/sub-$subject/ses-$session/anat/Native/sub-${subject}_ses-${session}_${hemi_name}_curvature.shape.gii \
  -project $ref_mesh \
  -adap_bary  



