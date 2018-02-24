#!/bin/sh
# Filename: userinfo.sh
# Location: /usr/share/bgscripts/work/userinfo.sh
# Author: bgstack15@gmail.com
# Startdate: 2018-01-03 16:11
# Title: Script that Displays User Info
# Purpose: Displays specific metrics this environment would like to query
# History:
# Usage:
# Reference:
#    id -Gnz https://stackoverflow.com/questions/14059916/is-there-a-command-to-list-all-unix-group-names/29615866#29615866
# Improve:
#    silence the greps when file does not exist
# Document:

# FUNCTIONS
clean_userinfo() {
   rm -rf "${tmpdir:-NOTHINGTODEL}" 1>/dev/null 2>&1
}

fail() {
   local number=$1 ; shift ;
   echo "$@"
   exit "${number}"
}

f_user() {
   printf "%s: %s\n" "user" "${1}"
}

f_getent() {
   local output="$( "${GETENT}" passwd "${user}" 2>/dev/null )"
   if test -z "${output}";
   then
      printf "%s: %s\n" "getent" "NO"
      return 1
   else
      printf "%s: %s\n" "getent" "YES"
      return 0
   fi
}

f_getent_type() {
   local is_files="" ; local is_sss="" ;
   "${GETENT}" passwd -s files "${user}" 1>/dev/null 2>&1 && is_files="files"
   "${GETENT}" passwd -s sss "${user}" 1>/dev/null 2>&1 && is_sss="sss"
   local is="$( echo "${is_files},${is_sss}" | sed -r -e 's/,$//;' -e 's/^,//;' )"
   printf "%s: %s\n" "getent_type" "${is}"
}

f_can_ssh() {
   # Get all ssh access limit strings
   local ssh_limit="$( grep -iE '^\s*allow(groups|users)\s' /etc/ssh/sshd_config 2>/dev/null )"
   local can_ssh=0
   # error if more than one line returned
   local line_count="$( echo -n "${ssh_limit}" | grep -E '.' | wc -l )"
   case "${line_count}" in
      0)
         # no restrictions on ssh
         can_ssh=1
         ;;

      1)
         # check allowusers string
         echo "${ssh_limit}" | grep -qE "AllowUsers\s+.*\<${user}\>" && can_ssh=1

         # check allowgroup string
         if ! test ${can_ssh} -eq 1;
         then
            id -Gnz "${user}" 2>/dev/null | tr '\0' '\n' | sed -r -e 's/^/\\\</;' -e 's/$/\\\>/;' > "${tmpfile1}"
            echo "${ssh_limit}" | grep -E "AllowGroups\s+.*" | grep -qf "${tmpfile1}" && can_ssh=1
         fi
         ;;

      *)
         fail 1 "Invalid ssh config detected. Please check /etc/ssh/sshd_config. Aborted."
         # the fail function will exit, so this return 1 will never actually execute.
         return 1
         ;;

   esac

   if test ${can_ssh} -gt 0 ;
   then
      printf "%s: %s\n" "can_ssh" "YES"
   else
      printf "%s: %s\n" "can_ssh" "NO"
   fi
}

f_can_sss() {
   # determine if sss user
   local can_sss=0
   if f_getent_type | grep -vqE 'sss' ;
   then
      can_sss=2
   else

      # Get all sssd access limit strings
      local sss_limit="$( grep -iE '^\s*simple_allow_(groups|users)\s' /etc/sssd/sssd.conf 2>/dev/null )"

      # error if more than one line returned
      local line_count="$( echo -n "${sss_limit}" | grep -E '.' | wc -l )"
      case "${line_count}" in
         0)
            # no restrictions on sss
            can_sss=1
            ;;

         1)
            # check simple_allow_users string
            echo "${sss_limit}" | grep -qE "simple_allow_users\s+.*\<${user}\>" && can_sss=1

            # check simple_allow_groups string
            if ! test ${can_sss} -eq 1;
            then
               id -Gnz "${user}" 2>/dev/null | tr '\0' '\n' | sed -r -e 's/^/\\\</;' -e 's/$/\\\>/;' > "${tmpfile1}"
               echo "${sss_limit}" | grep -E "simple_allow_groups\s+.*" | grep -q -f "${tmpfile1}" && can_sss=1
            fi
            ;;

         *)
            fail 1 "Invalid sssd config detected. Please check /etc/sssd/sssd.conf. Aborted."
            # the fail function will exit, so this return 1 will never actually execute.
            return 1
            ;;

      esac

   fi

   case "${can_sss}" in
      0)
         printf "%s: %s\n" "can_sss" "NO"
         ;;
      1)
         printf "%s: %s\n" "can_sss" "YES"
         ;;
      *)
         printf "%s: %s\n" "can_sss" "na"
         ;;
   esac

}

# TEMP FILES
tmpdir="$( mktemp -d )"
tmpfile1="$( TMPDIR="${tmpdir}" mktemp )"
logfile="$( TMPDIR="${tmpdir}" mktemp )"
trap 'clean_userinfo ; trap "" 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 ; exit 0 ;' 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20

# GET USERNAME FROM PARAMETERS
user="${1}" ; test -z "${user}" && fail 1 "${0} needs a username provided on the command line. Aborted."

# DEPENDENCIES
GETENT=$( which getent ) ; test -x "${GETENT}" || fail 1 "${0} needs getent. Aborted."

# RUN AS ROOT
test "$( id -u 2>/dev/null )" -eq 0 || fail 1 "${0} must be run as root. Aborted."

# MAIN LOOP
{

   # LEARN AND PRINT INFO
   f_user "${user}"
   f_getent
   f_getent_type
   f_can_ssh
   f_can_sss

} | tee -a "${logfile}"

# EXIT CLEANLY
exit 0
