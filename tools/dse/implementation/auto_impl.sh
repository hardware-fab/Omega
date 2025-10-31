#!/bin/bash

#----------------------------------------------------------------------------
#  This file is a part of the VESPA SoC Prototyping Framework
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the Apache 2.0 License.
#
# File:    auto_impl.sh
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

SCRIPT_FOLDER=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
PYTHON_SCRIPT="$SCRIPT_FOLDER/../configuration/ccf2espConfig.py"
MAKE_COMMAND="make vivado-syn"
RESULTS_FOLDER="$2"
SOC_FOLDER="$SCRIPT_FOLDER/../../../socs/$BOARD-$3"
IMPL_FOLDER="$SOC_FOLDER/vivado/esp-$BOARD.runs/impl_1"


INPUT_FOLDER="$1"
INDEX_FILE="$INPUT_FOLDER/index.txt"

while IFS= read -r line || [[ -n "$line" ]]; do
    INPUT_FILE="$INPUT_FOLDER/$line.ccf"
    OUTPUT_FOLDER="$RESULTS_FOLDER/impl-$line"
    
    cd "$SCRIPT_FOLDER"

    # Execute Python script with numbered input file
    python3 "$PYTHON_SCRIPT" "$INPUT_FILE" "$SOC_FOLDER"
    
    cd "$SOC_FOLDER"
    
    # Perform make command
    $MAKE_COMMAND
    
    cd "$SCRIPT_FOLDER"
    
    # Create output folder if it doesn't exist
    mkdir -p "$OUTPUT_FOLDER"

    # Move results to output folder
    cp $IMPL_FOLDER/top.bit "$OUTPUT_FOLDER"
    cp $IMPL_FOLDER/hierarchical_utilization.rpt "$OUTPUT_FOLDER"
    cp $IMPL_FOLDER/top_timing_summary_routed.rpt "$OUTPUT_FOLDER"
    cp $SOC_FOLDER/socgen/esp/.esp_config "$OUTPUT_FOLDER"
    cp $IMPL_FOLDER/top_power_routed.rpt "$OUTPUT_FOLDER"
    
    if [ ! -e $OUTPUT_FOLDER/top.bit ]; then
        echo "Error: The bitstream has not been generated!"
        break
    fi
done < "$INDEX_FILE"
