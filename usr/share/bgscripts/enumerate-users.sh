#!/bin/sh
# File: enumerate-users.sh
# Location: /usr/share/bgscripts/work/enumerate-users.sh
# Author: bgstack15
# Startdate: 2018-02-19
# Title: Script that Enumerates Users or Homedirs
# Purpose: For user- or homedir-based activities during package installations
# History:
#    2018-02-19 Originally written for irfan-rpm
# Usage:
#    for user in $( /usr/share/bgscripts/enumerate-users.sh ) ;
#    for user in $( /usr/share/bgscripts/enumerate-users.sh homedir ) ;
# Reference:
# Improve:
# Documentation:
#    This script outputs one per line: list of all known users, or alternatively all home directories
outputtype="${1}"
sssd_cache=/var/lib/sss/mc/passwd

case "${outputtype}" in
   homedir) col=6;; # homedir
   *) col=1;;       # user
esac

{

   # list all local objects
   getent passwd | awk -F':' -v "col=${col}" '$7 !~/nologin|shutdown|halt|sync/{print $col}' ;

   # list all domain objects
   strings "${sssd_cache}" | while read word ;
   do 
      case "${col}" in
         6) test -d "${word}" && echo "${word}" ;;
         *) getent passwd "${word}" | awk -F':' -v "col=${col}" '$7 !~/nologin|shutdown|halt|sync/{print $col}' ;;
      esac
   done

} 2>/dev/null | sort | uniq
