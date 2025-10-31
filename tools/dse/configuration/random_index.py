#----------------------------------------------------------------------------
#  This file is a part of the VESPA SoC Prototyping Framework
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the Apache 2.0 License.
#
# File:    random_index.py
# Authors: Gabriele Montanaro
#          Andrea Galimberti
#          Davide Zoni
# Company: Politecnico di Milano
# Mail:    name.surname@polimi.it
#
#----------------------------------------------------------------------------

import random
import sys

input_file_path = sys.argv[1]
output_file_path = sys.argv[2]
num_lines_to_choose = int(sys.argv[3])

def choose_random_lines(input_file, output_file, n):
  with open(input_file, 'r') as f:
    lines = f.readlines()

  if n > len(lines):
    print(f"Error: There are only {len(lines)} lines in the file.")
    return

  random_lines = random.sample(lines, n)

  with open(output_file, 'w') as f:
    f.writelines(random_lines)

choose_random_lines(input_file_path, output_file_path, num_lines_to_choose)
print(f"{num_lines_to_choose} random lines copied from {input_file_path} to {output_file_path}.")
