#!/usr/bin/env python3

"""
Created on Tue May 23 12:30:54 2017

@author: jelena
"""

# script for calculating average of gifti sulcal depth maps

import sys
import os
import csv

import numpy as np
import nibabel as nib

def usage():
    print(f"Usage:{sys.argv[0]} <folder where data metrics are> <weightsFile> <hemisphere> <output filename> <data type> <iter> <week>")
    sys.exit(1)

if len(sys.argv) < 2:
    usage()

in_dir = sys.argv[1]        # eg. work/adaptive_subjectsToDataConteALL
weights_file = sys.argv[2]  # config/weights/w28.csv
hemi = sys.argv[3]          # L
outfilename = sys.argv[4]   # week28.iter0.curv.L.AVERAGE.shape.gii
data_type = sys.argv[5]     # can be sulc or curv
myiter = sys.argv[6]        # 0
week = sys.argv[7]          # 28

total_data = np.array([0])
total_weight = 0

with open(weights_file, 'r') as f:  
    for row in csv.reader(f, delimiter='\t'):
        scan = row[0]
        weight = float(row[1])

        filename = f"{in_dir}/{scan}_week{week}/{scan}.{hemi}.{data_type}.iter{myiter}.resampled.func.gii"
        if not os.path.isfile(filename):
            print(f"{filename}: not found, skipping")
            continue
        if os.path.getsize(filename) == 0:
            print(f"{filename}: zero length file, skipping")
            continue

        print(f"loading {scan} ...")
        gii = nib.load(filename)
        data = gii.darrays[0].data

        # mix of float and int means numpy won't let us use += here
        total_data = total_data + weight * data
        total_weight += weight

average = total_data / total_weight

# reuse the file's structure for the new averaged data file
gii.darrays[0].data = np.float32(average)

print(f"saving {outfilename} ...")
nib.save(gii, f"{in_dir}/{outfilename}")
