#!/usr/bin/python3
# File: /usr/share/bgscripts/lib/updatevalue.py
# Author: bgstack15@gmail.com
# Startdate: 2016-10-11 15:59
# Title: Python Library For Updating Lines in a File
# Purpose: Allows idempotent and programmatic modifications to config files
# Package: bgscripts
# History:
#    2017-11-03 testing modifications for making a different wrapper
#    2017-11-12 converted to python library
# Usage:
#   import uvlib
#   uvlib.updateval(infile='/home/bgirton/sshd_example',verbose=True,apply=False,regex='^(#?\s*#?AllowUsers.*)bgirton ?(.*)',result=r'\1\2')
# Reference:
#    original updateval.sh
#    re.sub from http://stackoverflow.com/questions/5658369/how-to-input-a-regex-in-string-replace-in-python/5658377#5658377
#    shutil.copy2 http://pythoncentral.io/how-to-copy-a-file-in-python-with-shutil/
#    keepalive (python script) from keepalive-1.0-5
#    re.escape http://stackoverflow.com/questions/17830198/convert-user-input-strings-to-raw-string-literal-to-construct-regular-expression/17830394#17830394
#    https://stackoverflow.com/questions/29935276/inspect-getargvalues-throws-exception-attributeerror-tuple-object-has-no-a#29935277
# Improve:
#    idea: use argparse "nargs" optional input file to use stdin piping/redirection!
#    idea: be able to specify comment types

import re, shutil, os, argparse, sys
import bgs

uvlibpyversion="2017-11-12a"

def updateval(infile,regex,result,verbose=False,apply=False,debug=0,stanza="",stanzaregex="",atbeginning=False,modifyonly=False):
   def readlinkf(_inpath):
      if os.path.islink(infile):
         return os.path.join(os.path.dirname(_inpath),os.readlink(_inpath))
      else:
         return _inpath

   # Define default variables
   stanza_delim=['[',']','none']

   debuglevel = debug
   doapply = apply
   searchstring = regex
   destinationstring = result
   which_stanza = stanza
   stanza_regex = stanzaregex
   beginning = atbeginning

   outfile = infile + ".updateval-new"
   wasfixed = False

   # Detect if infile is symlink
   infile=readlinkf(infile)
   if bgs.debuglev(6,debuglevel): bgs.eprint('canonical file is',infile)

   # Derive stanza delimiters
   # It might be [newstanza] or ## Heading but it'll probably just be the []
   if re.compile('\[.*\]').match(which_stanza):
      if bgs.debuglev(8,debuglevel): bgs.eprint("Headings: [surrounding]")
      stanza_delim=["[","]",'surrounding'] # is default already
   elif re.compile('.*\(\)').match(which_stanza):
      if bgs.debuglev(8,debuglevel): bgs.eprint("Headings: end()")
      stanza_delim=["(",")",'end']
   elif re.compile('\(.*\)').match(which_stanza):
      if bgs.debuglev(8,debuglevel): bgs.eprint("Headings: (surrounding)")
      stanza_delim=["(",")",'surrounding']
   elif len(stanza_regex) > 0:
      if bgs.debuglev(8,debuglevel): bgs.eprint("Headings: ",stanza_regex)
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
      if bgs.debuglev(5,debuglevel): bgs.eprint("%s %s" % (linecount,line.rstrip()))

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
            if bgs.debuglev(3,debuglevel): bgs.eprint("Match stanza:", inline)
            this_stanza=stanzacount
            beginning_line=linecount
         else:
            if bgs.debuglev(3,debuglevel): bgs.eprint("Found new stanza:", inline)
            if this_stanza == stanzacount - 1 and match_line == 0:
               insert_line=linecount-1

      # check if matches the main search
      if regex_ss.match(inline):
         if which_stanza=="" or this_stanza==stanzacount:
            if bgs.debuglev(2,debuglevel): bgs.print("Match line:", inline)
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

   if action_string=="insert" and modifyonly:
      action_string="none"

   # Debug section
   if bgs.debuglev(6,debuglevel):
      bgs.eprint("match_line:",match_line)
      bgs.eprint("beginning_line:",beginning_line)
      bgs.eprint("insert_line:",insert_line)
   if bgs.debuglev(1,debuglevel):
      bgs.eprint("Action %s at line: %s" % (action_string,action_line))

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
            elif action_string=="none":
               pass
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
