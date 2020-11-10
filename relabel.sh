#!/bin/bash


set -e

codedir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $codedir/config/paths.sh
script=average_data_after_reverse_msm_and_resampling

    jobidStructure=`sbatch  -d $jobidAvdCurv -J
    ${iter}STR${week}${hemi}${data} -o
    ${outdir}/struct${week}_iter${iter}_${hemi}_${data}.out -e
    ${outdir}/struct${week}_iter${iter}_${hemi}_${data}.err -c 1 --mem=2G -p
    short  --wrap="${WBdir}/wb_command -set-structure
    $OutputTemplateFolder/$outfilename ${Structure} " | sed 's/Submitted batch
    job //g'`
