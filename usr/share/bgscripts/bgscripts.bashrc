#!/bin/sh
# File: /usr/share/bgscripts/bgscripts.bashrc
# Author: bgstack15
# Startdate: 2013-07-23
# Title: Master Template for ~bgstack15/.profile
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
#    2017-04-19 Added htmlize. Modified to only run if dot-sourced
#    2017-04-29 Added VISUAL and EDITOR.
#    2017-06-28 Added permtitle.
#    2017-07-19 Adjust exit logic on --fcheck to not exit if it was dot-sourced.
#    2017-09-16 Removed legacy stuff intended for 1p2 and added ~/.bcrc
#    2017-11-11 Added FreeBSD support. Moved bounce bash autocompletion out of OS-specific sections into main bashrc.
#    2018-01-06 Update htmlize and lsd. Add xdg-what
#    2018-02-23 Fix htmlize and lsd again
# Usage:
# Reference: https://shreevatsa.wordpress.com/2008/03/30/zshbash-startup-files-loading-order-bashrc-zshrc-etc/
#    https://github.com/bgstack15/deployscripts/blob/master/s1_setname.sh
#    permtitle https://bgstack15.wordpress.com/2017/05/29/edit-terminal-title-from-the-command-line/
# Improve:
pversion="2018-02-23a"
__dot_sourced=1; readlink -f $0 2>/dev/null | grep -qiE "\/usr\/.*share\/bgscripts\/bgscripts\.bashrc" && __dot_sourced=0
echo " $@ " | grep -qiE -- "\s--fcheck\s" 1>/dev/null 2>&1 && echo "${pversion}" | sed 's/[^0-9]//g;' && { test "${__dot_sourced}" = "0" && exit || return; }

if test "${__dot_sourced}" = "0";
then
   echo "Please dot-source this script. Aborted." 1>&2
   exit 1
fi

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
if test "${_noos}" = "0";
then
   test -f "/usr/share/bgscripts/bashrc.d/${thisos}.bashrc" && . "/usr/share/bgscripts/bashrc.d/${thisos}.bashrc"
   test -f "/usr/local/share/bgscripts/bashrc.d/${thisos}.bashrc" && . "/usr/local/share/bgscripts/bashrc.d/${thisos}.bashrc"
fi
if test "${_noflavor}" = "0";
then
   test -f "/usr/share/bgscripts/bashrc.d/${thisflavor}.bashrc" && . "/usr/share/bgscripts/bashrc.d/${thisflavor}.bashrc"
   test -f "/usr/local/share/bgscripts/bashrc.d/${thisflavor}.bashrc" && . "/usr/local/share/bgscripts/bashrc.d/${thisflavor}.bashrc"
fi
unset _noos _noflavor

# REACT TO OS # SIMPLE VARIABLES
case "${thisos}" in
   FreeBSD)
      export PS1="[\u@\h|\$( pwd )]\\$ "
      export PAGER=less
      _lscolorstring="-FG "
      alias sudo="/usr/local/bin/sudo"
      alias vi='vim'
      ;;
   Linux|*)
      export PS1="[\u@\h|\$( pwd )]\\$ "
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
export VISUAL=vi
export EDITOR="$VISUAL"
test -f ~/.bcrc && export BC_ENV_ARGS=~/.bcrc

# SIMPLE ALIASES
alias where='printf "%s\n%s\n" "$( id )" "$( pwd )"'

# SIMPLE FUNCTIONS
unalias ll 1>/dev/null 2>&1
function psg { ps -ef | grep -E "$1" | grep -viE "grep -.*E.* $1"; }
function lsf { ls -l ${_lscolorstring}"$@" | grep '^\-'; }
function lsd { find "${@}" -maxdepth 1 -mindepth 1 -type d -printf '%f\n' | xargs ls -ld ${_lscolorstring} ; }
function ll { ls -l ${_lscolorstring}"$@"; }
function lr { ls ${_lscolorstring}-ltr "$@"; }
function cx { chmod +x "$@"; }
function now { date "+%Y-%m-%d %T"; }
function vir { vi -R "$@"; }
function own { sudo chown ${USER}:"$( id -ng $USER )" "$@"; }
function sshg { ssh -o PreferredAuthentications=gssapi-keyex,gssapi-with-mic  -o PubkeyAuthentication=no -o PasswordAuthentication=no -o GSSAPIAuthentication=yes "$@"; }
function sshk { ssh -o PreferredAuthentications=publickey                     -o PubkeyAuthentication=yes -o PasswordAuthentication=no -o GSSAPIAuthentication=no "$@"; }
function sshp { ssh -o PreferredAuthentications=password,keyboard-interactive -o PubkeyAuthentication=no -o PasswordAuthentication=yes -o GSSAPIAuthentication=no "$@"; }

# COMPLEX FUNCTIONS
function cdmnt {
   cdmntdir=/mnt/scripts
   dirname="$@"; [[ "$dirname" = "now" ]] && dirname="$( date "+%Y-%m" )"
   [[ -d "${cdmntdir}/${dirname}" ]] && cd "${cdmntdir}/${dirname}" || cd ${sdir}
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
   # call: cdnewest [-d] /test/sysadmin/bin/bgstack15
   [[ "${1}" = "-d" ]] && { displayonly=1; shift; } || displayonly=0
   newdir="$( /usr/bin/sudo find "${1:-.}"/* -prune -type d 2>/dev/null | xargs stat -c "%Y %n" 2>/dev/null | sort -nr | head -n 1 | cut -d " " -f 2-; )"
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

htmlize() {
   $( which sed ) -r -e 's/</\xCAlt;/g;' -e 's/>/\xCAgt;/g;' -e 's/\&/\xCAamp;/g;' -e 's/\xCA(lt|gt|amp);/\&\1;/g;' ;
}


permtitle() {
   test -z "${__permtitle_file}" && {
      __permtitle_file="$( mktemp tmp.$$.XXXXX )"
      echo "${PROMPT_COMMAND}" > "${__permtitle_file}"
   }   
   case "${@}" in
      "") 
         export PROMPT_COMMAND="$( cat "${__permtitle_file}" )"
         ;;
      *)
         export PROMPT_COMMAND="printf '\033];%s\007' '$@'"
         ;;  
   esac
}

tty -s 1>/dev/null 2>&1 && ! echo " $@ " | grep -qiE -- "\s--noclear\s" 1>/dev/null 2>&1 && {
   clear
   tty
}

xdg-what() {
   local tf="${1}"
   xdg-mime query default "$( xdg-mime query filetype "${tf}" )"
}

# BASH AUTOCOMPLETION
# for bounce.sh
_bounce_autocomplete() {
   local cur prev words cword;
   _init_completion || return
   _tmpfile1="$( mktemp )"
   case "${prev}" in
      -n|--network)
         _available_interfaces; echo "${COMPREPLY[@]}" > "${_tmpfile1}"
         ;;
      -s|--service)
         _services; echo "${COMPREPLY[@]}" >> "${_tmpfile1}"
         ;;
      -m|--mount)
         awk '$3 ~ /cifs|nfs/{print $2}' /etc/fstab >> "${_tmpfile1}"
         ;;
      *)
         printf -- "-m\n-n\n-s\n--network\n--service\n--mount" >> "${_tmpfile1}"
         ;;
   esac
   COMPREPLY=($( compgen -W "$( cat ${_tmpfile1} )" -- "$cur" ))
   command rm -rf "${_tmpfile1}" 1>/dev/null 2>&1
   return 0
} &&
complete -F _bounce_autocomplete bounce

_pack() {
        # Bash autocompletion for the pack command. This finds the different build goals available in the current pack file.
        local cur prev words cword;
        _init_completion || return
        local thisfile=./pack; test "${cword}" = "1" && printf "${prev}\n" | grep -qE 'pack$' 2>/dev/null && thisfile="${prev}";

        # debugging info
        #local devtty=/dev/pts/2
        #printf "cur=%s\tprev=%s\twords=%s\tcword=%s\n" "${cur}" "${prev}" "${words}" "${cword}" > "${devtty}"
        #printf "${COMP_WORDS}\tCOMPWORD=${COMP_WORD}\n" > "${devtty}"

        # only provide options for the first word
        printf "${prev}\n" | grep -qE "pack$" && \
        COMPREPLY=( $( compgen -W "$( grep -E -- '\s*[[:alpha:]]+\)\s*$' "${thisfile}" | grep -v -E 'unknown' | sed -r -e 's/[^[:alpha:]]//g;' )" -- "${cur}" ) )
        return 0
} &&
complete -F _pack -o default pack

# LOCAL PROFILE IF FOUND
case "${thisos}" in Linux|FreeBSD) [[ -f ~/.bashrc.local ]] && . ~/.bashrc.local;; esac
