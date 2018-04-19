#!/bin/sh
# Filename: bounce.sh
# Location: 
# Author: bgstack15@gmail.com
# Startdate: 2017-04-16 15:39:59
# Title: Script that Bounces Objects
# Purpose: To make it easy to restart items regardless of type
# Package: bgscripts
# History: 
#    2017-11-11a Added FreeBSD support
# Usage: 
# Reference: ftemplate.sh 2017-01-11a; framework.sh 2017-01-11a
# Improve:
#   possibly take _available_interfaces from typeset -f on a fedora 25 system
fiversion="2017-01-17a"
bounceversion="2017-11-11a"

usage() {
   less -F >&2 <<ENDUSAGE
usage: bounce.sh [-duV] [-D delay] [-n|-d|-s] [object1 ...]
version ${bounceversion}
 -d debug   Show debugging info, including parsed variables.
 -u usage   Show this usage block.
 -V version Show script version number.
 -D delay   DELAY in seconds between down and up cycles. Default is "${DELAY}"
 object1... Item to restart. Supported items include network cards, network shares, and systemd services.
 -n|-d|-s   Optional flags that provide nice autocomplete options.
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

bounce_nics() {
   for _word in $@;
   do
      debuglev 2 && ferror "Bouncing ${_word}"
      #fsudo ifdown "${_word}"
      fsudo ip link set "${_word}" down
   done
   sleep "${DELAY}"
   for _word in $@;
   do
      #fsudo ifup "${_word}"
      fsudo ip link set "${_word}" up
   done
}

bounce_dirs() {
   # network shares
   ${sharesscript} -s "${DELAY}" -r $@
}

bounce_services() {
   # systemd services
   for _word in $@;
   do
      debuglev 2 && ferror "Bouncing ${_word}"
      fsudo systemctl stop "${_word}"
   done
   sleep "${DELAY}"
   for _word in $@;
   do
      fsudo systemctl start "${_word}"
   done
}

# DEFINE TRAPS

clean_bounce() {
   rm -f "${tmpfile1}" > /dev/null 2>&1
   #use at end of entire script if you need to clean up tmpfiles
}

CTRLC() {
   #trap "CTRLC" 2
   [ ] #useful for controlling the ctrl+c keystroke
   clean_bounce
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
      "d" | "debug" | "DEBUG" | "dd" ) setdebug; ferror "debug level ${debug}";;
      "u" | "usage" | "help" | "h" ) usage; exit 1;;
      "V" | "fcheck" | "version" ) ferror "${scriptfile} version ${bounceversion}"; exit 1;;
      "D" | "delay" | "DELAY" | "sec" | "second" | "seconds" ) getval; DELAY="${tempval}";;
      "n" | "s" | "m" | "network" | "nic" | "service" | "systemdservice" | "mount" | "dir" | "directory") :;;
      #"i" | "infile" | "inputfile" ) getval;infile1=${tempval};;
   esac
   
   debuglev 10 && { test ${hasval} -eq 1 && ferror "flag: ${flag} = ${tempval}" || ferror "flag: ${flag}"; }
}

# DETERMINE LOCATION OF FRAMEWORK
while read flocation; do if test -e ${flocation} && test "$( sh ${flocation} --fcheck 2>/dev/null )" -ge 20170111; then frameworkscript="${flocation}"; break; fi; done <<EOFLOCATIONS
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
/usr/local/share/bgscripts/framework.sh
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
DELAY=2
BOUNCE_TYPE=
tmpfile1="$( mktemp )"

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
setval 1 sharesscript <<EOFSHARESSCRIPT
/usr/local/share/bgscripts/shares.sh
/usr/share/bgscripts/shares.sh
EOFSHARESSCRIPT
test "${setvalout}" = "critical-fail" && ferror "${scripttrim}: 4. shares.sh not found. Aborted." && exit 4

# VALIDATE PARAMETERS
# objects before the dash are options, which get filled with the optvals
# to debug flags, use option DEBUG. Variables set in framework: fallopts
validateparams - "$@"

# CONFIRM TOTAL NUMBER OF FLAGLESSVALS IS CORRECT
#if test ${thiscount} -lt 2;
#then
#   ferror "${scriptfile}: 2. Fewer than 2 flaglessvals. Aborted."
#   exit 2
#fi

# CONFIGURE VARIABLES AFTER PARAMETERS

## REACT TO BEING A CRONJOB
#if test ${is_cronjob} -eq 1;
#then
#   [ ]
#else
#   [ ]
#fi

# SET TRAPS
trap "CTRLC" 2
#trap "CTRLZ" 18
trap "clean_bounce" 0

# MAIN LOOP
# Determine type of bounce
if echo "${fallopts}" | grep -qiE "$( ip -o link show | awk '{print $2}' | xargs | sed -e 's/ //g;' -e 's/:/\|/g;' )((eth|ens|enp)[0-9])|(wl.{0,8})";
then
   debuglev 1 && ferror "Found network cards";
   bounce_nics ${fallopts}
elif echo "${fallopts}" | grep -qiE "\/";
then
   debuglev 1 && ferror "Found network shares";
   bounce_dirs ${fallopts}
else
   # check if systemd service
   { find /lib/systemd/system/ -regextype grep -regex '.*\.service' | sed -r -e 's#.*\/##;' | sort | uniq > "${tmpfile1}"; } 2>/dev/null
   _issystemdservice=0
   for word in ${fallopts};
   do
      grep -qiE "${word}" "${tmpfile1}" && _issystemdservice=$(( _issystemdservice + 1 ))
   done
   if test ${_issystemdservice} -gt 0;
   then
      debuglev 1 && ferror "Found systemd services";
      bounce_services ${fallopts}
   else
      echo "not supported yet: ${fallopts}"
   fi
fi
