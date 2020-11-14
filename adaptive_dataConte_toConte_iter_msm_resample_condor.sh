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

if (( iter < 0 )); then
  echo "iter must be greater than or equal to 0"
  exit 1
fi
(( prev_iter = iter - 1 ))

n_to_process=0
n_missing_prior=0
n_missing_affine_prior=0
n_previously_completed=0
n_submitted=0

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
      (( n_to_process += 1 ))

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
      if [ $iter -eq 0 ]; then
        ref_data=$outdir/adaptive_subjectsToDataConteALL/week$week.init.${data}.${hemi}.AVERAGE.shape.gii 
      else
        ref_data=$outdir/adaptive_subjectsToDataConteALL/week${week}.iter$prev_iter.$data.$hemi.AVERAGE.shape.gii
      fi

			out_mesh=$scan-Conte69.$hemi.sphere.$data.iter$iter.surf.gii
			out_data=$scan-Conte69.$hemi.$data.iter$iter.func.gii

      # base name for the resampled data
			output_resampled=$out_base_dir/$scan.$hemi.curv.iter$iter.resampled 
      if [ $iter -eq 0 ]; then
        transmesh=$outdir/subjectsToDataConteALL/$scan/$scan-Conte69.$hemi.sphere.init.sulc.surf.gii
      else
        transmesh=$out_base_dir/$scan-Conte69.$hemi.sphere.$data.iter$prev_iter.surf.gii
      fi

      # missing prior iteration?
			if [ ! -f $ref_data ]; then
        (( n_missing_prior += 1 ))
        continue
      fi

      # missing affine_to_conte
      if [ ! -f $in_mesh ]; then
        (( n_missing_affine_prior += 1 ))
        continue
      fi

      # has this job completed previously? test for the existence of the final
      # file the script makes in transmesh mode
      if [ -f $output_resampled.func.gii ]; then
        (( n_previously_completed += 1 ))
        continue
      fi

      (( n_submitted += 1 ))
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

if [ $n_to_process -gt 0 ]; then
  echo "scans to process: $n_to_process"
fi
if [ $n_missing_prior -gt 0 ]; then
  echo "skipped due to missing prior iterations: $n_missing_prior"
fi
if [ $n_missing_affine_prior -gt 0 ]; then
  echo "skipped due to missing affines: $n_missing_affine_prior"
fi
if [ $n_previously_completed -gt 0 ]; then
  echo "previously completed: $n_previously_completed"
fi
if [ $n_submitted -gt 0 ]; then
  echo "submitted: $n_submitted"
fi

if [ $n_submitted -gt 0 ]; then
  condor_submit $condor_spec
fi
