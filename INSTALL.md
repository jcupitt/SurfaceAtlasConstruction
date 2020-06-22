# Install notes for Ubuntu 16.04

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

Now untar that FSL somewhere.





