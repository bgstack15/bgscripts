#!/bin/sh
# Filename: allow-group.sh
# Location: /usr/share/bgscripts/work/
# Author: bgstack15@gmail.com
# Startdate: 2018-04-30 11:32:20
# Title: Script that Allows or Disallows Groups in Sshd and Sssd Configs
# Purpose: To make it easy to allow groups in ssh and sssd
# Package: bgscripts
# History:
# Usage:
# Reference: ftemplate.sh 2018-04-19a; framework.sh 2017-11-11a
# Improve:
# Dependencies:
#    framework.sh
#    modconf.py
#    bgs.py
#    uvlib.py
fiversion="2018-04-19b"
allowgroupversion="2018-05-15a"

usage() {
   ${PAGER:-/usr/bin/less -F} >&2 <<ENDUSAGE
usage: allow-group.sh [-duV] [-v|-s] [-a|--noapply] [-c conffile] [--sshd_config sshd_config] [--sssd_conf sssd.conf] [--all] [--ssh] [--sssd] <--allow|--deny> group1 [ group2 ... ]
version ${allowgroupversion}
 -d debug   Show debugging info, including parsed variables.
 -u usage   Show this usage block.
 -V version Show script version number.
 -v verbose|noverbose|silent Set AG_VERBOSE
 -a apply|noapply  Set AG_APPLY
 -c conf    Read in this config file.
 --all|noall    Aliases of "--ssh --sssd" and "--nossh --nosssd"
 --ssh|nossh    Update sshd config
 --sssd|nosssd  Update sssd config
 --allow|deny   Add or remove the group from the permissions list.
 --sshd_config  Set AG_SSHD_CONFIG_FILE
 --sssd_conf    Set AG_SSSD_CONF_FILE
Environment variables (parameters override environment variables)
AG_ACTION=allow|deny If allow, add group to affected files. If deny, remove group.
AG_SSHD_CONFIG_FILE  Default is /etc/ssh/sshd_config
AG_SSSD_CONF_FILE    Default is /etc/sssd/sssd.conf
AG_SSH        If truthy, affect sshd. Default is yes.
AG_SSSD       If truthy, affect sssd. Default is yes.
AG_APPLY      If truthy, save changes and reload daemons. Default is yes.
AG_VERBOSE    Show the "allow" lines from the config files, regardless of changes that might be made
AG_MODCONF    Location of modconf.py dependency
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

escapize() {
   # call: escapize "${this_group}"
   # goal: find any spaces that do not have a slash in front, and insert a slash.
   local input="${1}"
   echo "${input}" | sed -r -e 's/([^\\]) /\1\\ /g;'

}

evaluate_action() {
   # call: evaluate_action "${AG_ACTION}" "${thisgroup}" "${AG_TMP_SSHD_CONFIG_FILE}" "${AG_TMP_SSSD_CONF_FILE}" "${AG_SSH}" "${AG_SSSD}"
   # Goal: prepare to react to each groupname that is passed in
   debuglev 5 && ferror "evaluate_action \"${1}\" \"${2}\" \"${3}\" \"${4}\" \"${5}\" \"${6}\""

   local this_action="${1}"
   local this_group="${2}"
   local this_sshd_config_file="${3}"
   local this_sssd_conf_file="${4}"
   local this_ssh="${5}"
   local this_sssd="${6}"

   local this_getent_group="$( getent group "${this_group}" )"

   # is group is defined
   if test -z "${this_getent_group}" && test "${this_action}" = "allow" ;
   then
      # warn about this group not existing
      ferror "group ${this_group} is not defined. Skipping."
   fi

   # if ssh=yes then update ssh
   fistruthy "${this_ssh}" && affect_ssh "${this_action}" "${this_group}" "${this_sshd_config_file}"

   # if sssd=yes then update sssd
   fistruthy "${this_sssd}" && affect_sssd "${this_action}" "${this_group}" "${this_sssd_conf_file}"

}

affect_ssh() {
   # call: affect_ssh "${this_action}" "${this_group}" "${this_sshd_config_file}"
   debuglev 6 && ferror "affect_ssh \"${1}\" \"${2}\" \"${3}\""

   local this_action="${1}"
   local this_group="${2}"
   local this_sshd_config_file="${3}"
   local this_var="AllowGroups"
   local this_var_delim=" "
   local this_item_delim=" "

   # escape the space, for the sshd_config
   this_group="$( escapize "${this_group}" )"

   case "${this_action}" in
      deny )
         python "${AG_MODCONF:-/tmp/modconf.py}" "${this_sshd_config_file}" -a --itemdelim "${this_item_delim}" --variabledelim "${this_var_delim}" remove "${this_var}" "${this_group}"
         ;;
      * )
         # nominally "allow" or "permit" but really this is the default action
         python "${AG_MODCONF:-/tmp/modconf.py}" "${this_sshd_config_file}" -a --itemdelim "${this_item_delim}" --variabledelim "${this_var_delim}" add "${this_var}" "${this_group}"
         ;;
   esac

}

affect_sssd() {
   # call: affect_sssd "${this_action}" "${this_group}" "${this_sssd_conf_file}"
   debuglev 6 && ferror "affect_sssd \"${1}\" \"${2}\" \"${3}\""

   local this_action="${1}"
   local this_group="${2}"
   local this_sssd_conf_file="${3}"
   local this_var="simple_allow_groups"
   local this_var_delim="="
   local this_item_delim=", "

   case "${this_action}" in
      deny )
         /usr/share/bgscripts/py/modconf.py "${this_sssd_conf_file}" -a --itemdelim "${this_item_delim}" --variabledelim "${this_var_delim}" remove "${this_var}" "${this_group}"
         ;;
      * )
         # nominally "allow" or "permit" but really this is the default action
         /usr/share/bgscripts/py/modconf.py "${this_sssd_conf_file}" -a --itemdelim "${this_item_delim}" --variabledelim "${this_var_delim}" add "${this_var}" "${this_group}"
         ;;
   esac

}

final_ssh() {
   # goal: react to changing the sshd_config file

   if diff -q "${AG_SSHD_CONFIG_FILE}" "${AG_TMP_SSHD_CONFIG_FILE}" 1>/dev/null 2>&1 ;
   then
      # same
      :
   else
      debuglev 9 && ferror /bin/cp -p "${AG_TMP_SSHD_CONFIG_FILE}" "${AG_SSHD_CONFIG_FILE}"
                           /bin/cp -p "${AG_TMP_SSHD_CONFIG_FILE}" "${AG_SSHD_CONFIG_FILE}"
      debuglev 9 && ferror service sshd reload
                           service sshd reload 1>&2
   fi

}

final_sssd() {
   # goal: react to changing the sssd.conf file

   if diff -q "${AG_SSSD_CONF_FILE}" "${AG_TMP_SSSD_CONF_FILE}" 1>/dev/null 2>&1 ;
   then
      # same
      :
   else
      debuglev 9 && ferror /bin/cp -p "${AG_TMP_SSSD_CONF_FILE}" "${AG_SSSD_CONF_FILE}"
                           /bin/cp -p "${AG_TMP_SSSD_CONF_FILE}" "${AG_SSSD_CONF_FILE}"
      debuglev 9 && ferror service sssd restart
                           service sssd restart 1>&2
   fi

}

# DEFINE TRAPS

clean_allowgroup() {
   # use at end of entire script if you need to clean up tmpfiles
   # rm -f "${tmpfile1}" "${tmpfile2}" 2>/dev/null

   # Delayed cleanup
   if test -z "${FETCH_NO_CLEAN}" ;
   then
      nohup /bin/bash <<EOF 1>/dev/null 2>&1 &
sleep "${AG_CLEANUP_SEC:-300}" ; /bin/rm -r "${AG_TMPDIR:-NOTHINGTODELETE}" 1>/dev/null 2>&1 ;
EOF
   fi
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
      "V" | "fcheck" | "version" ) ferror "${scriptfile} version ${allowgroupversion}"; exit 1;;
      #"i" | "infile" | "inputfile" ) getval; infile1=${tempval};;
      "c" | "conf" | "conffile" | "config" ) getval; conffile="${tempval}";;
      "a" | "apply" ) AG_APPLY=yes ;;
      "noa" | "noapply" | "no-apply" ) AG_APPLY=no ;;
      "v" | "verbose" ) AG_VERBOSE=yes ;;
      "nov" | "noverbose" | "no-verbose" | "quiet" | "q" | "silent" | "s" ) AG_VERBOSE=no ;;
      "all" ) AG_SSH=yes; AG_SSSD=yes ;;
      "noall" | "no-all" | "notall" | "not-all" ) AG_SSH=no; AG_SSSD=no ;;
      "ssh" | "sshd" ) AG_SSH=yes ;;
      "sss" | "sssd" ) AG_SSSD=yes ;;
      "nossh" | "nosshd" | "no-ssh" | "no-sshd" | "notssh" | "notsshd" | "not-ssh" | "not-sshd" ) AG_SSH=no ;;
      "nosss" | "nosssd" | "no-sss" | "no-sssd" | "notsss" | "notsssd" | "not-sss" | "not-sssd" ) AG_SSSD=no ;;
      "sshd_config" ) getval; AG_SSHD_CONFIG_FILE="${tempval}" ;;
      "sssd_conf" | "sssd_config" ) getval; AG_SSSD_CONF_FILE="${tempval}" ;;
      "allow" | "permit" ) AG_ACTION=allow ;;
      "deny" ) AG_ACTION=deny ;;
   esac

   debuglev 10 && { test ${hasval} -eq 1 && ferror "flag: ${flag} = ${tempval}" || ferror "flag: ${flag}"; }
}

# DETERMINE LOCATION OF FRAMEWORK
f_needed=20171111
while read flocation ; do if test -e ${flocation} ; then __thisfver="$( sh ${flocation} --fcheck 2>/dev/null )" ; if test ${__thisfver} -ge ${f_needed} ; then frameworkscript="${flocation}" ; break; else printf "Obsolete: %s %s\n" "${flocation}" "${__this_fver}" 1>&2 ; fi ; fi ; done <<EOFLOCATIONS
./framework.sh
$( pwd )/framework.sh
${scriptdir}/framework.sh
$HOME/bin/bgscripts/framework.sh
$HOME/bin/framework.sh
$HOME/bgscripts/framework.sh
$HOME/framework.sh
/usr/local/bin/bgscripts/framework.sh
/usr/local/bin/framework.sh
/usr/bin/bgscripts/framework.sh
/usr/bin/framework.sh
/bin/bgscripts/framework.sh
/usr/local/share/bgscripts/framework.sh
/usr/share/bgscripts/framework.sh
/tmp/framework.sh
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
define_if_new default_conffile "/tmp/allowgroup.conf"
define_if_new defuser_conffile ~/.config/allowgroup/allowgroup.conf
define_if_new AG_TMPDIR "$( mktemp -d )"
#tmpfile1="$( TMPDIR="${AG_TMPDIR}" mktemp )"
#tmpfile2="$( TMPDIR="${AG_TMPDIR}" mktemp )"

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
setval 1 this_modconf <<EOFMODCONF
/usr/share/bgscripts/py/modconf.py
/tmp/modconf.py
/root/modconf.py
EOFMODCONF
test "${setvalout}" = "critical-fail" && ferror "${scriptfile}: 4. modconf not found. Aborted." && exit 4

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
define_if_new AG_SSHD_CONFIG_FILE /etc/ssh/sshd_config
define_if_new AG_SSSD_CONF_FILE /etc/sssd/sssd.conf
define_if_new AG_SSH yes
define_if_new AG_SSSD yes
define_if_new AG_ACTION allow
define_if_new AG_APPLY yes
define_if_new AG_VERBOSE no

define_if_new AG_TMP_SSHD_CONFIG_FILE "$( TMPDIR="${AG_TMPDIR}" mktemp )"
define_if_new AG_TMP_SSSD_CONF_FILE "$( TMPDIR="${AG_TMPDIR}" mktemp )"

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
trap "__ec=$? ; clean_allowgroup ; trap '' 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 ; exit ${__ec} ;" 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20

# DEBUG SIMPLECONF
debuglev 8 && {
   ferror "Using values"
   # used values: EX_(OPT1|OPT2|VERBOSE)
   set | grep -iE "^AG_" 1>&2
}

# MAIN LOOP
#{

   # prepare initial temporary config files
   if ! test -e "${AG_SSHD_CONFIG_FILE}" && fistruthy "${AG_SSH}" ;
   then
      # skip ssh because its config file is not found
      AG_SSH=no
      ferror "Cannot find ${AG_SSHD_CONFIG_FILE}. Skipping ssh."
   else
      /bin/cat "${AG_SSHD_CONFIG_FILE}" > "${AG_TMP_SSHD_CONFIG_FILE}"
   fi
   if ! test -e "${AG_SSSD_CONF_FILE}" && fistruthy "${AG_SSSD}" ;
   then
      # skip sssd
      AG_SSSD=no
      ferror "Cannot find ${AG_SSSD_CONF_FILE}. Skipping sssd."
   else
      /bin/cat "${AG_SSSD_CONF_FILE}" > "${AG_TMP_SSSD_CONF_FILE}"
   fi

   # Loop over groups
   x=0
   while test ${x} -lt ${thiscount} ;
   do
      x=$(( x + 1 ))
      eval thisgroup="\$opt${x}"
      debuglev 1 && ferror "${AG_ACTION} ${thisgroup}"
      evaluate_action "${AG_ACTION}" "${thisgroup}" "${AG_TMP_SSHD_CONFIG_FILE}" "${AG_TMP_SSSD_CONF_FILE}" "${AG_SSH}" "${AG_SSSD}"
   done

   # show the allow lines if verbose
   if fistruthy "${AG_VERBOSE}" ;
   then
      ferror "After making any changes:"
      grep -iE '^[^#]*simple_allow_groups' "${AG_TMP_SSSD_CONF_FILE}"
      grep -iE '^[^#]*AllowGroups' "${AG_TMP_SSHD_CONFIG_FILE}"
   fi

   # apply changes if necessary
   if fistruthy "${AG_APPLY}" ;
   then
      fistruthy "${AG_SSH}" && final_ssh
      fistruthy "${AG_SSSD}" && final_sssd
   fi

#} | tee -a ${logfile}

# EMAIL LOGFILE
#${sendsh} ${sendopts} "${server} ${scriptfile} out" ${logfile} ${interestedparties}
