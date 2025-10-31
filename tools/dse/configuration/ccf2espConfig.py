#!/usr/bin/env python3

#----------------------------------------------------------------------------
#  This file is a part of the VESPA SoC Prototyping Framework
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the Apache 2.0 License.
#
# File:    ccf2espConfig.py
# Authors: Gabriele Montanaro
#          Andrea Galimberti
#          Davide Zoni
# Company: Politecnico di Milano
# Mail:    name.surname@polimi.it
#
#----------------------------------------------------------------------------


# Copyright (c) 2011-2023 Columbia University, System Level Design Group
# SPDX-License-Identifier: Apache-2.0

from tkinter import *
from tkinter import messagebox
import os.path
import glob
import sys
import re #GM change

#import NoCConfiguration as ncfg

def read_entries(file_path):
    entries = {}
    
    with open(file_path, 'r') as file:
        lines = file.readlines()
        
        for line in lines:
            line = line.strip()  # Remove leading/trailing whitespace
            
            if line:  # Skip empty lines
                variable, value = line.split('=')
                variable = variable.strip()
                value = value.strip()
                entries[variable] = value
                
    return entries

#GM note: con questa funzione viene scritto il file di backup
#Per ora metto solo le variabili che sto già usando, alle altre penserò in seguito (ma le lascio tutte lì commentate)
def write_config(config, file_name):
  print("Writing backup configuration: " + file_name)
  fp = open(soc_folder + '/socgen/esp/' + file_name, 'w')
  has_dvfs = False;
  
  fp.write("CPU_ARCH = " + config['CPU_ARCH'] + "\n")
  fp.write("NCPU_TILE = " + str(config['NCPU_TILE']) + "\n")
  #if self.transfers.get() == 1:
  fp.write("CONFIG_HAS_SG = y\n")
  #else:
  #  fp.write("#CONFIG_HAS_SG is not set\n")
  fp.write("CONFIG_NOC_ROWS = " + str(config['CONFIG_NOC_ROWS']) + "\n")
  fp.write("CONFIG_NOC_COLS = " + str(config['CONFIG_NOC_COLS']) + "\n")
  #if self.cache_en.get() == 1:
  #  fp.write("CONFIG_CACHE_EN = y\n")
  #else:
  fp.write("#CONFIG_CACHE_EN is not set\n")
  #if self.cache_rtl.get() == 1:
  fp.write("CONFIG_CACHE_RTL = y\n")
  #else:
  #  fp.write("#CONFIG_CACHE_RTL is not set\n")
  #if self.cache_spandex.get() == 1:
  #  fp.write("CONFIG_CACHE_SPANDEX = y\n")
  #else:
  fp.write("#CONFIG_CACHE_SPANDEX is not set\n")
  fp.write("CONFIG_CPU_CACHES = " + str(512) + " " + str(4) + " " + str(1024) + " " + str(16) + "\n")
  fp.write("CONFIG_ACC_CACHES = " + str(512) + " " + str(4) + "\n")
  fp.write("CONFIG_SLM_KBYTES = " + str(256) + "\n")
  #if self.jtag_en.get() == 1:
  #  fp.write("CONFIG_JTAG_EN = y\n")
  #else:
  fp.write("#CONFIG_JTAG_EN is not set\n")
  #if self.eth_en.get() == 1:
  fp.write("CONFIG_ETH_EN = y\n")
  #else:
  #  fp.write("#CONFIG_ETH_EN is not set\n")
  #if self.iolink_en.get() == 1:
  #  fp.write("CONFIG_IOLINK_EN = y\n")
  #else:
  fp.write("#CONFIG_IOLINK_EN is not set\n")
  #if self.svga_en.get() == 1:
  #fp.write("CONFIG_SVGA_EN = y\n")
  #else:
  fp.write("#CONFIG_SVGA_EN is not set\n")
  #if len(dsu_ip) == 8 and len(dsu_eth) == 12:
  #  self.dsu_ip = dsu_ip
  #  self.dsu_eth = dsu_eth
  fp.write("CONGIG_DSU_IP = " + "C0A80109" + "\n")
  fp.write("CONGIG_DSU_ETH = " + "A6A7A0F8043F" + "\n")
  #if self.noc.monitor_ddr.get() == 1:
  #  fp.write("CONFIG_MON_DDR = y\n")
  #else:
  fp.write("#CONFIG_MON_DDR is not set\n")
  #if self.noc.monitor_mem.get() == 1:
  #  fp.write("CONFIG_MON_MEM = y\n")
  #else:
  fp.write("#CONFIG_MON_MEM is not set\n")
  #if self.noc.monitor_inj.get() == 1:
  #  fp.write("CONFIG_MON_INJ = y\n")
  #else:
  fp.write("#CONFIG_MON_INJ is not set\n")
  #if self.noc.monitor_routers.get() == 1:
  #  fp.write("CONFIG_MON_ROUTERS = y\n")
  #else:
  fp.write("#CONFIG_MON_ROUTERS is not set\n")
  #if self.noc.monitor_accelerators.get() == 1:
  #  fp.write("CONFIG_MON_ACCELERATORS = y\n")
  #else:
  fp.write("#CONFIG_MON_ACCELERATORS is not set\n")
  #if self.noc.monitor_l2.get() == 1:
  #  fp.write("CONFIG_MON_L2 = y\n")
  #else:
  fp.write("#CONFIG_MON_L2 is not set\n")
  #if self.noc.monitor_llc.get() == 1:
  #  fp.write("CONFIG_MON_LLC = y\n")
  #else:
  fp.write("#CONFIG_MON_LLC is not set\n")
  #if self.noc.monitor_dvfs.get() == 1:
  #  fp.write("CONFIG_MON_DVFS = y\n")
  #else:
  fp.write("#CONFIG_MON_DVFS is not set\n")
  i = 0
  for y in range(0, int(config['CONFIG_NOC_ROWS'])):
    for x in range(0, int(config['CONFIG_NOC_COLS'])):
      #tile = self.noc.topology[y][x]
      #selection = tile.ip_type.get()
      #is_cpu = False
      #is_accelerator = False
      #is_slm = False
      tile_content = config['TILE_' + str(y) + '_' +  str(x)]
      clock_region = config['CLOCK_' + str(y) + '_' +  str(x)]
      has_pll = config['PLL_' + str(y) + '_' +  str(x)]
      bandwidth = config['BW_' + str(y) + '_' +  str(x)]
      fp.write("TILE_" + str(y) + "_" + str(x) + " = ")
      # Tile number
      fp.write(str(i) + " ")
      # Tile type
      if tile_content == "cpu":
        #is_cpu = True
        fp.write("cpu")
      elif tile_content == "IO":
        fp.write("misc")
      elif tile_content == "mem":
        fp.write("mem")
      elif tile_content == "empty":
        #is_slm = True
        fp.write("empty")
      #elif self.IPs.ACCELERATORS.count(selection):
        # is_accelerator = True
        #fp.write("acc")
      else:
        fp.write("acc")
      # Selected accelerator or tile type repeated
      fp.write(" " + tile_content)
      # Clock region info
      fp.write(" " + str(clock_region))
      if clock_region != 0:
        has_dvfs = True;
      fp.write(" " + str(has_pll))
      fp.write(" " + str(0))
      # SLM tile configuration
      #if is_slm:
      #  fp.write(" " + str(tile.has_ddr.get()))
      # Acceleator tile configuration
      if tile_content != "mem" and tile_content != "IO" and tile_content != "cpu" and tile_content != "empty":
        if "VIVADO" in tile_content:
          fp.write(" " + "dma64_w" + str(bandwidth))
        elif "RTL" in tile_content:
          fp.write(" " + "basic_dma64")
        fp.write(" " + str(0))
        fp.write(" " + "sld")
        n_cores = config['NCORES_' + str(y) + '_' +  str(x)]
        fp.write(" " + str(n_cores))
      fp.write("\n")
      i += 1
  if has_dvfs:
    fp.write("CONFIG_HAS_DVFS = y\n")
  else:
    fp.write("#CONFIG_HAS_DVFS is not set\n")
  fp.write("CONFIG_VF_POINTS = " + str(4) + "\n")
  for y in range(int(config['CONFIG_NOC_ROWS'])):
    for x in range(int(config['CONFIG_NOC_COLS'])):
      #tile = self.noc.topology[y][x]
      #selection = tile.ip_type.get()
      tile_content = config['TILE_' + str(y) + '_' +  str(x)]
      fp.write("POWER_" + str(y) + "_" + str(x) + " = ")
      fp.write(tile_content + " ")
      if tile_content == "mem" or tile_content == "IO" or tile_content == "cpu" and tile_content != "empty":
        for vf in range(4):
          fp.write(str(0) + " " + str(0) + " " + str(0) + " ")
        fp.write("\n")
      else:
        for vf in range(4):
          fp.write("0.0" + " " + "0.0" + " " + "0.0" + " ")
        fp.write("\n")
  fp.write("CONFIG_NOC_PLANES = " + str(config['CONFIG_NOC_PLANES']) + "\n")
  for y in range(0, int(config['CONFIG_NOC_ROWS'])):
    for x in range(0, int(config['CONFIG_NOC_COLS'])):
      fp.write ("NOC_" + str(y) + "_" + str(x) + " = 0\n")

  fp.write("CONFIG_MEM_SIZE_MAIN = " + str(config['CONFIG_MEM_SIZE_MAIN']) + "\n")
  fp.write("CONFIG_MEM_SIZE_SECONDARY = " + str(config['CONFIG_MEM_SIZE_SECONDARY']) + "\n")


def convert_config_file(file_path):
    initial_configs = read_entries(file_path)
    write_config(initial_configs)


# Example usage:
file_path = sys.argv[1]  # Replace with your file path
soc_folder = sys.argv[2]
initial_configs = read_entries(file_path)

# Printing the stored values
write_config(initial_configs, ".esp_config")
write_config(initial_configs, ".esp_config.bak")
