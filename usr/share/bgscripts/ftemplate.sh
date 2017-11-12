#!/bin/sh
# Filename: SCRIPTNAME
# Location: 
# Author: bgstack15@gmail.com
# Startdate: INSERTLONGDATE
# Title: 
# Purpose: 
# Package: 
# History: 
# Usage: 
# Reference: ftemplate.sh 2017-11-11a; framework.sh 2017-11-11a
# Improve:
fiversion="2017-11-11a"
SCRIPTTRIMversion="INSERTDATEa"

usage() {
   less -F >&2 <<ENDUSAGE
usage: SCRIPTNAME [-duV] [-c conffile]
version ${SCRIPTTRIMversion}
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
ENDUSAGE
}

# DEFINE FUNCTIONS

# DEFINE TRAPS

clean_SCRIPTTRIM() {
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

parseFlag() {
   flag="$1"
   hasval=0
   case ${flag} in
      # INSERT FLAGS HERE
      "d" | "debug" | "DEBUG" | "dd" ) setdebug; ferror "debug level ${debug}";;
      "u" | "usage" | "help" | "h" ) usage; exit 1;;
      "V" | "fcheck" | "version" ) ferror "${scriptfile} version ${SCRIPTTRIMversion}"; exit 1;;
      #"i" | "infile" | "inputfile" ) getval; infile1=${tempval};;
      "c" | "conf" | "conffile" | "config" ) getval; conffile="${tempval}";;
   esac
   
   debuglev 10 && { test ${hasval} -eq 1 && ferror "flag: ${flag} = ${tempval}" || ferror "flag: ${flag}"; }
}

# DETERMINE LOCATION OF FRAMEWORK
while read flocation; do if test -x ${flocation} && test "$( ${flocation} --fcheck )" -ge 20171111; then frameworkscript="${flocation}"; break; fi; done <<EOFLOCATIONS
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

# INITIALIZE VARIABLES
# variables set in framework:
# today server thistty scriptdir scriptfile scripttrim
# is_cronjob stdin_piped stdout_piped stderr_piped sendsh sendopts
. ${frameworkscript} || echo "$0: framework did not run properly. Continuing..." 1>&2
infile1=
outfile1=
logfile=${scriptdir}/${scripttrim}.${today}.out
define_if_new interestedparties "bgstack15@gmail.com"
# SIMPLECONF
define_if_new default_conffile "/etc/SCRIPTTRIM/SCRIPTTRIM.conf"
define_if_new defuser_conffile ~/.config/SCRIPTTRIM/SCRIPTTRIM.conf

# REACT TO OPERATING SYSTEM TYPE
case $( uname -s ) in
   Linux) : ;;
   FreeBSD) : ;;
   *) echo "${scriptfile}: 3. Indeterminate OS: $( uname -s )" 1>&2 && exit 3;;
esac

## REACT TO ROOT STATUS
#case ${is_root} in
#   1) # proper root
#      : ;;
#   sudo) # sudo to root
#      : ;;
#   "") # not root at all
#      #ferror "${scriptfile}: 5. Please run as root or sudo. Aborted."
#      #exit 5
#      :
#      ;;
#esac

# SET CUSTOM SCRIPT AND VALUES
#setval 1 sendsh sendopts<<EOFSENDSH     # if $1="1" then setvalout="critical-fail" on failure
#/usr/local/share/bgscripts/send.sh -hs  # setvalout maybe be "fail" otherwise
#/usr/share/bgscripts/send.sh -hs        # on success, setvalout="valid-sendsh"
#/usr/local/bin/send.sh -hs
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

## LOAD CONFIG FROM SIMPLECONF
## This section follows a simple hierarchy of precedence, with first being used:
##    1. parameters and flags
##    2. environment
##    3. config file
##    4. default user config: ~/.config/script/script.conf
##    5. default config: /etc/script/script.conf
#if test -f "${conffile}";
#then
#   get_conf "${conffile}"
#else
#   if test "${conffile}" = "${default_conffile}" || test "${conffile}" = "${defuser_conffile}"; then :; else test -n "${conffile}" && ferror "${scriptfile}: Ignoring conf file which is not found: ${conffile}."; fi
#fi
#test -f "${defuser_conffile}" && get_conf "${defuser_conffile}"
#test -f "${default_conffile}" && get_conf "${default_conffile}"

# CONFIGURE VARIABLES AFTER PARAMETERS

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
#   :
#else
#   :
#fi

# SET TRAPS
#trap "CTRLC" 2
#trap "CTRLZ" 18
#trap "clean_SCRIPTTRIM" 0

## DEBUG SIMPLECONF
#debuglev 5 && {
#   ferror "Using values"
#   # used values: EX_(OPT1|OPT2|VERBOSE)
#   set | grep -iE "^EX_" 1>&2
#}

# MAIN LOOP
#{
   :
#} | tee -a ${logfile}

# EMAIL LOGFILE
#${sendsh} ${sendopts} "${server} ${scriptfile} out" ${logfile} ${interestedparties}

## STOP THE READ CONFIG FILE
#exit 0
#fi; done; }
