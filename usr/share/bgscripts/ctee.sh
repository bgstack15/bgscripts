#!/bin/sh
# Filename: ctee.sh
# Location: /usr/share/bgscripts/
# Author: bgstack15@gmail.com
# Startdate: 2017-03-16 20:22:00
# Title: Script that Tees and Handles Color
# Purpose: Shows colorized output but saves to file the plain text
# Package: bgscripts
# History: 
# Usage: Always needs stdin from a pipe.
#    If a command wants to send uncolored stdout to tee, use unbuffer.
#    unbuffer ls -lF --color=always | ctee
# Reference: ftemplate.sh 2017-01-11a; framework.sh 2017-01-11a
#   find process on the other end of a pipe: https://superuser.com/a/401619/318045
#   remove color: http://www.commandlinefu.com/commands/view/3584/remove-color-codes-special-characters-with-sed
# Improve:
fiversion="2017-01-17a"
cteeversion="2017-03-16a"

usage() {
   less -F >&2 <<ENDUSAGE
usage: some-program | ctee.sh [-duV] [outfile1]
version ${cteeversion}
 -d debug   Throws error. For debugging, edit value \$devtty in the script.
 -u usage   Show this usage block.
 -V version Show script version number.
This script operates tee and preserves color on the output while sending uncolored output to the file.
Sometimes a program needs to be used with unbuffer to display color to a pipe.
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

clean_ctee() {
   #rm -f ${logfile} > /dev/null 2>&1
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
   flag="$1"
   hasval=0
   case ${flag} in
      # INSERT FLAGS HERE
      "d" | "debug" | "DEBUG" | "dd" )
         #setdebug; ferror "debug level ${debug}"
         ferror "${scriptfile}: For debugging change \$devtty in the script. Aborted."
         exit 1
         ;;
      "u" | "usage" | "help" | "h" ) usage; exit 1;;
      "V" | "fcheck" | "version" ) ferror "${scriptfile} version ${cteeversion}"; exit 1;;
      #"i" | "infile" | "inputfile" ) getval;infile1=${tempval};;
      "a" | "append" ) append=1;;
   esac
   
   debuglev 10 && { test ${hasval} -eq 1 && ferror "flag: ${flag} = ${tempval}" || ferror "flag: ${flag}"; }
}

# DETERMINE LOCATION OF FRAMEWORK
while read flocation; do if test -x ${flocation} && test "$( ${flocation} --fcheck )" -ge 20170111; then frameworkscript="${flocation}"; break; fi; done <<EOFLOCATIONS
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
test -z "${frameworkscript}" && echo "$0: framework not found. Aborted." 1>&2 && exit 4

# REACT TO OPERATING SYSTEM TYPE
case $( uname -s ) in
   Linux) [ ];;
   FreeBSD) [ ];;
   *) echo "${scriptfile}: 3. Indeterminate OS: $( uname -s )" 1>&2 && exit 3;;
esac

# INITIALIZE VARIABLES
# variables set in framework:
# today server thistty scriptdir scriptfile scripttrim
# is_cronjob stdin_piped stdout_piped stderr_piped sendsh sendopts
. ${frameworkscript} || echo "$0: framework did not run properly. Continuing..." 1>&2
infile1=
outfile1=
logfile=${scriptdir}/${scripttrim}.${today}.out
interestedparties="bgstack15@gmail.com"
append=0
devtty=/dev/null

## REACT TO ROOT STATUS
#case ${is_root} in
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
#test "${setvalout}" = "critical-fail" && ferror "${scriptfile}: 4. mailer not found. Aborted." && exit 4

# VALIDATE PARAMETERS
# objects before the dash are options, which get filled with the optvals
# to debug flags, use option DEBUG. Variables set in framework: fallopts
validateparams outfile1 - "$@"

# CONFIRM TOTAL NUMBER OF FLAGLESSVALS IS CORRECT
if test ${thiscount} -lt 1;
then
   outfile1=/dev/null
fi
#if test ${thiscount} -lt 2;
#then
#   ferror "${scriptfile}: 2. Fewer than 2 flaglessvals. Aborted."
#   exit 2
#fi

# CONFIGURE VARIABLES AFTER PARAMETERS

## START READ CONFIG FILE TEMPLATE
#oIFS="${IFS}"; IFS=$'\n'
#infiledata=$( ${sed} ':loop;/^\/\*/{s/.//;:ccom;s,^.[^*]*,,;/^$/n;/^\*\//{s/..//;bloop;};bccom;}' "${infile1}") #the crazy sed removes c style multiline comments
#IFS="${oIFS}"; infilelines=$( echo "${infiledata}" | wc -l )
#{ echo "${infiledata}"; echo "ENDOFFILE"; } | {
#   while read line; do
#   # the crazy sed removes leading and trailing whitespace, blank lines, and comments
#   if test ! "${line}" = "ENDOFFILE";
#   then
#      line=$( echo "${line}" | sed -e 's/^\s*//;s/\s*$//;/^[#$]/d;s/\s*[^\]#.*$//;' )
#      if test -n "${line}";
#      then
#         debuglev 8 && ferror "line=\"${line}\""
#         if echo "${line}" | grep -qiE "\[.*\]";
#         then
#            # new zone
#            zone=$( echo "${line}" | tr -d '[]' )
#            debuglev 7 && ferror "zone=${zone}"
#         else
#            # directive
#            varname=$( echo "${line}" | awk -F= '{print $1}' )
#            varval=$( echo "${line}" | awk -F= '{$1=""; printf "%s", $0}' | sed 's/^ //;' )
#            debuglev 7 && ferror "${zone}${varname}=\"${varval}\""
#            # simple define variable
#            eval "${zone}${varname}=\${varval}"
#         fi
#         ## this part is untested
#         #read -p "Please type something here:" response < ${thistty}
#         #echo "${response}"
#      fi
#   else

## REACT TO BEING A CRONJOB
#if test ${is_cronjob} -eq 1;
#then
#   [ ]
#else
#   [ ]
#fi

# SET TRAPS
#trap "CTRLC" 2
#trap "CTRLZ" 18
#trap "clean_ctee" 0

# this whole operation calculates where the stdout of this whole pipe goes
ttyresolved=0
_count=0
_pid=$$
_fd1="$( readlink -f /proc/${_pid}/fd/1 )"
while test ${ttyresolved} -lt 10;
do
   ttyresolved=$(( ttyresolved + 1 ))
   echo "before ${ttyresolved}, _pid=${_pid}, _fd1=${_fd1}" > ${devtty}
   case "${_fd1}" in
      *pipe:* )
         newpid=$( find /proc -type l -name '0' 2>/dev/null | xargs ls -l 2>/dev/null | grep -F "$( basename ${_fd1} )" | grep -viE "\/${_pid}\/"; )
         newpid=$( echo "${newpid}" | head -n1 | grep -oiE "\/proc\/[0-9]*\/" | grep -o "[0-9]*" )
         _pid=${newpid}
         _fd1="$( readlink -f /proc/${_pid}/fd/1 )"
         ;;
       *dev*|*/* )
         thisttyout="${_fd1}"
         ttyresolved=10
         ;;
   esac
done

echo "thisttyout ${thisttyout}" > ${devtty}

# MAIN LOOP
#{
   case "${append}" in
      1)
         tee ${thisttyout} | sed -u -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g" >> "${outfile1}"
         ;;
      *) tee ${thisttyout} | sed -u -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g" > "${outfile1}"
         ;;
   esac
#} | tee -a ${logfile}

# EMAIL LOGFILE
#${sendsh} ${sendopts} "${server} ${scriptfile} out" ${logfile} ${interestedparties}

## STOP THE READ CONFIG FILE
#exit 0
#fi; done; }
