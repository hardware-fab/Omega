#----------------------------------------------------------------------------
#  This file is a part of the VESPA SoC Prototyping Framework
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the Apache 2.0 License.
#
# File:    mcf2ccf.py.py
# Authors: Gabriele Montanaro
#          Andrea Galimberti
#          Davide Zoni
# Company: Politecnico di Milano
# Mail:    name.surname@polimi.it
#
#----------------------------------------------------------------------------

#This script takes as input a minimal configuration file, that is a text file containing only the minimal info regarding the size of the NoC and the name, positions and clock domain of every accelerator and memory tile present in the SoC.
#From the available information, this script assumes all the other data as PLL positions, cpu/io tiles positions, ecc.
#It returns as output a complete configuration file, that is a text file that can be translated one-to-one to an esp configuration file.

import sys
import os
import shutil
import numpy as np
sys.path.append(sys.path[0] + '/../generic')
import load_data

#Arguments: input configuration file and output directory
input_file = sys.argv[1]
tiles_info = sys.argv[2]
output_folder = sys.argv[3]

#Bench/bandwidth association
acc_dict = load_data.loadAllAccInfo(tiles_info)

#Keywords for minimal configuration scripts
noc_keyword = "NOC"
mem_keyword = "MEM"
empty_keyword = "EMPTY"

#---------------------------------Function to read a minimal configuration file-----------------------------------------------------
def read_file_and_create_dictionary(file_path):
  # Create an empty dictionary to store the data
  entry_dict = {}
  entry_count = 0
  # Open the file and read it line by line
  with open(file_path, 'r') as file:
    for line in file:
      # Split each line into words
      words = line.split()

      # Check if the line has the expected format
      if len(words) == 5:
        entry_name = "entry" + str(entry_count)
        tile_type = words[0]
        x_value = int(words[1])
        y_value = int(words[2])
        clk_domain = int(words[3])
        par_lvl = int(words[4])
        # Store the values in the dictionary
        entry_dict[entry_name] = (tile_type, x_value, y_value, clk_domain, par_lvl)
        entry_count = entry_count + 1
      else:
        print(f"Warning: Skipped invalid line - {line.strip()}")

  return entry_dict


#----------------------------------Simple function to write a complete configuration file-----------------------------------

def write_config(folder, data):
  #Noc size from a specific entry in the dictionary
  noc_size = data["entry0"]
  noc_x = noc_size[1]
  noc_y = noc_size[2]
  n_domains = noc_size[3]
  n_mem_tiles = 0
  #A couple of check notes to understand which positions/clock domains have been filled
  positions_check = np.zeros((noc_y, noc_x), dtype=int)
  domains_check = [0] * n_domains
  #Extracting the configuration name, as the sequence of the accelerators in the SoC
  config_name = "config"
  for yy in range (0, noc_y):
    for xx in range (0, noc_x):
      for entry_name, (tile_type, x, y, clk, par) in data.items():
        if tile_type != noc_keyword and xx == x and yy == y:
          config_name += "_" + tile_type
          if tile_type != mem_keyword and tile_type != empty_keyword:
            config_name += "x" + str(par)
  #Create index file (necessary even with single executions for the auto_impl.sh script)
  fp_indexfile = open(folder + "/index.txt", 'w')
  fp_indexfile.write(config_name + "\n")
  #Print the configuration name and open the configuration file
  print("Writing configuration: " + config_name + "\n")
  fp = open(folder + "/" + config_name + ".ccf", 'w')
  #Write preliminary info
  fp.write("CPU_ARCH = ariane\n")
  fp.write("NCPU_TILE = 1\n")
  fp.write("CONFIG_NOC_ROWS = " + str(noc_y) + "\n")
  fp.write("CONFIG_NOC_COLS = " + str(noc_x) + "\n")
  fp.write("CONFIG_NOC_PLANES = 1\n")

  #Write accelerators data
  for entry_name, (tile_type, x, y, clk, par) in data.items():
    #Check the position
    if tile_type == noc_keyword:
      continue
    if positions_check[y, x] != 0:
      print("Error: this position has already been filled. Terminating the execution. \n")
      return
    positions_check[y, x] = 1
    print("Filling position " + str(x) + ", " + str(y) + "\n")
    #Empty tile
    if tile_type == empty_keyword:
      fp.write("TILE_" + str(y) + "_" + str(x) + " = empty\n")
      fp.write("CLOCK_" + str(y) + "_" + str(x) + " = 0\n")
      fp.write("PLL_" + str(y) + "_" + str(x) + " = 0\n")
      fp.write("BW_" + str(y) + "_" + str(x) + " = 0\n")
    #Memory tile
    elif tile_type == mem_keyword:
      fp.write("TILE_" + str(y) + "_" + str(x) + " = mem\n")
      fp.write("CLOCK_" + str(y) + "_" + str(x) + " = 0\n")
      fp.write("PLL_" + str(y) + "_" + str(x) + " = 0\n")
      fp.write("BW_" + str(y) + "_" + str(x) + " = 0\n")
      n_mem_tiles = n_mem_tiles + 1
    #Accelerator tile
    else:
      #Put PLLs only in the first accelerator of a specific clock domain
      if(domains_check[clk] == 0):
        has_pll = 1
        domains_check[clk] = 1
      else:
        has_pll = 0
      #Name and clock domains info are already in the dictionary, bandwidth has its own
      fp.write("TILE_" + str(y) + "_" + str(x) + " = " + acc_dict[tile_type][0] + "\n")
      fp.write("CLOCK_" + str(y) + "_" + str(x) + " = " + str(clk) + "\n")
      fp.write("PLL_" + str(y) + "_" + str(x) + " = " + str(has_pll) + "\n")
      fp.write("BW_" + str(y) + "_" + str(x) + " = " + str(acc_dict[tile_type][1]) + "\n")
      fp.write("NCORES_" + str(y) + "_" + str(x) + " = " + str(par) + "\n")

  #Write other components' data, checking which positions have not been filled
  count = 0
  for y in range(0, noc_y):
    for x in range(0, noc_x):
      if positions_check[y, x] == 0:
        #CPU
        if count == 0:
          clock_region = 1
          has_pll = 1
          bandwidth = 0
          tile_content = "cpu"
        #I/O
        elif count == 1:
          clock_region = 0
          has_pll = 0
          bandwidth = 0
          tile_content = "IO"
        count += 1
        #Check for empty tiles (TODO: put empty tiles instead of terminating the execution!)
        if count > 2:
          print("Error: one or more tiles cannot be filled. Terminating the execution. \n")
          return
        #Write the entry
        fp.write("TILE_" + str(y) + "_" + str(x) + " = " + tile_content + "\n")
        fp.write("CLOCK_" + str(y) + "_" + str(x) + " = " + str(clock_region) + "\n")
        fp.write("PLL_" + str(y) + "_" + str(x) + " = " + str(has_pll) + "\n")
        fp.write("BW_" + str(y) + "_" + str(x) + " = " + str(bandwidth) + "\n")

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

  #Close files
  fp.close()
  fp_indexfile.close()

# Collects the minimal configuration file info in a dictionary
main_dict = read_file_and_create_dictionary(input_file)

#Generates the complete configuration file from the dictionary
write_config(output_folder, main_dict)
