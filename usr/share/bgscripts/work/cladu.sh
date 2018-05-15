#!/bin/sh
# Filename: cladu.sh
# Location: /usr/share/bgscripts/work/
# Author: bgstack15@gmail.com
# Startdate: 2018-03-09 09:35:31
# Title: Script that Converts Local User to AD User
# Purpose: To facilitate removing local users in favor of domain users
# Package: bgscripts-core
# History: 
# Usage: 
# Reference: ftemplate.sh 2017-11-11m; framework.sh 2017-11-11m
# Improve:
#    Add domain user back into the local groups. It was a design decision to skip that.
# Dependencies:
#    framework
#    userinfo.sh
#    send.sh (optional)
fiversion="2017-11-11m"
claduversion="2018-03-09a"

usage() {
   less -F >&2 <<ENDUSAGE
usage: cladu.sh [-duV] [-gr] [--ng] [--nr] user1 [ user2 user3 ... ]
version ${claduversion}
 -d debug   Show debugging info, including parsed variables.
 -u usage   Show this usage block.
 -V version Show script version number.
 -g groups  Add the AD user to the local groups of the local user. Default is to skip this action.
 --ng       Do not perform the -g action
 -r --report  Generate report in each user homedir.
 --nr       Do not perform the -r action
 -e x@y.z   Send summary report to specified email addresses (comma-delimited). Default is ${CLADU_EMAIL_ADDRESS}.
Environment variables:
Parameters override environment variables
CLADU_USERINFO_SCRIPT=/usr/share/bgscripts/work/userinfo.sh
CLADU_USER_REPORT    any truthy value will perform the -r action. Default is YES.
CLADU_USER_REPORT_FILENAME=converted.txt    File to save report to in each homedir
CLADU_GROUPS  any non-null value will perform the -g action.
CLADU_EMAIL   any truthy value will perform the -e action
CLADU_EMAIL_ADDRESS   destination emails (comma-delimited)
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
remove_user() {
   # call: remove_user ${tu}
   debuglev 9 && ferror "remove_user ${@}"
   local tu="${1}"

   # GET USERINFO PARTS
   local tuinfo="$( ${CLADU_USERINFO_SCRIPT} "${tu}" 2>/dev/null )"

   # CONFIRM USER EXISTS AS LOCAL USER
   echo "${tuinfo}" | grep -qE "getent_type:.*files" || { echo "${tu} Skipped: not found as local user" ; return 1 ; }
   local tu_local="$( getent passwd -s files "${tu}" )"
   local tluid="$( echo "${tu_local}" | awk -F':' '{print $3}' )"

   # CONFIRM USER EXISTS AS DOMAIN USER
   echo "${tuinfo}" | grep -qE "getent_type:.*sss" || { echo "${tu} Failed: not found as domain user" ; return 2 ; }
   local tu_domain="$( getent passwd -s sss "${tu}" )"
   local tduid="$( echo "${tu_domain}" | awk -F':' '{print $3}' )"

   # LEARN HOMEDIRS
   local tu_lhomedir="$( echo "${tu_local}" | cut -d':' -f6 )"
   local tu_dhomedir="$( echo "${tu_domain}" | cut -d':' -f6 )"

   # LEARN LOCAL GROUPS OF LOCAL USER
   local tu_these_local_groups="$( grep -iE ":${tu}(\s*$|,)|:.*,${tu}" /etc/group 2>/dev/null | cut -d':' -f1 | xargs )"

   # LEARN DOMAIN USER PRIMARY GROUP
   local tu_dgroup="$( getent group -s sss "$( getent passwd -s sss "${tu}" | cut -d':' -f4 )" | cut -d':' -f1 )"

   # LEARN IF USER CAN SSSD
   echo "${tuinfo}" | grep -qE "can_sss:.*YES" || { echo "${tu} Failed: not authorized in sssd" ; return 2 ; }

   # DELETE LOCAL USER
   userdel "${tu}" ; local result=$?

   # ADD DOMAIN USER TO LOCAL GROUPS
   if test -n "${CLADU_GROUPS}" && test -n "${tu_these_local_groups}" ;
   then
      usermod -a -G "$( printf "${tu_these_local_groups}" | tr '[[:space:]]' ',' )" "${tu}"
   fi

   # REPORT STATUS
   case "${result}" in
      0)
         local message="${tu} Succeeded: uid ${tluid} to ${tduid}."

         # LIST LOCAL GROUPS OF OLD LOCAL USER
         # if there were local groups to react to
         if test -n "${tu_these_local_groups}" ;
         then
            if test -z "${CLADU_GROUPS}" ;
            then
               # if we were supposed to skip adding user to grouops
               message="${message} You might need to manually re-add user to local groups: ${tu_these_local_groups}"
            else
               # we went ahead and added the user to local groups
               message="${message} Added back to local groups: ${tu_these_local_groups}"
            fi
         fi

         echo "${message}"
         ;;
      8) 
         echo "${tu} Failed: user currently logged in" ; return 2
         ;;
      *) 
         echo "${tu} Failed: userdel returned code ${result}. Please update ${scriptfile} with new error code option." ; return 2
         ;;
   esac

   # MOVE HOMEDIR TO NEW HOMEDIR
   if test "${tu_lhomedir}" != "${tu_dhomedir}" ;
   then
      if test -d "${tu_dhomedir}" ;
      then
         # fail silently. We will just leave the old homedir in place.
         :
      else
         mv "${tu_lhomedir}" "${tu_dhomedir}" &
      fi
   else
      # no change required.
      :
   fi

   # CHANGE OWNERSHIP OF FILES
   find "${tu_dhomedir}" -exec chown "${tu}.${tu_dgroup}" {} +
   
   # GENERATE REPORT FOR USER
   if fistruthy "${CLADU_USER_REPORT}" ;
   then
      local tf="${tu_dhomedir}/${CLADU_USER_REPORT_FILENAME}"
      touch "${tf}" ; chown "${tu}.${tu_dgroup}" "${tf}" ; chmod 0640 "${tf}"
      {
         date -u "+%FT%TZ"
         echo "User ${tu} (${tluid}) converted to AD account (${tduid}) on host ${server}."
         echo "Previous local groups: ${tu_these_local_groups}"
      } > "${tf}"
   fi

}

# DEFINE TRAPS

clean_cladu() {
   # use at end of entire script if you need to clean up tmpfiles
   rm -f "${logfile}" "${tmpfile}" 1>/dev/null 2>&1
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
      "V" | "fcheck" | "version" ) ferror "${scriptfile} version ${claduversion}"; exit 1;;
      #"i" | "infile" | "inputfile" ) getval; infile1=${tempval};;
      #"c" | "conf" | "conffile" | "config" ) getval; conffile="${tempval}";;
      "g" | "group" | "groups" ) CLADU_GROUPS="YES";;
      "ng" | "nogroup" | "no-group" | "no-groups" | "nogroups" ) unset CLADU_GROUPS;;
      "r" | "report" | "reports" | "userreport" | "userreports" | "user-report" | "user-reports" ) CLADU_USER_REPORT="YES";;
      "nr" | "noreport" | "no-report" | "noreports" | "no-reports" | "nouserreport" | "no-userreport" | "nouserreports" | "no-userreports" | "nouser-report" | "no-user-report" | "nouser-reports" | "no-user-reports" ) unset CLADU_USER_REPORT;;
      "e" ) CLADU_EMAIL="YES" ; getval; test -n "${tempval}" && CLADU_EMAIL_ADDRESS="${tempval}" ;;
      "ne" | "noemail" | "nosummary" | "no-email" | "no-summary" ) unset CLADU_EMAIL ;;
   esac
   
   debuglev 10 && { test ${hasval} -eq 1 && ferror "flag: ${flag} = ${tempval}" || ferror "flag: ${flag}"; }
}

# DETERMINE LOCATION OF FRAMEWORK
while read flocation; do if test -e ${flocation} && test "$( sh ${flocation} --fcheck 2>/dev/null )" -ge 20171111; then frameworkscript="${flocation}"; break; fi; done <<EOFLOCATIONS
./framework.sh
/tmp/framework.sh
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
logfile="$( mktemp )"
tmpfile="$( mktemp )"
test -z "${CLADU_USERINFO_SCRIPT}" && CLADU_USERINFO_SCRIPT=/usr/share/bgscripts/work/userinfo.sh
test -z "${CLADU_USER_REPORT_FILENAME}" && CLADU_USER_REPORT_FILENAME=converted.txt
test -z "${CLADU_USER_REPORT}" && CLADU_USER_REPORT="YES"
test -z "${CLADU_EMAIL}" && CLADU_EMAIL="YES"
define_if_new CLADU_EMAIL_ADDRESS "bgstack15@gmail.com"
# SIMPLECONF
define_if_new default_conffile "/etc/cladu/cladu.conf"
define_if_new defuser_conffile ~/.config/cladu/cladu.conf

# REACT TO OPERATING SYSTEM TYPE
case $( uname -s ) in
   Linux) : ;;
   FreeBSD) : ;;
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
      :
      ;;
esac

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
trap "clean_cladu" 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20

## DEBUG SIMPLECONF
debuglev 5 && {
   ferror "Using values"
   # used values: EX_(OPT1|OPT2|VERBOSE)
   set | grep -iE "^CLADU_" 1>&2
}

# MAIN LOOP
{
   # loop through each user
   x=0
   while test $x -lt ${thiscount} ;
   do
      x=$(( x + 1 ))
      eval tu=\"\${opt${x}}\"
      remove_user "${tu}" 
      # RECORD RESULT
      case $? in
         0) echo "SUCCESS" >> "${tmpfile}" ;; 
         1) echo "SKIPPED" >> "${tmpfile}" ;; 
         *) echo "FAILED" >> "${tmpfile}" ;;
      esac
   done

} | tee -a ${logfile}

if fistruthy "${CLADU_EMAIL}" ;
then
   # PREPARE SUBJECT LINE
   succeeded="$( grep -cE "SUCCESS" "${tmpfile}" 2>/dev/null )"
   skipped="$( grep -cE "SKIPPED" "${tmpfile}" 2>/dev/null )"
   failed="$( grep -cE "FAILED" "${tmpfile}" 2>/dev/null )"
   this_subject="CLADU: ${server}, ${succeeded} converted"
   test ${skipped} -gt 0 && this_subject="${this_subject}, ${skipped} skipped"
   test ${failed} -gt 0 && this_subject="${this_subject}, ${failed} failed"

   # PREPARE CLADU_EMAIL_ADDRESS
   CLADU_EMAIL_ADDRESS="$( echo "${CLADU_EMAIL_ADDRESS}" | tr ',' ' ' )"

   # EMAIL LOGFILE
   ${sendsh} -f "${USER}@${server}" ${sendopts} "${this_subject}" ${logfile} ${CLADU_EMAIL_ADDRESS}
fi
