#!/bin/sh
# Filename: dnskeepalive.sh
# Location: 
# Author: bgstack15@gmail.com
# Startdate: 2017-04-16 22:04:59
# Title: Service that Rotates DNS Servers if the Primary is Unresponsive
# Purpose: 
# Package: bgscripts
# History: 
# Usage: 
# Reference: ftemplate.sh 2017-01-11a; framework.sh 2017-01-11a
#    https://github.com/kvz/nsfailover/blob/master/nsfailover.sh
# Improve:
# Dependencies:
fiversion="2017-01-17a"
dnskeepaliveversion="2017-04-16a"

usage() {
   less -F >&2 <<ENDUSAGE
usage: dnskeepalive.sh [-duV] [-c conffile]
version ${dnskeepaliveversion}
 -d debug   Show debugging info, including parsed variables.
 -u usage   Show this usage block.
 -V version Show script version number.
 -c conffile Specify config file. If not provided, use default values for everything.
 -1 one     Run dnskeepalive just once.
Return values:
0 Normal
1 Help or version info displayed
2 Count or type of flaglessvals is incorrect
3 Incorrect OS type
4 Unable to find dependency
5 Not run as root or sudo
6 Already running, or problem with lockfile.
ENDUSAGE
}

# DEFINE FUNCTIONS

function get_conf {
   local _infile="$1"
   local _tmpfile1="$( mktemp )"
   # WORKHERE: get string from my blog
   grep -viE "^$|^#" "${_infile}" | while read _line;
   do
      local _left="$( echo "${_line}" | cut -d'=' -f1 )"
      eval "_thisval=\"\${${_left}}\""
      test -z "${_thisval}" && echo "${_line}" >> "${_tmpfile1}"
   done
   test -f "${_tmpfile1}" && . "${_tmpfile1}" 1>/dev/null 2>&1
   /bin/rm -rf "${_tmpfile1}"
}

function dnsisgood() {
   local _ns="${1}"
   local _domain="${2}"
   local _result="$( $( which dig ) @${_ns} +time=3 +tries=1 +short "${_domain}" 2>/dev/null)"

   #test -n "${_result}"; return $?
   # test zone. this is not for production.
   case "${_ns}" in
      *111*) _result="foo";;
      *) _result= ;;
   esac

   test -n "${_result}"; return $?
}

function log {
   echo "$@"
}

# DEFINE TRAPS

clean_dnskeepalive() {
   #rm -f ${logfile} > /dev/null 2>&1
   [ ] #use at end of entire script if you need to clean up tmpfiles
   rm -f "${lockfile}"
}

CTRLC() {
   #trap "CTRLC" 2
   [ ] #useful for controlling the ctrl+c keystroke
   clean_dnskeepalive
   trap "" 0; exit 0
}

CTRLZ() {
   #trap "CTRLZ" 18
   [ ] #useful for controlling the ctrl+z keystroke
   clean_dnskeepalive
}

parseFlag() {
   flag="$1"
   hasval=0
   case ${flag} in
      # INSERT FLAGS HERE
      "d" | "debug" | "DEBUG" | "dd" ) setdebug; ferror "debug level ${debug}";;
      "u" | "usage" | "help" | "h" ) usage; exit 1;;
      "V" | "fcheck" | "version" ) ferror "${scriptfile} version ${dnskeepaliveversion}"; exit 1;;
      #"i" | "infile" | "inputfile" ) getval;infile1=${tempval};;
      "c" | "conf" | "config" | "conffile" ) getval; conffile="${tempval}";;
      "1" | "one" | "ONE" ) DNSK_ONESHOT=yes;;
      "clean" ) clean_dnskeepalive; exit 0;;
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
. ${frameworkscript} || { echo "$0: framework did not run properly. Aborted." 1>&2; exit 4; }
infile1=
outfile1=
default_conffile=/etc/bgscripts/dnskeepalive.conf
conffile="${default_conffile}"
logfile=${scriptdir}/${scripttrim}.${today}.out
interestedparties="bgstack15@gmail.com"
lockfile="/tmp/.dnskeepalive.lock"

# REACT TO ROOT STATUS
case ${is_root} in
   1) # proper root
      [ ] ;;
   sudo) # sudo to root
      [ ] ;;
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

# READ CONFIG FILES
if test -f "${conffile}";
then
   get_conf "${conffile}"
else
   ferror "${scriptfile}: Ignoring conf file which is not found: ${conffile}."
fi
test -f "${default_conffile}" && get_conf "${default_conffile}"

## REACT TO BEING A CRONJOB
#if test ${is_cronjob} -eq 1;
#then
#   [ ]
#else
#   [ ]
#fi

## EXIT IF LOCKFILE EXISTS
if test -e "${lockfile}";
then
   if /bin/ps -ef | awk '/dnskeepalive/{print $2}' | grep -qiE "$( cat "${lockfile}" )";
   then
      log "Already running (pid $( cat "${lockfile}" ). Aborted."
      exit 6
   else
      log "Previous instance did not exit cleanly. Cleaning up."
   fi
fi

# SET TRAPS
trap "CTRLC" 2
#trap "CTRLZ" 18
trap "clean_dnskeepalive" 0

# CREATE LOCKFILE
if ! touch "${lockfile}";
then
   log "Could not create lockfile ${lockfile}. Aborted."
   exit 6
else
   echo "$$" > "${lockfile}"
fi

# MAIN LOOP
#{
   log "${scripttrim} started"
   debuglev 5 && {
      ferror "using values"
      #set | grep -iE "DNSK_(DELAY|RESOLVCONF|ENABLED|TESTDOMAIN)" 1>&2
      set | grep -iE "DNSK_" 1>&2
   }
   # WORKHERE: get istruthy from bgconf?
   while test -n "${DNSK_ENABLED}" && test "${DNSK_ENABLED}" = "yes";
   do
      bupfile="$( /usr/bin/bup -d "${DNSK_RESOLVCONF}" | cut -d' ' -f4 )"
      goodorder=
      badorder=

      # collect nameservers
      # WORKHERE: discover how to parse nameservers in a real resolv.conf
      ns1="$( grep -iE "nameserver" "${DNSK_RESOLVCONF}" 2>/dev/null | cut -d' ' -f2 )"
      ns2="$( grep -iE "nameserver" "${DNSK_RESOLVCONF}" 2>/dev/null | cut -d' ' -f3 )"
      ns3="$( grep -iE "nameserver" "${DNSK_RESOLVCONF}" 2>/dev/null | cut -d' ' -f4 )"
      ns4="$( grep -iE "nameserver" "${DNSK_RESOLVCONF}" 2>/dev/null | cut -d' ' -f5 )"
      oldorder="$( grep -iE "nameserver" "${DNSK_RESOLVCONF}" )"

      x=0
      while test ${x} -lt 4;
      do
         x=$(( x + 1 ))
         eval "thisns=\"\${ns${x}}\""
         if test -n "${thisns}";
         then
            if dnsisgood "${thisns}" "${DNSK_TESTDOMAIN}";
            then
               goodorder="${goodorder} ${thisns}"
            else
               badorder="${badorder} ${thisns}"
            fi
         fi
      done
      neworder="$( echo "nameserver ${goodorder} ${badorder}" | sed -r -e 's/^ +//g;s/ +$//g;s/ +/ /g;' )"
      if test "${neworder}" = "${oldorder}";
      then
         debuglev 1 && log "no changes required"
      else
         log "changed nameserver priority to: ${neworder}"
         /usr/bin/bup "${DNSK_RESOLVCONF}"
         sed -i -r -e "s/^nameserver.*/${neworder}/;" "${DNSK_RESOLVCONF}"
      fi

      if test "${DNSK_ONESHOT}" = "yes" || test -n "${DNSK_ONESHOT}";
      then
         break 2
      fi
      sleep "${DNSK_DELAY}"
   done
#} | tee -a ${logfile}

# EMAIL LOGFILE
#${sendsh} ${sendopts} "${server} ${scriptfile} out" ${logfile} ${interestedparties}

## STOP THE READ CONFIG FILE
#exit 0
#fi; done; }
