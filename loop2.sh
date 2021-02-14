#!/bin/bash

set -e
# set -x

job_number=733

while true; do

  echo complete:
  find /vol/dhcp-derived-data/defaced_1feb21 -name complete | wc
  echo images:
  find /vol/dhcp-derived-data/defaced_1feb21 -name "*.nii.gz" | wc
  echo date:
  date

  # this will error out if there's no work to be done
  ./deface-all.sh 

  echo waiting ...
  sleep 600 # 10 minutes
  condor_rm $job_number

  # assuming no one else is running anything argh
  ((job_number+=1))
done
