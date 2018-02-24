#!/bin/sh
# Filename: dnskeepalive.sh
# Location: 
# Author: bgstack15@gmail.com
# Startdate: 2017-04-16 22:04:59
# Title: Service that Rotates DNS Servers if the Primary is Unresponsive
# Purpose: 
# Package: bgscripts
# History: 
#    2017-04-20 suppressed error "bup: /etc/resolv.conf does not exist."
#    2017-05-24 added extra cleanup of temp file during loop to see if this reduces clutter in /tmp directory
#    2017-08-22 Suppressed error message on bup
#    2017-08-22 Added FreeBSD location support
# Usage: 
# Reference: ftemplate.sh 2017-01-11a; framework.sh 2017-01-11a
#    https://github.com/kvz/nsfailover/blob/master/nsfailover.sh
# Improve:
# Dependencies:
fiversion="2017-01-17a"
dnskeepaliveversion="2017-11-11a"

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

get_conf() {
   local _infile="$1"
   local _tmpfile1="$( mktemp )"
   grep -viE '^\s*((#).*)?$' "${_infile}" | while read _line;
   do
      local _left="$( echo "${_line}" | cut -d'=' -f1 )"
      eval "_thisval=\"\${${_left}}\""
      test -z "${_thisval}" && echo "${_line}" >> "${_tmpfile1}"
   done
   test -f "${_tmpfile1}" && . "${_tmpfile1}" 1>/dev/null 2>&1
   /bin/rm -rf "${_tmpfile1}"
}

dnsisgood() {
   local _ns="${1}"
   local _domain="${2}"
   local _result="$( $( which dig ) @${_ns} +time=3 +tries=1 +short "${_domain}" 2>/dev/null | head -n1 )"
   local _exit="$?"
   debuglev 8 && ferror "ns=${_ns}   result=${_result}   exit=${_exit}"

   ## test zone. this is not for production.
   #case "${_ns}" in
   #   *111*) _result="foo";;
   #   *) _result= ;;
   #esac


   case "${_result}" in
      *'connection timed'*) return 1;;
      *) 
         if test -z "${_result}" || test "${_exit}" -ne 0;
         then
            return 1 # this dns server is not working
         else
            return 0 # all is fine
         fi
         ;;
   esac

}

log() {
   # send to stdout because journald will log it.
   echo "$@"
}

# DEFINE TRAPS

clean_dnskeepalive() {
   #rm -f ${logfile} > /dev/null 2>&1
   [ ] #use at end of entire script if you need to clean up tmpfiles
   rm -f "${lockfile}" "${tmpfile1}"
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
/home/bgstack15/rpmbuild/SOURCES/bgscripts-1.2-9/usr/share/bgscripts/framework.sh
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
. ${frameworkscript} || { echo "$0: framework did not run properly. Aborted." 1>&2; exit 4; }
infile1=
outfile1=
default_conffile=/etc/bgscripts/dnskeepalive.conf
conffile="${default_conffile}"
logfile=${scriptdir}/${scripttrim}.${today}.out
interestedparties="bgstack15@gmail.com"
lockfile="/tmp/.dnskeepalive.lock"
tmpfile1="$( mktemp )"

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
setval 1 bupscript<<EOFBUPSCRIPT
/usr/local/bin/bup
/usr/bin/bup
/usr/local/share/bgscripts/bup.sh
/usr/share/bgscripts/bup.sh
EOFBUPSCRIPT
test "${setvalout}" = "critical-fail" && ferror "${scripttrim}: 4. bup not found. Aborted." && exit 4

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
   test "${conffile}" = "${default_conffile}" || ferror "${scriptfile}: Ignoring conf file which is not found: ${conffile}."
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
      log "Previous instance did not exit cleanly."
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
      # used values: "DNSK_(DELAY|RESOLVCONF|ENABLED|TESTDOMAIN|ONESHOT)" 1>&2
      set | grep -iE "DNSK_" 1>&2
   }
   while test -n "${DNSK_ENABLED}" && fistruthy "${DNSK_ENABLED}";
   do
      bupfile="$( ${bupscript} -d "${DNSK_RESOLVCONF}" | cut -d' ' -f4 )"
      goodorder=
      badorder=

      # collect nameservers
      grep -iE "nameserver" "${DNSK_RESOLVCONF}" 2>/dev/null | sed -r -e 's/nameserver\s*//g;' | xargs > "${tmpfile1}"
      oldorder="$( cat "${tmpfile1}" )"
      ns1="$( cut -d' ' -f1 "${tmpfile1}" )"
      ns2="$( cut -d' ' -f2 "${tmpfile1}" )"
      ns3="$( cut -d' ' -f3 "${tmpfile1}" )"
      ns4="$( cut -d' ' -f4 "${tmpfile1}" )"

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
      neworder="$( echo "${goodorder} ${badorder}" | sed -r -e 's/^ +//g;s/ +$//g;s/ +/ /g;' )"
      if test "${neworder}" = "${oldorder}";
      then
         debuglev 1 && log "no changes required"
      else
         log "changed nameserver priority to: ${neworder}"
         ${bupscript} "${DNSK_RESOLVCONF}" 1>/dev/null 2>&1
         {
            grep -viE "^nameserver " "${DNSK_RESOLVCONF}"
            for word in ${neworder};
            do
               printf "nameserver %s\n" "${word}"
            done
         } > "${tmpfile1}"; cat "${tmpfile1}" > "${DNSK_RESOLVCONF}"; rm -f "${tmpfile1}";
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
