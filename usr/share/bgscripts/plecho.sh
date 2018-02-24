#!/bin/bash
# File: /usr/share/bgscripts/plecho.sh
# Author: bgstack15@gmail.com
# Startdate: 2015-11-20
# Title: Piped Log Echo
# Purpose: Prepends server, timestamp, and user to data including what is piped in
# Package: bgscripts
# History: 2015-12-01 updated to work with stdin no matter ssh or not
#    2016-08-03 made more portable, but the read command depends on /bin/bash
# Usage: echo "bar" | plecho "foo"
# Reference: /test/sysadmin/bin/bgstack15/args/input.sh 2014-05-26a
# Improve: 

# template: [2014-07-08 14:43:45]picard@enterprise "$@"
myplecho() {
   local mplserver=$( hostname -s ); local mplnow=$( date '+%Y-%m-%d %T' )
   while test -z "$1" && test -n "$@"; do shift; done
   local sisko="$@"
   test -z "$sisko" && \
      printf "[%19s]%s@%s\n" "$mplnow" "$USER" "$mplserver" || \
      printf "[%19s]%s@%s: %s\n" "$mplnow" "$USER" "$mplserver" "${sisko#" *"}" ;
}

main() {
   if test ! -t 0; # if piped in any way shape or form
   then
      # could be either piped, ssh+pipe, or just ssh
      read -n0 -t1 mplfirstc mplfirstl; mplpiped=$?
      if test ${mplpiped} -eq 0; # so if there is truly input
      then
         # truly mplpiped
         myplecho "$@" "${mplfirstc}${mplfirstl}"
         while read line 2>/dev/null;
         do
            myplecho "$@" "$line"
         done
      else
         myplecho "$@"
      fi
   else
      myplecho "$@"
   fi
}

main "$@" 
