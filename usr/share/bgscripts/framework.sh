#!/bin/sh
# File: /usr/share/bgscripts/framework.sh
# Author: bgstack15@gmail.com
# Startdate: 2014-06-02 15:22
# Title: Framework for Common Elements in My Scripts
# Purpose: Library of common script elements
# Package: bgscripts 1.2-18
# History: fv2017-06-08a=fi2017-08-23a
#    2016-02-26a updated and shortened functions!
#    2016-05-25a added thisip and ip address validation
#    2016-07-12a fixed thisos and thisflavor; added thisflavorversion
#    2016-08-03a adding Bourne shell compatibility, for FreeBSD
#    2016-09-14a Added some 2>/dev/null to os-release file checks
#    2016-11-30a fixed wc commands to use stdin so it does not print filename
#    2017-01-11a Beefed up thisos/thisflavor. 
#       Moved whole package to /usr/share/bgscripts.
#    2017-03-11b cleaned up a few comments and swapped out [[ ]] brackets for test
#       Removed mktmpfiles functions. Other miscellaneous fixes.
#       Rewrote fwhich function to use readlink -f
#       Fixed the parameter parsing where it uses echo. It was choking on "-n" because echo uses that.
#    2017-04-17a Cleaned up fwhich. General cleanup of functions
#    2017-06-08a Added tweak to get_conf
# Usage: dot-source this script in ftemplate.sh used by newscript.sh
# Reference: 
# Improve: 
fversion="2017-06-08a"

# DEFINE FUNCTIONS

isflag() {
   # input: $1=word to parse
   case "$1" in
      --*) retval=2;;
      -*) retval=1;;
      *) retval=0;;
   esac
   echo $retval
}

parseParam() {
   # determines if --longname or -shortflagS that need individual parsing
   trimParam=$( printf '%s' "${param}" | sed -n 's/--//p' )
   _rest=
   if test -n "$trimParam";
   then
      parseFlag $trimParam
   else
      #splitShortStrings
      _i=2
      while test ${_i} -le ${#param};
      do
         _j=$( expr ${_i} + 1)
         #_char=$(expr substr "$param" $_i 1)
         #_rest=$(expr substr "$param" $_j 255)
         _char=$( printf '%s' "${param}" | cut -c ${_i})
         _rest=$( printf '%s' "${param}" | cut -c ${_j}-255)
         parseFlag $_char
         _i=$( expr ${_i} + 1)
      done
   fi
}

getval() {
   tempval=
   if test -n "${_rest}";
   then
      tempval="${_rest}"
      hasval=1
      _i=255   # skip rest of splitShortStrings because found the value!
   elif test -n "$nextparam" && test $(isflag "$nextparam") -eq 0;
   then
      tempval="$nextparam"
      hasval=1 #DNE; is affected by ftemplate!
      paramnum=$nextparamnum
   fi
}

debuglev() {
   # call: debuglev 5 && ferror "debug level is at least a five!"
   # added 2015-11-17
   localdebug=0; localcheck=0;
   fisnum ${debug} && localdebug=${debug}
   fisnum ${1} && localcheck=${1}
   test $localdebug -ge $localcheck && return 0 || return 1
}

fisnum() {
   # call: fisnum $1 && debug=$1 || debug=10
   fisnum=;
   case $1 in
      ''|*[!0-9]*) fisnum=1;; # invalid
      *) fisnum=0;; # valid number
   esac
   return ${fisnum}
}

fistruthy() {
   # call: if fistruthy "$val"; then
   local _return=
   case "$( echo "${1}" | tr '[:upper:]' '[:lower:]' )" in
      yes|1|y|true|always) _return=true;;
   esac
   test -n "${_return}"; return $?
}

setval() {
   # call: setval 0 value1 value2 value3 ... <<EOFOPTIONS
   # /bin/foo1 --optforfoo1
   # /usr/bin/foo2 --optforfoo2
   # EOFOPTIONS
   #              ^ 0 = soft fail, 1 = critical-fail
   quitonfail="${1}"; shift
   _vars="${@}"
   #echo "_vars=${_vars}"
   _varcount=0
   for _word in ${_vars}; do _varcount=$( expr $_varcount + 1 ); eval "_var${_varcount}=${_word}"; done
   _usethis=0
   while read line;
   do
      _varcount=0
      if test ! "${_usethis}x" = "0x"; then break; fi
      #echo "line=${line}";
      for _word in ${line};
      do
         _varcount=$( expr $_varcount + 1 )
         #echo "word ${_varcount}=${_word}";
         case "${_varcount}" in
            1)
               #echo "Testing for existence of file ${_word}"
               if test -f "${_word}";
               then
                  _usethis=1
                  #echo "${_var1}=${_word}"
                  eval "${_var1}=${_word}"
               fi
               ;;
            *)
               #echo "just an option: ${_word}"
               if test "${_usethis}x" = "1x";
               then
                  #eval echo "\${_var${_varcount}}=${_word}"
                  eval eval "\${_var${_varcount}}=${_word}"
               fi
               ;;
         esac
      done
   done
   #eval echo "testfile=\$${_var1}"
   eval _testfile=\$${_var1}
   if test ! -f "${_testfile}";
   then
      case "${quitonfail}" in 1) _failval="critical-fail";; *) _failval="fail";; esac
      eval "${_var1}=${_failval}"
      setvalout=${_failval}
   else
      eval setvalout="valid-${_var1}"
   fi
}

flecho() {
   if test "$lechoscript" = ""; #so only run the first time!
   then
      setval 0 lechoscript << EOFLECHOSCRIPTS
./plecho.sh
${scriptdir}/plecho.sh
~/bin/bgscripts/plecho.sh
~/bin/plecho.sh
~/bgscripts/plecho.sh
~/plecho.sh
/usr/local/bin/bgscripts/plecho.sh
/usr/local/bin/plecho.sh
/usr/bin/bgscripts/plecho.sh
/usr/bin/plecho.sh
/usr/bin/plecho
/bin/bgscripts/plecho.sh
/usr/share/bgscripts/plecho.sh
EOFLECHOSCRIPTS
      lechoscriptvalid="${setvalout}"
   fi
   if test "$lechoscriptvalid" = "valid-lechoscript";
   then
      $lechoscript "$@"
   else
      #ORIGINAL echo [`date '+%Y-%m-%d %T'`]$USER@`uname -n`: "$*"
      myflecho() {
         mflnow=$( date '+%Y-%m-%d %T' ) 
         while test -z "$1" && test -n "$@"; do shift; done
         sisko="$@"
         test -z "$sisko" && \
            printf "[%19s]%s@%s\n" "$mflnow" "$USER" "$server" || \
            printf "[%19s]%s@%s: %s\n" "$mflnow" "$USER" "$server" "${sisko#" *"}" ;
      }
      if test ! -t 0; # observe that this is different from plecho
      then
         _x=0
         while read line;
         do
            _x=1
            myflecho "$@" "$line"
         done
         test $_x -eq 0 && myflecho "$@" "$line"
      else
         myflecho "$@"
      fi
   fi
}

fsudo() {
   if test "${myfsudo}" = ""; # so just run first time. Added 2015-07-10
   then
      setval 1 myfsudo myfsudoopts <<EOFSUDO
/usr/local/bin/sudo
/usr/bin/sudo
/bin/sudo
./sudo
EOFSUDO
   fi
   if test -x ${myfsudo};
   then
      ${myfsudo} "$@"
   else
      ferror "$scriptfile: fsudo couldn't find sudo. Adjust framework.sh"
   fi
}

fwhich() {
   # call: fwhich $infile1
   # returns the fqdn of files
   readlink -f "$@"
}

ferror() {
   # call: ferror "$scriptfile: 2. Something bad happened-- error message 2."
   echo "$@" 1>&2
}

linecat() {
   # call: linecat "foo" "bar"
   # output: foobar
   printf "%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s\n" "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" "$9" "${10}" "${11}" "${12}" "${13}" "${14}" "${15}"
}

prepend() { while read prependinput; do linecat "$@" "$prependinput"; done; }
append()  { while read appendinput;  do linecat "$appendinput"  "$@"; done; }

setmailopts() {
   setval 0 sendsh sendopts<<EOFSENDSH
./send.sh -hs
${scriptdir}/send.sh -hs
~/bin/bgscripts/send.sh -hs
~/bin/send.sh -hs
~/bgscripts/send.sh -hs
~/send.sh -hs
/usr/local/bin/bgscripts/send.sh -hs
/usr/local/bin/send.sh -hs
/usr/bin/bgscripts/send.sh -hs
/usr/bin/send.sh -hs
/usr/send.sh -hs
/bin/bgscripts/send.sh -hs
/usr/share/bgscripts/send.sh -hs
/usr/bin/mail -s
EOFSENDSH
}

setdebug() {
   # call: setdebug
   debug=10
   getval
   if test $hasval -eq 1;
   then
      if fisnum ${tempval};
      then
         debug=${tempval}
      else
         #test paramnum -le paramcount && paramnum=$( expr ${paramnum} - 1 )
         hasval=0
      fi
   elif fisnum ${_rest};
   then
      debug=${_rest}
      _i=255
   else
      test $paramnum -le $paramcount && test -z ${nextparam} && paramnum=$( expr ${paramnum} - 1 )
   fi
}

isvalidip() {
   # call: if isvalidip "${input}"; then echo yes; fi
   #   or: isvalidip $input && echo yes
   iptotest="${1}"
   echo "${iptotest}" | grep -qoE "^((25[0-5]|2[0-4][0-9]|1[0-9]{2}|[0-9]{1,2})\.){3}(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[0-9]{1,2})$"
}

get_conf() {
   # call: get_conf "${conffile}"
   local _infile="$1"
   local _tmpfile1="$( mktemp )"
   sed -e 's/^\s*//;s/\s*$//;/^[#$]/d;s/\s*[^\]#.*$//;' "${_infile}" | grep -viE "^$" | while read _line;
   do
      local _left="$( echo "${_line}" | cut -d'=' -f1 )"
      eval "_thisval=\"\${${_left}}\""
      test -z "${_thisval}" && echo "${_line}" >> "${_tmpfile1}"
   done
   test -f "${_tmpfile1}" && { . "${_tmpfile1}" 1>/dev/null 2>&1; debuglev 10 && cat "${_tmpfile1}" 1>&2; }
   /bin/rm -rf "${_tmpfile1}" 1>/dev/null 2>&1
}

define_if_new() {
   # call: define_if_new IFW_IN_LOG_FILE "/var/log/messages"
   eval thisval="\${${1}}"
   test -z "${thisval}" && eval "$1"=\"$2\"
}

# INITIALIZE VARIABLES
#infile1=
#outfile1=
#logfile=
today=$( date '+%Y-%m-%d' )
now=$( date '+%Y-%m-%d %T' )
server=$( hostname -s )
thistty=$( tty )
thisip=$( ifconfig 2>/dev/null | awk '/Bcast|broadcast/{print $2}' | tr -cd '[^0-9\.\n]' | head -n1 )
thisos="$( uname -s )"
# get thisflavor and thisflavorversion. Examples: centos, ubuntu, redhat
if test -f /etc/os-release;
then
   eval thisflavor=$( grep -iE "^\s*ID=" /etc/os-release 2>/dev/null | sed 's/^.*=//;' | tr 'A-Z' 'a-z' )
   eval thisflavorversion=$( grep -iE "^\s*PRETTY_NAME=" /etc/os-release 2>/dev/null | sed -e 's/^.*=//;' | tr -dc '0-9.' )
elif test -f /etc/system-release && test $( wc -l < /etc/system-release 2>/dev/null ) -eq 1;
then
   eval thisflavor=$( awk '{print $1}' < /etc/system-release 2>/dev/null | tr 'A-Z' 'a-z' )
   eval thisflavorversion=$( </etc/system-release sed -e 's/^.*=//;' 2>/dev/null | tr -dc '0-9.' )
else
   if test "${thisos}" = "FreeBSD"; then
      thisflavor="$( uname -i )"; thisflavorversion="$( uname -r )";
   else
      thisflavor="other"
      thisflavorversion="unknown"
   fi
fi
case "${thisos}" in FreeBSD) sed=gsed;; *) sed=sed;; esac

# if framework is dot sourced then $0 will be "-bash" and screw things up
case ${0} in
   "-bash")
      scriptdir="$( pwd )"
      scriptfile="dot-sourced";;
   *)
      scriptdir="$( cd $( dirname ${0} ); pwd )"
      scriptfile="$( basename ${0} | sed 's!/./!/!g;s!\./!!g' )"
      scripttrim="${scriptfile%%.sh}"
      ;;
esac

# SPECIAL RUNTIME-RELATED VARIABLES
thisppid=$( ps -p $$ -o ppid | awk 'NR>1' | tr -d ' ' )
cronpid=$( ps -ef | grep -E "/c[r]on" | grep -vE "grep.*-E.*cron|[0-9]\s*vi " | awk '{print $2}' )
test "$cronpid" = "$thisppid" && is_cronjob=1
test ! -t 0 && stdin_piped=1
test ! -t 1 && stdout_piped=1
test ! -t 2 && stderr_piped=1
test "$( tty 2>&1 )" = "not a tty" && stdin_local=1
test "$USER" = "root" && is_root=1
test -n "$SUDO_USER" && is_root="sudo"

nullflagcount=0
validateparams() {
   # VALIDATE PARAMETERS
   # scroll through all parameters and check for isflag.
   # if isflag, get all flags listed. Also grab param#.
   paramcount=$#
   thiscount=0;thisopt=0;freeopt=0;
   varsyet=0
   paramnum=0
   debug=0
   fallopts=
   while test $paramnum -lt $paramcount;
   do
      paramnum=$( expr ${paramnum} + 1 )
      eval param=\${$paramnum}
      nextparamnum=$( expr ${paramnum} + 1 )
      eval nextparam=\${$nextparamnum}
      case $param in
         "-")
            if test "$varsyet" = "0";
            then
               # first instance marks beginning of flags and parameters.
               #Until then it was the names of variables to fill.
               varsyet=1
            else
               nullflagcount=$( expr ${nullflagcount} + 1 ) #useful for separating flags from something else?
               debuglev 10 && ferror "null flag!" # second instance is null flag.
            fi
            ;;
      esac
      if test -n "$param";
      then 
         # parameter $param exists.
         if test $(isflag $param) -gt 0;
         then
            # IS FLAG
            parseParam
         else
            # IS VALUE
            if test "$varsyet" = "0";
            then
               thisopt=$( expr ${thisopt} + 1 )
               test "${param}" = "DEBUG" && debug=10 && thisopt=$( expr ${thisopt} - 1 ) || \
                  eval "varname${thisopt}=${param}"
                  #varname[${thisopt}]="${param}"
               debuglev 10 && ferror "var \"${param}\" named"
            else
               thiscount=$( expr ${thiscount} + 1 )
               test $thiscount -gt $thisopt && freeopt=$( expr ${freeopt} + 1 )
               #eval ${varname[${thiscount}]:-opt${freeopt}}="\"${param}\""
               eval "thisvarname=\${varname${thiscount}}"
                  test -z "${thisvarname}" && eval "thisvarname=opt${freeopt}"
               eval "${thisvarname}=\"${param}\""
               eval fallopts=\"${fallopts} ${param}\"
               debuglev 10 && ferror "${thisvarname} value: ${param}"
            fi
         fi
      fi
   done
   fallopts="${fallopts# }"
   if debuglev 10;
   then
      ferror "thiscount=$thiscount"
      ferror "fallopts=$fallopts"
      ferror "Framework $fversion"
      ferror "Finput $fiversion"
   fi
}

# PROCEDURAL SECTION ( NOT MAIN HOWEVER; THIS IS STILL LIBRARY )
echo " $@ " | grep -qiE -- "--fcheck" 1>/dev/null 2>&1 && { echo "$fversion" | sed 's/[^0-9]//g;'; } || setmailopts
