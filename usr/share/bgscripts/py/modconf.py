#!/usr/bin/python2
# File: /usr/share/bgscripts/py/modconf.py
# Author: bgstack15@gmail.com
# Startdate: 2017-11-06
# Title: Python Script that Updates/Adds Variables
# Purpose: Idempotently modify variables in conf files
# Package: bgscripts
# History:
#    2017-11-03 Turned updateval into a library named uvlib
#    2017-12-04 attemping a rewrite to work more thoroughly
# Usage:
#    modconf.py -v /etc/rc.conf set ntpd_enable YES
# Reference:
#    import lib regardless of py2 and py3 status https://stackoverflow.com/questions/67631/how-to-import-a-module-givne-the-full-path#67692
# Improve:
from __future__ import print_function
import argparse, sys

from uvlib import manipulatevalue
# If I end up needing the separate uvlib.py2 or uvlib.py3 files
#uvlib_file="/usr/share/bgscripts/py/uvlib.py" + str(sys.version_info[0])
#print(uvlib_file)
#with open(uvlib_file) as f:
#   code=compile(f.read(),uvlib_file, 'exec')
#   exec(code, globals(), locals())

updatevalversion="2018-01-06a"

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
parser.add_argument("-s","--stanza", help="[stanza] or stanza() or custom regex",default="")
parser.add_argument("--stanzaregex", help="definition of stanza regex", default="")
parser.add_argument("-b","--beginning", help="Insert variable at beginning of stanza or file if match to add is not found.",action="store_true")
parser.add_argument("-B","--beginningline", help="Insert item at beginning of line if match to add is not found.",action="store_true")
args = parser.parse_args()

# Configure variables after parameters
debuglevel=0
if args.debug is None:
   # -d was used but no value provided
   debuglevel = 10
elif args.debug:
   debuglevel = args.debug

manipulatevalue(infile=args.infile,
                      verbose=args.verbose,
                      variable=args.variable,
                      item=args.item,
                      action=args.action,
                      itemdelim=args.itemdelim,
                      variabledelim=args.variabledelim,
                      comment=args.comment,
                      debug=debuglevel,
                      stanza=args.stanza,
                      stanzaregex=args.stanzaregex,
                      beginning=args.beginning,
                      beginningline=args.beginningline,
                      apply=args.apply)
