#----------------------------------------------------------------------------
#  This file is a part of the VESPA SoC Prototyping Framework
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the Apache 2.0 License.
#
# File:    auto_exec_locked.py
# Authors: Gabriele Montanaro
#          Andrea Galimberti
#          Davide Zoni
# Company: Politecnico di Milano
# Mail:    name.surname@polimi.it
#
#----------------------------------------------------------------------------

#A very simple python script to be called every time you need to lock the access to the FPGA.
#It waits until it can
from filelock import Timeout, FileLock
import subprocess
import sys
import os

script_path = sys.path[0] + "/auto_exec.sh"
impl_folder = sys.argv[1]
exec_folder = sys.argv[2]
soc_suffix = sys.argv[3]

#Lock path
#lock_path = "/home/" + os.getlogin() + "/.virtex7_fpga.lock"
lock_path = "/home/" + os.getlogin() + "/.u55c_fpga.lock"

#Before proceeding, acquire the lock
lock = FileLock(lock_path, timeout=1)
gainedLock = False
while(not gainedLock):
  try:
    with lock.acquire(timeout=5):
      print("Gained access to the serial port")
      gainedLock = True

      subprocess.run([script_path, impl_folder, exec_folder, soc_suffix])

  except Timeout:
    print("Another instance of this application is communicating through serial port")




