#!/usr/bin/env python3
# File: /usr/share/bgscripts/updateval.py
# Author: bgstack15@gmail.com
# Startdate: 2016-10-11 15:59
# Title: Python Script that Updates/Adds Value
# Purpose: Allows idempotent and programmatic modifications to config files
# Package: bgscripts
# History:
#    2016-07-27 wrote shell script 
#    2016-09-14 added the shell script version to bgscripts package
#    2016-10-12 added flags
#    2016-10-19 added stanza option
#    2016-10-24 adding stanza() and (stanza) types
#    2017-01-11 moved whole package to /usr/share/bgscripts
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

import re, shutil, os, argparse
updatevalversion="2017-01-11a"

# Define default variables
_stanza_delim=['[',']','surrounding']

# Parse parameters
parser = argparse.ArgumentParser(description="Idempotent value updater for a file",epilog="If searchstring is not found, deststring will be appended to infile")
parser.add_argument("-v","--verbose",help="displays output",      action="store_true",default=False)
parser.add_argument("-a","--apply",  help="perform substitution", action="store_true",default=False)
parser.add_argument("-L","--all",    help="replace all instances",action="store_true",default=False)
parser.add_argument("infile", help="file to use")
parser.add_argument("searchstring", help="regex string to search")
parser.add_argument("deststring", help="literal string that should be there")
parser.add_argument("-V","--version", action="version", version="%(prog)s " + updatevalversion)
parser.add_argument("-s","--stanza", help="only in specified [stanza] or stanza()",default="")
parser.add_argument("-b","--beginning", help="Insert value at beginning of stanza or file if match not found.",action="store_true")
args = parser.parse_args()

# Configure variables after parameters
verbose = args.verbose
doapply = args.apply
doall = args.all
infile = args.infile
searchstring = args.searchstring
destinationstring = args.deststring
stanza=args.stanza
beginning=args.beginning

wasfixed = False
outfile = infile + ".updateval-new"

# Derive stanza delimiters
# It might be [newstanza] or ## Heading but it'll probably just be the []
if re.compile('\[.*\]').match(stanza):
   _stanza_delim=["[","]",'surrounding'] # is default already
elif re.compile('.*\(\)').match(stanza):
   _stanza_delim=["(",")",'end']
elif re.compile('\(.*\)').match(stanza):
   _stanza_delim=["(",")",'surrounding']

# Make file if it does not exist
if not os.path.isfile(infile): open(infile, "w").close()

# If line exists, replace it
stanzacount=0
thisstanza=-1
shutil.copy2(infile,outfile) # initialize duplicate file with same perms
with open(outfile, "w") as outf:
   for line in open(infile, "r"):
      # set default outline
      outline = line.rstrip('\n')
      # check if new stanza
      if "surrounding" in _stanza_delim[2]:
         s = re.compile( "\\" + _stanza_delim[0] + ".*" + "\\" + _stanza_delim[1] )
      elif "end" in _stanza_delim[2]:
         s = re.compile( ".*" + "\\" + _stanza_delim[0] + "\\" + _stanza_delim[1] )
      if ( not wasfixed or doall ) and s.match( line ):
         stanzacount+=1
         #print("stanza " + str(stanzacount) + ": " + line.rstrip())
         # check if this stanza
         if re.compile( re.escape(stanza) ).match( line.strip() ):
            thisstanza=stanzacount
         # if we moved past the correct stanza but did not fix it
         if ( thisstanza == stanzacount - 1 ) and not wasfixed:
            outline = destinationstring + '\n' + outline
            wasfixed = True
      p = re.compile( searchstring )
      # if line matches the searchstring, as well as we have not fixed it yet or we are doing all changes, as well as this stanza matches or no stanza specified
      if p.match( line ) and ( not wasfixed or doall ) and ( thisstanza == stanzacount or stanza == "" ):
         outline = re.sub( searchstring, destinationstring, line).rstrip( '\n' )
         wasfixed = True

      # Output
      if verbose: print(outline)
      outf.write(outline + '\n')

# Append line if it has not been fixed yet
if not wasfixed:
   with open(outfile, "a") as outf:
      if verbose: print(destinationstring)
      outf.write(destinationstring + '\n')

# replace old file with new file
if doapply:
   shutil.move(outfile,infile)

# Clean up outfile just in case
try:
   os.remove(outfile)
except Exception as e:
   pass
