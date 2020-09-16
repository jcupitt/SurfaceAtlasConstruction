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
docker run --rm -it msm:latest /bin/bash
cd /usr/local
tar cfz ~/fsl.tar.gz fsl
scp ~/fsl.tar.gz jcupitt@yishui
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
scp workbench.tar.gz jcupitt@yishui:
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
scp mirtk.tar.gz jcupitt@yishui:
^D
```

And untar somewhere. I put it here:

```
/vol/dhcp-derived-data/surface-atlas-jcupitt/mirtk
```

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

## Edit `config/paths.sh`

You need to set the various variables to point to the right directories.

- Conte69 atlas
- Struct pipeline output
- MSM/FSL/Workbench/MIRTK binaries
- Ages and names of volumes to process for the cluster scripts in `ages.csv`

## Pre-align surfaces

Test with something like this (scan name, age at scan, hemisphere):

```
./pre_rotation.sh CC00507XX12-148202 42 L
```

Then to process all scans:

```
./pre_rotation_condor.sh config/ages.csv
```

## Alignment to Conte69 atlas

Test like this:

```
./affine_to_Conte.sh CC00507XX12-148202 42 L
```

