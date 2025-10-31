#----------------------------------------------------------------------------
#  This file is a part of the VESPA SoC Prototyping Framework
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the Apache 2.0 License.
#
# File:    config_space_dpr.py
# Authors: Gabriele Montanaro
#          Andrea Galimberti
#          Davide Zoni
# Company: Politecnico di Milano
# Mail:    name.surname@polimi.it
#
#----------------------------------------------------------------------------

# This file generates a list of all the possible configurations (in terms of accelerators sequence)
# given a specific scenario

import sys
import os
import shutil
import itertools
sys.path.append(sys.path[0] + '/../generic')
import load_data
import random

#Inputs
tiles_info = sys.argv[1]
dse_info = sys.argv[2]
output_file = sys.argv[3]

#Configuration variables
noc_x = load_data.getNocSizeX(dse_info)
noc_y = load_data.getNocSizeY(dse_info)
n_mem = load_data.getMemNum(dse_info)
free_slots = noc_x*noc_y - 2 - n_mem

randomize_order = True

parallelism_levels = load_data.getParLvls(dse_info)
accelerators = load_data.getAccList(dse_info)
thresholds = load_data.getThresholdList(dse_info)

accInfo = load_data.loadAllAccInfo(tiles_info)
tilesArea = load_data.loadTilesArea(tiles_info)

#A function for area estimation
def estimate_area(tiles_list):
  area_est = 0
  for tile in tiles_list:
    if tile == 0:
      area_est = area_est + tilesArea["EMPTY"]
    else:
      area_est = area_est + accInfo[accelerators[int((tile-1)/len(parallelism_levels))]][3 + (tile-1)%len(parallelism_levels)]
  return area_est

#A simple function that returns the configuration line
def write_config_line(tiles_list):
  line = ""
  for i in range(0, len(tiles_list)):
    if tiles_list[i] == 0:
      line = line + "EMPTY"
    else:
      line = line + accelerators[int((tiles_list[i]-1)/len(parallelism_levels))] + "x" + str(parallelism_levels[(tiles_list[i]-1)%len(parallelism_levels)])
    line = line + " "
  #Add the area at the end
  #line = line + str(estimate_area(tiles_list))

  return line

#A simple function that randomize the order of lines in a file
def randomize_file(filename):
  # Read the lines from the input file
  with open(filename, 'r') as file:
    lines = file.readlines()
  # Shuffle the lines randomly
  random.shuffle(lines)
  # Write the shuffled lines
  with open(filename, 'w') as file:
    file.writelines(lines)



#A list with all numbers from 0 to the number of possible implementations for a tile
# 0      -> Empty tile
# others -> Accelerator tile
available_tile_impl = [i for i in range(len(parallelism_levels)*len(accelerators)+1)]

#Then, find all the combinations of the possible implementations of a single tile
#tiles_comb = list(itertools.product(available_tile_impl, repeat=free_slots))
tiles_comb = list(itertools.combinations_with_replacement(available_tile_impl, free_slots))

n_config = len(tiles_comb)

#Generate all the output directories and index files
index_file = open(output_file, 'w')

count = 0


#tiles_reduction = []
#mem_comb = []
#Finally, iterate over all the possible combinations
for tiles_order in tiles_comb:
  #Check that the combination is feasible - that is, it has every accelerator and at least one memory tile
  acc_check = [0]*len(accelerators)
  acc_check_tot = 1
  for x in range(0, free_slots):
    if tiles_order[x] >= 1:
      acc_check[int((tiles_order[x]-1)/len(parallelism_levels))] = 1
  for x in range(0, len(accelerators)):
    if(acc_check[x] == 0):
      acc_check_tot = 0
  if acc_check_tot == 0:
    continue

  #Extra check: verify if the configuration satisfies the minimum throughput requirements
  #(for each app, the sum of the throughput of the single accelerators in isolation is higher than the threshold)
  max_thr = [0]*len(accelerators)
  for x in range(0, free_slots):
    if tiles_order[x] >= 1:
      app_id = int((tiles_order[x]-1)/len(parallelism_levels))
      app_par_lvl = int(parallelism_levels[(tiles_order[x]-1)%len(parallelism_levels)])

      max_thr[app_id] = max_thr[app_id] + app_par_lvl*accInfo[accelerators[app_id]][2]

  threshold_met = 1
  for app in range(0, len(accelerators)):
    if max_thr[app] < thresholds[app]:
      threshold_met = 0
      break

  if threshold_met == 0:
    continue

  #if randomize_order:
  #  random.shuffle(tiles_order)

  index_file.write(write_config_line(tiles_order) + "\n")
  count = count + 1


index_file.close()

if randomize_order:
  randomize_file(output_file)

print("Number of possible configurations: " + str(n_config) + "\n")
print("Number of feasible configurations: " + str(count) + "\n")



