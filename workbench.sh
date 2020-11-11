#!/bin/bash

# run wb_command in our environment, eg.:
#
#   ./workbench.sh 12 ... args to wb_command
#
# where "12" is the job id from eg. condor

set -e

jid=$1 
shift
codedir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $codedir/config/paths.sh

run wb_command $*
