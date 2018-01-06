#!/usr/bin/python3
# File: /usr/share/bgscripts/py/uvlib.py3
# Author: bgstack15@gmail.com
# Startdate: 2016-10-11 15:59
# Title: Python Library For Updating Lines in a File
# Purpose: Stores functions for updateval/modconf-style scripts
# Package: bgscripts
# History:
#    2017-11-03 testing modifications for making a different wrapper
#    2017-11-12 converted to python library
#    2018-01-05 merged in the updated manipulatevalue for modconf.py and split for different python versions
# Usage:
#   import uvlib
#   uvlib.updateval(infile='/home/bgirton/sshd_example',verbose=True,apply=False,regex='^(#?\s*#?AllowUsers.*)bgirton ?(.*)',result=r'\1\2')
# Reference:
#    original updateval.sh
#    re.sub from http://stackoverflow.com/questions/5658369/how-to-input-a-regex-in-string-replace-in-python/5658377#5658377
#    shutil.copy2 http://pythoncentral.io/how-to-copy-a-file-in-python-with-shutil/
#    keepalive (python script) from keepalive-1.0-5
#    re.escape http://stackoverflow.com/questions/17830198/convert-user-input-strings-to-raw-string-literal-to-construct-regular-expression/17830394#17830394
#    itemlist help https://stackoverflow.com/questions/32939452/converting-a-list-to-string-in-python-2-7
# Improve:
#    idea: use argparse "nargs" optional input file to use stdin piping/redirection!
#    fix action ADD where user asks to add the item that is already present and at the end of the list.
import re, shutil, os, string
import bgs, json

uvlibpyversion="2018-01-06a"

def updateval(infile,regex,result,verbose=False,apply=False,debug=0,stanza="",stanzaregex="",atbeginning=False,addline="MyUnMatchedSTR1NG"):
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
      regex_headings = re.compile( "MyUnMatchedSTR1NG" )
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
            if bgs.debuglev(2,debuglevel): bgs.eprint("Match line:", inline)
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
      if addline != 'MyUnMatchedSTR1NG':
         destinationstring=addline
   else:
      action_string="insert"
      action_line=insert_line
      if addline != 'MyUnMatchedSTR1NG':
         destinationstring=addline

   if action_string=="insert" and destinationstring=='':
      action_string="none"

   # Debug section
   if bgs.debuglev(6,debuglevel):
      bgs.eprint("match_line:",match_line)
      bgs.eprint("beginning_line:",beginning_line)
      bgs.eprint("insert_line:",insert_line)
      bgs.eprint("destinationstring:",destinationstring)
      bgs.eprint("addline:",addline)
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

#############################################################
# action=add,remove,empty,set,gone
def manipulatevalue(infile,variable,item,action,itemdelim=",",variabledelim="=",verbose=False,apply=False,comment='#',debug=0,stanza="_NONE_X",stanzaregex="_NONE_X",beginning=False,beginningline=False):

   # Validate input
   if not action in ['add','remove','gone','set',]:
      print('Requested action not fully implemented yet. Continuing...')

   if bgs.debuglev(10,debug): bgs.eprint(bgs.caller_args())
   regex='^\s*' + variable + '\s*' + variabledelim + '.*$'
   addline='addline'
   if bgs.debuglev(8,debug): bgs.eprint(json.dumps(locals(),indent=3,separators=(',',': ')))

   def readlinkf(_inpath):
      if os.path.islink(infile):
         return os.path.join(os.path.dirname(_inpath),os.readlink(_inpath))
      else:
         return _inpath

   # Define default variables
   stanza_delim=['[',']','none']

   destinationstring = '' # destinationstring is dependent on the item and action and so on

   outfile = infile + ".updateval-new"
   wasfixed = False

   # Detect if infile is symlink
   infile=readlinkf(infile)
   if bgs.debuglev(6,debug): bgs.eprint('canonical file is',infile)

   # Derive stanza delimiters
   # It might be [newstanza] or ## Heading but it'll probably just be the []
   if re.compile('\[.*\]').match(stanza):
      if bgs.debuglev(8,debug): bgs.eprint("Headings: [surrounding]")
      stanza_delim=["[","]",'surrounding'] # is default already
   elif re.compile('.*\(\)').match(stanza):
      if bgs.debuglev(8,debug): bgs.eprint("Headings: end()")
      stanza_delim=["(",")",'end']
   elif re.compile('\(.*\)').match(stanza):
      if bgs.debuglev(8,debug): bgs.eprint("Headings: (surrounding)")
      stanza_delim=["(",")",'surrounding']
   elif len(stanzaregex) > 0:
      if bgs.debuglev(8,debug): bgs.eprint("Headings: ",stanzaregex)
      stanza_delim=[stanzaregex,stanza,'regex']

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
      regex_headings = re.compile( "MyUnMatchedSTR1NG" )
   regex_ws = re.compile(re.escape(stanza))
   try:
      regex_ws_straight = re.compile(stanza)
   except:
      regex_ws_straight = re.compile(re.escape(stanza))
   regex_ss = re.compile(regex)

   # Find where to insert/replace the line
   linecount=0
   stanzacount=0
   insert_line=0
   beginning_line=0
   match_line=0
   match_line_string=''
   this_stanza=0
   for line in open(infile, "r"):
      linecount+=1
      inline=line.strip()
      if bgs.debuglev(5,debug): bgs.eprint("%s %s" % (linecount,line.rstrip()))

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
         if _takeaction == 1 and stanza != "":
            if bgs.debuglev(3,debug): bgs.eprint("Match stanza:", inline)
            this_stanza=stanzacount
            beginning_line=linecount
         else:
            if bgs.debuglev(3,debug): bgs.eprint("Found new stanza:", inline)
            if this_stanza == stanzacount - 1 and match_line == 0:
               insert_line=linecount-1

      # check if matches the main search
      if regex_ss.match(inline):
         if stanza=="" or this_stanza==stanzacount:
            if bgs.debuglev(2,debug): bgs.eprint("Match line:", inline)
            match_line=linecount
            match_line_string=line.strip('\n')

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
      #if addline != 'MyUnMatchedSTR1NG':
      #   destinationstring=addline
   else:
      action_string="insert"
      action_line=insert_line
      #if addline != 'MyUnMatchedSTR1NG':
      #   destinationstring=addline

   if bgs.debuglev(3,debug):
      bgs.eprint("action_string:",action_string)
      bgs.eprint("action:",action)

   # matrix: action_string   action        written
   #         update          add           x
   #         update          remove        x
   #         update          empty         x
   #         update          set           x
   #         update          gone          x
   #         insert          add           x
   #         insert          remove        x
   #         insert          empty         x
   #         insert          set           x
   #         insert          gone          x

   if action_string=="insert" and ( action=="set" or action=="add" ):
      destinationstring=variable + variabledelim + item

   if action_string=="insert" and ( action=="empty" ):
      destinationstring=variable + variabledelim

   if action_string=="insert" and ( action=="gone" or action=="remove" ):
      destinationstring=''
      action_string="none"

   if action_string=="insert" and destinationstring=='':
      action_string="none"

   if action_string=="update" and ( action=="set" ):
      destinationstring=re.sub(r'(\s*'+variable+'\s*'+variabledelim+'\s*).*','\\1'+item,match_line_string)

   if action_string=="update" and ( action=="empty" ):
      destinationstring=re.sub(r'(\s*'+variable+'\s*'+variabledelim+'\s*).*','\\1',match_line_string)

   if action_string=="update" and ( action=="add" or action=="remove" ):
      # split items into list, if item not in listofitems, then listofitems.additem
      itemlist=str.split(re.sub(r'\s*'+variable+'\s*'+variabledelim+'\s*(.*)','\\1',match_line_string),sep=itemdelim)
      if action=="add" and not item in itemlist:
         if not beginningline:
            itemlist.append(item)
         else:
            itemlist.insert(0,item)
      if action=="remove" and item in itemlist: itemlist.remove(item)
      itemlist_string=itemdelim.join([str(x) for x in itemlist])
      destinationstring=re.sub(r'(\s*'+variable+'\s*'+variabledelim+'\s*).*','\\1'+itemlist_string,match_line_string)

   if action_string=="update" and ( action=="gone" ):
      destinationstring=''
      action_string="remove"

   # Debug section
   if bgs.debuglev(6,debug):
      bgs.eprint("match_line:",match_line)
      bgs.eprint("beginning_line:",beginning_line)
      bgs.eprint("insert_line:",insert_line)
      bgs.eprint("destinationstring: '" + destinationstring + "'")
      bgs.eprint("addline:",addline)
   if bgs.debuglev(1,debug):
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
            elif action_string=="remove":
               # will respond to this action_string a few lines later
               pass
            else:
               print("Error! Uncertain action.")
         # output
         if not (action_string=="remove" and linecount==action_line):
            if verbose: print(outline)
            outf.write(outline+'\n')

   # replace old file with new file
   if apply:
      shutil.move(outfile,infile)

   # Clean up outfile just in case
   try:
      os.remove(outfile)
   except Exception as e:
      pass

   # weird json error
   #if bgs.debuglev(9,debug): bgs.eprint(json.dumps(locals(),indent=3,separators=(',',': ')))
