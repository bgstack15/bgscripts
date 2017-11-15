#!/usr/bin/python3
# File: /usr/share/bgscripts/py/modconf.py
# Author: bgstack15@gmail.com
# Startdate: 2017-11-06
# Title: Python Script that Updates/Adds Variables
# Purpose: Idempotently modify variables in conf files
# Package: bgscripts
# History:
#    2017-11-03 Turned updateval into a library named uvlib
# Usage:
#   modconf.py /etc/rc.conf set ntpd_enable YES
# Reference:
# Improve:
from __future__ import print_function
import argparse
import uvlib

updatevalversion="2017-11-14b"

parser = argparse.ArgumentParser()
parser.add_argument("-d","--debug", nargs='?', default=0, type=int, choices=range(0,11), help="Set debug level.")
parser.add_argument("-v","--verbose",help="displays output",      action="store_true",default=False)
parser.add_argument("-a","--apply",  help="perform substitution", action="store_true",default=False)
parser.add_argument("-V","--version", action="version", version="%(prog)s " + updatevalversion)
parser.add_argument("infile", default="", help="file to use")
parser.add_argument("action", default="", help='[ add | remove | set | gone | empty ]')
parser.add_argument("variable", default="")
parser.add_argument("item", default="")
parser.add_argument("-i","--itemdelim", default=",", help="default = \",\"")
parser.add_argument("-l","--variabledelim", default="=", help="default = \"=\"")
parser.add_argument("-c","--comment", default="#", help="Comment character, default = \"#\"")
args = parser.parse_args()

# Configure variables after parameters
debuglevel=0
if args.debug is None:
   # -d was used but no value provided
   debuglevel = 10
elif args.debug:
   debuglevel = args.debug

uvlib.manipulatevalue(infile=args.infile,
                      verbose=args.verbose,
                      variable=args.variable,
                      item=args.item,
                      action=args.action,
                      itemdelim=args.itemdelim,
                      variabledelim=args.variabledelim,
                      comment=args.comment,
                      debug=debuglevel,
                      apply=args.apply)
