#!/bin/sh
# File: /usr/share/bgscripts/shares.sh
# Author: bgstack15@gmail.com
# Startdate: 2017-04-03 10:29:32
# Title: Script that Remounts Network Mounts
# Purpose: To revitalize network shares that might have gone stale
# Package: 
# History: 
#    2017-04-16 Added >/dev/null to umount and mount commands
# Usage: 
# Reference: ftemplate.sh 2017-01-11a; framework.sh 2017-01-11a
# Improve:
fiversion="2017-01-17a"
sharesversion="2017-04-04a"

usage() {
   less -F >&2 <<ENDUSAGE
usage: shares.sh [-duV] [-r|-k] [-a] [-t <type>] [/mounted/directory [ ... ]]
version ${sharesversion}
 -d debug   Show debugging info, including parsed variables.
 -u usage   Show this usage block.
 -V version Show script version number.
 -r remount Remount shares
 -k keepalive Touch shares to keep them from timing out
 -a all     All shares. Can be limited with -t. Default behavior if no directories provided.
 -t <type>  Only this type of share. Needs -a flag.
Return values:
0 Normal
1 Help or version info displayed
2 Invalid input options
3 Incorrect OS type
4 Unable to find dependency
5 Not run as root or sudo
ENDUSAGE
}

# DEFINE FUNCTIONS

# DEFINE TRAPS

clean_shares() {
   rm -f ${tempfile1} > /dev/null 2>&1
   #use at end of entire script if you need to clean up tmpfiles
}

CTRLC() {
   #trap "CTRLC" 2
   #useful for controlling the ctrl+c keystroke
   clean_shares
}

CTRLZ() {
   #trap "CTRLZ" 18
   [ ] #useful for controlling the ctrl+z keystroke
}

parseFlag() {
   flag="$1"
   hasval=0
   case ${flag} in
      # INSERT FLAGS HERE
      "d" | "debug" | "DEBUG" | "dd" ) setdebug; ferror "debug level ${debug}";;
      "u" | "usage" | "help" | "h" ) usage; exit 1;;
      "V" | "fcheck" | "version" ) ferror "${scriptfile} version ${sharesversion}"; exit 1;;
      #"i" | "infile" | "inputfile" ) getval;infile1=${tempval};;
      "r" | "remount" ) action=remount;;
      "k" | "keepalive" ) action=keepalive;;
      "a" | "all" ) allshares=1;;
      "t" | "type" ) getval; type="${tempval}";;
   esac
   
   debuglev 10 && { test ${hasval} -eq 1 && ferror "flag: ${flag} = ${tempval}" || ferror "flag: ${flag}"; }
}

# DETERMINE LOCATION OF FRAMEWORK
while read flocation; do if test -x ${flocation} && test "$( ${flocation} --fcheck )" -ge 20170111; then frameworkscript="${flocation}"; break; fi; done <<EOFLOCATIONS
./framework.sh
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
/usr/share/bgscripts/framework.sh
EOFLOCATIONS
test -z "${frameworkscript}" && echo "$0: framework not found. Aborted." 1>&2 && exit 4

# REACT TO OPERATING SYSTEM TYPE
case $( uname -s ) in
   Linux) [ ];;
   FreeBSD) [ ];;
   *) echo "${scriptfile}: 3. Indeterminate OS: $( uname -s )" 1>&2 && exit 3;;
esac

# INITIALIZE VARIABLES
# variables set in framework:
# today server thistty scriptdir scriptfile scripttrim
# is_cronjob stdin_piped stdout_piped stderr_piped sendsh sendopts
. ${frameworkscript} || echo "$0: framework did not run properly. Continuing..." 1>&2
infile1=
outfile1=
logfile=${scriptdir}/${scripttrim}.${today}.out
interestedparties="bgstack15@gmail.com"
allshares=0
tempfile1="$( mktemp )"
action=none
validtypes="cifs nfs nfs4 nfs3" # space delimited
type="" # will be defined by parameter
excludes="/proc"

## REACT TO ROOT STATUS
#case ${is_root} in
#   1) # proper root
#      [ ] ;;
#   sudo) # sudo to root
#      [ ] ;;
#   "") # not root at all
#      #ferror "${scriptfile}: 5. Please run as root or sudo. Aborted."
#      #exit 5
#      [ ]
#      ;;
#esac

# SET CUSTOM SCRIPT AND VALUES
#setval 1 sendsh sendopts<<EOFSENDSH      # if $1="1" then setvalout="critical-fail" on failure
#/usr/share/bgscripts/send.sh -hs     #                setvalout maybe be "fail" otherwise
#/usr/local/bin/send.sh -hs               # on success, setvalout="valid-sendsh"
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

# CONFIGURE VARIABLES AFTER PARAMETERS
action="$( echo "${action}" | tr '[:upper:]' '[:lower:]' )"
case "${action}" in
   keepalive|remount) :;;
   *) ferror "Please provide a valid action: remount or keepalive. Aborted." && exit 2;;
esac

if test -n "${type}" && allshares=0;
then
   ferror "Ignoring -t ${type} because -a was not used."
fi

## START READ CONFIG FILE TEMPLATE
#oIFS="${IFS}"; IFS=$'\n'
#infiledata=$( ${sed} ':loop;/^\/\*/{s/.//;:ccom;s,^.[^*]*,,;/^$/n;/^\*\//{s/..//;bloop;};bccom;}' "${infile1}") #the crazy sed removes c style multiline comments
#IFS="${oIFS}"; infilelines=$( echo "${infiledata}" | wc -l )
#{ echo "${infiledata}"; echo "ENDOFFILE"; } | {
#   while read line; do
#   # the crazy sed removes leading and trailing whitespace, blank lines, and comments
#   if test ! "${line}" = "ENDOFFILE";
#   then
#      line=$( echo "${line}" | sed -e 's/^\s*//;s/\s*$//;/^[#$]/d;s/\s*[^\]#.*$//;' )
#      if test -n "${line}";
#      then
#         debuglev 8 && ferror "line=\"${line}\""
#         if echo "${line}" | grep -qiE "\[.*\]";
#         then
#            # new zone
#            zone=$( echo "${line}" | tr -d '[]' )
#            debuglev 7 && ferror "zone=${zone}"
#         else
#            # directive
#            varname=$( echo "${line}" | awk -F= '{print $1}' )
#            varval=$( echo "${line}" | awk -F= '{$1=""; printf "%s", $0}' | sed 's/^ //;' )
#            debuglev 7 && ferror "${zone}${varname}=\"${varval}\""
#            # simple define variable
#            eval "${zone}${varname}=\${varval}"
#         fi
#         ## this part is untested
#         #read -p "Please type something here:" response < ${thistty}
#         #echo "${response}"
#      fi
#   else

## REACT TO BEING A CRONJOB
#if test ${is_cronjob} -eq 1;
#then
#   [ ]
#else
#   [ ]
#fi

# SET TRAPS
trap "CTRLC" 2
#trap "CTRLZ" 18
trap "clean_shares" 0

# MAIN LOOP
#{
   # PREPARE LIST OF SHARES
   cat /dev/null > "${tempfile1}"
   case "${allshares}" in
      0)
         # just the ones on the command line
         _x=0
         while test $_x -lt $thiscount;
         do
            _x=$(( _x + 1 ))
            eval _ti="\${opt${_x}}"
            debuglev 5 && ferror "understood ${_ti}"
            echo "${_ti}" >> "${tempfile1}"
         done
         ;;
      1)
         # all currently mounted filesystems of the requested type
         # get type, if requested
         alltypes="$( echo "${validtypes}" | tr ' ' '|' )"
         case "${type}" in
            "")
               searchstring="(${alltypes})"
               ;;
            *)
               if echo "${validtypes}" | grep -qiE "${type}" 1>/dev/null 2>&1;
               then
                  searchstring="${type}"
               else
                  searchstring="."
               fi
         esac

         # exclude the items in "exclude"
         excludes="($( echo "${excludes}" | tr ' ' '|' ))"
         test -z "${excludes}" && excludes="KFNOWOKJGOWF8ILJ" # random string

         # prepare actual list of mounts
         mount | grep -viE "${excludes}" | awk "/type ${searchstring}/{print \$3;}" >> "${tempfile1}"
         ;;
   esac

   case "${action}" in
      remount)

         # umount shares
         while read word;
         do
            debuglev 1 && echo "remounting ${word}";
            fsudo umount -l "${word}" & 1>/dev/null 2>&1
         done < "${tempfile1}"

         # mount shares
         while read word;
         do
            fsudo mount "${word}" & 1>/dev/null 2>&1
         done < "${tempfile1}"

         ;;
      keepalive)

         while read word;
         do
            debuglev 1 && echo "touching ${word}";
            touch --no-create "${word}/.fskeepalive" 1>/dev/null 2>&1
         done < "${tempfile1}"

         ;;
   esac

#} | tee -a ${logfile}

# EMAIL LOGFILE
#${sendsh} ${sendopts} "${server} ${scriptfile} out" ${logfile} ${interestedparties}

## STOP THE READ CONFIG FILE
#exit 0
#fi; done; }
