#!/bin/sh
# Filename: treesize.sh
# Location: 
# Author: bgstack15@gmail.com
# Startdate: 2015-11-20 13:43:41
# Title: 
# Purpose: 
# History: 2017-01-11 moved whole package to /usr/share/bgscripts
# Usage: 
# Reference: ftemplate.sh 2015-11-20a; framework.sh 2015-11-20a
# Improve:
fiversion="2015-11-20a"
treesize2version="2017-01-11a"

usage() {
   less -F >&2 <<ENDUSAGE
usage: treesize2.sh [-duV] [-i infile1]
version ${treesize2version}
 -d debug   Show debugging info, including parsed variables.
 -u usage   Show this usage block.
 -V version Show script version number.
 -i infile  Overrides default infile value. Default is none.
Return values:
0 Normal
1 Help or version info displayed
2 Count or type of flaglessvals is incorrect
3 Incorrect OS type
4 Unable to find dependency
5 Not run as root or sudo
ENDUSAGE
}

# DEFINE FUNCTIONS

# DEFINE TRAPS

clean_treesize2() {
   #rm -f $logfile >/dev/null 2>&1
   [ ] #use at end of entire script if you need to clean up tmpfiles
}

CTRLC() {
   #trap "CTRLC" 2
   [ ] #useful for controlling the ctrl+c keystroke
}

CTRLZ() {
   #trap "CTRLZ" 18
   [ ] #useful for controlling the ctrl+z keystroke
}

parseFlag() {
   flag=$1
   hasval=0
   case $flag in
      # INSERT FLAGS HERE
      "d" | "debug" | "DEBUG" | "dd" ) setdebug; ferror "debug level ${debug}";;
      "u" | "usage" | "help") usage; exit 1;;
      "V" | "fcheck" | "version") ferror "${scriptfile} version ${treesize2version}"; exit 1;;
      #"i" | "infile" | "inputfile") getval;infile1=$tempval;;
   esac
   
   debuglev 10 && { test hasval -eq 1 && ferror "flag: $flag = $tempval" || ferror "flag: $flag"; }
}

# DETERMINE LOCATION OF FRAMEWORK
while read flocation; do if test -x $flocation && test "$( $flocation --fcheck )" -ge 20160803; then frameworkscript=$flocation; break; fi; done <<EOFLOCATIONS
./framework.sh
${scriptdir}/framework.sh
~/bin/bgscripts/framework.sh
~/bin/framework.sh
~/bgscripts/framework.sh
~/framework.sh
/usr/local/bin/bgscripts/framework.sh
/usr/local/bin/framework.sh
/usr/bin/bgscripts/framework.sh
/usr/bin/framework.sh
/bin/bgscripts/framework.sh
/usr/share/bgscripts/framework.sh
EOFLOCATIONS
test -z "$frameworkscript" && echo "$0: framework not found. Aborted." 1>&2 && exit 4

# REACT TO OPERATING SYSTEM TYPE
case $( uname -s ) in
   Linux) [ ];;
   FreeBSD) [ ];;
   *) echo "$scriptfile: 3. Indeterminate OS: $( uname -s )" 1>&2 && exit 3;;
esac

# INITIALIZE VARIABLES
# variables set in framework:
# today server thistty scriptdir scriptfile scripttrim
# is_cronjob stdin_piped stdout_piped stderr_piped sendsh sendopts
. ${frameworkscript} || echo "$0: framework did not run properly. Continuing..." 1>&2
infile1=
outfile1=
logfile=${scriptdir}/${scripttrim}.${today}.out
interestedparties="root"

## REACT TO ROOT STATUS
#case $is_root in
#   1) # proper root
#      [ ] ;;
#   sudo) # sudo to root
#      [ ] ;;
#   "") # not root at all
#      #ferror "${scriptfile}: 5. Please run as root or sudo. Aborted."
#      #exit 5
#      [ ]
#      ;;
#esac

# SET CUSTOM SCRIPT AND VALUES
#setval 1 sendsh sendopts<<EOFSENDSH      # if $1="1" then setvalout="critical-fail" on failure
#/usr/share/bgscripts/send.sh -hs     #                setvalout maybe be "fail" otherwise
#/usr/local/bin/send.sh -hs               # on success, setvalout="valid-sendsh"
#/usr/bin/mail -s
#EOFSENDSH
#test "$setvalout" = "critical-fail" && ferror "${scriptfile}: 4. mailer not found. Aborted." && exit 4

# VALIDATE PARAMETERS
# objects before the dash are options, which get filled with the optvals
# to debug flags, use option DEBUG. This function populates variable fallopts
validateparams - "$@"

# CONFIRM TOTAL NUMBER OF FLAGLESSVALS IS CORRECT
#if test $thiscount -lt 2;
#then
#   ferror "${scriptfile}: 2. Fewer than 2 flaglessvals. Aborted."
#   exit 2
#fi

# CONFIGURE VARIABLES AFTER PARAMETERS
test -z "${fallopts}" && fallopts="."

## READ CONFIG FILE TEMPLATE
#grep -viE "^$|^#" "${infile1}" | sed "s/[^\]#.*$//;' | while read line
##BASH BELOW
##while read -r line
#do
#   echo "$line"
#   read -p "Please type something here:" response < $thistty
#   echo "$response"
#done
##BASH BELOW
##done < <( grep -viE "^$|^#" "${infile1}" | sed 's/[^\]#.*$//g;' )

## REACT TO BEING A CRONJOB
#if test $is_cronjob -eq 1;
#then
#   [ ]
#else
#   [ ]
#fi

# SET TRAPS
#trap "CTRLC" 2
#trap "CTRLZ" 18
#trap "clean_treesize2" 0

# MAIN LOOP
#{
   debuglev 1 && echo "find ${fallopts} 2>/dev/null | xargs du -a 2>/dev/null | sort -n | sed 's!\/\/!\/!g;'"
   find ${fallopts} ${fallopts}/* -type d 2>/dev/null | xargs du 2>/dev/null | sort -n | sed 's!\/\/!\/!g;'
   [ ]
#} | tee -a $logfile

# EMAIL LOGFILE
#$sendsh $sendopts "$server $scriptfile out" $logfile $interestedparties
