#!/bin/bash

# run with eg.:
#   ./pre_rotation.sh CC00058XX13-34534 43 L

codedir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $codedir/config/paths.sh

if [ $# -ne 3 ]; then
  echo "usage: $0 scan week hemi"
  exit 1
fi

scan=$1 
week=$2
hemi=$3

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

in_volume=${indir}/derivatives/sub-$subject/ses-$session/anat/sub-${subject}_ses-${session}_T2w_restore_brain.nii.gz
in_sphere=${indir}/sub-$subject/ses-$session/anat/Native/sub-${subject}_ses-${session}_${hemi_name}_sphere.surf.gii
vol_template=$volumetric_atlas_dir/average/t2w/t$week.nii.gz

surf_transform=/vol/medic01/users/ecr05/dHCP_processing/TEMPLATES/new_surface_template/week40.iter30.sphere.%hemi%.dedrift.AVERAGE_removedAffine.surf.gii

out_dof=$5
out_sphere=$6


# used to run with:

${SURF2TEMPLATE}/surface_to_template_alignment/pre_rotation.sh $native_volume
$native_sphereL $templatevolume $pre_rotationL
$outdir/volume_dofs/${subjid}-${session}.dof ${native_rot_sphereL}  $mirtk_BIN
$WB_BIN

in_volume=$1
in_sphere=$2
vol_template=$3
surf_transform=$4
out_dof=$5
out_sphere=$6
mirtk=$7
wb_command=$8

out_doftxt=$(echo $out_dof | sed 's/\.dof/\.txt/g')

echo newnames $out_dof $out_doftxt $intermediate_sphere

echo mirtk register $vol_template $in_volume  -model Rigid -sim NMI -bins 64 -dofout $out_dof

if [ ! -f $out_doftxt ]; then
    $mirtk register $vol_template $in_volume  -model Rigid -sim NMI -bins 64 -dofout $out_dof

    $mirtk convert-dof $out_dof  $out_doftxt -target $vol_template -source $in_volume -output-format flirt
else
    echo "dof exists!"
fi


intermediate_sphere=$(echo $in_sphere | sed 's/.surf.gii/tmp_rot.surf.gii/g')

$wb_command -surface-apply-affine $in_sphere $out_doftxt $intermediate_sphere

$wb_command -surface-modify-sphere  $intermediate_sphere 100 $intermediate_sphere -recenter

$wb_command -surface-apply-affine $intermediate_sphere  $surf_transform  $out_sphere

$wb_command -surface-modify-sphere  $out_sphere 100 $out_sphere -recenter
rm $intermediate_sphere


