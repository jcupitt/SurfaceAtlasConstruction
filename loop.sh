#!/bin/bash

set -e
# set -x

cmd="$*"

echo looping for: $cmd

finished() {
  condor_jobs=($(condor_q jcupitt -totals -af:h jobs))
  echo ${condor_jobs[1]}
}

while true; do
  echo waiting ...
  while true; do 
    fin=$(finished)
    if [ $fin == 0 ]; then
      break
    fi
    sleep 5
  done

  echo -n "date: "
  date

  # this will error out if there's no work to be done
  $cmd
done
