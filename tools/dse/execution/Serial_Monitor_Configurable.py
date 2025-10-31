#----------------------------------------------------------------------------
#  This file is a part of the VESPA SoC Prototyping Framework
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the Apache 2.0 License.
#
# File:    Serial_Monitor_Configurable.py
# Authors: Gabriele Montanaro
#          Andrea Galimberti
#          Davide Zoni
# Company: Politecnico di Milano
# Mail:    name.surname@polimi.it
#
#----------------------------------------------------------------------------

import sys
import serial
import time

#Argument 1: port name (USB0, USB1, ecc.)
#Argument 2: output file path
#Argument 3: execution time


# Serial port configuration
port = "/dev/tty" + sys.argv[1]  # Replace with the correct serial port
baudrate = 38400  # Replace with the correct baud rate

# File configuration
output_file = sys.argv[2]

# Time configuration
time_out = int(sys.argv[3])  # Timeout in seconds
print(f"UART time-out time: {time_out}")

# Open the serial port
ser = serial.Serial(port, baudrate, timeout=time_out)
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
                if elapsed_time >= time_out:
                    break
            except:
                print("ERROR: received an invalid line.\n")

    except KeyboardInterrupt:
        pass

    finally:
        ser.close()




