#!/bin/bash

# run with eg.:
# 
#   ./pre_rotation.sh 12 CC00058XX13-34534 43 L
# 
# the first number is the job id, usually issued by condor etc., and is used
# to generate filenames unique to this task

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

# clip to schuh atlas range
if (( week > 44 )); then
  schuh_week=44
elif (( week < 28 )); then
  schuh_week=28
else
  schuh_week=$week
fi

in_volume=${indir}/sub-$subject/ses-$session/anat/sub-${subject}_ses-${session}_T2w_restore_brain.nii.gz
in_sphere=${indir}/sub-$subject/ses-$session/anat/Native/sub-${subject}_ses-${session}_${hemi_name}_sphere.surf.gii
vol_template=$volumetric_atlas_dir/templates/t2w/t$schuh_week.nii.gz
surf_transform=$codedir/rotational_transforms/week40_toFS_LR_rot.$hemi.txt
intermediate_sphere=$(echo $in_sphere | sed 's/.surf.gii/tmp_rot.surf.gii/g')

# the file we generate
out_dof=$outdir/volume_dofs/$subject-$session.dof
out_doftxt=$(echo $out_dof | sed 's/\.dof/\.txt/g')
out_sphere=$outdir/pre_rotation/$subject-$session/${hemi_name}_sphere.rot.surf.gii

mkdir -p $outdir/volume_dofs
mkdir -p $outdir/pre_rotation/$subject-$session

if [ ! -f $out_doftxt ]; then
  run mirtk register $vol_template $in_volume \
    -model Rigid -sim NMI -bins 64 -dofout $out_dof

  run mirtk convert-dof $out_dof $out_doftxt \
    -target $vol_template -source $in_volume -output-format flirt
fi

run wb_command -surface-apply-affine \
  $in_sphere $out_doftxt $intermediate_sphere

run wb_command -surface-modify-sphere  \
  $intermediate_sphere 100 $intermediate_sphere -recenter

run wb_command -surface-apply-affine \
  $intermediate_sphere $surf_transform  $out_sphere

run wb_command -surface-modify-sphere  \
  $out_sphere 100 $out_sphere -recenter

rm $intermediate_sphere
