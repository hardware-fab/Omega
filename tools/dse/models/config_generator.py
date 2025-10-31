#----------------------------------------------------------------------------
#  This file is a part of the VESPA SoC Prototyping Framework
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the Apache 2.0 License.
#
# File:    config_generator.py
# Authors: Gabriele Montanaro
#          Andrea Galimberti
#          Davide Zoni
# Company: Politecnico di Milano
# Mail:    name.surname@polimi.it
#
#----------------------------------------------------------------------------

#This script generates a set of complete configuration files given certain rules.
#It must be considered just a template, since every DSE will require a slightly modified version of this script.
#I will try to keep this template updated with every new feature I will add for different DSEs

import sys
import os
import shutil
import itertools
import random
sys.path.append(sys.path[0] + '/../generic')
import load_data

#----------------------------------------CONFIGURATION VARIABLES-----------------------------------------

#Configuration parameters - edit them to customize the output of this script

#Number of output folders (for parallel implementations)
n_output_folders = 5

#Optional: choose only some random config
randomize = True
n_random_configs = 200

#---------------------------------------------------------------------------------------------------------

#Generic constants
#bw_dict = {'ADPCM_VIVADO': 32, 'AES_VIVADO': 32, 'BLOWFISH_VIVADO': 8 , 'DFADD_VIVADO': 64, 'DFDIV_VIVADO': 64, 'DFMUL_VIVADO': 64, 'DFSIN_VIVADO': 64, 'GSM_VIVADO': 16, 'MIPS_VIVADO': 32, 'MOTION_VIVADO': 32, 'SHA_VIVADO': 8, 'SHA3_RTL': 64}

#Inputs
tilesInfoFile = sys.argv[1]
dseConfigFile = sys.argv[2]
output_folder = sys.argv[3]


#NOC size
noc_x = load_data.getNocSizeX(dseConfigFile)
noc_y = load_data.getNocSizeY(dseConfigFile)
free_slots = noc_x*noc_y-2

#Possible parallelism levels
parallelism_levels = load_data.getParLvls(dseConfigFile)

#List of required accelerators
accelerators = load_data.getAccList(dseConfigFile)

#Info on all the accelerators
acc_info = load_data.loadAllAccInfo(tilesInfoFile)



#----------------------------------------FUNCTIONS-----------------------------------------

#A simple function that returns the name of a configuration
def find_config_name(tiles_list):
  name = "config"
  for i in range(0, len(tiles_list)):
    if tiles_list[i] == 0:
      name = name + "_EMPTY"
    elif tiles_list[i] == 1:
      name = name + "_MEM"
    else:
      name = name + "_" + accelerators[int((tiles_list[i]-2)/len(parallelism_levels))] + "x" + str(parallelism_levels[(tiles_list[i]-2)%len(parallelism_levels)])
  return name


#Simple function to write a single configuration
def write_config(tiles, folder):
  #print("Writing configuration: " + find_config_name(tiles))
  fp = open(folder + "/" + find_config_name(tiles) + ".ccf", 'w')
  fp.write("CPU_ARCH = ariane\n")
  fp.write("NCPU_TILE = 1\n")
  fp.write("CONFIG_NOC_ROWS = " + str(noc_y) + "\n")
  fp.write("CONFIG_NOC_COLS = " + str(noc_x) + "\n")
  fp.write("CONFIG_NOC_PLANES = 1\n")
  pll_placed = 0
  n_mem_tiles = 0
  i = 0
  for y in range(0, noc_y):
    for x in range(0, noc_x):
      #CPU
      if x == 0 and y == 0:
        clock_region = 1
        has_pll = 1
        bandwidth = 0
        tile_content = "cpu"
        n_cores = 0
      #I/O
      elif x == 0 and y == 1:
        clock_region = 0
        has_pll = 0
        bandwidth = 0
        tile_content = "IO"
        n_cores = 0
      else:
        #Memory or empty tile
        if tiles[i] < 2:
          clock_region = 0
          has_pll = 0
          bandwidth = 0
          n_cores = 0
          if tiles[i] == 0:
            tile_content = "empty"
          else:
            tile_content = "mem"
            n_mem_tiles = n_mem_tiles + 1
        #Accelerator tile
        else:
          clock_region = 2
          if pll_placed == 0:
            has_pll = 1
            pll_placed = 1
          else:
            has_pll = 0
          bandwidth = acc_info[accelerators[int((tiles[i]-2)/len(parallelism_levels))]][1]
          tile_content = acc_info[accelerators[int((tiles[i]-2)/len(parallelism_levels))]][0]
          n_cores = parallelism_levels[(tiles[i]-2)%len(parallelism_levels)]

        i = i + 1

      fp.write("TILE_" + str(y) + "_" + str(x) + " = " + tile_content + "\n")
      fp.write("CLOCK_" + str(y) + "_" + str(x) + " = " + str(clock_region) + "\n")
      fp.write("PLL_" + str(y) + "_" + str(x) + " = " + str(has_pll) + "\n")
      fp.write("BW_" + str(y) + "_" + str(x) + " = " + str(bandwidth) + "\n")
      if n_cores != 0:
        fp.write("NCORES_" + str(y) + "_" + str(x) + " = " + str(n_cores) + "\n")

  mem_size_main = 2048/n_mem_tiles
  #The minimum size of the first memory is 1MB to make the system work
  if(2048/n_mem_tiles < 1024):
    mem_size_main = 1024
  #The secondary memories can be as small as needed
  mem_size_secondary = 1024
  if(n_mem_tiles != 1):
    mem_size_secondary = 1024/(n_mem_tiles-1)

  fp.write("CONFIG_MEM_SIZE_MAIN = " + str(int(mem_size_main)) + "\n")
  fp.write("CONFIG_MEM_SIZE_SECONDARY = " + str(int(mem_size_secondary)) + "\n")

#A list with all numbers from 0 to the number of possible implementations for a tile
# 0 -> Empty tile
# 1 -> Memory tile
# >2 -> Accelerator tile
available_tile_impl = [i for i in range(len(parallelism_levels)*len(accelerators)+2)]

#Then, find all the combinations of the possible implementations of a single tile
#tiles_comb = list(itertools.product(available_tile_impl, repeat=free_slots))       #Combinations (every possible one)
tiles_comb = list(itertools.combinations_with_replacement(available_tile_impl, free_slots))  #Combinations without permutations

#Optional part: randomize the list and chose only some configurations
if randomize:
  random.shuffle(tiles_comb)

n_config = len(tiles_comb)

#Generate all the output directories and index files
index_file = []
for i in range (0, n_output_folders):
  shutil.rmtree(output_folder + "_" + str(i), ignore_errors=True)
  os.mkdir(output_folder + "_" + str(i))
  index_file.append(open(output_folder + "_" +  str(i) + "/index.txt", 'w'))

count = 0


#Finally, iterate over all the possible combinations
for tiles_order in tiles_comb:
  #Check that the combination is feasible - that is, it has every accelerator and at least one memory tile
  mem_check = 0
  acc_check = [0]*len(accelerators)
  acc_check_tot = 1
  for x in range(0, free_slots):
    if tiles_order[x] == 1:
      mem_check = mem_check + 1
    elif tiles_order[x] >= 2:
      acc_check[int((tiles_order[x]-2)/len(parallelism_levels))] = 1
  for x in range(0, len(accelerators)):
    if(acc_check[x] == 0):
      acc_check_tot = 0
  if mem_check == 0 or mem_check == 3 or mem_check > 4 or acc_check_tot == 0:
    continue

  i = count%n_output_folders
  write_config(tiles_order, output_folder + "_" + str(i))
  index_file[i].write(find_config_name(tiles_order) + "\n")
  count = count + 1

  if randomize and count == n_random_configs:
    break

print("Number of possible configurations: " + str(n_config) + "\n")
print("Number of feasible configurations: " + str(count) + "\n")



