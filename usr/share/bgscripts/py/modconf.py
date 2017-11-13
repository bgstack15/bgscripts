#!/usr/bin/python3
# File: /usr/share/bgscripts/updateval2.py
# Author: bgstack15@gmail.com
# Startdate: 2016-10-11 15:59
# Title: Python Script that Updates/Adds Value version 2
#    WORKHERE: make manipulatevalue() in the uvlib, and make modconf a wrapper.
# Purpose: Allows idempotent and programmatic modifications to config files
# Package: bgscripts
# History:
#    2016-07-27 wrote shell script
#    2016-09-14 added the shell script version to bgscripts package
#    2016-10-12 added flags
#    2016-10-19 added stanza option
#    2016-10-24 adding stanza() and (stanza) types
#    2017-01-11 moved whole package to /usr/share/bgscripts
#    2017-06-12 rewrote whole detection and update sections
#    2017-08-22 updated: if infile is symlink, set infile to link destination
#    2017-11-03 Turned updateval into a library named uvlib
# Usage:
#   updateval.py /etc/rc.conf "^ntpd_enable=.*" 'ntpd_enable="YES"' --apply
# Reference:
#    /usr/share/bgscripts/updateval.sh
#    re.sub from http://stackoverflow.com/questions/5658369/how-to-input-a-regex-in-string-replace-in-python/5658377#5658377
#    shutil.copy2 http://pythoncentral.io/how-to-copy-a-file-in-python-with-shutil/
#    keepalive (python script) from keepalive-1.0-5
#    re.escape http://stackoverflow.com/questions/17830198/convert-user-input-strings-to-raw-string-literal-to-construct-regular-expression/17830394#17830394
#    https://stackoverflow.com/questions/29935276/inspect-getargvalues-throws-exception-attributeerror-tuple-object-has-no-a#29935277
# Improve:
#    idea: use argparse "nargs" optional input file to use stdin piping/redirection!
#    idea: be able to specify comment types

import re, shutil, os, argparse, sys
import inspect, json
from uvlib import updateval
updatevalversion="2017-11-03a"

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
args = parser.parse_args()

if args.item:
   infile=args.infile
   action=args.action
   variable=args.variable
   item=args.item

# action=add,remove,empty,set,gone
def manipulatevalue(infile,variable,item,action,itemdelim=",",variabledelim="=",verbose=False,apply=False):
   #print caller_args()
   regex=''
   result=''
   if action == "remove":
      # this one works almost perfectly. Just need to investigate when variable = equals, has, space
      regex='^(\s*' + variable + '\s*' + variabledelim + '.*?)(' + itemdelim + item + '\b|' + item + itemdelim +'|' + item + '\s*$)((.*?)|\s*$)'
      result=r'\1\4'
   elif action == "add":
      regex='^(\s*' + variable + '\s*' + variabledelim + '\s*)(?!.*' + item + '(' + itemdelim + '|\b|$))(.*?)$'
      result=r'\1' + item + itemdelim + r'\3'
   elif action == "empty":
      regex='^(\s*' + variable + '\s*' + variabledelim + '\s*).*$'
      result=r'\1'
   elif action == "set":
      #WORKHERE was halfway through typing this
      regex='^(\s*' + variable + '\s*' + variabledelim + '\s*)'

   print(json.dumps(locals(),indent=3,separators=(',',': ')))

   updateval(infile=infile,verbose=verbose,apply=apply,regex=regex,result=result,modifyonly=True)

manipulatevalue(infile=infile,verbose=True,variable=variable,item=item,action=action,itemdelim=args.itemdelim,variabledelim=args.variabledelim)
