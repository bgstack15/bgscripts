#!/bin/sh
# File: /usr/share/bgscripts/fl.sh
# Author: bgstack15@gmail.com
# Startdate: 2014-10-16 09:35
# Title: Script that runs "find | xargs ls -dl" for the Given Parameters
# Purpose: To make it easier to ls -dl various files matching filename patterns in . and subdirs
# Package: bgscripts
# History: 2015-11-23 updated for bgscripts
#    2016-08-03 converted to /bin/sh
#    2017-01-11 moved whole package to /usr/share/bgscripts
#    2017-11-11a Added FreeBSD location support
# Usage: 
# Reference: ftemplate.sh 2014-08-04b; framework.sh 2014-08-04b
# Improve:
fiversion="2017-01-11a"
flversion="2017-11-11a"

usage() {
   less -F >&2 <<ENDUSAGE
usage: fl.sh [-ud]
 -u usage   Show this usage block.
 -d debug   Show what search would be used. Prevents actual operation.
Return values:
0 Normal
1 Help screen displayed
3 Incorrect OS type
4 Unable to find dependency
ENDUSAGE
}

parseFlag() {
   flag=$1
   hasval=0
   case $flag in
      # INSERT FLAGS HERE
      "d" | "debug" | "DEBUG" | "dd" ) setdebug; ferror "debug level ${debug}";;
      "u" | "usage" | "help") usage; exit 1;;
      *) flargs="${flargs} -${flag}";;
      #"i" | "infile" | "inputfile") getval;infile1=$tempval;;
   esac
   
   debuglev 10 && { test ${hasval} -eq 1 && ferror "flag: $flag = $tempval" || ferror "flag: $flag"; }
}

# DETERMINE LOCATION OF FRAMEWORK
while read flocation; do if test -x ${flocation} && test "$( ${flocation} --fcheck )" -ge 20170111; then frameworkscript=$flocation; break; fi; done <<EOFLOCATIONS
./framework.sh
/usr/local/share/bgscripts/framework.sh
/usr/share/bgscripts/framework.sh
EOFLOCATIONS
test -z "$frameworkscript" && echo "$0: framework not found. Aborted." 1>&2 && exit 4

# REACT TO OPERATING SYSTEM TYPE
case $( uname -s ) in
   Linux|FreeBSD) [ ];;
   *) ferror "$scriptfile: 3. Indeterminate OS: $( uname -s )" && exit 3;;
esac

# INITIALIZE VARIABLES
# variables set in framework:
# today server thistty scriptdir scriptfile scripttrim
# is_cronjob stdin_piped stdout_piped stderr_piped
# sendsh sendopts
. $frameworkscript

# VALIDATE PARAMETERS
# objects before the dash are options, which get filled with the optvals
# to debug flags, use option DEBUG
validateparams - "$@"

# MAIN LOOP
# assemble full string
x=0
findstring=""
while test ${x} -lt ${thiscount};
do
   x=$( expr ${x} + 1 )
   eval addthis=\$opt$x
   findstring=${findstring}" -o -name \"$addthis\""
done
findstring=${findstring##" -o "} # to trim first OR operand
if debuglev 1;
then
   echo find . ${findstring} \| xargs ls -dl ${flargs}
else
   eval find . ${findstring} | xargs ls -dl ${flargs}
fi
