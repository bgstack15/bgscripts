#!/usr/bin/python3
# File: /usr/share/bgscripts/py/updatevalue.py
# Author: bgstack15@gmail.com
# Startdate: 2016-10-11 15:59
# Title: Python Script that Updates/Adds Value version 2.5
# Purpose: Allows idempotent and programmatic modifications to config files
# Package: bgscripts
# History:
#    2016-10-11 converted shell script into a basic python version 1
#    2017-11-03 testing modifications for making a different wrapper
#    2017-11-14a v 2.5 modified to only wrap around the uvlib python library
# Usage:
#   updateval.py /etc/rc.conf "^ntpd_enable=.*" 'ntpd_enable="YES"' --apply
# Reference:
# Improve:
#    idea: use argparse "nargs" optional input file to use stdin piping/redirection!
#    idea: be able to specify comment types
import argparse
import bgs, uvlib

updatevalversion="2017-11-14a"

# Parse parameters
parser = argparse.ArgumentParser(description="Idempotent value updater for a file",epilog="If searchstring is not found, deststring will be inserted to infile")
parser.add_argument("-d","--debug", nargs='?', default=0, type=int, choices=range(0,11), help="Set debug level.")
parser.add_argument("-v","--verbose",help="displays output",      action="store_true",default=False)
parser.add_argument("-a","--apply",  help="perform substitution", action="store_true",default=False)
parser.add_argument("infile", help="file to use")
parser.add_argument("searchstring", help="regex string to search")
parser.add_argument("deststring", help="literal string that should be there")
parser.add_argument("-V","--version", action="version", version="%(prog)s " + updatevalversion)
parser.add_argument("-s","--stanza", help="[stanza] or stanza() or custom regex",default="")
parser.add_argument("--stanzaregex", help="definition of stanza regex", default="")
parser.add_argument("-b","--beginning", help="Insert value at beginning of stanza or file if match not found.",action="store_true")
args = parser.parse_args()

# Configure variables after parameters
debuglevel=0
if args.debug is None:
   # -d was used but no value provided
   debuglevel = 10
elif args.debug:
   debuglevel = args.debug
   debuglevel = debug

verbose = args.verbose
doapply = args.apply
infile = args.infile
searchstring = args.searchstring
destinationstring = args.deststring
which_stanza=args.stanza
stanza_regex=args.stanzaregex
beginning=args.beginning

uvlib.updateval(infile,
                regex=searchstring,
                result=destinationstring,
                verbose=verbose,
                apply=doapply,
                debug=debuglevel,
                stanza=which_stanza,
                stanzaregex=stanza_regex,
                atbeginning=beginning)
