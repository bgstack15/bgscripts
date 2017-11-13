#!/usr/bin/python3
# File: /usr/share/bgscripts/py/bgs.py
# Author: bgstack15@gmail.com
# Startdate: 2017-11-12 16:00
# Title: Python Library For Bgscripts
# Purpose: Brings in My Personal Python Library
# Package: bgscripts
# History:
#    2017-11-03 testing modifications for making a different wrapper
# Usage:
#    import os, sys
#    lib_path = os.path.abspath(os.path.join('..', '..', '..', '..', '..', 'usr', 'share', 'bgscripts', 'py'))
#    sys.path.append(lib_path)
#    import bgs
# Reference:
#    dli.py
#    https://stackoverflow.com/questions/30781962/import-module-from-specific-folder/30782090#30782090
# Improve:
import os, sys

bgspyversion="2017-11-12a"

# A more complete example of how to use debuglev:
#    parser = argparse.ArgumentParser()
#    parser.add_argument("-d","--debug", nargs='?', default=0, type=int, choices=range(0,11), help="Set debug level.")
#    args = parser.parse_args()
#    debuglevel = 0
#    if args.debug is None:
#       # -d was used but no value provided
#       debuglevel = 10
#    elif args.debug:
#       debuglevel = args.debug
def debuglev(numbertocheck,debuglevel=0):
   # call: if bgscripts.debuglev(3,debuglevel): print('debug info is displayed')

   # if numbertocheck <= debuglevel then return truthy 
   debuglev = False
   try:
      if int(numbertocheck) <= int(debuglevel):
         debuglev = True 
   except Exception as e:
      pass
   return debuglev 

def readlinkf(inpath):
   # simulates readlink -f from *nix
   if os.path.islink(infile):
      return os.path.join(os.path.dirname(inpath),os.readlink(inpath))
   else:
      return inpath

def eprint(*args, **kwargs):
   print(*args, file=sys.stderr, **kwargs)
