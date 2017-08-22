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
usage: some-program | ctee.sh [-aduV] [outfile1]
version ${cteeversion}
 -a append  Append to given file, do not overwrite.
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

parseFlag() {
   flag="$1"
   hasval=0
   case ${flag} in
      # INSERT FLAGS HERE
      "d" | "debug" | "DEBUG" | "dd" )
         ferror "${scriptfile}: For debugging change \$devtty in the script. Aborted."
         exit 1
         ;;
      "u" | "usage" | "help" | "h" ) usage; exit 1;;
      "V" | "fcheck" | "version" ) ferror "${scriptfile} version ${cteeversion}"; exit 1;;
      "a" | "append" ) append=1;;
   esac
   
   debuglev 10 && { test ${hasval} -eq 1 && ferror "flag: ${flag} = ${tempval}" || ferror "flag: ${flag}"; }
}

# DETERMINE LOCATION OF FRAMEWORK
while read flocation; do if test -x ${flocation} && test "$( ${flocation} --fcheck )" -ge 20170111; then frameworkscript="${flocation}"; break; fi; done <<EOFLOCATIONS
/usr/share/bgscripts/framework.sh
EOFLOCATIONS
test -z "${frameworkscript}" && echo "$0: framework not found. Aborted." 1>&2 && exit 4

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

# VALIDATE PARAMETERS
# objects before the dash are options, which get filled with the optvals
# to debug flags, use option DEBUG. Variables set in framework: fallopts
validateparams outfile1 - "$@"

# CONFIRM TOTAL NUMBER OF FLAGLESSVALS IS CORRECT
if test ${thiscount} -lt 1;
then
   outfile1=/dev/null
fi

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
case "${append}" in
   1)
      tee ${thisttyout} | sed -u -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g" >> "${outfile1}"
      ;;
   *) tee ${thisttyout} | sed -u -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g" > "${outfile1}"
      ;;
esac
