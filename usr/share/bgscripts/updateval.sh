#!/bin/sh
# File: /usr/share/bgscripts/updateval.sh
# Author: bgstack15@gmail.com
# Startdate: 2016-08-01
# Title: Script that Updates/Adds Value
# Purpose: Allows idempotent and programmatic modifications to config files
# Package: bgscripts
# History:
#    2016-09-14 added this file to bgscripts package
# Usage:
#   updateval.sh /etc/rc.conf "^ntpd_enable=.*" 'ntpd_enable="YES"' --apply
#    Will look for the first, regex string in file /etc/rc.conf, and if it finds it, it will replace it with the second string. If it does not find the first string, it will append the second string to the file
# Reference:
#    "Building the FreeBSD 10.3 Template.docx"
# Improve:
#    Rebuild using framework possibly
infile="${1}"
searchstring="${2}"
destinationstring="${3}"
doapply="${4}"
tmpfile="$( mktemp )"
lineexists=0

#determine sed command
case "$( uname -s )" in
   FreeBSD) sedcommand=gsed; formatstring="-f %p";;
   Linux|*) sedcommand=sed; formatstring="-c %a";;
esac

linenum=$( awk "/${searchstring}/ { print FNR; }" "${infile}" )
for word in ${linenum};
do
   if test -n "${word}" && test ${word} -ge 0;
   then
      # line number is valid
      lineexists=1
      if test "${doapply}" = "--apply";
      then
         $sedcommand -i -e "s/${searchstring}/${destinationstring}/;" ${infile}
      else
         $sedcommand -e "s/${searchstring}/${destinationstring}/;" ${infile}
      fi
   fi
done
if test "${lineexists}x" = "0x";
then
   # must add the value
   if test "${doapply}" = "--apply";
   then
      { cat "${infile}"; printf "${destinationstring}\n"; } > ${tmpfile}
      _perms=$( stat ${formatstring} "${infile}" | tail -c5 )
      mv "${tmpfile}" "${infile}"
      chmod "${_perms}" "${infile}"
   else
      { cat "${infile}"; printf "${destinationstring}\n"; }
   fi
fi
