#----------------------------------------------------------------------------
#  This file is a part of the VESPA SoC Prototyping Framework
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the Apache 2.0 License.
#
# File:    copy_results.py
# Authors: Gabriele Montanaro
#          Andrea Galimberti
#          Davide Zoni
# Company: Politecnico di Milano
# Mail:    name.surname@polimi.it
#
#----------------------------------------------------------------------------

import sys
import load_data
import os

new_dataset_line = ""

def extract_configuration(source_file):
  global new_dataset_line
  with open(source_file, 'r') as file:
    for line in file:
      # Split each line into words
      #words = line.split("_")
      words = [''.join(c for c in word if c.isalnum()) for word in line.split("_")]
      #Add the entry to the output line
      for word_count in range(0, len(words)):
        if words[word_count] != "config":
          new_dataset_line = new_dataset_line + words[word_count]
          if word_count != len(words)-1:
            new_dataset_line = new_dataset_line + " "

      return line.strip()

def find_lut_consumption(source_file):
  global new_dataset_line
  with open(source_file) as file:
    for line in file:
      if ("| top" in line):
        words = line.split()
        new_dataset_line = new_dataset_line + " " + words[5]
        print("Added area consumption: " + words[5] + " LUTs")

def copy_text_between_keywords(source_file, start_keyword, end_keyword):
  global new_dataset_line
  with open(source_file, 'r') as source:
    lines = source.readlines()

  try:
    start_index = next(i for i, line in enumerate(lines) if start_keyword in line) + 1
    end_index = next(i for i, line in enumerate(lines) if end_keyword in line)
  except:
    start_index = -1
    end_index = -1

  if start_index == -1:
    new_dataset_line = ""
    print("ERROR: no result found")
  
  else:
    extracted_text = lines[start_index:end_index]
    new_dataset_line = new_dataset_line + " " + extracted_text[0].replace("EXEC_RESULTS ", "")
    print("Added execution data: " + extracted_text[0])


def copy_results_dpr(config_line, exec_file):
  global new_dataset_line
  new_dataset_line = config_line.replace("\n", " ")
  copy_text_between_keywords(exec_file, 'DATA_START', 'DATA_END')
  return new_dataset_line



def main():
  results_folder = sys.argv[1]
  output_file = sys.argv[2]

  start_keyword = 'DATA_START'
  end_keyword = 'DATA_END'

  #If no result is available, write a placeholder
  if not os.path.exists(results_folder):
    with open(output_file, 'a') as destination:
      destination.write("-\n")
  else:
    config = extract_configuration(results_folder + "/index.txt")
    find_lut_consumption(results_folder + "/impl-" + config + "/hierarchical_utilization.rpt")
    copy_text_between_keywords(results_folder + "/exec-" + config + "/output_" + config + ".txt", start_keyword, end_keyword)

    print("Resulting dataset line: " + new_dataset_line)

    with open(output_file, 'a') as destination:
        destination.writelines(new_dataset_line)


if __name__ == "__main__":
  main()

