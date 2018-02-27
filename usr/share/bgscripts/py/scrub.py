#!/usr/bin/env python2
# Filename: scrub.py
# Location: /usr/share/bgscripts/py/
# Author: bgstack15@gmail.com
# Startdate: 2016-09-28
# Title: Script that Simultaneously Copies and Scrubs a Directory
# Purpose: Prepare projects for publication by removing private information like usernames and hostnames
# Package: Various
# History:
#    2016-10-03 working on batch rename files
#    2016-10-20 added not ".tgz" in source.name
#    2016-10-27 Fixed error when trying chmod on a symlink
#    2016-10-31 Handle symlinks by duplicating the link and stopping there.
#               Also separated directory, filename renaming tasks
#    2016-11-16 added to bgscripts package
#               Also changed conf file directives
#    2016-11-30 added debuglev
#    2017-01-11 moved whole package to /usr/share/bgscripts
# Usage:
#    Store this file with any package that gets published. Adjust scrub.txt in local directory.
#  # First line: source directory      Second line: target directory. WILL BE OVERWRITTEN!
#  /etc/ansible
#  /home/bjones/ansible.clean
#  # Rest of the lines are "OLD WORD" "NEW WORD"
#  bjones bgstack15
#  rsmith rmstack15
# Reference:
#    http://stackoverflow.com/questions/79968/split-a-string-by-spaces-preserving-quoted-substrings-in-python/524796#524796
#    http://stackoverflow.com/questions/6706953/python-using-subprocess-to-call-sed#6707003
#    http://stackoverflow.com/questions/6584871/remove-last-character-if-its-a-backslash/6584893#6584893
#    http://stackoverflow.com/questions/2212643/python-recursive-folder-read/2212728#2212728
#    parallel lists: http://stackoverflow.com/questions/1663807/how-can-i-iterate-through-two-lists-in-parallel-in-python
#    file renames http://stackoverflow.com/questions/225735/batch-renaming-of-files-in-a-directory/7917798#7917798
# Improve:
#    Add option to specify scrub file
#    Add exclude option to scrub file, such as .git and so on
#    Accept CLI options like source, destination, even exclusions?
#    Add flag for performing file renames as well, or file renames only
import re, shlex, os, sys, shutil, argparse
from pathlib import Path

# scrubpy version
scrubpyversion = "2017-01-11a"

# Define functions

def removeComments(string):
   #string = re.sub(re.compile("/\*.*?\*/",re.DOTALL ) ,"", string)
   #string = re.sub(re.compile("//.*?\n" ) ,"" ,string)
   pattern = r"(\".*?\"|\'.*?\')|(/\*.*?\*/|(//|#)[^\r\n]*$)"
   regex = re.compile(pattern, re.MULTILINE|re.DOTALL)
   def _replacer(match):
      if match.group(2) is not None:
         return ""
      else:
         return match.group(1)
   return regex.sub(_replacer, string)

def isValidFile(_thisstring):
   # return true if not in the list specified in scrub.txt
   # ignoredtypes
   _isValidFile=True
   _searchstring=""
   for _word in ignoredtypes:
      _searchstring = _searchstring + _word + "|"
   _searchstring = ".*\.(" + _searchstring.rstrip('|') + ")"
   #print(_searchstring)
   #if re.compile('.*\.(tgz|png|gif|jpg|pyc|pyo|git|swp|ico)').match(_thisstring):
   if re.compile(_searchstring).match(_thisstring):
      _isValidFile=False
   #print( _thisstring + ": " + str(_isValidFile) )
   return _isValidFile

def debuglev(_numbertocheck):
   # if _numbertocheck <= debuglevel then return truthy
   _debuglev = False
   try:
      if int(_numbertocheck) <= int(debuglevel):
         _debuglev = True
   except Exception as e:
      pass
   return _debuglev

# Parse parameters
parser = argparse.ArgumentParser(description="Prepare projects for publication by removing private information like usernames and hostnames")
parser.add_argument("-d","--debug", nargs='?', default=0, type=int, choices=range(0,11), help="Set debug level.")
parser.add_argument("-V","--version", action="version", version="%(prog)s " + scrubpyversion)
args = parser.parse_args()

debuglevel=0

if args.debug is None:
   # -d was used but no value provided
   debuglevel = 10
elif args.debug:
   debuglevel = args.debug

# Main code
stringfile = open('scrub.txt','r')
count=0
thisdir=""
newdir=""
oldstrings=[]
newstrings=[]
ignoredtypes=[]

while True:
   x = stringfile.readline().rstrip()
   if not x:
      count += 1
   if count >= 100: break
   x = removeComments(x)
   #print("x=" + x)
   y = shlex.split (x)
   if len(y) >= 1:
      if thisdir == "":
         thisdir = y[0]
      elif newdir == "":
         newdir = y[0]
   if len(y) >= 2: 
      #print("y[0]=" + y[0] + "\t and y[1]=" + y[1])
      if "source" in y[0].lower():
         thisdir = y[1]
      elif "target" in y[0].lower():
         newdir = y[1]
      elif "ignore" in y[0].lower():
         ignoredtypes = y[1].split()
      else:
         oldstrings.append(y[0])
         newstrings.append(y[1])

# After the file is done
stringfile.close()
#newdir = thisdir.rstrip('\/') + ".scrubbed/"

if False:
   print("\nthisdir=" + thisdir)
   print("newdir=" + newdir + '\n')
   print("oldstrings are:")
   print(oldstrings)
   print("newstrings are:")
   print(newstrings)
   print("Ignored filetypes are:")
   print(ignoredtypes)

# Clean scrubbed directory
try:
   shutil.rmtree(newdir)
except:
   pass

shutil.copytree(thisdir,newdir,symlinks=True)

# Execute substitutions
for rootfolder, subdirs, files in os.walk(thisdir):
   for filename in files:
      sourcepath = os.path.join(rootfolder, filename)
      destdir = rootfolder.replace(thisdir.rstrip('\/'),newdir.rstrip('\/'))
      destfile = os.path.join(destdir, filename)
      if os.path.islink( sourcepath ):
         _symlinktarget = os.readlink( sourcepath )
         try:
            os.symlink( _symlinktarget, destfile )
         except Exception as e:
            pass
      else:
         with open( sourcepath, "r" ) as source:
            if isValidFile( source.name ):
               if debuglev(5): print("sourcefile=" + source.name)
               if debuglev(8): print("destfile=" + destfile + '\n')
               with open( destfile, "w") as target:
                  data = source.read()
                  for oldword, newword in zip(oldstrings, newstrings):
                     data = data.replace(oldword,newword)
                  changed = data
                  target.write(changed)

# Execute directory renames
for rootfolder, subdirs, files in os.walk(newdir):
   for subdir in subdirs:
      oldpath = os.path.join(rootfolder, subdir)
      for oldword, newword in zip(oldstrings, newstrings):
         if oldword in oldpath:
            os.rename(oldpath, oldpath.replace(oldword,newword))

# Execute file renames
# Used "file renames" reference, as well as the structure of directory traversal used earlier, which was from a different source.
for rootfolder, subdirs, files in os.walk(newdir):
   for filename in files:
      oldpath = os.path.join(rootfolder, filename)
      for oldword, newword in zip(oldstrings, newstrings):
         if oldword in oldpath:
            if debuglev(7): print("oldword=" + oldword + "\toldpath=" + oldpath)
            os.rename(oldpath, oldpath.replace(oldword,newword))
