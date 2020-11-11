# Install notes for Ubuntu 16.04

## FSL, MSN, Workbench and MIRTK

You need FSL6 and MSM built from source. You won't be able to do this on the
Imperial machines unless you have admin rights since you need 
gcc-4.8 to link against the prebuilt FSL binaries.

Instead, build in a docker image and copy the binary out.

```
git clone https://github.com/jcupitt/docker-builds.git
cd docker-builds/msm-fsl6-ubuntu16.04
docker pull ubuntu:xenial
docker build -t msm .
```

Normally you'd copy out of the container with docker cp or perhaps docker
exec and two tars, but that fails over NFS, frustratingly.

Instead, run a shell and scp out:

```
docker run --rm -it jcupitt/msm:latest /bin/bash
cd /usr/local
tar cfz ~/fsl.tar.gz fsl
scp ~/fsl.tar.gz jcupitt@yishui.doc.ic.ac.uk:
^D
```

Now untar that FSL somewhere. I put it here:

```
/vol/dhcp-derived-data/surface-atlas-jcupitt/fsl
```

We also need Workbench. Again, build in docker like this:

```
cd docker-builds/workbench
docker pull ubuntu:xenial
docker build -t workbench .
```

And get the binary out with scp:

```
docker run --rm -it workbench:latest /bin/bash
cd /usr/local
tar cfz workbench.tar.gz workbench
scp workbench.tar.gz jcupitt@yishui.doc.ic.ac.uk:
^D
```

And untar somewhere. I put it here:

```
/vol/dhcp-derived-data/surface-atlas-jcupitt/workbench
```

You also need MIRTK. You can build it like this:

```
cd docker-builds/mirtk-ubuntu16.04
docker build -t john/mirtk:xenial .
```

And get the binary out with scp:

```
docker run --rm -it mirtk:xenial /bin/bash
cd /usr/local
tar cfz mirtk.tar.gz mirtk
scp mirtk.tar.gz jcupitt@yishui.doc.ic.ac.uk:
^D
```

And untar somewhere. I put it here:

```
/vol/dhcp-derived-data/surface-atlas-jcupitt/mirtk
```

## Anaconda

The pipeline uses some Python. The simplest way to get this to run across
condor is to use anaconda:

https://www.anaconda.com/products/individual

I installed to `/vol/dhcp-derived-data/surface-atlas-jcupitt/anaconda3`.

## Conte69 atlas

There's a copy of the complete atlas in:

```
/vol/dhcp-derived-data/surface-atlas-jcupitt/Conte-surface
```

This is quite hard to download -- the server which hosts the atlas failed in
2016 and you now have to apply for access to a backup server. Use the copy
above if possible.

## Schuh atlas

You need the atlas for volumetric template space. dHCP uses the Schuh atlas,
and I put a copy of the latest one here:

```
/vol/dhcp-derived-data/surface-atlas-jcupitt/schuh-atlas-jan2020
```

## `templateDHCP` and `new_surface_template`

Need these too, add notes.

## `subjects.tsv`

This needs to list scan and age at scan, one per line. For example:

```
CC00507XX12-148202 42 
```

Generate this file from the structural pipeline's `combined.tsv` with:

```
./generate_subjects.sh combined.tsv config/subjects.tsv
```

## Edit `config/paths.sh`

You need to set the various variables to point to the right directories.

- Conte69 atlas
- Struct pipeline output
- MSM/FSL/Workbench/MIRTK binaries

## Reset output area

```
rm -rf ../work/*
```

## Pre-align surfaces

Test with something like this (job id, scan name, age at scan, hemisphere):

```
./pre_rotation.sh 12 CC00507XX12-148202 42 L
```

Then to process all scans:

```
./pre_rotation_condor.sh config/subjects.tsv
```

If you see an auth error, try rerunning `kinit`. 

Check progress:

```
condor_q
```

See why some processing failed:

```
condor_q -analyze
```

Remove the failed jobs:

```
condor_rm 183
```

And try running `pre_rotation_condor.sh` again (it will only resubmit jobs for
images which did not generate).

## Alignment to Conte69 atlas

Test like this:

```
./affine_to_Conte.sh 12 CC00507XX12-148202 42 L
```

Then to process all scans:

```
./affine_to_Conte_condor.sh config/subjects.tsv
```

## Sucal depth alignment

Now do initial msm using sulcal depth map to drive the registration.
`msm_template_to_subjects_iterate.sh` is general registration script used
throughout template construction.

Test with eg.:

```
./msm_template_to_subjects_iterate.sh \
  12 \
  /vol/dhcp-derived-data/surface-atlas-jcupitt/SurfaceAtlasConstruction/config/config_strain_NEWSTRAIN_SPHERE_LONGITUDINAL_new \
  /vol/dhcp-derived-data/surface-atlas-jcupitt/work/affine_to_Conte/CC00692XX17-200301/Conte69.L.sphere.AFFINE.surf.gii \
  /vol/dhcp-derived-data/surface-atlas-jcupitt/Conte-surface/MNINonLinear/fsaverage_LR32k/Conte69.L.sphere.32k_fs_LR.surf.gii \
  /vol/dhcp-derived-data/derived_aug20_recon07/derivatives/sub-CC00692XX17/ses-200301/anat/Native/sub-CC00692XX17_ses-200301_left_sulc.shape.gii \
  /vol/dhcp-derived-data/surface-atlas-jcupitt/Conte-surface/MNINonLinear/fsaverage_LR32k/Conte69.L.32k_fs_LR.shape.gii \
  /vol/dhcp-derived-data/surface-atlas-jcupitt/work/subjectsToDataConteALL/CC00692XX17-200301 \
  CC00692XX17-200301-Conte69.L.sphere.init.sulc.surf.gii \
  CC00692XX17-200301-Conte69.L.init.sulc.func.gii \
  L
```

Takes about 40m to run.

Run on all scans with:

```
./dataConte_sulc_msm_subjects_to_Conte_condor.sh config/subjects.tsv
```

## Resample curvature

Next, resample curvature after initial registration. Test like this:

```
./dataConte_curv_resample_after_msm_init.sh 12 CC00507XX12-148202 42 L
```

Run on all scans like this:

```
./dataConte_curv_resample_after_msm_init_condor.sh config/subjects.tsv
```

Three scans fail, not investigated why.

## Generate weights

For each week, we need to pick a set of scans to average for that week, plus a
weighting for each one. The weights are chosen to give effectively the same
number of inputs to each week: a large sigma for weeks with few scans (so more
are averaged), a small sigma for weeks with many scans.

`generate_weights.py` has various params you can tune, see inside.

```
export PYTHONHOME=/vol/dhcp-derived-data/surface-atlas-jcupitt/anaconda3
eval "$($PYTHONHOME/bin/conda shell.bash hook)"
./generate_weights.py config/subjects.tsv config/weights
```

Generates `config/weights/w41.csv` etc.

## Average sulc and curv

Compute average `*init.sulc` and `*init.curv` for each week. This 
script runs `dataConte_average_after_msm.py`.

```
./adaptive_dataConte_average_after_msm_and_resample_condor.sh config/subjects.tsv
```

The `weights/` CSVs will list scans which don't exist, so don't worry too much
about messages re. missing files.

## Iterate

msm registration using curvature, iter=0, then resample. This fetches the set
of scans to process from the weights files.

```
./adaptive_dataConte_toConte_iter0_msm_resample_condor.sh 
```

Average the resampled surfaces. This script runs
`average_data_after_reverse_msm_and_resampling.py`.

```
./adaptive_dataConte_average_after_reverse_msm_and_resampling_condor.sh
```

And use `wb_command` to relabel the structures.

```
./adaptive_dataConte_relabel_condor.sh
```



