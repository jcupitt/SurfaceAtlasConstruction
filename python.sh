#!/bin/bash

# run a python script using our environment, eg.:
#
#   ./python.sh 12 something.py arg1 arg2
#
# where "12" is the job id from eg. condor

jid=$1 
codedir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $codedir/config/paths.sh

shift
echo PYTHONHOME = $PYTHONHOME
run python $*
