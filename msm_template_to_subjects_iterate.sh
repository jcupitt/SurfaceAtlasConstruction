#!/bin/bash

#set -x
set -e

Conf=$1
inmesh=$2
refmesh=$3 
indata=$4 
refdata=$5
OutputRegFolder=$6
OutputTempFolder=$7
OutMesh=$8
OutData=$9
hemi=${10}
output=${11}
transmesh=${12}

MSMbin=/vol/medic01/users/jbozek/MSM # MSMbin=/homes/ecr05/fsldev/src/MSM # for Ubuntu 16

if [ ! -e ${OutputTempFolder} ] ; then
    mkdir -p ${OutputTempFolder}
else 
    rm -r ${OutputTempFolder}
    mkdir -p ${OutputTempFolder}
fi

cd ${OutputTempFolder}

echo "###Doing nonlinear MSM  ###"

trans=""
if [ -e "$transmesh" ] ; then
    echo "exists transmesh"
    trans="--trans=${transmesh}"

    ${MSMbin}/msm \
	--levels=3 \
	--conf=${Conf} \
	--inmesh=${inmesh} \
	--refmesh=${refmesh} \
	--indata=${indata} \
	--refdata=${refdata} \
	--out=${OutputTempFolder}/${hemi}. \
	--verbose \
	$trans

else 
    echo "no trans mesh"
    ${MSMbin}/msm \
	--levels=3 \
	--conf=${Conf} \
	--inmesh=${inmesh} \
	--refmesh=${refmesh} \
	--indata=${indata} \
	--refdata=${refdata} \
	--out=${OutputTempFolder}/${hemi}. \
	--verbose 
    
fi

cp  ${OutputTempFolder}/${hemi}.sphere.reg.surf.gii ${OutputRegFolder}/${OutMesh}
cp  ${OutputTempFolder}/${hemi}.transformed_and_reprojected.func.gii ${OutputRegFolder}/${OutData}
echo " done with msm"
echo "output mesh is " $OutMesh
echo ""

echo "resample output data"
${MSMbin}/msmresample ${OutputRegFolder}/${OutMesh} $output -project $refmesh -labels $indata -adap_bary
