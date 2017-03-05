# File: /usr/share/bgscripts/lecho.sh
# Author: bgstack15@gmail.com
# Startdate: 2015-11-20
# Title: Log Echo
# Purpose: Prepends server, timestamp, and user to data
# Package: bgscripts
# History: 
# Usage: lecho "foo"
# Reference: 
# Improve: 

# template: [2014-07-08 14:43:45]picard@enterprise "$@"
mylecho() {
   mlserver=$( hostname -s ); mlnow=$( date '+%Y-%m-%d %T' )
   while test -z "$1" && test -n "$@"; do shift; done
   sisko="$@"
   test -z "$sisko" && \
      printf "[%19s]%s@%s\n" "$mlnow" "$USER" "$mlserver" || \
      printf "[%19s]%s@%s: %s\n" "$mlnow" "$USER" "$mlserver" "${sisko#" *"}" ;
}

mylecho "$@" 
