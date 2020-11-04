#!/usr/bin/env python3

# split scans into weeks and compute a weight for each

# run with eg.:
#
#   ./generate_weights.py combined.tsv config/weights

# and the files for each week will be written to the config/weights dir

import sys
import math
import csv
import re

# we have scans in 27 - 45 ... ignore the extremes
min_age = 28
max_age = 44

def norm(x):
    return math.exp(-x**2 / 2) / math.sqrt(2 * math.pi)

def norm_pdf(x, sigma, mean):
    return (1 / sigma) * norm((x - mean) / sigma)

ages = {}
with open(sys.argv[1], 'r') as f:
    for row in csv.reader(f, delimiter='\t'):
        scan = row[0]
        age = int(row[1])

        ages[scan] = age

# start of with sigma 1.0, then broaden the edges to get about the same number
# of pixels for each template
start_sigma = 1.0
sigmas = {age: start_sigma for age in range(min_age, max_age + 1)}

# compute the "mass" of scans for each week
masses = {age: 0.0 for age in range(min_age, max_age + 1)}
for week in range(min_age, max_age + 1):
    for scan in ages.keys():
        masses[week] += start_sigma * norm_pdf(ages[scan], sigmas[week], week)

# we aim to keep the average mass the same
total_mass = 0
for week in range(min_age, max_age + 1):
    total_mass += masses[week]
average_mass = total_mass / (1 + max_age - min_age)

# for each week, do a binary search to find the best sigma
for week in range(min_age, max_age + 1):
    sigma = sigmas[week]
    mass = masses[week]
    lower_bound = 0.1
    upper_bound = 2.5

    while True:
        #print(f"week = {week}")
        #print(f"sigma = {sigma}")
        #print(f"mass = {mass}")
        #print(f"lower_bound = {lower_bound}")
        #print(f"upper_bound = {upper_bound}")

        if mass > average_mass:
            upper_bound = sigma
            sigma = lower_bound + (sigma - lower_bound) / 2
        else:
            lower_bound = sigma
            sigma = sigma + (upper_bound - sigma) / 2

        mass = 0
        for scan in ages.keys():
            # scale by sigma since we don't want to wider curves to be lower
            mass += sigma * norm_pdf(ages[scan], sigma, week)

        if upper_bound - lower_bound < 0.1:
            break

    sigmas[week] = sigma
    masses[week] = mass 

print(f"sigmas = {sigmas}")
print(f"masses = {masses}")
print(f'average_mass = {average_mass}')

for week in range(min_age, max_age + 1):
    filename = f"{sys.argv[2]}/w{week}.csv"
    print(f"generating {filename} ...")
    with open(filename, "w") as f:
        for scan in ages.keys():
            age = ages[scan]
            sigma = sigmas[week]
            weight = (1.0 / 0.3989) * sigma * norm_pdf(age, sigma, week)
            if weight > 0.1:
                print(f"{scan}\t{weight}", file=f)

