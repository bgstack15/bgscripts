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
#    Use as a systemd unit. The main daemon mode is just ./monitor-resize.sh
#    A child process can be specifically spawned:
#    sudo ./monitor-resize.sh --display :0 --user bgstack15 --child -c /home/bgstack15/rpmbuild/SOURCES/bgscripts-1.2-17/etc/bgscripts/monitor-resize.conf --instance 5
# Reference: ftemplate.sh 2017-06-08a; framework.sh 2017-06-08a
# Improve:
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

get_displays() {
   # Reference: https://bgstack15.wordpress.com/2017/09/06/find-running-x-sessions/
   { ps -eo pid,command | awk '/-session/ {print $1}' | while read thispid; do cat /proc/${thispid}/environ | tr '\0' '\n' | grep "DISPLAY" | sed -e "s/^/${thispid} $( stat -c '%U' /proc/${thispid}/comm ) $( basename $( readlink -f /proc/${thispid}/exe ) ) /;"; done; } 2>/dev/null | grep -iE "xfce|cinnamon"
}

# DEFINE TRAPS

clean_monitorresize() {
   # use at end of entire script if you need to clean up tmpfiles

   # send kill signals to children
   cat "${tmpfilepids}" 2>/dev/null | while read thispid junk;
   do
      kill -15 "${thispid}"
   done

   rm -f "${tmpfilemaster}" "${tmpfilemasterold}" "${tmpfilemasteractions}" "${tmpfilepids}" 2>/dev/null
   rm -f /tmp/kill_monitor-resize.tmp 2>/dev/null
   trap "" 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20
   exit 0
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
   trap "" 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 16 17 18 19 20
   exit 0
}

trap_sigterm_child() {
   # use with: trap "trap_sigterm_child" 15
   echo "Child ${childinstance} terminated by daemon."
   clean_monitorresize_child
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
define_if_new default_conffile /etc/bgscripts/monitor-resize.conf
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

# CONFIGURE VARIABLES AFTER PARAMETERS
define_if_new MONITOR_RESIZE_DELAY=2
define_if_new MONITOR_RESIZE_CHILD=/usr/share/bgscripts/gui/monitor-resize.sh
define_if_new MONITOR_RESIZE_CHILD_FLAG=--child
define_if_new MONITOR_RESIZE_COMMAND=/usr/share/bgscripts/gui/resize.sh
define_if_new MONITOR_RESIZE_TEMP_DIR=/tmp/bgscripts

## REACT TO BEING A CRONJOB
#if test ${is_cronjob} -eq 1;
#then
#   [ ]
#else
#   [ ]
#fi

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
         # every 10*DELAY seconds, check for running processes and add children if necessary.
         # if told to stop, then send signal 15 to children.
         # keep list of running children, by pid.
         
         # make temp file
         test -n "${MONITOR_RESIZE_TEMP_DIR}" && mkdir "${MONITOR_RESIZE_TEMP_DIR}" 2>/dev/null
         tmpfilemaster="$( mktemp -p "${MONITOR_RESIZE_TEMP_DIR}" tmp.master.$$.XXXXXX )"
         tmpfilemasterold="${tmpfilemaster}.old"; touch "${tmpfilemasterold}"
         tmpfilemasteractions="$( mktemp -p "${MONITOR_RESIZE_TEMP_DIR}" tmp.actions.$$.XXXXXX )"
         tmpfilepids="$( mktemp -p "${MONITOR_RESIZE_TEMP_DIR}" tmp.pids.$$.XXXXXX )"

         # SET TRAPS
         #trap "CTRLC" 2
         #trap "CTRLZ" 18
         trap "clean_monitorresize" 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20

         while ! test -f /tmp/kill_monitor-resize.tmp;
         do

            # generate list of displays
            get_displays | cut -d' ' -f2,4 > "${tmpfilemaster}"
            debuglev 8 && cat "${tmpfilemaster}"

            # compare to old list
            if ! test "$( cat "${tmpfilemaster}" 2>/dev/null )" = "$( cat "${tmpfilemasterold}" 2>/dev/null )";
            then
               # display
               diff -s "${tmpfilemaster}" "${tmpfilemasterold}" 2>/dev/null | sed -r -e '1d' -e 's/^</Added/;' -e 's/^>/Removed/;'
               diff -s "${tmpfilemaster}" "${tmpfilemasterold}" 2>/dev/null | sed -r -e '1d' -e 's/^</Added/;' -e 's/^>/Removed/;' > "${tmpfilemasteractions}"
            fi

            # spawn child processes based on changes
            cat "${tmpfilemasteractions}" | while read thisaction thisuser thisdisplay;
            do
               tmpdisplay="$( echo "${thisdisplay}" | sed 's/DISPLAY=//;' )"
               case "${thisaction}" in
                  Added)
                     "${MONITOR_RESIZE_CHILD}" "${MONITOR_RESIZE_CHILD_FLAG}" --display "${tmpdisplay}" --user "${thisuser}" --instance "${RANDOM}" -c "${conffile}" &
                     debuglev 2 && printf "%s %s %s %s\n" "$!" "${thisuser}" "${tmpdisplay}"
                     printf "%s %s %s %s\n" "$!" "${thisuser}" "${tmpdisplay}" >> "${tmpfilepids}"
                     ;;
                  Removed)
                     thisline="$( grep -iE "${thisuser} ${tmpdisplay}" "${tmpfilepids}" 2>/dev/null )"
                     if test -n "${thisline}"
                     then
                        thispid="$( printf "%s\n" "${thisline}" | awk '{print $1}' )"
                        kill -15 "${thispid}" && sed -i -r -e "/^${thisline}$/d" "${tmpfilepids}" && \
                           debuglev 2 && printf "%s\n" "${thisline}"
                     fi
                     ;;
               esac
            done

            # loop file
            cat "${tmpfilemaster}" > "${tmpfilemasterold}"
            cat /dev/null > "${tmpfilemasteractions}"

            sleep "$( printf '%s*3\n' "${MONITOR_RESIZE_DELAY}" | bc )"
         done

         rm -f /tmp/kill_monitor-resize.tmp
         ferror "${scriptfile}: Ultimate kill switch used."
         exit 0
         ;;
#############################################################3
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
         trap "clean_monitorresize_child" 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 16 17 18 19 20
         trap "trap_sigterm_child" 15

         # perform checks
         while true;
         do
            #requestedsize="$( { DISPLAY=${childdisplay} xrandr --current | head -n3 | tail -n1 | awk '{print $1}'; } 2>/dev/null )"
            #getsize_command="xrandr --current | head -n3 | tail -n1 | awk '{print $1}'"
            requestedsize="$( {
               su - "${childuser}" -c "DISPLAY=${childdisplay} xrandr --current 2>/dev/null | head -n3 | tail -n1 | awk '{print \$1}'";
            } 2>/dev/null )"
            if ! test "$( cat "${tmpfilechild}" )" = "${requestedsize}";
            then
               printf "Child ${childinstance} ${childuser}${childdisplay} requested size: ${requestedsize}\n"
               su - "${childuser}" -c "DISPLAY=${childdisplay} ${MONITOR_RESIZE_COMMAND}" 2>/dev/null
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
