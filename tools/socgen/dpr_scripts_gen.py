#----------------------------------------------------------------------------
#  This file is a part of the VESPA SoC Prototyping Framework
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the Apache 2.0 License.
#
# File:    socmap_gen.vhd
# Authors: Gabriele Montanaro
#          Andrea Galimberti
#          Davide Zoni
# Company: Politecnico di Milano
# Mail:    name.surname@polimi.it
#
#----------------------------------------------------------------------------

#!/usr/bin/env python3

#This python script contains three functions: "GenerateDprScripts", "GenerateDefaultTileDpr", and "GenerateFloorplanDpr"
#The first one has the goal of generating the tcl script that configures the reconfigurable modules and partitions inside the Vivado project.
#The second one duplicates the tile_dpr module of a specific accelerator to be used as a default dpr tile during simulation.
#The third one generates a constraint file containing the Pblocks of the reconfigurable partition.


from collections import defaultdict
import math
from thirdparty import *
import os
import json
import sys
import re

#####################   GenerateDprScripts   #####################

def GenerateDprScripts(esp_config, soc):

  fp = open('dpr_flow.tcl', 'w')

  #Print a header for a more readable file
  fp.write("#This tcl script is generated from the file dpr_scripts_gen.py\n")
  fp.write("#It implements the commands to make a reconfigurable partition from every DPR tile,\n")
  fp.write("#and to make a reconfigurable module from each selected accelerator.\n\n\n")

  #If no dpr tile is present in the design, leave this file empty.
  if esp_config.ndpr == 0:
    fp.write("#No DPR tiles in the design. This script is empty.\n")
    fp.close()
    return

  fp.write("open_project esp-" + soc.FPGA_BOARD + ".xpr\n\n")

  fp.write("###  Activate DFX flow  ###\n")
  fp.write("set_property PR_FLOW 1 [current_project]\n\n")

  fp.write("###  Create RP from \"tile_dpr\" module  ###\n")
  fp.write("create_partition_def -name acc_slot -module tile_dpr\n\n\n")

  #The system allows only powers of two as parallelism levels
  power = 1
  par_lvls = []
  while power <= soc.reconf_ncores.get():
    par_lvls.append(power)
    power = power*2

  #Generate one reconfigurable module for each accelerator and each parallelism level
  fp.write("##########  CREATION OF THE RECONFIGURABLE MODULES  ##########\n\n")

  fp.write("###  Create reconfigurable modules from the default dpr tile  ###\n")
  fp.write("create_reconfig_module -name tile_dpr -partition_def [get_partition_defs acc_slot ]  -define_from tile_dpr\n")
  fp.write("update_compile_order -fileset tile_dpr\n\n")

  fp.write("###  Create reconfigurable modules from the empty dpr tile  ###\n")
  fp.write("create_reconfig_module -name tile_dpr_empty -partition_def [get_partition_defs acc_slot ]  -define_from tile_dpr_empty\n")
  fp.write("update_compile_order -fileset tile_dpr_empty\n\n")

  for acc in soc.reconf_acc:
    fp.write("###  Create reconfigurable modules from " + acc + "  ###\n")
    for par in par_lvls:
      module_name = "tile_dpr_" + acc + "_PAR" + str(par)
      fp.write("create_reconfig_module -name " + module_name + " -partition_def [get_partition_defs acc_slot ]  -define_from " + module_name + "\n")
      fp.write("update_compile_order -fileset " + module_name + "\n\n")
  fp.write("\n")

  #Each configuration is a repetition of a single reconfigurable module on each available tile.
  #The first configuration is the default tile (Vivado requires that a RM with the same name as the RP is present in the configurations).
  conf_count = 0
  fp.write("##########  CREATION OF THE CONFIGURATIONS  ##########\n\n")
  #Default configuration
  instance_name = "dpr_tile.tile_dpr_i/tile_dpr_1:tile_dpr"
  fp.write("create_pr_configuration -name config_" + str(conf_count) + " -partitions [list ")
  for tile_count in range(0, esp_config.ntiles):
    if esp_config.tiles[tile_count].type == "dpr":
      fp.write("esp_1/tiles_gen[" + str(tile_count) + "]." + instance_name + " ")
  fp.write("]\n")
  #Empty configuration
  conf_count = 1
  instance_name = "dpr_tile.tile_dpr_i/tile_dpr_1:tile_dpr_empty"
  fp.write("create_pr_configuration -name config_" + str(conf_count) + " -partitions [list ")
  for tile_count in range(0, esp_config.ntiles):
    if esp_config.tiles[tile_count].type == "dpr":
      fp.write("esp_1/tiles_gen[" + str(tile_count) + "]." + instance_name + " ")
  fp.write("]\n")
  #Other configurations
  for acc in soc.reconf_acc:
    for par in par_lvls:
      conf_count += 1
      instance_name = "dpr_tile.tile_dpr_i/tile_dpr_1:tile_dpr_" + acc + "_PAR" + str(par)
      fp.write("create_pr_configuration -name config_" + str(conf_count) + " -partitions [list ")
      for tile_count in range(0, esp_config.ntiles):
        if esp_config.tiles[tile_count].type == "dpr":
          fp.write("esp_1/tiles_gen[" + str(tile_count) + "]." + instance_name + " ")
      fp.write("]\n")
  fp.write("\n\n")

  #Generate the design runs (one for each configuration). The first configuration creates the parent run, the others are its children.
  fp.write("##########  CREATION OF THE DESIGN RUNS  ##########\n\n")
  fp.write("set_property PR_CONFIGURATION config_0 [get_runs impl_1]\n")
  for run_count in range(1, conf_count+1):
    fp.write("create_run child_" + str(run_count) + "_impl_1 -parent_run impl_1 -flow {Vivado Implementation 2023} -pr_config config_" + str(run_count) + "\n")

  fp.close()


#####################   GenerateDefaultTileDpr   #####################
  
def GenerateDefaultTileDpr(default_acc_name):

  #Find output path
  out_dir = "../../socketgen/dpr"
  if not os.path.exists(out_dir):
    print("ERROR: you should run \"make socketgen\" to generate the DPR accelerator modules before trying to setup a DPR project.")

  #Define source and destination VHDL files
  source_module = out_dir + "/tile_dpr_" + default_acc_name + "_PAR1.vhd"
  dest_module = "tile_dpr.vhd"

  #Copy the source in the destination, changing only the lines where the module name appears
  with open(dest_module, 'w') as dest:
    with open(source_module, 'r') as source:
      for tline in source:
        if tline.find("entity tile_dpr_" + default_acc_name + "_PAR1 is") >= 0:
          dest.write("entity tile_dpr is\n")
        elif tline.find("architecture rtl of tile_dpr_" + default_acc_name + "_PAR1 is") >= 0:
          dest.write("architecture rtl of tile_dpr is\n")
        else:
          dest.write(tline)



#####################   GenerateFloorplanDpr   #####################

def GenerateFloorplanDpr(esp_config, soc):

  fp = open('dpr_floorplan.xdc', 'w')

  #Print a header for a more readable file
  fp.write("#This constraint file has been automatically generated from the file " + sys.path[0] + "/dpr_scripts_gen.py\n")
  fp.write("#It implements a set of Pblocks for the DPR flow, retrieved from the \"dpr_floorplan.json\" file, available in the \"constraints\" folder.\n\n\n")

  #If no dpr tile is present in the design, leave this file empty.
  if esp_config.ndpr == 0:
    fp.write("#No DPR tiles in the design. This constraint file is empty.\n")
    fp.close()
    return

  fp.write("####################### !!!WARNING!!! ######################\n\n")
  fp.write("#The number of LUTs, FFs, DSPs and BRAMs in each Pblock is limited, and it may not be enough for large accelerators (especially in terms of DSPs).\n")
  fp.write("#When it happens, Vivado throws an error saying that the Pblock does not contain enough resources.\n")
  fp.write("#If you use accelerators with a large area consumption, please check the size of the Pblocks with Vivado.\n\n")
  fp.write("############################################################\n\n\n")

  #Get the coordinates of the possible Pblocks inside the device from a dedicated json file
  data_file = "../../../../constraints/" + soc.FPGA_BOARD + "/dpr_pblocks.json"
  with open(data_file, 'r') as file:
    pblocks_xy_total = json.load(file)

  #Based on the max parallelism level, choose the right dictionary
  pblocks_xy = pblocks_xy_total["PARLVL_" + str(soc.reconf_ncores.get())]

  #Generate a configurable number of pblocks
  pblock_count = 1
  for tile_count in range(0, esp_config.ntiles):
    if esp_config.tiles[tile_count].type == "dpr":
      fp.write("########## PBLOCK " + str(pblock_count) + " ##########\n\n")
      pblock_name = "pblock_tile_dpr_" + str(pblock_count)
      fp.write("create_pblock " + pblock_name + "\n")
      fp.write("add_cells_to_pblock [get_pblocks " + pblock_name + "] [get_cells -quiet [list {esp_1/tiles_gen[" + str(tile_count) + "].dpr_tile.tile_dpr_i/tile_dpr_1}]]\n")
      fp.write("resize_pblock [get_pblocks " + pblock_name + "] -add {" + pblocks_xy["pblock_tile_dpr_" + str(pblock_count)]["SLICE"]["start"]  + ":" + pblocks_xy["pblock_tile_dpr_" + str(pblock_count)]["SLICE"]["end"] + "}\n")
      fp.write("resize_pblock [get_pblocks " + pblock_name + "] -add {" + pblocks_xy["pblock_tile_dpr_" + str(pblock_count)]["DSP"]["start"]    + ":" + pblocks_xy["pblock_tile_dpr_" + str(pblock_count)]["DSP"]["end"] + "}\n")
      fp.write("resize_pblock [get_pblocks " + pblock_name + "] -add {" + pblocks_xy["pblock_tile_dpr_" + str(pblock_count)]["RAMB18"]["start"] + ":" + pblocks_xy["pblock_tile_dpr_" + str(pblock_count)]["RAMB18"]["end"] + "}\n")
      fp.write("resize_pblock [get_pblocks " + pblock_name + "] -add {" + pblocks_xy["pblock_tile_dpr_" + str(pblock_count)]["RAMB36"]["start"] + ":" + pblocks_xy["pblock_tile_dpr_" + str(pblock_count)]["RAMB36"]["end"] + "}\n")
      if "LAGUNA" in pblocks_xy["pblock_tile_dpr_" + str(pblock_count)]:
        fp.write("resize_pblock [get_pblocks " + pblock_name + "] -add {" + pblocks_xy["pblock_tile_dpr_" + str(pblock_count)]["LAGUNA"]["start"] + ":" + pblocks_xy["pblock_tile_dpr_" + str(pblock_count)]["LAGUNA"]["end"] + "}\n")
      fp.write("set_property SNAPPING_MODE ON [get_pblocks " + pblock_name + "]\n\n\n")
      pblock_count += 1



#####################   Main   #####################

#The function of this script when directly called from the terminal is to generate the json file from an xdc vivado file containing the pblocks declaration

# Patterns to match pblock sections in the .xdc file
pblock_pattern = r"create_pblock\s+(\S+)"
resize_pattern = r"resize_pblock\s+\[get_pblocks\s+(\S+)\]\s+-add\s+\{(\S+):(\S+)\}"

# A function to categorize resource type based on the start of the string
def GetResourceType(resource):
    if resource.startswith("SLICE"):
        return "SLICE"
    elif resource.startswith("DSP"):
        return "DSP"
    elif resource.startswith("RAMB18"):
        return "RAMB18"
    elif resource.startswith("RAMB36"):
        return "RAMB36"
    elif resource.startswith("LAGUNA"):
        return "LAGUNA"
    return "UNKNOWN"

# Parse the .xdc file
def ParseXdc(file_path):
  pblocks = {}
  current_pblock = None

  with open(file_path, 'r') as f:
    for line in f:
      # Check for create_pblock line
      pblock_match = re.search(pblock_pattern, line)
      if pblock_match:
        current_pblock = pblock_match.group(1)
        pblocks[current_pblock] = {}

      # Check for resize_pblock lines
      resize_match = re.search(resize_pattern, line)
      if resize_match and current_pblock:
        resource_type = GetResourceType(resize_match.group(2))
        if resource_type not in pblocks[current_pblock]:
          pblocks[current_pblock][resource_type] = {}
        pblocks[current_pblock][resource_type]['start'] = resize_match.group(2)
        pblocks[current_pblock][resource_type]['end'] = resize_match.group(3)

  return pblocks

# Convert the parsed data to JSON format
def ConvertToJson(pblocks, output_file):
  with open(output_file, 'w') as f:
    json.dump(pblocks, f, indent=4)

# Example usage
if __name__ == "__main__":
  xdc_file = sys.argv[1]
  output_json = sys.argv[2]

  pblocks_data = ParseXdc(xdc_file)
  ConvertToJson(pblocks_data, output_json)

  print(f'Conversion complete! JSON saved to {output_json}')
