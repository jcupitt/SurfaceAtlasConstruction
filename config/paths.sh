# adjust all paths here ... this file is read by all the scripts on startup

# before sourcing this file, set codedir to the directory containing the
# scripts

if [ x${codedir:-x} == xx ]; then
  echo codedir not set
  exit 1
fi

base=$codedir

# config area 
config=$base/config

# start up FSL ... msm is in the FSL bin directory
export FSLDIR=/vol/dhcp-derived-data/surface-atlas-jcupitt/fsl
. $FSLDIR/etc/fslconf/fsl.sh 
PATH=$FSLDIR/bin:$PATH

# write all output here
outdir=/vol/dhcp-derived-data/surface-atlas-jcupitt/work
logdir=$outdir/logs
affinedir=$outdir/affineToConte 

# set of file to process 
# columns are
#     source age week
# separated by whitespace (no commas) and no header line
to_process=$config/subjs_270_ageScan_week.csv

# location of input subject spheres - meshes that have been pre-aligned, 
# through estimation of a rigid transformation between each subject's T2w 
# image and the infant volumetric template. 
# 
# This ensures all neonatal surfaces have the same orientation and centering. 
# Further, we estimate, and apply to each individual surface, a rotation 
# between previously developed template (Bozek et al., 2016), which was 
# constructed in MNI space, and adult Conte69 atlas (Van Essen et al., 
# 2012; Glasser and Van Essen, 2011), which is signficantly rotated with 
# respect to the MNI space, in order to initialise alignment.
dir=/vol/medic01/users/jbozek/MSMtemplate/subjects 

# location of input data file (sulc)
DATAdir=/vol/dhcp-derived-data/structural-pipeline/dhcp-v2.4/

atlasDir=/vol/medic01/users/jbozek/HCP_standard_mesh_atlases/Conte69/MNINonLinear/fsaverage_LR32k


