#----------------------------------------------------------------------------
#  This file is a part of the VESPA SoC Prototyping Framework
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the Apache 2.0 License.
#
# File:    load_data.py
# Authors: Gabriele Montanaro
#          Andrea Galimberti
#          Davide Zoni
# Company: Politecnico di Milano
# Mail:    name.surname@polimi.it
#
#----------------------------------------------------------------------------

# This is a module containing functions that read configuration files and translates them to python variables.
# It will be imported from all the other DSE modules in order to read two information file: the generic one
# (with info on the various tiles) and the specific one (with information on the SoCs to be explored in the
# current DSE).

import sys


#Very simple function that returns all the lines between two given keywords
def extractTextBetweenKeywords (source_file, start_keyword, end_keyword):

  with open(source_file, 'r') as source:
    lines = source.readlines()

  start_index = next(i for i, line in enumerate(lines) if start_keyword in line) + 1
  end_index = next(i for i, line in enumerate(lines) if end_keyword in line)

  extracted_text = lines[start_index:end_index]

  return extracted_text


#Very simple function that returns a line containing a specific keyword
def extractLineWithKeyword (source_file, keyword):

  with open(source_file, 'r') as source:
    lines = source.readlines()

  extracted_text = ""
  for line in lines:
    if keyword in line:
      extracted_text = line

  return extracted_text


#This function returns a dictionary containing all the accelerators' info
def loadAllAccInfo (tiles_file):
  entry_dict = {}
  #Find the important portion of the text file
  extracted_text = extractTextBetweenKeywords(tiles_file, "ACC_LIST_START", "ACC_LIST_END")
  #Check each line
  for line in extracted_text:
    # Split each line into words
    words = line.split()
    # Check if the line has the expected format
    if len(words) == 8:
      acc_name = words[0]
      acc_esp = words[1]
      acc_bw = int(words[2])
      acc_thr = float(words[3])
      acc_area_x1 = int(words[4])
      acc_area_x2 = int(words[5])
      acc_area_x4 = int(words[6])
      behaviour = words[7]
      # Store the values in the dictionary
      entry_dict[acc_name] = (acc_esp, acc_bw, acc_thr, acc_area_x1, acc_area_x2, acc_area_x4, behaviour)

  return entry_dict


#This function returns the area data of non-accelerator tiles
def loadTilesArea (tiles_file):
  entry_dict = {}
  #Find the important portion of the text file
  extracted_text = extractTextBetweenKeywords(tiles_file, "TILES_AREA_START", "TILES_AREA_END")
  #Check each line
  for line in extracted_text:
    # Split each line into words
    words = line.split()
    # Check if the line has the expected format
    if len(words) == 2:
      tile_name = words[0]
      tile_area = int(words[1])
      # Store the values in the dictionary
      entry_dict[tile_name] = (tile_area)

  return entry_dict


#This function returns the X size of the NoC
def getNocSizeX (dse_file):
  #Find the interesting line
  line = extractLineWithKeyword(dse_file, "NOC_SIZE_X")
  #Return the value
  words = line.split()
  return int(words[1])

#This function returns the Y size of the NoC
def getNocSizeY (dse_file):
  #Find the interesting line
  line = extractLineWithKeyword(dse_file, "NOC_SIZE_Y")
  #Return the value
  words = line.split()
  return int(words[1])

#This function returns a list containing all the possible parallelism levels
def getParLvls (dse_file):
  #Find the interesting line
  line = extractLineWithKeyword(dse_file, "PAR_LVLS")
  #Return the value
  words = line.split()
  par_lvls = []
  for i in range(1, len(words)):
    par_lvls.append(int(words[i]))
  return par_lvls

#This function returns a list containing all the accelerators available in the current DSE
def getAccList (dse_file):
  #Find the interesting line
  line = extractLineWithKeyword(dse_file, "ACC_LIST")
  #Return the value
  words = line.split()
  acc_list = []
  for i in range(1, len(words)):
    acc_list.append(words[i])
  return acc_list

#This function returns a list containing all the accelerators thresholds
def getThresholdList (dse_file):
  #Find the interesting line
  line = extractLineWithKeyword(dse_file, "THR_LIST")
  #Return the value
  words = line.split()
  thr_list = []
  for i in range(1, len(words)):
    thr_list.append(float(words[i]))
  return thr_list

#This function returns the number of memory tiles available in the configuration
def getMemNum (dse_file):
  #Find the interesting line
  line = extractLineWithKeyword(dse_file, "N_MEM")
  #Return the value
  words = line.split()
  if (len(words) == 2):
    return int(words[1])
  else:
    mem_list = []
    for i in range(1, len(words)):
      mem_list.append(int(words[i]))
    return mem_list   

#This function returns a dictionary with the "memory priority" of each accelerator
def loadAccOrder (tiles_file):
  entry_dict = {}
  #Find the important portion of the text file
  extracted_text = extractTextBetweenKeywords(tiles_file, "ACC_ORDER_START", "ACC_ORDER_END")
  #Check each line
  for line in extracted_text:
    # Split each line into words
    words = line.split()
    # Check if the line has the expected format
    if len(words) > 1:
      count = 0
      for acc in words:
        entry_dict[acc] = count
        count += 1

  return entry_dict

#Functions test
#dse_conf = sys.argv[1]
#general_info = sys.argv[2]
#
#print(loadAllAccInfo(general_info))
#print(loadTilesArea(general_info))
#print("Noc x = " + str(getNocSizeX(dse_conf)))
#print("Noc y = " + str(getNocSizeY(dse_conf)))
#print(getParLvls(dse_conf))
#print(getAccList(dse_conf))

