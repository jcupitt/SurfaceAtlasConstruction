#!/bin/bash

# Jelena Bozek, 2018

# run with eg.:
#   ./adaptive_dataConte_toConte_iter_msm_resample_condor.sh 1
# where "1" is the iteration number 
# uses config/weights to get the set of scans to process

codedir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $codedir/config/paths.sh
script=adaptive_dataConte_toConte_iter_msm

iter=$1
condor_spec=$outdir/tmp/$script.$$.condor

mkdir -p $outdir/tmp
mkdir -p $outdir/logs

echo generating tmp/$(basename $condor_spec) ...
echo "# condor submit file for $script " > $condor_spec 
echo -n "# " >> $condor_spec 
date >> $condor_spec 
cat >> $condor_spec <<EOF
Executable = msm_template_to_subjects_iterate.sh
Universe   = vanilla
Log        = $outdir/logs/\$(Process).condor.$script.log
error      = $outdir/logs/\$(Process).condor.$script.err
EOF

# these don't change
data="curv"
kernel=adaptive
sigma=1

if (( iter < 1 )); then
  echo "iter must be greater than 0"
  exit 1
fi
# set -e before this line will terminate the script if iter == 1
(( prev_iter = iter - 1 ))

# can't have this at the top
# set -x
set -e

for week in {28..44}; do
  weights=$codedir/config/weights/w${week}.csv

  while IFS='' read -r line || [[ -n "$line" ]]; do
    columns=($line)
    scan=${columns[0]}
    weight=${columns[1]}

    # skip lines which are not image specs
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
      out_base_dir=$outdir/adaptive_subjectsToDataConteALL/${scan}_week$week

      in_mesh=$outdir/affine_to_Conte/$scan/Conte69.$hemi.sphere.AFFINE.surf.gii
      # Jelena had Conte69.$hemi.sphere.32k_fs_LR_recentred.surf.gii, but we 
      # only have this available :( 
      ref_mesh=$conte_atlas_dir/Conte69.$hemi.sphere.32k_fs_LR.surf.gii

      # guess: is this the right one?
      native_data=$struct_pipeline_dir/sub-$subject/ses-$session/anat/Native/sub-${subject}_ses-${session}_${hemi_name}_curvature.shape.gii
			ref_data=$outdir/adaptive_subjectsToDataConteALL/week${week}.iter$prev_iter.$data.$hemi.AVERAGE.shape.gii

			out_mesh=$scan-Conte69.$hemi.sphere.$data.iter$iter.surf.gii
			out_data=$scan-Conte69.$hemi.$data.iter$iter.func.gii

      # base name for the resampled data
			output_resampled=$out_base_dir/$scan.$hemi.curv.iter$iter.resampled 
			transmesh=$out_base_dir/$scan-Conte69.$hemi.sphere.$data.iter$prev_iter.surf.gii

      # has this job completed previously? test for the existence of the final
      # file the script makes in transmesh mode
      if [ -f $output_resampled.func.gii ]; then
        echo $output_resampled.func.gii exists
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
        $hemi \
        $output_resampled \
        $transmesh" >> $condor_spec
      echo "Queue" >> $condor_spec
    done
  done < $weights
done

condor_submit $condor_spec
