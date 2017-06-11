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
#    2017-06-10 rewriting everything for it
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
updatevalversion="2017-01-11a"

def debuglev(_numbertocheck):
   # if _numbertocheck <= debuglevel then return truthy
   _debuglev = False
   try:
      if int(_numbertocheck) <= int(debuglevel):
         _debuglev = True
   except Exception as e:
      pass
   return _debuglev

# Define default variables
stanza_delim=['[',']','surrounding']

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

wasfixed = False
outfile = infile + ".updateval-new"

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
   s = re.compile("\\"+stanza_delim[0]+".*"+"\\"+stanza_delim[1])
elif "end" in stanza_delim[2]:
   s = re.compile( ".*" + "\\" + stanza_delim[0] + "\\" + stanza_delim[1] )
elif "regex" in stanza_delim[2]:
   s = re.compile( stanza_delim[0] )
regex_ws = re.compile(re.escape(which_stanza))
regex_ws_straight = re.compile(which_stanza)
regex_ss = re.compile(searchstring)

# Find where to insert/replace the line
stanzacount=0
linecount=0
thisstanza=-1
beginning_line=0
insert_line=0
match_line=0
wouldfix=0
for line in open(infile, "r"):
   linecount+=1
   inline=line.strip()
   if debuglev(6): print("%s %s" % (linecount,inline))
   # detect if is a new stanza
   if s.match(inline):
      if debuglev(6): print("Heading","\"" + inline + "\"")
      stanzacount+=1
      if wouldfix == 0 and thisstanza >= 0 and thisstanza < stanzacount:
         insert_line=linecount-1
         if beginning == True: insert_line=beginning_line
      # detect if correct stanza
      if regex_ws.match(inline) or regex_ws_straight.match(inline):
         thisstanza=stanzacount
         beginning_line=linecount
         if debuglev(2): print("Matching stanza, line %s: \"%s\"" % (beginning_line, inline))
      wouldfix=0
   # detect if this line matches and is in the correct stanza
   if regex_ss.match(inline):
      if thisstanza == stanzacount or which_stanza == '':
         match_line=linecount
         if debuglev(2): print("Matching line %s: \"%s\"" % (match_line, inline))
         wouldfix=1

if insert_line==0 and match_line==0 and beginning==False: insert_line=linecount

action="insert after"
_displaynum=insert_line
if match_line > 0:
   action="modify"
   _displaynum=match_line

# debug section
if debuglev(1):
   print("Think we should %s line %s" % (action,_displaynum))

sys.exit(0)

#if stanza_delim[0] == stanzadef and stanza_delim[1] == "":
#   thisstanza=0
#shutil.copy2(infile,outfile) # initialize duplicate file with same perms
#with open(outfile, "w") as outf:
#   for line in open(infile, "r"):
#      # set default outline
#      outline = line.rstrip('\n')
#      # check if new stanza
#      if "surrounding" in stanza_delim[2]:
#         s = re.compile( "\\" + stanza_delim[0] + ".*" + "\\" + stanza_delim[1] )
#      elif "end" in stanza_delim[2]:
#         s = re.compile( ".*" + "\\" + stanza_delim[0] + "\\" + stanza_delim[1] )
#      elif "regex" in stanza_delim[2]:
#         s = re.compile( stanza_delim[0] )
#      if ( not wasfixed or doall ) and s.match( line ):
#         stanzacount+=1
#         #print("stanza " + str(stanzacount) + ": " + line.rstrip())
#         # check if this stanza
#         #if re.compile( re.escape(stanza) ).match( line.strip() ):
#         if re.compile( re.escape(stanza) ).match( line.strip() ) or ( stanza_delim[2] == 'regex' and re.compile(stanza).match(line.strip()) ):
#            thisstanza=stanzacount
#         # if we moved past the correct stanza but did not fix it
#         if ( thisstanza == stanzacount - 1 ) and not wasfixed:
#            outline = destinationstring + '\n' + outline
#            wasfixed = True
#      p = re.compile( searchstring )
#      # if line matches the searchstring, as well as we have not fixed it yet or we are doing all changes, as well as this stanza matches or no stanza specified
#      if p.match( line ) and ( not wasfixed or doall ) and ( thisstanza == stanzacount or stanza == "" ):
#         outline = re.sub( searchstring, destinationstring, line).rstrip( '\n' )
#         wasfixed = True

      # Output
#      if verbose: print(outline)
#      outf.write(outline + '\n')

# Append line if it has not been fixed yet
#if not wasfixed:
#   with open(outfile, "a") as outf:
#      if verbose: print(destinationstring)
#      outf.write(destinationstring + '\n')

# replace old file with new file
#if doapply:
#   shutil.move(outfile,infile)

# Clean up outfile just in case
try:
   os.remove(outfile)
except Exception as e:
   pass
