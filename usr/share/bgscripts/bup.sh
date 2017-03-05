#!/bin/sh
# File: /usr/share/bgscripts/bup.sh
# Author: bgstack15@gmail.com
# Startdate: 2014-06-16
# Title: Script that Automatically Bups Files (v2)
# Purpose: To make datestamped bup copies
# Package: bgscripts
# History: 2015-11-23 adjusted for bgscripts.rpm
#    2016-08-03 converted to /bin/sh for portability
#    2017-01-11 moved whole package to /usr/share/bgscripts
# Usage: 
# Reference: 
# Improve:
fiversion="2017-01-11a"

# DEFINE FUNCTIONS
usage() {
   more >&2 <<ENDUSAGE
usage: bup.sh [-udp] [<infile1> <infile2> <infile3> ...] [<outdir>]
 -u usage    Show this usage block.
 -d debug    Show parameters while being parsed. Prevents actual operation.
 -p pwd      For all files, bup each file to PWD. Ignored if <outdir> is specified.
 infile1     Required. This is a file to bup.
Notes:
 If the last object name passed is a directory, it will be used to store each
bupfile. Otherwise, the script will bup each file to its own location.
Return values:
0 normal
1 help screen displayed
2 infile not specified
4 cannot find dependency
ENDUSAGE
}

copyfile() {
   #$1 = original file (thisfile)
   #$2 = backup file
   debuglev 1 && echo cp -p $1 $2 || cp -p $1 $2
}

bup_file() {
   #call: bup_file $filenametobup
   #$1 = oldfile

   # CALCULATE OUTDIR/NEWFILE
   thisbupfile=$1
   thisshortfile=$(basename "$thisbupfile")
   thisdir=$(dirname "$thisbupfile")
   if test -d "$masteroutdir";
   then
      # use masteroutdir since it exists
      newfile="$masteroutdir"/$thisshortfile.$today
   else
      # check if absolute path was used
      if test "$thisshortfile" = "$thisbupfile";
      then
         #relative filename used
         newfile=$thisdir/$thisshortfile.$today
      else
         #absolute pathname used
         newfile=$thisbupfile.$today
      fi
   fi

   # CALCULATE FIRST AVAILABLE NUMBER SUFFIX (i.e. 2014-06-16.01)
   bupcounter=1
   for bupcounter in $( count 1 1 20 | xargs printf "%02g\n" );
   do
      padnum=$bupcounter
      if [ ! -f "$newfile.$padnum" ];
      then
         newfile=$newfile.$padnum
         break
      fi
   done
   
   newfile=$( echo "$newfile" | sed 's!\/\/!\/!g;' )
   copyfile $thisbupfile $newfile
}

count() {
   #call: for number in $( count 1 1 20 )
   countr="$1"; counts="$2"; countt="$3"
   countcounter=$countr
   while test $countcounter -le $countt;
   do
      printf "$countcounter\n"
      countcounter=$( expr ${countcounter} + ${counts} )
   done
}

parseFlag() {
   flag=$1
   hasval=0
   case $flag in
      # INSERT FLAGS HERE
      "d" ) debug=1;;
      "debug" | "DEBUG" | "dd" ) setdebug; ferror "debug level ${debug}";;
      "u" | "usage" | "help") usage; exit 1;;
      #"i" | "infile" | "inputfile") getval;infile1=$tempval;;
      "p" | "pwd") masteroutdir=$(pwd);;
   esac
   
   debuglev 10 && { test $hasval -eq 1 && ferror "flag: $flag = $tempval" || ferror "flag: $flag"; }
}

# DETERMINE LOCATION OF FRAMEWORK
while read flocation; do if test -x ${flocation} && test "$( $flocation --fcheck )" -ge 20170111; then frameworkscript=$flocation; break; fi; done <<EOFLOCATIONS
./framework.sh
/usr/share/bgscripts/framework.sh
EOFLOCATIONS
test -z "$frameworkscript" && echo "$0: framework not found. Aborted." 1>&2 && exit 4

# INITIALIZE VARIABLES
# variables set in framework:
# today server thistty scriptdir scriptfile
# is_cronjob stdin_piped stdout_piped stderr_piped
. $frameworkscript
infile1=
outfile1=
logfile=
currentdir=$(pwd)

# VALIDATE PARAMETERS
# objects before the dash are options, which get filled with the optvals
# to debug flags, use option DEBUG
validateparams - "$@"

# CONFIRM TOTAL NUMBER OF FLAGLESSVALS IS CORRECT
if test $thiscount -lt 1;
then
   ferror "$scriptfile: 2. No file specified."
   exit 2
fi

# CONFIGURE VARIABLES AFTER PARAMETERS
numfiles=$thiscount
eval lastfile=\${opt$numfiles}

# MAIN LOOP

# DETERMINE IF LASTFILE IS DIR
if test -d $lastfile;
then
   # it's a directory. Overwrite -p flag (if set).
   masteroutdir="$lastfile"
   numfiles=$( expr ${numfiles} - 1 )
fi

#echo "masteroutdir=\"$masteroutdir\""

# LOOP THROUGH FILES
x=0
while test $x -lt $numfiles;
do
   x=$( expr ${x} + 1 )
   eval thisfile=\$opt$x
   #echo "file $x:\"$thisfile\""
   # CONFIRM FILE EXISTS
   if test ! -f $thisfile && test ! "$masteroutdir" = "$thisfile";
   then
      #invalid file.
      ferror "$scriptfile: $thisfile does not exist."
      #exit 3
   else
      #valid file, so perform bup operation!
      bup_file $thisfile
   fi
done
