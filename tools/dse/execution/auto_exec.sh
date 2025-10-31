#!/bin/bash

#----------------------------------------------------------------------------
#  This file is a part of the VESPA SoC Prototyping Framework
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the Apache 2.0 License.
#
# File:    auto_exec.sh
# Authors: Gabriele Montanaro
#          Andrea Galimberti
#          Davide Zoni
# Company: Politecnico di Milano
# Mail:    name.surname@polimi.it
#
#----------------------------------------------------------------------------

set -e

#BOARD="profpga-xc7v2000t"
BOARD="xilinx-u55c-xcu55c"

INPUT_FOLDER="$1"
SCRIPT_FOLDER=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
SOC_FOLDER="$SCRIPT_FOLDER/../../../socs/$BOARD-$3"
PYTHON_SCRIPT="Serial_Monitor.py"
MAKE_COMMANDS=("make esp-config" "make generic_tb_rtl-baremetal" "make fpga-program" "TEST_PROGRAM=./soft-build/ariane/baremetal/generic_tb_rtl.exe make fpga-run")
RESULTS_FOLDER="$2"

INDEX_FILE="$INPUT_FOLDER/index.txt"

echo "Input folder is $INPUT_FOLDER"
echo "Results folder is $RESULTS_FOLDER"
echo "SoC suffix is $3"

echo "Index file is $INDEX_FILE"

while IFS= read -r line || [[ -n "$line" ]]; do

    OUTPUT_FOLDER="$RESULTS_FOLDER/exec-$line"


    cd $SCRIPT_FOLDER
    # Copy the esp_config and the bitstream
    cp "$INPUT_FOLDER/impl-$line/.esp_config" "$SOC_FOLDER/socgen/esp/"
    cp "$INPUT_FOLDER/impl-$line/top.bit" "$SOC_FOLDER"

    cd $SOC_FOLDER
    # Execute make commands (modify as needed)
    for cmd in "${MAKE_COMMANDS[@]}"; do
        echo "Executing command: $cmd"
        eval $cmd
    done

    cd $SCRIPT_FOLDER

    # Execute Python script
    python3 "$PYTHON_SCRIPT"

    # Create output folder if it doesn't exist
    mkdir -p "$OUTPUT_FOLDER"

    # Save file in output folder
    cp "output.txt" "$OUTPUT_FOLDER/output_$line.txt"
done < "$INDEX_FILE"
