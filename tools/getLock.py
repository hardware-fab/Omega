#----------------------------------------------------------------------------
#  This file is a part of the VESPA SoC Prototyping Framework
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the Apache 2.0 License.
#
# File:    getLock.py
# Authors: Gabriele Montanaro
#          Andrea Galimberti
#          Davide Zoni
# Company: Politecnico di Milano
# Mail:    name.surname@polimi.it
#
#----------------------------------------------------------------------------


#A very simple python script to be called every time you need to lock the access to the FPGA.
#It wait for the lock, and when it has obtained the lock it keeps it until the user insert a code
from filelock import Timeout, FileLock
import subprocess
import sys
import os

print("\nWait to aquire the lock before starting any operation!!!")

#Lock path
lock_path = "/home/" + os.getlogin() + "/.virtex7_fpga.lock"

#Before proceeding, acquire the lock
lock = FileLock(lock_path, timeout=1)
gainedLock = False
while(not gainedLock):
  try:
    with lock.acquire(timeout=5):
      print("\nGained access to the serial port. Now you can execute your application.")
      gainedLock = True

      command = ""
      #Aggiungi un semplice controllo di un inserimento di parola con while, ed è fatta!
      while command != "exit":
        print('\nEnter exit to quit the program and free the lock:')
        command = input()



  except Timeout:
    print("Another application is using the serial port. Please wait.")

print("\n\nLock released. Exiting...\n")



