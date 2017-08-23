#!/bin/sh
# Filename: monitor-resize.sh
# Location: 
# Author: bgstack15@gmail.com
# Startdate: 2017-08-23 08:00:11
# Title: Daemon that Checks for Updated Virtual Display Size and Requests a Resize
# Purpose: Automatically resizes spice and vnc virtual displays
# Package: bgscripts
# History: 
# Usage: 
#   use as a systemd unit.
# A child process can be specifically spawned:
# sudo ./monitor-resize.sh --display :0 --user bgirton --child -c /home/bgirton/rpmbuild/SOURCES/bgscripts-1.2-17/etc/bgscripts/monitor-resize.conf  --instance 5
# Reference: ftemplate.sh 2017-06-08a; framework.sh 2017-06-08a
# Improve:
# modes of operation:
#    master daemon process
#  x instance
fiversion="2017-06-08a"
monitorresizeversion="2017-08-23a"

usage() {
   less -F >&2 <<ENDUSAGE
usage: monitor-resize.sh [-duV] [-c conffile]
version ${monitorresizeversion}
 -d debug   Show debugging info, including parsed variables.
 -u usage   Show this usage block.
 -V version Show script version number.
 -c conf    Read in this config file.
Return values:
 0 Normal
 1 Help or version info displayed
 2 Count or type of flaglessvals is incorrect
 3 Incorrect OS type
 4 Unable to find dependency
 5 Not run as root or sudo
 6 Child parameters are invalid
ENDUSAGE
}

# DEFINE FUNCTIONS
childerror() {
   # call: childerror 1 1 "Fatal error! Please fix and try again."
   # first parameter is fatal. 1 is exit after displaying message.
   # second parameter is exit code. Required but unused even if message is not fatal.
   # second parameter is text to display.
   local _isfatal="$1"
   local _exitcode="$2"
   shift; shift; local _therest="$@"
   ferror "${_therest}"
   fistruthy "${_isfatal}" && exit "${_exitcode}"
}

# DEFINE TRAPS

clean_monitorresize() {
   # use at end of entire script if you need to clean up tmpfiles
   #rm -f ${tmpfile} 1>/dev/null 2>&1
   :
}

CTRLC() {
   # use with: trap "CTRLC" 2
   # useful for controlling the ctrl+c keystroke
   :
}

CTRLZ() {
   # use with: trap "CTRLZ" 18
   # useful for controlling the ctrl+z keystroke
   :
}

clean_monitorresize_child() {
   rm -f "${tmpfilechild}" 2>/dev/null
   trap "" 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20
   exit 0
}

parseFlag() {
   flag="$1"
   hasval=0
   case ${flag} in
      # INSERT FLAGS HERE
      "d" | "debug" | "DEBUG" | "dd" ) setdebug; ferror "debug level ${debug}";;
      "u" | "usage" | "help" | "h" ) usage; exit 1;;
      "V" | "fcheck" | "version" ) ferror "${scriptfile} version ${monitorresizeversion}"; exit 1;;
      #"i" | "infile" | "inputfile" ) getval; infile1=${tempval};;
      "c" | "conf" | "conffile" | "config" ) getval; conffile="${tempval}";;
      "child" ) mode=1;;
      "display" ) getval; childdisplay="${tempval}";;
      "user" ) getval; childuser="${tempval}";;
      "instance" ) getval; childinstance="${tempval}";;
   esac
   
   debuglev 10 && { test ${hasval} -eq 1 && ferror "flag: ${flag} = ${tempval}" || ferror "flag: ${flag}"; }
}

# DETERMINE LOCATION OF FRAMEWORK
while read flocation; do if test -x ${flocation} && test "$( ${flocation} --fcheck )" -ge 20170608; then frameworkscript="${flocation}"; break; fi; done <<EOFLOCATIONS
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

# INITIALIZE VARIABLES
# variables set in framework:
# today server thistty scriptdir scriptfile scripttrim
# is_cronjob stdin_piped stdout_piped stderr_piped sendsh sendopts
. ${frameworkscript} || echo "$0: framework did not run properly. Continuing..." 1>&2
infile1=
outfile1=
logfile=${scriptdir}/${scripttrim}.${today}.out
mode=0  # mode=1 is for children processes
define_if_new interestedparties "bgstack15@gmail.com"
# SIMPLECONF
define_if_new default_conffile ~/rpmbuild/SOURCES/bgscripts-1.2-17/etc/bgscripts/monitor-resize.conf
define_if_new defuser_conffile ~/.config/bgscripts/monitor-resize.conf

# REACT TO OPERATING SYSTEM TYPE
case $( uname -s ) in
   Linux) [ ];;
   FreeBSD) [ ];;
   *) echo "${scriptfile}: 3. Indeterminate OS: $( uname -s )" 1>&2 && exit 3;;
esac

# REACT TO ROOT STATUS
case ${is_root} in
   1) # proper root
      : ;;
   sudo) # sudo to root
      : ;;
   "") # not root at all
      ferror "${scriptfile}: 5. Please run as root or sudo. Aborted."
      exit 5
      ;;
esac

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
validateparams - "$@"

# CONFIRM TOTAL NUMBER OF FLAGLESSVALS IS CORRECT
#if test ${thiscount} -lt 2;
#then
#   ferror "${scriptfile}: 2. Fewer than 2 flaglessvals. Aborted."
#   exit 2
#fi

# CONFIGURE VARIABLES AFTER PARAMETERS

# LOAD CONFIG FROM SIMPLECONF
# This section follows a simple hierarchy of precedence, with first being used:
#    1. parameters and flags
#    2. environment
#    3. config file
#    4. default user config: ~/.config/script/script.conf
#    5. default config: /etc/script/script.conf
if test -f "${conffile}";
then
   get_conf "${conffile}"
else
   if test "${conffile}" = "${default_conffile}" || test "${conffile}" = "${defuser_conffile}"; then :; else test -n "${conffile}" && ferror "${scriptfile}: Ignoring conf file which is not found: ${conffile}."; fi
fi
test -f "${defuser_conffile}" && get_conf "${defuser_conffile}"
test -f "${default_conffile}" && get_conf "${default_conffile}"

## START READ CONFIG FILE TEMPLATE
#oIFS="${IFS}"; IFS="$( printf '\n' )"
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
#trap "clean_monitorresize" 0

# DEBUG SIMPLECONF
debuglev 5 && {
   ferror "Using values"
   # used values: EX_(OPT1|OPT2|VERBOSE)
   set | grep -iE "^MONITOR_RESIZE_" 1>&2
}

# MAIN LOOP
#{
   # determine mode
   case "${mode}" in
      0)
         # master daemon
         ;;
      1)
         # child mode
         debuglev 9 && ferror "Mode: child, pid $$, instance ${childinstance}"

         # determine if all variables are provided
         test -z "${childdisplay}" && childerror 1 6 "${scriptfile}: --display value is invalid. Aborted."
         test -z "${childuser}" && childerror 1 6 "${scriptfile}: --user value is invalid. Aborted."
         if test -z "${MONITOR_RESIZE_DELAY}" || ! fisnum "${MONITOR_RESIZE_DELAY}";
         then
            childerror 1 6 "${scriptfile}: delay not provided! Please check config files. Aborted."
         fi

         # display debugging info
         debuglev 5 && {
            echo "display ${childdisplay} user ${childuser} instance ${childinstance}"
         }
         # make temp file
         test -n "${MONITOR_RESIZE_TEMP_DIR}" && mkdir "${MONITOR_RESIZE_TEMP_DIR}" 2>/dev/null
         tmpfilechild="$( mktemp -p "${MONITOR_RESIZE_TEMP_DIR}" tmp.$$.XXXXXX )"

         #su - "${childuser}" -c "DISPLAY=${childdisplay} ${MONITOR_RESIZE_COMMAND}"

         # set traps
         trap "clean_monitorresize_child" 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20

         # perform checks
         while true;
         do
            #requestedsize="$( { DISPLAY=${childdisplay} xrandr --current | head -n3 | tail -n1 | awk '{print $1}'; } 2>/dev/null )"
            getsize_command="xrandr --current | head -n3 | tail -n1 | awk '{print $1}'"
            requestedsize="$( {
               su - "${childuser}" -c "DISPLAY=${childdisplay} xrandr --current | head -n3 | tail -n1 | awk '{print \$1}'";
            } 2>/dev/null )"
            if ! test "$( cat "${tmpfilechild}" )" = "${requestedsize}";
            then
               flecho "Child ${childinstance} ${childuser}${childdisplay} requested size: ${requestedsize}"
               su - "${childuser}" -c "DISPLAY=${childdisplay} ${MONITOR_RESIZE_COMMAND}"
               printf "%s" "${requestedsize}" > "${tmpfilechild}"
            fi
         
            sleep "${MONITOR_RESIZE_DELAY}"

         done

         # if the while loop finishes, it gets here and it should never get here.
         childerror 1 18 "Unusual termination of child pid $$, instance ${childinstance}."
         ;;
      *)
         ferror "Mode not supported yet: ${mode}. Aborted."
         exit 1
   esac
#} | tee -a ${logfile}

# EMAIL LOGFILE
#${sendsh} ${sendopts} "${server} ${scriptfile} out" ${logfile} ${interestedparties}

## STOP THE READ CONFIG FILE
#exit 0
#fi; done; }
