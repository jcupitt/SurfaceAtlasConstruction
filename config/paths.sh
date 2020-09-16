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
PATH=$WORKBENCHHOME/bin_linux64:$PATH

# and we need MIRTK for registration
export MIRTKHOME=/vol/dhcp-derived-data/surface-atlas-jcupitt/mirtk
PATH=$MIRTKHOME/bin:$PATH

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
indir=/vol/dhcp-derived-data/derived_jun20_recon07/derivatives

# schuh atlas we use as volumetric template space
volumetric_atlas_dir=/vol/dhcp-derived-data/surface-atlas-jcupitt/schuh-atlas-jan2020

# conte69 atlas
conte_atlas_dir=/vol/dhcp-derived-data/surface-atlas-jcupitt/Conte-surface/MNINonLinear/fsaverage_LR32k

# surface templates
surface_template_dir=/vol/dhcp-derived-data/surface-atlas-jcupitt/new_surface_template

mkdir -p $logdir

run() {
	cmd="$*"
	echo running: $cmd
	echo running: $cmd >> $logdir/$$.output.log
	echo running: $cmd >> $logdir/$$.error.log
	$cmd >> $logdir/$$.output.log 2>> $logdir/$$.error.log
	if [ $? != 0 ]; then
		echo =====================
		echo failed: $logdir/$$.error.log 
		tail $logdir/$$.error.log
		exit 1
	fi
}
