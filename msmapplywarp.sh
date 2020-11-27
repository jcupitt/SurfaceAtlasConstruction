#!/bin/bash

# the final set of warps, eg.:
#
#   ./msmapplywarp.sh 12 CCxxx-yyy 0.777 L 7
#
# where "12" is the job id from eg. condor

set -e

jid=$1 
shift
codedir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $codedir/config/paths.sh

scan=$1
week=$2
iter=$3
hemi=$4
weight=$5

# skip lines which are not image specs
if ! [[ $scan =~ (CC.*)-(.*) ]]; then
  continue
fi
subject=${BASH_REMATCH[1]}
session=${BASH_REMATCH[2]}

if [[ $hemi == L ]]; then
  hemi_name=left
else
  hemi_name=right
fi
data="curv"

registered_sphere=$outdir/adaptive_subjectsToDataConteALL/${scan}_week$week/$scan-Conte69.$hemi.sphere.${data}.iter${iter}.surf.gii  
output_anatomy_resampled=$outdir/adaptive_subjectsToDataConteALL/${scan}_week$week/${scan}-Conte69.$hemi.sphere.iter${iter}_resampled
# Jelena had Conte69.$hemi.sphere.32k_fs_LR_recentred.surf.gii, but we 
# only have this available :( 
sphere_conte=$conte_atlas_dir/Conte69.$hemi.sphere.32k_fs_LR.surf.gii
anat_conte=$conte_atlas_dir/Conte69.$hemi.sphere.32k_fs_LR.surf.gii
original_anatomy=$struct_pipeline_dir/sub-$subject/ses-$session/anat/Native/sub-${subject}_ses-${session}_${hemi_name}_sphere.surf.gii
output_neonatal_anat_affine_aligned=$outdir/adaptive_subjectsToDataConteALL/${scan}_week$week/$scan-Conte69.$hemi.sphere.iter${iter}_affine
output_anatomy_resampled=$outdir/adaptive_subjectsToDataConteALL/${scan}_week$week/$scan-Conte69.$hemi.sphere.iter${iter}_resampled
output_anatomy_resampled_base=$outdir/adaptive_subjectsToDataConteALL/${scan}_week$week/$scan-Conte69.$hemi.sphere.iter${iter}_final

run msmapplywarp \
  $registered_sphere \
  $output_anatomy_resampled \
  -anat $sphere_conte $anat_conte

run msmapplywarp \
  $original_anatomy \
  $output_neonatal_anat_affine_aligned \
  -deformed ${output_anatomy_resampled}_anatresampled.surf.gii  \
  -original $original_anatomy \
  -affine \
  -writeaffine

run msmapplywarp \
  $sphere_conte \
  $output_anatomy_resampled_base \
  -anat ${registered_sphere} \
    ${output_neonatal_anat_affine_aligned}_warp.surf.gii

