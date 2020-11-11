#!/bin/bash

# run a python script using our environment, eg.:
#
#   ./python.sh 12 something.py arg1 arg2
#
# where "12" is the job id from eg. condor

jid=$1 
shift
codedir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# change $0 so that our logs are named usefully ... only works in bash5+ sadly
BASH_ARGV0=$1
source $codedir/config/paths.sh

run python $*
