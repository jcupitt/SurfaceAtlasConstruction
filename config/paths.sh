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

# workbench is used for pre_rotation.sh
export WORKBENCHHOME=/vol/dhcp-derived-data/surface-atlas-jcupitt/workbench
PATH=$WORKBENCHHOME/bin:$PATH

# write all output here
outdir=/vol/dhcp-derived-data/surface-atlas-jcupitt/work
logdir=$outdir/logs
affinedir=$outdir/affineToConte 

# set of file to process 
# columns are
# 	subject_id session_id age_at_scan
# separated by whitespace (no commas) and no header line
to_process=$config/subjects.tsv

# struct pipeline output we process
indir=/vol/dhcp-derived-data/derived_jun20_recon07

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

# conte69 atlas
atlasDir=/vol/dhcp-derived-data/surface-atlas-jcupitt/Conte-surface/MNINonLinear/fsaverage_LR32k


