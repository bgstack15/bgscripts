#!/bin/sh
# File: /usr/share/bgscripts/bgscripts.bashrc
# Author: blg
# Startdate: 2013-07-23
# Title: Master Template for ~bgirton/.profile
# Package: bgscripts
# Purpose: To standardize my shell environments and hold central info
# History: 2014-07-24 updated, cleaned up, organized, etc.
#    2014-08-13 lr=ls -ltr
#    2014-10-14 remmed pipe stuff; I didn't use it
#    2014-10-21 fixed fcheck location in script
#    2015-11-11 fixed psg
#    2015-11-23 making it more linux-friendly
#    2016-02-02 removed bp alias because its a part of bgscripts now
#    2016-05-25 added checking for example.com before adding proxy commands
#    2016-06-06 updated ls aliases to include --color=auto
#    2016-07-26 added initial FreeBSD compatiblity, including ls modifications
#    2016-11-30 added "--noglobalprofile" and "--noclear" options
#    2016-12-01 fixed fcheck
#    2016-12-08 added os and flavor checks
#    2016-12-12 removed cd /mnt/scripts
#    2017-01-02 adding options "--nodeps", "--noos", "--noflavor", "--noproxy"
#    2017-01-10 fixed all options on centos 5, 6 by using \s instead of \B
#    2017-01-17 Fixed location for bgscripts package dependencies
#    2017-03-04 removed proxy options and AIX support for version 1p2
# Usage:
# Reference: https://shreevatsa.wordpress.com/2008/03/30/zshbash-startup-files-loading-order-bashrc-zshrc-etc/
#    https://github.com/bgstack15/deployscripts/blob/master/s1_setname.sh
# Improve:
pversion="2017-03-04a"
echo " $@ " | grep -qiE -- "\s--fcheck\s" 1>/dev/null 2>&1 && echo "${pversion}" | sed 's/[^0-9]//g;' && exit

# DEFINE OS AND FLAVOR
thisos="$( uname -s )"
# get thisflavor and thisflavorversion. Examples: centos, ubuntu, redhat
if test -f /etc/os-release;
then
   eval thisflavor="$( grep -iE "^\s*ID=" /etc/os-release 2>/dev/null | sed 's/^.*=//;' | tr 'A-Z' 'a-z' )"
   eval thisflavorversion="$( grep -iE "^\s*PRETTY_NAME=" /etc/os-release 2>/dev/null | sed -e 's/^.*=//;' | tr -dc '0-9.' )"
elif test -f /etc/system-release && test $( wc -l < /etc/system-release 2>/dev/null ) -eq 1;
then
   eval thisflavor="$( awk '{print $1}' < /etc/system-release 2>/dev/null | tr 'A-Z' 'a-z' )"
   eval thisflavorversion="$( </etc/system-release sed -e 's/^.*=//;' 2>/dev/null | tr -dc '0-9.' )"
else
   if test "${thisos}" = "FreeBSD"; then
      thisflavor="$( uname -i )"; thisflavorversion="$( uname -r )";
   else
      thisflavor="other"
      thisflavorversion="unknown"
   fi
fi

# GLOBAL PROFILE
! echo " $@ " | grep -qiE -- "\s--noglobalprofile\s" 1>/dev/null 2>&1 && case "${thisos}" in Linux) [[ -f /etc/bashrc ]] && . /etc/bashrc;; esac

# OS AND FLAVOR PROFILE
_noos=0; _noflavor=0;
echo " $@ " | grep -qiE -- "\s--nodeps" 1>/dev/null 2>&1 && { _noos=1; _noflavor=1; }
echo " $@ " | grep -qiE -- "\s--noos" 1>/dev/null 2>&1 && _noos=1
echo " $@ " | grep -qiE -- "\s--noflavor" 1>/dev/null 2>&1 && _noflavor=1
test "${_noos}" = "0" && test -f "/usr/share/bgscripts/bashrc.d/${thisos}.bashrc" && . "/usr/share/bgscripts/bashrc.d/${thisos}.bashrc"
test "${_noflavor}" = "0" && test -f "/usr/share/bgscripts/bashrc.d/${thisflavor}.bashrc" && . "/usr/share/bgscripts/bashrc.d/${thisflavor}.bashrc"
unset _noos _noflavor

# REACT TO OS # SIMPLE VARIABLES
case "${thisos}" in
   FreeBSD)
      export PATH=/mnt/scripts:${PATH}
      export PS1="[\u@\h|\$( pwd )]\\$ "
      export PAGER=less
      _lscolorstring="-FG "
      export sdir=/mnt/scripts
      alias sudo="/usr/local/bin/sudo"
      alias vi='vim'
      ;;
   Linux|*)
      export PATH=/mnt/scripts:${PATH}
      export PS1="[\u@\h|\$( pwd )]\\$ "
      export sdir=/mnt/scripts
      alias sudo="/usr/bin/sudo"
      disownstring="disown"
      _lscolorstring="-F --color=auto "
      ;;
esac

[[ -s "$MAIL" ]] && echo "$MAILMSG"

# SIMPLE VARIABLES
SERVER="$( hostname -s )"
set -o vi
export today="$( date '+%Y-%m-%d' )"

# SIMPLE ALIASES
alias where='printf "%s\n%s\n" "$( id )" "$( pwd )"'

# SIMPLE FUNCTIONS
unalias ll 1>/dev/null 2>&1
function psg { ps -ef | grep -E "$1" | grep -viE "grep -.*E.* $1"; }
function lsf { ls -l ${_lscolorstring}"$@" | grep '^\-'; }
function lsd { ls -l ${_lscolorstring}"$@" | grep '^d'; }
function ll { ls -l ${_lscolorstring}"$@"; }
function lr { ls ${_lscolorstring}-ltr "$@"; }
function cx { chmod +x "$@"; }
function now { date "+%Y-%m-%d %T"; }
function vir { vi -R "$@"; }
function own { sudo chown ${USER}:"$( id -ng $USER )" "$@"; }

# COMPLEX FUNCTIONS
function cdmnt {
   cdmntdir=/mnt/scripts
   dirname="$@"; [[ "$dirname" = "now" ]] && dirname="$( date "+%Y-%m" )"
   [[ -d "${cdmntdir}/${dirname}" ]] && cd "${cdmntdir}/${dirname}" || cd ${sdir}
}
function dsmci {
   #Tivoli TSM one-liner for when a backup failed overnight (oneliner)
   echo "i\nquit" | sudo dsmc; exit
}
function newest {
   # call: newest . filename
   # newest is complete tree navigation inside $searchdir
   [[ ! "$1" = "" ]] && searchdir="$1" || searchdir="."
   [[ ! "$2" = "" ]] && searchstring="$2" || searchstring="*"
   find $searchdir -name "*$searchstring*" 2>/dev/null | xargs ls -t 2>/dev/null | head -n 1 ;
}
function newer {
   # call: newer . filename
   # newer is max-depth=1
   [[ ! "$1" = "" ]] && searchdir="$1" || searchdir="."
   [[ ! "$2" = "" ]] && searchstring="$2"
   olddir="$( pwd )"
   cd $searchdir 2>/dev/null
   errnum=$?
   [[ ! "$errnum" = "0" ]] && break
   find . ! -name . -prune -name "*$searchstring*" 2>/dev/null | xargs ls -t 2>/dev/null | head -n 1 | sed "s!\.\/!$searchdir\/!;s!\/\/!/!g;" ;
   cd $olddir
}
function cdnewest {
   # call: cdnewest [-d] /test/sysadmin/bin/bgirton
   [[ "${1}" = "-d" ]] && { displayonly=1; shift; } || displayonly=0
   newdir="$( /usr/bin/sudo find "${1:-.}"/* -prune -type d 2>/dev/null | xargs /opt/freeware/bin/stat -c "%Y %n" 2>/dev/null | sort -nr | head -n 1 | cut -d " " -f 2-; )"
   [[ "${displayonly}" = "0" ]] && cd ${newdir} || {
      whichdir="$( cd $( dirname "${newdir}" ); pwd )"
      echo "${whichdir}/$( basename "${newdir##./}" )"
   }
}
function ccat {
   for word in "$@"
   do
      cat "$@" | highlight -O ansi
   done
}

tty -s 1>/dev/null 2>&1 && ! echo " $@ " | grep -qiE -- "\s--noclear\s" 1>/dev/null 2>&1 && {
   clear
   tty
}

# LOCAL PROFILE IF FOUND
case "${thisos}" in Linux|FreeBSD) [[ -f ~/.bashrc.local ]] && . ~/.bashrc.local;; esac

# CD
#[[ -d "${sdir}" ]] 2>/dev/null && cd "${sdir}" 2>/dev/null
