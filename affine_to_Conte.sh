#!/bin/bash

# run with eg.:
#   ./affine_to_Conte.sh 12 CC00058XX13 43.2 L

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

in_mesh=$outdir/pre_rotation/$subject-$session/${hemi_name}_sphere.rot.surf.gii
in_data=$struct_pipeline_dir/sub-$subject/ses-$session/anat/Native/sub-${subject}_ses-${session}_${hemi_name}_sulc.shape.gii

# Jelena had Conte69.${hemi}.sphere.32k_fs_LR_recentred.surf.gii, but we only
# have this available :( 
ref_mesh=$conte_atlas_dir/Conte69.$hemi.sphere.32k_fs_LR.surf.gii
ref_data=$conte_atlas_dir/Conte69.$hemi.32k_fs_LR.shape.gii

out_base_dir=$outdir/affine_to_Conte/$subject-$session
out_mesh=$out_base_dir/Conte69.${hemi}.sphere.AFFINE.surf.gii
out_data=$out_base_dir/Conte69.${hemi}.sulc.AFFINE.func.gii

mkdir -p $out_base_dir

# 1. MSM writes files to outdir
# 2. it will keep adding + signs to log filename to get a unique name, but 
#    this will not work reliably on NFS since file create is not atomic
# 3. therefore we must run in /tmp and copy the result to NFS on completion
tmp_dir=/tmp/$scan-$hemi.$jid.$$
rm -rf $tmp_dir
mkdir -p $tmp_dir

cd $tmp_dir

run echo "### Affine to Conte69, source = $source, week = $week"
run msm \
    --levels=1 \
    --conf=$config/config_strain_NEWSTRAIN_SPHERE_FS_LR_AFFINE \
    --inmesh=${in_mesh} \
    --refmesh=${ref_mesh} \
    --indata=${in_data} \
    --refdata=${ref_data} \
    --out=$tmp_dir/$hemi- \
    --verbose

run cp $tmp_dir/$hemi-sphere.reg.surf.gii $out_mesh
run cp $tmp_dir/$hemi-transformed_and_reprojected.func.gii $out_data

run rm -rf $tmp_dir

run echo "done with affine"

