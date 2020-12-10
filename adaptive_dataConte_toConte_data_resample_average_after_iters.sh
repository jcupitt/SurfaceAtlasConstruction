# Jelena Bozek, 2018

# resample and average data (sulc, myelin, thickness) for the final template

# run with eg.:
#   ./adaptive_dataConte_toConte_data_resample_average_after_iters.sh 7
# where 7 is the final iter
# uses config/weights to get the set of scans to process

codedir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $codedir/config/paths.sh

iter=$1
if (( iter < 1 )); then
  echo "iter must be greater than or equal to 1"
  exit 1
fi

for hemi in L R; do
  if [[ $hemi = L ]]; then
    hemi_name=left
    structure=CORTEX_LEFT     
  else
    hemi_name=right
    structure=CORTEX_RIGHT
  fi

  for data in sulc thickness myelin_map; do  
    for week in {28..44}; do
      echo processing hemi $hemi, data $data, week $week ...

      outfilename=week$week.iter$iter.$data.$hemi.AVERAGE.shape.gii
      weights=$codedir/config/weights/w${week}.csv
      n_prior_missing=0
      n_native_missing=0

      while IFS='' read -r line || [[ -n "$line" ]]; do
        columns=($line)
        scan=${columns[0]}
        weight=${columns[1]}

        # skip lines in to_process which are not image specs
        if ! [[ $scan =~ (CC.*)-(.*) ]]; then
          continue
        fi
        subject=${BASH_REMATCH[1]}
        session=${BASH_REMATCH[2]}

        registered_sphere=$outdir/adaptive_subjectsToDataConteALL/${scan}_week$week/$scan-Conte69.$hemi.sphere.dedrift.curv.iter$iter.surf.gii 
        data_resampled=$outdir/adaptive_subjectsToDataConteALL/${scan}_week$week/$scan.$hemi.$data.iter$iter.resampled
        sphere_conte=$conte_atlas_dir/Conte69.$hemi.sphere.32k_fs_LR.surf.gii

        case $data in
          sulc | thickness)
            native_data=$struct_pipeline_dir/sub-$subject/ses-$session/anat/Native/sub-${subject}_ses-${session}_${hemi_name}_$data.shape.gii
            ;;

          myelin_map)
            # called .func.gii
            native_data=$struct_pipeline_dir/sub-$subject/ses-$session/anat/Native/sub-${subject}_ses-${session}_${hemi_name}_$data.func.gii
            ;;
        esac

        if [ ! -f $registered_sphere ]; then
          # one of our ~140 failures
          (( n_prior_missing += 1 ))
          continue
        fi

        if [ ! -f $native_data ]; then
          # struct pipeline failure
          (( n_native_missing += 1 ))
          continue
        fi

        run msmresample \
          $registered_sphere \
          $data_resampled \
          -labels $native_data \
          -project $sphere_conte \
          -adap_bary

      done < $weights;

      if [[ $n_prior_missing > 0 ]]; then
        run echo skipped $n_prior_missing missing prior surfaces
      fi

      if [[ $n_native_missing > 0 ]]; then
        run echo skipped $n_native_missing missing native surfaces
      fi

      run ./average_data_after_reverse_msm_and_resampling.py \
        $outdir/adaptive_subjectsToDataConteALL \
        $weights \
        $hemi  \
        $outfilename \
        $data \
        $iter \
        $week 
      
      run wb_command -set-structure \
        $outdir/adaptive_subjectsToDataConteALL/$outfilename \
        $structure 

    done 
  done
done


