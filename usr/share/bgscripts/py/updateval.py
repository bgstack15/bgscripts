#!/usr/bin/python3
# File: /usr/share/bgscripts/updateval2.py
# Author: bgstack15@gmail.com
# Startdate: 2016-10-11 15:59
# Title: Python Script that Updates/Adds Value version 2
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
# Usage:
#   updateval.py /etc/rc.conf "^ntpd_enable=.*" 'ntpd_enable="YES"' --apply
# Reference:
#    /usr/share/bgscripts/updateval.sh
#    re.sub from http://stackoverflow.com/questions/5658369/how-to-input-a-regex-in-string-replace-in-python/5658377#5658377
#    shutil.copy2 http://pythoncentral.io/how-to-copy-a-file-in-python-with-shutil/
#    keepalive (python script) from keepalive-1.0-5
#    re.escape http://stackoverflow.com/questions/17830198/convert-user-input-strings-to-raw-string-literal-to-construct-regular-expression/17830394#17830394
# Improve:
#    idea: use argparse "nargs" optional input file to use stdin piping/redirection!
#    idea: be able to specify comment types

import re, shutil, os, argparse, sys
updatevalversion="2017-08-22a"

def debuglev(_numbertocheck):
   # if _numbertocheck <= debuglevel then return truthy
   _debuglev = False
   try:
      if int(_numbertocheck) <= int(debuglevel):
         _debuglev = True
   except Exception as e:
      pass
   return _debuglev

def readlinkf(_inpath):
   if os.path.islink(infile):
      return os.path.join(os.path.dirname(_inpath),os.readlink(_inpath))
   else:
      return _inpath

# Define default variables
stanza_delim=['[',']','none']

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

verbose = args.verbose
doapply = args.apply
infile = args.infile
searchstring = args.searchstring
destinationstring = args.deststring
which_stanza=args.stanza
stanza_regex=args.stanzaregex
beginning=args.beginning

outfile = infile + ".updateval-new"
wasfixed = False

# Detect if infile is symlink
infile=readlinkf(infile)
if debuglev(6): print('canonical file is',infile)

# Derive stanza delimiters
# It might be [newstanza] or ## Heading but it'll probably just be the []
if re.compile('\[.*\]').match(which_stanza):
   if debuglev(8): print("Headings: [surrounding]")
   stanza_delim=["[","]",'surrounding'] # is default already
elif re.compile('.*\(\)').match(which_stanza):
   if debuglev(8): print("Headings: end()")
   stanza_delim=["(",")",'end']
elif re.compile('\(.*\)').match(which_stanza):
   if debuglev(8): print("Headings: (surrounding)")
   stanza_delim=["(",")",'surrounding']
elif len(stanza_regex) > 0:
   if debuglev(8): print("Headings: ",stanza_regex)
   stanza_delim=[stanza_regex,which_stanza,'regex']

# Make file if it does not exist
if not os.path.isfile(infile): open(infile, "w").close()

# prepare regex
if "surrounding" in stanza_delim[2]:
   regex_headings = re.compile("\\"+stanza_delim[0]+".*"+"\\"+stanza_delim[1])
elif "end" in stanza_delim[2]:
   regex_headings = re.compile( ".*" + "\\" + stanza_delim[0] + "\\" + stanza_delim[1] )
elif "regex" in stanza_delim[2]:
   regex_headings = re.compile( stanza_delim[0] )
else:
   regex_headings = re.compile( "WGLIWJLGJSDKFJLWJIEGLJWLJlwgi28P" )
regex_ws = re.compile(re.escape(which_stanza))
try:
   regex_ws_straight = re.compile(which_stanza)
except:
   regex_ws_straight = re.compile(re.escape(which_stanza))
regex_ss = re.compile(searchstring)

# Find where to insert/replace the line
linecount=0
stanzacount=0
insert_line=0
beginning_line=0
match_line=0
this_stanza=0
for line in open(infile, "r"):
   linecount+=1
   inline=line.strip()
   if debuglev(5): print("%s %s" % (linecount,line.rstrip()))

   # check if a new zone
   if regex_headings.match(inline):
      stanzacount+=1
      _takeaction=0
      try:
         if regex_ws_straight.match(inline):
            _takeaction=1
      except:
         pass
      if regex_ws.match(inline):
         _takeaction=1
      if _takeaction == 1 and which_stanza != "":
         if debuglev(3): print("Match stanza:", inline)
         this_stanza=stanzacount
         beginning_line=linecount
      else:
         if debuglev(3): print("Found new stanza:", inline)
         if this_stanza == stanzacount - 1 and match_line == 0:
            insert_line=linecount-1

   # check if matches the main search
   if regex_ss.match(inline):
      if which_stanza=="" or this_stanza==stanzacount:
         if debuglev(2): print("Match line:", inline)
         match_line=linecount

# Be ready to add to end of file
stanzacount+=1
if this_stanza == stanzacount -1 and match_line == 0:
   insert_line=linecount

# Prepare which action
action_string=""
action_line=0
if match_line > 0:
   action_string="update"
   action_line=match_line
elif beginning:
   action_string="insert"
   action_line=beginning_line
else:
   action_string="insert"
   action_line=insert_line

# Debug section
if debuglev(6):
   print("match_line:",match_line)
   print("beginning_line:",beginning_line)
   print("insert_line:",insert_line)
if debuglev(1):
   print("Action %s at line: %s" % (action_string,action_line))

# Update file
linecount=0
have_fixed=0
regex_blank_line=re.compile('^\s*$')
with open(outfile, "w") as outf:
   # if first line
   if action_line == 0 and action_string == "insert":
      if verbose: print(destinationstring)
      outf.write(destinationstring+'\n')
      have_fixed=1
   # go through file
   for line in open(infile, "r"):
      linecount+=1
      outline=line.rstrip('\n')
      if have_fixed != 1 and linecount == action_line:
         if action_string=="update":
            outline=re.sub(regex_ss,destinationstring,outline)
            have_fixed=1
         elif action_string=="insert":
            if regex_blank_line.match(outline):
               outline=destinationstring+'\n'+outline
            else:
               outline=outline+'\n'+destinationstring
            have_fixed=1
         else:
            print("Error! Uncertain action.")
      # output
      if verbose: print(outline)
      outf.write(outline+'\n')

# replace old file with new file
if doapply:
   shutil.move(outfile,infile)

# Clean up outfile just in case
try:
   os.remove(outfile)
except Exception as e:
   pass
