#!/bin/bash

# run with eg.:
#   ./affine_to_Conte.sh CC00058XX13 43.2 L

codedir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $codedir/config/paths.sh

if [ $# -ne 3 ]; then
  echo "usage: $0 source week hemi"
  exit 1
fi

source=$1 
week=$2
hemi=$3

inmesh=${dir}/${source}/${source}.${hemi}.sphere.template-${week}.RIGID.recentred.rotatedToConte.surf.gii 
refmesh=${atlasDir}/Conte69.${hemi}.sphere.32k_fs_LR_recentred.surf.gii

indata=${DATAdir}/surfaces/${source}/workbench/${source}.${hemi}.sulc.native.shape.gii 
refdata=${atlasDir}/Conte69.${hemi}.32k_fs_LR.shape.gii

OutMesh=${source}-Conte69.${hemi}.sphere.AFFINE.surf.gii
OutData=${source}-Conte69.${hemi}.sulc.AFFINE.func.gii


OutputTempFolder=${affinedir}/${source}/${source}_to_Conte69_$hemi
rm -rf ${OutputTempFolder}
mkdir -p ${OutputTempFolder}

cd ${OutputTempFolder}

echo "### Affine to Conte69, source = $source, week = $week"

msm \
    --levels=1 \
    --conf=$config/config_strain_NEWSTRAIN_SPHERE_FS_LR_AFFINE \
    --inmesh=${inmesh} \
    --refmesh=${refmesh} \
    --indata=${indata} \
    --refdata=${refdata} \
    --out=${OutputTempFolder}/${hemi}. \
    --verbose

cp  ${OutputTempFolder}/${hemi}.sphere.reg.surf.gii ${affinedir}/${source}/${OutMesh}
cp  ${OutputTempFolder}/${hemi}.transformed_and_reprojected.func.gii ${affinedir}/${source}/${OutData}
echo " done with affine"



