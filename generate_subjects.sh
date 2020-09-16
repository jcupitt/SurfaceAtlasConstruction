#!/bin/bash

# run with eg.:
#   ./generate_subjects.sh combined.tsv config/subjects.tsv

codedir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $codedir/config/paths.sh

if [ $# -ne 2 ]; then
  echo "usage: $0 combined.tsv subject-file"
  exit 1
fi

combined=$1 
subjects=$2

rm -f $subjects

while IFS='' read -r line || [[ -n "$line" ]]; do
  columns=($line)
  subject=${columns[0]}
  session=${columns[1]}
  gender=${columns[2]}
  age_at_birth=${columns[3]}
  age_at_scan=${columns[4]}
  
  if ! [[ $subject =~ CC.* ]]; then
    continue
  fi

  int_age_at_scan=$(printf %.0f "$age_at_scan")

  echo -e $subject-$session\\t$int_age_at_scan >> $subjects
done < $combined
