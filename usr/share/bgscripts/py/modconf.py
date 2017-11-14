#!/usr/bin/python3
# File: /usr/share/bgscripts/py/modconf.py
# Author: bgstack15@gmail.com
# Startdate: 2017-11-06
# Title: Python Script that Updates/Adds Value version 2
#    WORKHERE: make manipulatevalue() in the uvlib, and make modconf a wrapper.
# Purpose: Idempotently modify variables in conf files
# Package: bgscripts
# History:
#    2017-11-03 Turned updateval into a library named uvlib
# Usage:
#   modconf.py /etc/rc.conf "^ntpd_enable=.*" 'ntpd_enable="YES"' --apply
# Reference:
#    /usr/share/bgscripts/updateval.sh
#    https://stackoverflow.com/questions/29935276/inspect-getargvalues-throws-exception-attributeerror-tuple-object-has-no-a#29935277
# Improve:
#    

import re, shutil, os, argparse, sys
import inspect, json
from uvlib import updateval
updatevalversion="2017-11-13a"

def caller_args():
   frame = inspect.currentframe()
   outer_frames = inspect.getouterframes(frame)
   caller_frame = outer_frames[1][0]
   return inspect.getargvalues(caller_frame)

parser = argparse.ArgumentParser()
parser.add_argument("infile", default="")
parser.add_argument("action", default="")
parser.add_argument("variable", default="")
parser.add_argument("item", default="")
parser.add_argument("-d","--itemdelim", default=",")
parser.add_argument("-v","--variabledelim", default="=")
parser.add_argument("-c","--comment", default="#")
args = parser.parse_args()

if args.item:
   infile=args.infile
   action=args.action
   variable=args.variable
   item=args.item

# action=add,remove,empty,set,gone
def manipulatevalue(infile,variable,item,action,itemdelim=",",variabledelim="=",verbose=False,apply=False,comment='#'):
   #print caller_args()
   regex=''
   result=''
   if action == "remove":
      # this one very well
      regex='^(?:(?:(\s*' + variable + '\s*' + variabledelim + '.*?)(' + itemdelim + item + '\b|' + item + itemdelim +'|' + itemdelim + item + '\s*$))|(?:(' + variable + '\s*' + variabledelim + '\s*)' + item + '\s*$))((.*?)|\s*$)'
      result=r'\g<1>\g<4>\g<3>'
   elif action == "add":
      regex='^(\s*' + variable + '\s*' + variabledelim + '\s*)(?!.*' + item + '(' + itemdelim + '|\b|$))(.*?)$'
      result=r'\g<1>' + item + itemdelim + r'\g<3>'
   elif action == "empty":
      regex='^(\s*' + variable + '\s*' + variabledelim + '\s*).*$'
      result=r'\g<1>'
   elif action == "set":
      regex='^(\s*' + variable + '\s*' + variabledelim + '\s*).*$'
      result=r'\g<1>' + item
   elif action == "gone" or action == "comment":
      regex='^(\s*' + variable + '\s*' + variabledelim + '\s*.*)$'
      result=comment + r'\g<1>'

   print(json.dumps(locals(),indent=3,separators=(',',': ')))

   updateval(infile=infile,verbose=verbose,apply=apply,regex=regex,result=result,modifyonly=True)

manipulatevalue(infile=infile,verbose=True,variable=variable,item=item,action=action,itemdelim=args.itemdelim,variabledelim=args.variabledelim,comment=args.comment)