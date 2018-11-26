#!/bin/bash

source=$1 
week=$2
hemi=$3


# set paths to binaries, scripts, data
MSMbin=/vol/medic01/users/jbozek/MSM # MSMbin=/homes/ecr05/fsldev/src/MSM # for Ubuntu 16
Scripts=/vol/medic01/users/jbozek/scripts

dir=/vol/medic01/users/jbozek/MSMtemplate/subjects # location of input subject spheres - meshes that have been pre-aligned, through estimation of a rigid transformation between each subject's T2w image and the infant volumetric template. This ensures all neonatal surfaces have the same orientation and centering. Further, we estimate, and apply to each individual surface, a rotation between previously developed template (Bozek et al., 2016), which was constructed in MNI space, and adult Conte69 atlas (Van Essen et al., 2012; Glasser and Van Essen, 2011), which is signficantly rotated with respect to the MNI space, in order to initialise alignment.

DATAdir=/vol/dhcp-derived-data/structural-pipeline/dhcp-v2.4/  # location of input data file (sulc)

atlasDir=/vol/medic01/users/jbozek/HCP_standard_mesh_atlases/Conte69/MNINonLinear/fsaverage_LR32k

affinedir=/vol/medic01/users/jbozek/MSMtemplate/affineToConte # this is the output location for affine
mkdir -p $affinedir/$source


Conf=${Scripts}/configs/config_strain_NEWSTRAIN_SPHERE_FS_LR_AFFINE # configuration file

inmesh=${dir}/${source}/${source}.${hemi}.sphere.template-${week}.RIGID.recentred.rotatedToConte.surf.gii 
refmesh=${atlasDir}/Conte69.${hemi}.sphere.32k_fs_LR_recentred.surf.gii

indata=${DATAdir}/surfaces/${source}/workbench/${source}.${hemi}.sulc.native.shape.gii 
refdata=${atlasDir}/Conte69.${hemi}.32k_fs_LR.shape.gii

OutMesh=${source}-Conte69.${hemi}.sphere.AFFINE.surf.gii
OutData=${source}-Conte69.${hemi}.sulc.AFFINE.func.gii


OutputTempFolder=${affinedir}/${source}/${source}_to_Conte69_$hemi
if [ ! -e ${OutputTempFolder} ] ; then
    mkdir ${OutputTempFolder}
else 
    rm -r ${OutputTempFolder}
    mkdir ${OutputTempFolder}
fi

cd ${OutputTempFolder}

echo "###Doing  affine to Conte69 ###"
echo $source $week


${MSMbin}/msm \
    --levels=1 \
    --conf=${Conf} \
    --inmesh=${inmesh} \
    --refmesh=${refmesh} \
    --indata=${indata} \
    --refdata=${refdata} \
    --out=${OutputTempFolder}/${hemi}. \
    --verbose

cp  ${OutputTempFolder}/${hemi}.sphere.reg.surf.gii ${affinedir}/${source}/${OutMesh}
cp  ${OutputTempFolder}/${hemi}.transformed_and_reprojected.func.gii ${affinedir}/${source}/${OutData}
echo " done with affine"



