#!/usr/bin/env python3
# File: /usr/share/bgscripts/py/dli.py
# Author: bgstack15@gmail.com
# Startdate: 2016-12-08 10:31
# Title: Python Script that Performs Faster Package Lookups
# Purpose: Provides faster dnf installed/available searches
# History:
#    2017-11-12a Changed to use bgs python lib
#    2018-01-28a Save output to ~/.dli directory, so it does not clutter $HOME
# Usage:
# Reference:
#    subprocess get stdout http://stackoverflow.com/questions/6706953/python-using-subprocess-to-call-sed/6707003#6707003
#    http://stackoverflow.com/questions/5574702/how-to-print-to-stderr-in-python/14981125#14981125
#    ensure directory exists https://stackoverflow.com/questions/273192/how-can-i-create-a-directory-if-it-does-not-exist#273227
# Improve:
#    find way to use the latest file, instead of making one for today
from __future__ import print_function
import argparse, datetime, os, sys, subprocess, re
from distutils.spawn import find_executable
from bgs import debuglev, eprint

dlipyversion="2018-01-28a"

# Define functions

# Default default variables
refresh = False
outdir = os.path.expanduser("~") + "/.dli"
fileprefix = outdir + "/dnf"
thisfile = ""
aori = "installed"
today = datetime.date.today().isoformat()
command_dnf = "dnf"
searchstring = []

# Parse parameters
parser = argparse.ArgumentParser(description="Provides faster dnf searches")
aoriparam = parser.add_mutually_exclusive_group()
aoriparam.add_argument("-i", "--installed", action='store_true', help='Default value.')
aoriparam.add_argument("-a", "--available", action='store_true')
parser.add_argument("-r", "--refresh", action='store_true', help='Force a refresh of an existing file for today.')
parser.add_argument("searchstring", nargs='*')
parser.add_argument("-d","--debug", nargs='?', default=0, type=int, choices=range(0,11), help="Set debug level.")
parser.add_argument("-V","--version", action="version", version="%(prog)s " + dlipyversion)

args = parser.parse_args()

debuglevel=0
if args.debug is None:
   # -d was used but no value provided
   debuglevel = 10
elif args.debug:
   debuglevel = args.debug

if args.available: aori = "available"
refresh = args.refresh
if args.searchstring: searchstring = args.searchstring

if debuglev(10,debuglevel): print(searchstring)

# Determine filename
thisfile = fileprefix + "." + aori + "." + today + ".log"
if debuglev(5,debuglevel): eprint("Using file " + thisfile)

# Ensure the ~/.dli directory exists
if not os.path.exists(outdir):
   os.makedirs(outdir)

# Determine yum or dnf
#print(os.environ)
if find_executable("dnf", os.getenv('PATH', '/usr/bin:/bin:/sbin')):
   if debuglev(8,debuglevel): eprint("Using dnf.")
   # which is default already so NOP
elif find_executable("yum", os.getenv('PATH', '/usr/bin:/bin:/sbin')):
   if debuglev(8,debuglevel): eprint("Using yum.")
   command_dnf = "yum"
else:
   eprint("Error: cannot find dnf or yum. Aborted.")
   sys.exit(1)

# Refresh file if needed
if refresh == True or not os.path.isfile(thisfile):
   if debuglev(3,debuglevel): eprint("Refreshing file.")
   # execute dnf list installed > thisfile
   # execute command_dnf list aori > thisfile
   with open(thisfile, "w") as outfile:
      sub = subprocess.call([command_dnf,'-q','list',aori], stdout=outfile)
else:
   if debuglev(3,debuglevel): eprint("File exists.")

# Grep file if flaglessvals were given
if len(searchstring) > 0:
   grepstring = ""
   for word in searchstring:
      grepstring = grepstring + "|.*" + word + ".*"
   grepstring = grepstring.lstrip('|')
   regex = re.compile(grepstring)
   #subprocess.call(['grep','-iE',grepstring, thisfile])
   with open(thisfile, "r") as openfile:
      for line in openfile:
         if regex.match(line):
            print(line.rstrip())
else:
   subprocess.call(["vi",thisfile])
   pass
