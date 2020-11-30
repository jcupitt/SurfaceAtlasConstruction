#!/bin/bash

# Jelena Bozek, 2018

# run with eg.:
#   ./dataConte_dedrift_condor.sh 7
# where 7 is the final iter
# uses config/weights to get the set of scans to process

codedir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $codedir/config/paths.sh
script=dataConte_dedrift_average

mkdir -p $outdir/tmp
mkdir -p $outdir/logs

# these don't change
data="curv"
iter=$1
if (( iter < 1 )); then
  echo "iter must be greater than or equal to 1"
  exit 1
fi

dof_dir=$outdir/adaptive_subjectsToDataConteALL/dofdir
vtk_dir=$outdir/adaptive_subjectsToDataConteALL/vtk
mkdir -p $vtk_dir

for hemi in L R; do  #R ; do
  for surf in very_inflated midthickness white pial sphere inflated; do
    for week in {28..44}; do
      echo processing hemi $hemi, surf $surf, week $week ...

      weights=$codedir/config/weights/w${week}.csv

      # we need to make a weights file which only contains valid scans
      tmp_weights=$outdir/tmp/temp-weights.tsv
      rm -rf $tmp_weights

      while IFS='' read -r line || [[ -n "$line" ]]; do
        columns=($line)
        scan=${columns[0]}
        weight=${columns[1]}

        # convert matrix into dof file
        output_neonatal_anat_affine_aligned=$outdir/adaptive_subjectsToDataConteALL/${scan}_week$week/$scan-Conte69.$hemi.dedrift.$surf.iter${iter}_affine

        if [ ! -f ${output_neonatal_anat_affine_aligned}_affinewarp.txt ]; then
          continue
        fi
  
        mkdir -p $dof_dir/$week

        run mirtk convert-dof \
          ${output_neonatal_anat_affine_aligned}_affinewarp.txt \
          $dof_dir/$week/$scan-Conte69.$hemi.dedrift.$surf.iter${iter}_affine_affinewarp.dof \
          -input-format aladin 

        # add to filtered weights file ... no comma
        echo $scan $weight >> $tmp_weights

      done < $weights;

      if [ $hemi == L ]; then   
        structure=CORTEX_LEFT     
      elif [ $hemi == R ]; then  
        structure=CORTEX_RIGHT
      fi

      # average dofs
      run mirtk average-dofs \
        $outdir/adaptive_subjectsToDataConteALL/week${week}_dedrift.dof \
        -v -all -invert -norigid \
        -dofdir $dof_dir/$week \
        -dofnames $tmp_weights \
        -suffix -Conte69.${hemi}.dedrift.${surf}.iter${iter}_affine_affinewarp.dof

      # average-dofs fails with a mat multiply error, perhaps a non-square
      # matrix for invert?
      exit 1

      # apply new dof to averaged mesh
      # convert everything to .vtk and apply dof to vtks; when obtaining new average, set the structure
      run mirtk convert-pointset \
        $outdir/adaptive_subjectsToDataConteALL/week$week.iter$iter.$surf.$hemi.dedrift.AVERAGE.surf.gii \
        $vtk_dir/week$week.iter$iter.$surf.$hemi.dedrift.AVERAGE.surf.vtk 

      run mirtk transform-points \
        $vtk_dir/week$week.iter$iter.$surf.$hemi.dedrift.AVERAGE.surf.vtk \
        $vtk_dir/week$week.iter$iter.$surf.$hemi.dedrift.AVERAGE_removedAffine.surf.vtk \
        -dofin $outdir/adaptive_subjectsToDataConteALL/week${week}_dedrift.dof

      run mirtk convert-pointset \
        $vtk_dir/week$week.iter$iter.$surf.$hemi.dedrift.AVERAGE_removedAffine.surf.vtk \
        $outdir/adaptive_subjectsToDataConteALL/week${week}.iter$iter.$surf.$hemi.dedrift.AVERAGE_removedAffine.surf.gii

      run wb_command -set-structure \
        $outdir/adaptive_subjectsToDataConteALL/week$week.iter$iter.$surf.$hemi.dedrift.AVERAGE_removedAffine.surf.gii \
        $structure

      # recentre the sphere
      if [ "$surf" == "sphere" ]; then
        run wb_command -surface-modify-sphere \
          $outdir/adaptive_subjectsToDataConteALL/week$week.iter$iter.$surf.$hemi.dedrift.AVERAGE_removedAffine.surf.gii \
          100 \
          $outdir/adaptive_subjectsToDataConteALL/week$week.iter$iter.$surf.$hemi.dedrift.AVERAGE_removedAffine.surf.gii \
          -recenter 
      fi

    done
  done
done



