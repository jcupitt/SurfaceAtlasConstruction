# Package up the results ready for distribution

# run with eg.:
#   ./package.sh 7

codedir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $codedir/config/paths.sh

iter=$1
if (( iter < 1 )); then
  echo "iter must be greater than or equal to 1"
  exit 1
fi

packaged=$outdir/packaged
echo generating $packaged ...
rm -rf $packaged
mkdir -p $packaged

for hemi in L R; do
  for week in {28..44}; do
    for surf in white midthickness pial very_inflated sphere; do
      run cp \
        $outdir/adaptive_subjectsToDataConteALL/week$week.iter$iter.$surf.$hemi.dedrift.AVERAGE_removedAffine.surf.gii \
        $packaged/dHCP.week$week.$hemi.$surf.surf.gii
    done

    for shape in myelin_map sulc thickness; do
      run cp \
        $outdir/adaptive_subjectsToDataConteALL/week$week.iter$iter.$shape.$hemi.AVERAGE.shape.gii \
        $packaged/dHCP.week$week.$hemi.$shape.shape.gii
    done 
  done
done
