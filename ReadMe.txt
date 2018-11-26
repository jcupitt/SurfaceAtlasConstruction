# Scripts for neonatal template construction
# 
# "Construction of a neonatal cortical surface atlas using Multimodal Surface Matching in the Developing Human Connectome Project", Bozek et al., Neuroimage, 179, p. 11-29, 2018

# templates available at: 
https://brain-development.org/brain-atlases/atlases-from-the-dhcp-project/cortical-surface-atlas-bozek/
 


# scripts need to be run one after the other to construct the neonatal cortical surface template - change paths in scripts and location of binaries; also check if file naming convention has been changed


#start with affine registration of subjects to Conte69; the batch script submits affine_to_Conte.sh to slurm 
./affine_to_Conte.bat


# now do initial msm using sulcal depth map to drive the registration; the batch script submits msm_template_to_subjects_iterate.sh to slurm (script msm_template_to_subjects_iterate.sh is general registration script used throughout the template construction)
./dataConte_sulc_msm_subjects_to_Conte.bat 


# resample curvature after initial registration
./dataConte_curv_resample_after_msm_init.bat


# get average *init.sulc and *init.curv; this batch script calls dataConte_average_after_msm.py
./adaptive_dataConte_average_after_msm_and_resample.bat


# script runs (on slurm) msm registration using curvature, iter=0; it submits jobs msm_template_to_subjects_iterate.sh to slurm and when done it averages all data with average_data_after_reverse_msm_and_resampling.py 
./adaptive_dataConte_toConte_iter0_msm_resample_average.bat


# script iterates and refines the atlas using curvature; does msm (msm_template_to_subjects_iterate.sh) and averaging of data (average_data_after_reverse_msm_and_resampling.py)
./adaptive_dataConte_toConte_iterate_resample_average.bat


# when all iterations have finished, do msmapplywarp and average the sphere, before applying dedrifting and averaging of other surfaces
./adaptive_dataConte_average_before_dedrift.bat


# do dedrifting and averaging of dedrifted surfaces
./dataConte_dedrift.bat


# remove affine transformation from the anatomy
./adaptive_remove_affine_transfom.bat



# apply alignment and average all features after final iteration (sulcal depth, thickness and myelin maps)
./adaptive_dataConte_toConte_data_resample_average_after_iters.bat
