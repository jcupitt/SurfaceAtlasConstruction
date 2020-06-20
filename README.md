# Scripts for neonatal template construction

This set of scripts are for constructing neonatal surface templates. See:

*Construction of a neonatal cortical surface atlas using Multimodal
Surface Matching in the Developing Human Connectome Project*, Bozek et al.,
Neuroimage, 179, p. 11-29, 2018

The templates may be downloaded from:

    https://brain-development.org/brain-atlases/atlases-from-the-dhcp-project/cortical-surface-atlas-bozek/

# Process
 
The scripts need to be run one after the other to construct the neonatal
cortical surface template -- change paths in scripts and location of binaries;
also check if file naming convention has been changed.

Start with affine registration of subjects to Conte69; the batch script
submits `affine_to_Conte.sh` to slurm

    ./affine_to_Conte.bat

Now do initial msm using sulcal depth map to drive the registration; the
batch script submits `msm_template_to_subjects_iterate.sh` to slurm. Script
`msm_template_to_subjects_iterate.sh` is general registration script used
throughout the template construction.

    ./dataConte_sulc_msm_subjects_to_Conte.bat 

Next, resample curvature after initial registration.

    ./dataConte_curv_resample_after_msm_init.bat

Get average `*init.sulc` and `*init.curv`; this batch script calls 
`dataConte_average_after_msm.py`.

    ./adaptive_dataConte_average_after_msm_and_resample.bat

Script runs (on slurm) msm registration using curvature, iter=0; it submits
jobs `msm_template_to_subjects_iterate.sh` to slurm and when done it averages
all data with `average_data_after_reverse_msm_and_resampling.py`.

    ./adaptive_dataConte_toConte_iter0_msm_resample_average.bat

Script iterates and refines the atlas using curvature; does msm
(`msm_template_to_subjects_iterate.sh)` and averaging of data
(`average_data_after_reverse_msm_and_resampling.py`).

    ./adaptive_dataConte_toConte_iterate_resample_average.bat

When all iterations have finished, do msmapplywarp and average the sphere,
before applying dedrifting and averaging of other surfaces.

    ./adaptive_dataConte_average_before_dedrift.bat

Do dedrifting and averaging of dedrifted surfaces.

    ./dataConte_dedrift.bat

Remove affine transformation from the anatomy.

    ./adaptive_remove_affine_transfom.bat

Apply alignment and average all features after final iteration (sulcal depth,
thickness and myelin maps).

    ./adaptive_dataConte_toConte_data_resample_average_after_iters.bat
