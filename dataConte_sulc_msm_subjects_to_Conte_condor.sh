#!/bin/bash

# run with eg.:
#   ./dataConte_sulc_msm_subjects_to_Conte_condor.sh config/subjects.tsv

set -e

codedir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $codedir/config/paths.sh

to_process=$1
condor_spec=$outdir/tmp/dataConte_sulc_msm_subjects_to_Conte.$$.condor

mkdir -p $outdir/tmp
mkdir -p $outdir/logs

echo generating tmp/$(basename $condor_spec) ...
echo "# condor submit file for pre_rotation.sh" > $condor_spec 
echo -n "# " >> $condor_spec 
date >> $condor_spec 
cat >> $condor_spec <<EOF
Executable = msm_template_to_subjects_iterate.sh
Universe   = vanilla
Log        = $outdir/logs/\$(Process).condor.dataConte_sulc_msm_subjects_to_Conte.log
error      = $outdir/logs/\$(Process).condor.dataConte_sulc_msm_subjects_to_Conte.err
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
    if [[ $hemi = L ]]; then
      hemi_name=left
    else
      hemi_name=right
    fi

    conf=$codedir/config/config_strain_NEWSTRAIN_SPHERE_LONGITUDINAL_new

    # Jelena had Conte69.${hemi}.sphere.32k_fs_LR_recentred.surf.gii, but we 
    # only have this available :( 
    in_base_dir=$outdir/affine_to_Conte/$subject-$session
    in_mesh=$in_base_dir/Conte69.$hemi.sphere.AFFINE.surf.gii
    ref_mesh=$conte_atlas_dir/Conte69.$hemi.sphere.32k_fs_LR.surf.gii

    # guess: is this the right one?
    native_data=$struct_pipeline_dir/sub-$subject/ses-$session/anat/Native/sub-${subject}_ses-${session}_${hemi_name}_sulc.shape.gii
    ref_data=$conte_atlas_dir/Conte69.$hemi.32k_fs_LR.shape.gii

    out_base_dir=$outdir/subjectsToDataConteALL/$scan
    out_mesh=$scan-Conte69.$hemi.sphere.init.sulc.surf.gii
    out_data=$scan-Conte69.$hemi.init.sulc.func.gii

    temp_dir=$out_base_dir/toConte_${scan}_${hemi}_iter0
    mkdir -p $temp_dir

    # has this job completed previously? test for the existence of the final
    # file the script makes
    if [ -f $out_base_dir/$out_data ]; then
      continue
    fi

    echo "" >> $condor_spec
    echo "arguments = \$(Process) \
      $conf \
      $in_mesh \
      $ref_mesh \
      $native_data \
      $ref_data \
      $out_base_dir \
      $out_mesh \
      $out_data \
      $hemi" >> $condor_spec
    echo "Queue" >> $condor_spec
  done
done < $to_process

condor_submit $condor_spec
