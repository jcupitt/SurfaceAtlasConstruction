#!/usr/bin/env /vol/medic01/users/ecr05/anaconda3/bin/python

"""
Created on Tue May 23 12:30:54 2017

@author: jelena
"""

# script for calculating average of gifti sulcal depth maps

import numpy as np
import sys
from sys import argv

import nibabel as nib
import nibabel.gifti as nibgif
import os

def usage():
    print ("Usage: " + argv[0] + " <folder where data metrics are> <weightsFile> <hemisphere> <output filename>")
    sys.exit(1)

if len(argv) < 2:
    usage()


inFolder  = argv[1]  # dirConte=/vol/medic01/users/jbozek/MSMtemplate/affineToConte
weightsFile = argv[2]  # weights=/vol/medic01/users/jbozek/new_weights/results/etc-${kernel}/kernel_sigma=${sigma}/weights_t=${targetage}.csv
hemi = argv[3]
outfilename = argv[4]  
data=argv[5]  # can be sulc or curv
mylist=argv[6]
myiter=argv[7]
week=argv[8]


print (myiter)

w=0
suma=[0]
suma= np.array(suma)
print (suma)


with open (weightsFile, 'rt') as f: 
    for line in f:
        text= line.split(" ")
        source= text[0]
        weight= float(text[1])
        
        print (source)
        print (weight)
        
        filename=str(source) + "_week" + str(week) + "/" + str(source) + "." + str(hemi) + "." + str(data) + ".iter" + str(myiter) + ".resampled.func.gii"
        giiFilename=os.path.join(inFolder, filename)

        print (giiFilename)

        giiFile=nibgif.giftiio.read(giiFilename)
        dataSulc=giiFile.darrays[0].data

        suma=weight * dataSulc + suma
     
        print(suma)
        w = w + weight
 
average=suma/w
print(average)


# just using input file's structure for having that structure in the new file that contains averaged data
giiFile.darrays[0].data=np.float32(average)

#outfilename="week" + str(targetage) + ".iter0.ico7.sulc." + str(hemi) + "AVERAGE.shape.gii"
outfile=    os.path.join(inFolder, outfilename)
nib.save(giiFile,outfile)

