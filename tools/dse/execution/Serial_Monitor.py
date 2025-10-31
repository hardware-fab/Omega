#----------------------------------------------------------------------------
#  This file is a part of the VESPA SoC Prototyping Framework
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the Apache 2.0 License.
#
# File:    Serial_Monitor.py
# Authors: Gabriele Montanaro
#          Andrea Galimberti
#          Davide Zoni
# Company: Politecnico di Milano
# Mail:    name.surname@polimi.it
#
#----------------------------------------------------------------------------

import serial
import time

# Serial port configuration
port = "/dev/ttyUSB2"  # Replace with the correct serial port
baudrate = 38400  # Replace with the correct baud rate

# File configuration
output_file = "output.txt"

# Time configuration
timeout = 20  # Timeout in seconds


# Open the serial port
ser = serial.Serial(port, baudrate, timeout=10)
# Open the output file
with open(output_file, "w") as file:
    start_time = time.time()

    try:
        while True:
            # Read a line from the serial port
            try:
                line = ser.readline().decode("utf-8").strip()

                # Save the line to the output file
                if line:
                    file.write(line + "\n")
                    file.flush()

                # Check if the timeout has been reached
                elapsed_time = time.time() - start_time
                if elapsed_time >= timeout:
                    break
            except:
                print("ERROR: received an invalid line.\n")
    except KeyboardInterrupt:
        pass

    finally:
        ser.close()




