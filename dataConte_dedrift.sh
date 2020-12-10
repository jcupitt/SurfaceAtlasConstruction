#!/bin/bash

# run with eg.:
#   ./dataConte_dedrift.sh 12 CCxx-yy 28 7 L pial 0.7

jid=$1 
shift
codedir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $codedir/config/paths.sh

if [ $# -ne 6 ]; then
  echo "usage: $0 jid scan week iter hemi surf weight"
  exit 1
fi

scan=$1
week=$2
iter=$3
hemi=$4
surf=$5
weight=$6
data="curv"

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

# Jelena had Conte69.$hemi.sphere.32k_fs_LR_recentred.surf.gii, but we 
# only have this available :( 
sphere_conte=$conte_atlas_dir/Conte69.$hemi.sphere.32k_fs_LR.surf.gii
anat_conte=$conte_atlas_dir/Conte69.$hemi.$surf.32k_fs_LR.surf.gii
sphere_in=$outdir/adaptive_subjectsToDataConteALL/${scan}_week$week/$scan-Conte69.$hemi.sphere.$data.iter$iter.surf.gii  
sphere_project_to=$sphere_conte 
sphere_average=$outdir/adaptive_subjectsToDataConteALL/week$week.iter$iter.sphere.$hemi.AVERAGE.surf.gii
sphere_recentred=$outdir/adaptive_subjectsToDataConteALL/week$week.iter$iter.sphere.$hemi.AVERAGE.recentred.surf.gii
sphere_unproject_from=$sphere_recentred   #average sphere from the iteration
sphere_out=$outdir/adaptive_subjectsToDataConteALL/${scan}_week$week/$scan-Conte69.$hemi.sphere.dedrift.$data.iter$iter.surf.gii 

run wb_command \
  -surface-modify-sphere $sphere_average 100 $sphere_recentred \
  -recenter
run wb_command \
  -surface-sphere-project-unproject $sphere_in $sphere_project_to $sphere_unproject_from $sphere_out

# re-do computation of the template
# do the nonlinear final anatomy, after iter=$iter
registered_sphere=$sphere_out 
original_anatomy=$struct_pipeline_dir/sub-$subject/ses-$session/anat/Native/sub-${subject}_ses-${session}_${hemi_name}_$surf.surf.gii
output_neonatal_anat_affine_aligned=$outdir/adaptive_subjectsToDataConteALL/${scan}_week$week/$scan-Conte69.$hemi.dedrift.$surf.iter${iter}_affine
output_anatomy_resampled=$outdir/adaptive_subjectsToDataConteALL/${scan}_week$week/$scan-Conte69.$hemi.dedrift.$surf.iter${iter}_resampled
output_anatomy_resampled_base=$outdir/adaptive_subjectsToDataConteALL/${scan}_week$week/$scan-Conte69.$hemi.dedrift.$surf.iter${iter}_final

run msmapplywarp \
  $registered_sphere \
  $output_anatomy_resampled \
  -anat $sphere_conte $anat_conte

run msmapplywarp \
  $original_anatomy \
  $output_neonatal_anat_affine_aligned \
  -deformed ${output_anatomy_resampled}_anatresampled.surf.gii \
  -original $original_anatomy \
  -affine \
  -writeaffine

run msmapplywarp \
  $sphere_conte \
  $output_anatomy_resampled_base  \
  -anat ${registered_sphere} \
    ${output_neonatal_anat_affine_aligned}_warp.surf.gii

