#----------------------------------------------------------------------------
#  This file is a part of the VESPA SoC Prototyping Framework
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the Apache 2.0 License.
#
# File:    random_config.py
# Authors: Gabriele Montanaro
#          Andrea Galimberti
#          Davide Zoni
# Company: Politecnico di Milano
# Mail:    name.surname@polimi.it
#
#----------------------------------------------------------------------------


#This script takes as input the size of the NoC and number of applications, and generates a minimal configuration file.
#The generated configuration has no particular meaning: is a simple configuration necessary to start the implementation loop.

import sys
import os
import shutil
import numpy as np
import random
sys.path.append(sys.path[0] + '/../generic')
import load_data

#Arguments: soc information and output file
dse_file = sys.argv[1]
config_file = sys.argv[2]

noc_size_x = load_data.getNocSizeX(dse_file)
noc_size_y = load_data.getNocSizeY(dse_file)
par_list = load_data.getParLvls(dse_file)
app_list = load_data.getAccList(dse_file)
app_num = len(app_list)


#Initialization
print("Creating random configuration for SoC with size (x=" + str(noc_size_x) + ",y=" + str(noc_size_y) + ") and " + str(app_num) + " applications")
fp = open(config_file, 'w')
tile_counter = 0

#A random configuration is generated, tile by tile. Here only the tile's type is chosen (empty, mem, or which accelerator).
#Then it is checked: if the check is passed, the configuration is implemented;
#otherwise, another generation round is started

check = 0
tile_list = [-1]*(noc_size_x*noc_size_y-2)

while check == 0:

  #Configuration generation
  for i in range(0, noc_size_x*noc_size_y-2):
    tile_list[i] = random.randint(0, app_num+2-1)

  #Chech: we need the presence of every accelerator and of a power of two number of memory tiles

  n_mem_tiles = 0
  n_app_tiles = [0]*app_num
  check = 1

  #Count every interesting tile type
  for i in range(0, noc_size_x*noc_size_y-2):
    if tile_list[i] == 1:
      n_mem_tiles = n_mem_tiles + 1
    if tile_list[i] > 1:
      n_app_tiles[tile_list[i]-2] = n_app_tiles[tile_list[i]-2] + 1

  #Memory check
  if n_mem_tiles == 0 or n_mem_tiles == 3 or n_mem_tiles > 4:
    check = 0

  #Accelerators check
  for app in range(0, app_num):
    if n_app_tiles[app] == 0:
      check = 0


#First entry: noc general parameters
fp.write("NOC " + str(noc_size_x) + " " + str(noc_size_y) + " " + str(3) + " " + str(app_num) + "\n")

#Main loop
for y in range(0, noc_size_y):
  for x in range(0, noc_size_x):
    #The first 2 positions of the first column are dedicated to cpu and IO
    if (x==0 and y<2):
      continue
    #Empty tile
    if tile_list[tile_counter] == 0:
      fp.write("EMPTY" + " " + str(x) + " " + str(y) + " " + str(0) + " " + str(0) + "\n")
    #Memory tile
    if tile_list[tile_counter] == 1:
      fp.write("MEM" + " " + str(x) + " " + str(y) + " " + str(0) + " " + str(0) + "\n")
    #Accelerator tile (parallelism is randomized here)
    if tile_list[tile_counter] > 1:
      fp.write(app_list[tile_list[tile_counter]-2] + " " + str(x) + " " + str(y) + " " + str(2) + " " + str(par_list[random.randint(0, len(par_list)-1)]) + "\n")
    tile_counter = tile_counter + 1

fp.close()
