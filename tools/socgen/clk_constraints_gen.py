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

from collections import defaultdict
import math
from thirdparty import *

def print_constraints(esp_config, soc):

  fp = open('dfs_constraints.xdc', 'w')

  #domain_masters_vector = [0]*esp_config.ndomain
  #domain_counter_vector = [0]*esp_config.ndomain
  clk_names_dict = {}

  #Print a header for a more readable file
  fp.write("#This is a constraints file generated automatically, that separates the mutually exclusive clocks produced by the dfs\n")

  #Find all the master tiles, and save their positions in a vector
  for i in range (0, esp_config.ntiles):
    t = esp_config.tiles[i]
    #if t.has_pll == 1:
     # domain_masters_vector[t.clk_region] = i

  #Find the path of the mux inside the dfs
  for i in range (0, esp_config.ntiles):
    t = esp_config.tiles[i]

    #Mem tiles do not have separated clocks
    #NOTE: that's also true for IO tiles, but since there is just 1 IO tile we use it for the creation of noc clock
    if t.type == "mem" or t.type == "empty":
      continue

    dfs_path = ""
    clkbuf_path = ""

    #Delimitate each clock region with comments
    if t.type == "misc":
      fp.write("\n\n###################################### CLOCKS FOR NOC INTERCONNECT ######################################\n\n")
    else:
      fp.write("\n\n######################################## CLOCKS FOR TILE " + str(i) + " ########################################\n\n")

    mst_index = -1

    #When we found the IO tile, we generate the noc clock
    if t.type == "misc":
      dfs_path = "interconnect_clock_dvfs.dvfs_manager_1/dfs_inst/"
    #otherwise, the clock is inside the master tile
    #else:
    #  mst_index = domain_masters_vector[t.clk_region]
    #  mst_tile = esp_config.tiles[mst_index]
    #  #CPU path
    #  if mst_tile.cpu_id != -1 :
    #    dfs_path = "esp_1/tiles_gen[" + str(mst_index) + "].cpu_tile.tile_cpu_i/clock_with_dfs.dfs_manager_1/dfs_inst/"
    #  #DPR path
    #  elif t.type == "dpr":
    #    dfs_path = "esp_1/tiles_gen[" + str(mst_index) + "].dpr_tile.tile_dpr_i/clock_with_dfs.dfs_manager_1/dfs_inst/"
    #  #Accelerator path
    #  else:
    #    dfs_path = "esp_1/tiles_gen[" + str(mst_index) + "].accelerator_tile.tile_acc_i/clock_with_dfs.dfs_manager_1/dfs_inst/"
    #CPU paths
    elif t.cpu_id != -1 :
      dfs_path = "esp_1/tiles_gen[" + str(i) + "].cpu_tile.tile_cpu_i/clock_with_dfs.dfs_manager_1/dfs_inst/"
      clkbuf_path = "esp_1/tiles_gen[" + str(i) + "].cpu_tile.tile_cpu_i/clock_no_pll.BUFG_inst/"
    #DPR paths
    elif t.type == "dpr":
      dfs_path = "esp_1/tiles_gen[" + str(i) + "].dpr_tile.tile_dpr_i/clock_with_dfs.dfs_manager_1/dfs_inst/"
      clkbuf_path = "esp_1/tiles_gen[" + str(i) + "].dpr_tile.tile_dpr_i/clock_no_pll.BUFG_inst/"
    #Accelerator paths
    else:
      dfs_path = "esp_1/tiles_gen[" + str(i) + "].accelerator_tile.tile_acc_i/clock_with_dfs.dfs_manager_1/dfs_inst/"
      clkbuf_path = "esp_1/tiles_gen[" + str(i) + "].accelerator_tile.tile_acc_i/clock_no_pll.BUFG_inst/"

    #print("mst_index = " + str(mst_index))

    #Clock paths
    clk_mmcm_mst = dfs_path + "mmcm_1/mmcm_adv_inst/CLKOUT0"
    #clk_mmcm_src_0 = dfs_path + "output_muxes[" + str(domain_counter_vector[t.clk_region]) + "].clock_mux/I0"
    #clk_mmcm_src_1 = dfs_path + "output_muxes[" + str(domain_counter_vector[t.clk_region]) + "].clock_mux/I1"
    #clk_mmcm_out = dfs_path + "output_muxes[" + str(domain_counter_vector[t.clk_region]) + "].clock_mux/O"
    clk_mmcm_src_0 = dfs_path + "clock_mux/I0"
    clk_mmcm_src_1 = dfs_path + "clock_mux/I1"
    clk_mmcm_out = dfs_path + "clock_mux/O"
    clk_buf_in = clkbuf_path + "I"
    clk_buf_out = clkbuf_path + "O"

    clk_name_prefix = "clk_domain_" + str(t.clk_region) + "_tile_" + str(i) + "_"

    mul_factor = 2
    #Ariane cannot reach 100MHz (except on UltraScale+), thus it must always have its own DFS
    if soc.TECH != "virtexup" and mst_index != -1 and mst_tile.type == "cpu":
      mul_factor = 1

    if(t.type == "misc"):
      clk_name_prefix = "clk_domain_0_noc_"
    else:
      clk_name_prefix = "clk_domain_" + str(t.clk_region) + "_tile_" + str(i) + "_"


    if t.type == "misc" or t.has_pll == 1:
      fp.write("create_generated_clock -name " + clk_name_prefix + "mmcm_mst [get_pins " + clk_mmcm_mst + "]\n")
      fp.write("create_generated_clock -name " + clk_name_prefix + "mmcm_src_0 -divide_by 1 -multiply_by " + str(mul_factor) + " -source [get_pins " + clk_mmcm_src_0 + "] [get_pins " + clk_mmcm_out + "]\n")
      fp.write("create_generated_clock -name " + clk_name_prefix + "mmcm_src_1 -divide_by 1 -multiply_by " + str(mul_factor) + " -add -master " + clk_name_prefix + "mmcm_mst -source [get_pins " + clk_mmcm_src_1 + "] [get_pins " + clk_mmcm_out + "]\n")
      fp.write("set_clock_groups -physically_exclusive -group " + clk_name_prefix + "mmcm_src_0 -group " + clk_name_prefix + "mmcm_src_1\n")
    #else:
    #  fp.write("create_generated_clock -name " + clk_name_prefix + "clkbuf -divide_by 1 -multiply_by 1 -source [get_pins " + clk_buf_in + "] [get_pins " + clk_buf_out + "]\n")

    #Save clock names in a dictionary, to retrieve them later
    if t.type == "misc" or t.has_pll == 1:
      clk_names_dict.update({"tile_" + str(i) + "_0": clk_name_prefix + "mmcm_src_0"})
      clk_names_dict.update({"tile_" + str(i) + "_1": clk_name_prefix + "mmcm_src_1"})
    #else:
    #  clk_names_dict.update({"tile_" + str(i) : clk_name_prefix + "clkbuf"})

    #update the counter for the clock domain
    #if t.type != "misc":
     # domain_counter_vector[t.clk_region] += 1





  #After all the clocks have been generated, I need to set them as -asynchronous with respect to each other and also to the original clock
  fp.write("\n\n\n\n###################################### SET CLOCKS ASYNC TO EACH OTHER ######################################\n\n\n")

  fp.write("set_property CLOCK_DEDICATED_ROUTE BACKBONE [get_nets clkgenmigref0/xcup.v/in0]\n\n")


  for i in range (0, esp_config.ntiles):
    t = esp_config.tiles[i]

    #Mem tiles do not have separated clocks
    #NOTE: that's also true for IO tiles, but since there is just 1 IO tile we use it for the creation of noc clock
    if t.type == "mem" or t.type == "empty":
      continue

    if t.has_pll == 1 or t.type == "misc":
      fp.write("set_clock_groups -asynchronous -group [get_clocks " + clk_names_dict["tile_" + str(i) + "_0"] + "] -group [get_clocks clk_board_p]\n")
      fp.write("set_clock_groups -asynchronous -group [get_clocks " + clk_names_dict["tile_" + str(i) + "_1"] + "] -group [get_clocks clk_board_p]\n")
      #fp.write("set_clock_groups -asynchronous -group [get_clocks " + clk_names_dict["tile_" + str(i) + "_0"] + "] -group [get_clocks clk_board]\n")
      #fp.write("set_clock_groups -asynchronous -group [get_clocks " + clk_names_dict["tile_" + str(i) + "_1"] + "] -group [get_clocks clk_board]\n")
      fp.write("set_clock_groups -asynchronous -group [get_clocks " + clk_names_dict["tile_" + str(i) + "_0"] + "] -group [get_clocks clk_nobuf]\n")
      fp.write("set_clock_groups -asynchronous -group [get_clocks " + clk_names_dict["tile_" + str(i) + "_1"] + "] -group [get_clocks clk_nobuf]\n")
    #else:
    #  fp.write("set_clock_groups -asynchronous -group [get_clocks " + clk_names_dict["tile_" + str(i)] + "] -group [get_clocks clk_board_p]\n")
    #  fp.write("set_clock_groups -asynchronous -group [get_clocks " + clk_names_dict["tile_" + str(i)] + "] -group [get_clocks clk_board]\n")
    #  fp.write("set_clock_groups -asynchronous -group [get_clocks " + clk_names_dict["tile_" + str(i)] + "] -group [get_clocks clk_nobuf]\n")

    if t.type == "misc" or t.has_pll == 1:
      for j in range (0, i):
        if esp_config.tiles[j].type == "misc" or esp_config.tiles[j].has_pll == 1:
          for ii in range(0, 2):
            for jj in range(0, 2):
              fp.write("set_clock_groups -asynchronous -group [get_clocks " + clk_names_dict["tile_" + str(i) + "_" + str(ii)] + "] -group [get_clocks " + clk_names_dict["tile_" + str(j) + "_" + str(jj)] + "]\n")
        fp.write("\n")



    #if t.type == "misc" or t.has_pll == 1:
    #for j in range (0, i):
    #  if esp_config.tiles[j].type == "mem" or esp_config.tiles[j].type == "empty":
    #    continue
    #  elif esp_config.tiles[j].type == "misc" or esp_config.tiles[j].has_pll:
    #    for ii in range(0, 2):
    #      for jj in range(0, 2):
    #        fp.write("set_clock_groups -asynchronous -group [get_clocks " + clk_names_dict["tile_" + str(i) + "_" + str(ii)] + "] -group [get_clocks " + clk_names_dict["tile_" + str(j) + "_" + str(jj)] + "]\n")
    #  else:
    #    for ii in range(0, 2):
    #      fp.write("set_clock_groups -asynchronous -group [get_clocks " + clk_names_dict["tile_" + str(i) + "_" + str(ii)] + "] -group [get_clocks " + clk_names_dict["tile_" + str(j)] + "]\n")
    #fp.write("\n")

    #else:
    #  for j in range (0, i):
    #    if esp_config.tiles[j].type == "mem" or esp_config.tiles[j].type == "empty":
    #      continue
    #    elif esp_config.tiles[j].type == "misc" or esp_config.tiles[j].has_pll:
    #      for jj in range(0, 2):
    #        fp.write("set_clock_groups -asynchronous -group [get_clocks " + clk_names_dict["tile_" + str(i)] + "] -group [get_clocks " + clk_names_dict["tile_" + str(j) + "_" + str(jj)] + "]\n")
    #    else:
    #      fp.write("set_clock_groups -asynchronous -group [get_clocks " + clk_names_dict["tile_" + str(i)] + "] -group [get_clocks " + clk_names_dict["tile_" + str(j)] + "]\n")
    #  fp.write("\n")

    # Write the override to avoid clock issues caused by the placement of the MMCM and the output buffers in a different clock region.
    # Note that this override is highly discouraged by Vivado. However, clock regions in the Alveo are smaller (and more abundant, of course),
    # making it much more difficult to follow this placement rule.
    if t.type == "misc":
      fp.write("set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets interconnect_clock_dvfs.dvfs_manager_1/dfs_inst/mmcm_0/clk_out1]\n")
      fp.write("set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets interconnect_clock_dvfs.dvfs_manager_1/dfs_inst/mmcm_1/clk_out1]\n\n")
    elif t.has_pll == 1:
      dfs_path = ""
      if t.cpu_id != -1 :
        dfs_path = "esp_1/tiles_gen[" + str(i) + "].cpu_tile.tile_cpu_i/clock_with_dfs.dfs_manager_1/dfs_inst/"
      #DPR path
      elif t.type == "dpr":
        dfs_path = "esp_1/tiles_gen[" + str(i) + "].dpr_tile.tile_dpr_i/clock_with_dfs.dfs_manager_1/dfs_inst/"
      #Accelerator path
      else:
        dfs_path = "esp_1/tiles_gen[" + str(i) + "].accelerator_tile.tile_acc_i/clock_with_dfs.dfs_manager_1/dfs_inst/"

      fp.write("set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets  " + dfs_path + "mmcm_0/clk_out1]\n")
      fp.write("set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets  " + dfs_path + "mmcm_1/clk_out1]\n\n")

  fp.close()

