#!/bin/sh
# Filename: host-bup.sh
# Location: 
# Author: bgstack15@gmail.com
# Startdate: 2017-05-24 19:51:55
# Title: Script that Bups Configs on a Host
# Purpose: To provide a single conf and command for backing up important conf files
# Package: bgscripts
# History: 
# Usage: host-bup
# Reference: ftemplate.sh 2017-05-24a; framework.sh 2017-05-24a
# Improve:
fiversion="2017-05-24a"
hostbupversion="2017-05-24a"

usage() {
   less -F >&2 <<ENDUSAGE
usage: host-bup.sh [-duV] [-c conffile]
version ${hostbupversion}
 -d debug   Show debugging info, including parsed variables.
 -u usage   Show this usage block.
 -V version Show script version number.
 -c conf    Select conf file. Default is ${conffile}.
 -n dryrun  Only perform debugging. Do not execute scripts or build tgz.
 -f force   Ignore hostname mismatch.
host-bup.sh is designed to easily bup the config files on a host.
Debug level 5 and above will not execute the script_1_cmd values.
Return values:
0 Normal
1 Help or version info displayed
2 Hostname mismatch
3 Incorrect OS type
4 Unable to find dependency
5 Not run as root or sudo
ENDUSAGE
}

# DEFINE FUNCTIONS

# DEFINE TRAPS

clean_hostbup() {
   rm -f ${tmpfile1} > /dev/null 2>&1
   [ ] #use at end of entire script if you need to clean up tmpfiles
}

CTRLC() {
   #trap "CTRLC" 2
   [ ] #useful for controlling the ctrl+c keystroke
   clean_hostbup
   trap '' 0; exit
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
      "V" | "fcheck" | "version" ) ferror "${scriptfile} version ${hostbupversion}"; exit 1;;
      #"i" | "infile" | "inputfile" ) getval;infile1=${tempval};;
      "c" | "conffile" | "conf" ) getval; conffile="${tempval}";;
      "n" | "dry" | "dryrun" ) HOSTBUP_DRYRUN=1;;
      "f" | "force" ) HOSTBUP_FORCE=1;;
   esac
   
   debuglev 10 && { test ${hasval} -eq 1 && ferror "flag: ${flag} = ${tempval}" || ferror "flag: ${flag}"; }
}

# DETERMINE LOCATION OF FRAMEWORK
while read flocation; do if test -x ${flocation} && test "$( ${flocation} --fcheck )" -ge 20170524; then frameworkscript="${flocation}"; break; fi; done <<EOFLOCATIONS
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
tmpfile1="$( mktemp )"
logfile=${scriptdir}/${scripttrim}.${today}.out
define_if_new interestedparties "bgstack15@gmail.com"
# SIMPLECONF
define_if_new default_conffile "/etc/installed/host-bup.conf"
conffile="${default_conffile}"

# REACT TO OPERATING SYSTEM TYPE
case $( uname -s ) in
   Linux) [ ];;
   FreeBSD) [ ];;
   *) echo "${scriptfile}: 3. Indeterminate OS: $( uname -s )" 1>&2 && exit 3;;
esac

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
validateparams - "$@"

# CONFIRM TOTAL NUMBER OF FLAGLESSVALS IS CORRECT
#if test ${thiscount} -lt 2;
#then
#   ferror "${scriptfile}: 2. Fewer than 2 flaglessvals. Aborted."
#   exit 2
#fi

# CONFIGURE VARIABLES AFTER PARAMETERS

# GET CONFIG custom for host-bup
if ! test -f "${conffile}";
then
   ferror "${scripttrim}: 4. Cannot find conffile ${conffile}. See example at /usr/share/bgscripts/docs/host-bup.conf.example. Aborted."
   exit 4
fi

## START READ CONFIG FILE TEMPLATE
oIFS="${IFS}"; IFS="$( printf '\n' )"
infiledata=$( ${sed} ':loop;/^\/\*/{s/.//;:ccom;s,^.[^*]*,,;/^$/n;/^\*\//{s/..//;bloop;};bccom;}' "${conffile}") #the crazy sed removes c style multiline comments
IFS="${oIFS}"; infilelines=$( echo "${infiledata}" | wc -l )
{ echo "${infiledata}"; echo "ENDOFFILE"; } | {
   while read line; do
   # the crazy sed removes leading and trailing whitespace, blank lines, and comments
   if test ! "${line}" = "ENDOFFILE";
   then
      line=$( echo "${line}" | sed -e 's/^\s*//;s/\s*$//;/^[#$]/d;s/\s*[^\]#.*$//;' )
      if test -n "${line}";
      then
         debuglev 8 && ferror "line=\"${line}\""
         if echo "${line}" | grep -qiE "\[.*\]";
         then
            # new zone
            zone=$( echo "${line}" | tr -d '[]' | tr ':' '_' )
            debuglev 7 && ferror "zone=${zone}"
         else
            # directive
            varname=$( echo "${line}" | awk -F= '{print $1}' )
            varval=$( echo "${line}" | awk -F= '{$1=""; printf "%s", $0}' | sed 's/^ //;' )
            case "${zone}" in
               hostbup_main)
                  debuglev 7 && ferror "${zone}_${varname}=\"${varval}\""
                  # simple define variable
                  eval "${zone}_${varname}=\${varval}"
                  ;;
               hostbup_files)
                  debuglev 7 && ferror "${varname}"
                  echo "${varname}" >> "${tmpfile1}"
                  ;;
               *) # officially ignore it
                  :
                  ;;
            esac
         fi
         ## this part is untested
         #read -p "Please type something here:" response < ${thistty}
         #echo "${response}"
      fi
   else

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
trap "clean_hostbup" 0

eval hostbup_main_tar_out_file="${hostbup_main_tar_out_file}"

# DEBUG SIMPLECONF
debuglev 5 && {
   ferror "Using values:"
   # used values: EX_(OPT1|OPT2|VERBOSE)
   set | grep -iE "^hostbup" 1>&2
   ferror "Back up files:"
   cat "${tmpfile1}" 1>&2
}
define_if_new HOSTBUP_DRYRUN "${hostbup_main_dryrun}"

# MAIN LOOP
#{

   # Check against hostname
   if ! test "$( hostname --fqdn )" = "${hostbup_main_hostname}";
   then
      if ! test "${HOSTBUP_FORCE}";
      then
         ferror "${scripttrim}: 2. Current hostname $( hostname --fqdn ) does not match conffile hostname ${hostbup_main_hostname}."
         ferror "Override this with the --force option. Aborted."
         exit 2
      fi
   fi

   # Show if dry run
   fistruthy "${HOSTBUP_DRYRUN}" && ferror "Dry run"
   # Execute pre scripts
   x=0; _shown=0
   while test $x -lt "${hostbup_main_script_count}";
   do
      x=$(( x + 1 ))
      eval thiscommand="\${hostbup_main_script_${x}_cmd}"
      debuglev 5 && {
         test "${_shown}" = "0" && { ferror "Commands to run:"; _shown=1; }
         ferror "${thiscommand}"
      }
      ! fistruthy "${HOSTBUP_DRYRUN}" && eval ${thiscommand}
   done

   # Tarball everything
   debuglev 1 && echo tar -zcf "${hostbup_main_tar_out_file}" -C / $( cat "${tmpfile1}" )
   ! fistruthy "${HOSTBUP_DRYRUN}" && { {
      tar -zcf "${hostbup_main_tar_out_file}" --ignore-failed-read -C / $( cat "${tmpfile1}" ) 2>&1 1>&3
   } | grep -viE "tar: Removing leading ." 1>&2; } 3>&1
   [ ]
#} | tee -a ${logfile}

# EMAIL LOGFILE
#${sendsh} ${sendopts} "${server} ${scriptfile} out" ${logfile} ${interestedparties}

# STOP THE READ CONFIG FILE
exit 0
fi; done; }
