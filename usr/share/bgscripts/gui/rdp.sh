#!/bin/sh
# Filename: rdp.sh
# Location: /usr/share/bgscripts/gui/
# Author: bgstack15@gmail.com
# Startdate: 2016-02-08 11:55:31
# Title: Script that Opens RDP Connections Based on RDP Files
# Purpose:
# Package:
# History: 2016-05-23 removed pw from debug display
#    2016-12-04 updated for Korora 24/25 with the version check.
#    2017-01-11 moved whole package to /usr/share/bgscripts
#    2017-01-19 added rdp.conf options
#    2017-01-25 Changed the notification if no file was specified.
#    2017-02-02 Added file selection if called form gui without a file.
# Usage:
#    Warning: Some systems don't like the clipboard sharing.
#    This script uses /etc/bgscripts/rdp.conf and ~/.config/bgscripts/rdp.conf for extra settings.
# Reference: ftemplate.sh 2016-02-02a; framework.sh 2016-02-02a
#    https://github.com/FreeRDP/FreeRDP/wiki/CommandLineInterface
#    exit codes https://github.com/FreeRDP/FreeRDP/blob/90b3bf4891e426d422ddb0581560450013832e5e/client/X11/xfreerdp.h#L252
#    mirror-master.sh from mirror-1.0-6 package for the config parsing.
# Improve:
#    Check for more error types, including when the certificate has updated and you haven't approved it yet.
#    Long shot: Someday give the ability to edit/write RDP files.
fiversion="2016-02-02a"
rdpversion="2017-02-02a"

usage() {
   less -F >&2 <<ENDUSAGE
usage: rdp.sh [-duV] infile1 [-U userfile] [--gui]
version ${rdpversion}
 -d debug   Show debugging info, including parsed variables.
 -u usage   Show this usage block.
 -V version Show script version number.
 infile     RDP file to read.
 -U userfile Selects fstab-style userfile. Default is "${userfile}"
 --gui      Shows alerts in the gui and not on a command line.
Return values:
0 Normal
1 Help or version info displayed
2 Count or type of flaglessvals is incorrect
3 Incorrect OS type
4 Unable to find dependency
5 Not run as root or sudo
6 incorrect config file
ENDUSAGE
}

# DEFINE FUNCTIONS
function getscreensize {
   # call: getscreensize thisheight thiswidth
   # assigns W and H to the 2 variables sent to the function
   calledvar1=${1-thiswidth}
   calledvar2=${2-thisheight}
   thisfile=$(mktemp -u)
 
   # exact methods will differ depending on available packages and distros
   # Korora 22
   grep -qiE "(Fedora|Korora).*(2.)" /etc/redhat-release 2>/dev/null && \
      xdpyinfo | grep -oiE "dimensions.*[0-9]{3,4}x[0-9]{3,4} pi" | tr -d '[A-Za-wyz ():]' | tr 'x' ' ' > ${thisfile}
   read myx myy < ${thisfile}
   eval "${calledvar1}=\${myx}"
   eval "${calledvar2}=\${myy}"
   rm -rf ${thisfile}
}

function getuser {
   # call: getuser "${userfile}" thisuser thispassword
   # read fstab credentials file "userfile" and place in strings thisuser and thispassword
   # Note: This gets user in domain\username format.

   calledvar1=${2-thisuser}
   calledvar2=${3-thispassword}

   [[ -n "$1" ]] && thisinfile="$1"
   if [[ -f "${thisinfile}" ]];
   then
      for word in $( fsudo grep -viE "^$|^#" "${thisinfile}" );
      do
         item="${word%%=*}"
         value="${word##*=}"
         case "${item}" in
            domain) usertemp="${value}\\${usertemp}";;
            username|user) usertemp="${usertemp}${value}";;
            password) passtemp="${value}";;
            *) [ ];; #other item is useless
         esac
      done
   else
      # not a valid file, so get username from environment
      domain=$( hostname -d )
      usertemp="${domain}\\$USER"
   fi

   eval "$calledvar1=\$usertemp"
   eval "$calledvar2=\$passtemp"

}

function displaymessage {
   # call: displaymessage error "This error happened."
   _msgtype="${1}"
   _msgstring="${2}"
   case ${usinggui} in
      1)
         case "${_msgstring}" in
            *\*) _msgstring="$( echo "${_msgstring}" | sed -e 's/\\/\\\\/g;' )"
               ;;
         esac
         zenity --"${_msgtype}" --text "${_msgstring}" 2>/dev/null
         ;;
      *)
         _msgtype="$( echo "${_msgtype}" | sed 's/^[a-z]/\u&/;' )"
         echo "${_msgtype}: ${_msgstring}"
         ;;
   esac
}

function parse_config {
   # call: parse_config "${conffile1}"
   _conffile="${1}"

   oIFS="${IFS}"; IFS=$'\n'
   conffiledata=( $( sed ':loop;/^\/\*/{s/.//;:ccom;s,^.[^*]*,,;/^$/n;/^\*\//{s/..//;bloop;};bccom;}' "${_conffile}") ) #the crazy sed removes c style multiline comments
   IFS="${oIFS}"
   for line in "${conffiledata[@]}";
   do line=$( echo "${line}" | sed -e 's/^\s*//;s/\s*$//;/^[#$]/d;s/\s*[^\]#.*$//;' ); test -n "${line}" && {
      # the crazy sed removes leading and trailing whitespace, blank lines, and comments
      debuglev 8 && ferror "line=\"$line\""
      if echo "${line}" | grep -qiE "\[.*\]";
      then
         # new zone
         zone=$( echo "${line}" | tr -d '[]' )
         debuglev 7 && ferror "zone=${zone}"
      else
         # directive
         varname=$( echo "${line}" | awk -F\  '{print $1}' )
         varval=$( echo "${line}" | awk -F\  '{$1=""; printf "%s", $0}' | sed 's/^ //;' )
         debuglev 7 && ferror $( eval echo ${varname}=\\\"${varval}\\\" )
         # simple define variable #eval "${zone}${varname}=\${varval}"
         if test "${zone}" = "bgscripts/rdp";
         then
            case "${varname}" in
               "minversion")
                  # get script version
                  _scriptversion="$( echo "${rdpversion}" | sed 's/[^0-9]//g;' )"
                  # get varval version
                  _conffileversion="$( echo "${varval}" | sed 's/[^0-9]//g;' )"
                  # if varval is newer than script, throw alert and quit
                  if test "${_conffileversion}" -gt "${_scriptversion}";
                  then
                     ferror "Config file ${_conffile} is newer version: ${varval}. Aborted."
                     exit 6
                  fi
                  ;;
               "defaultoptions" | "options" | "alloptions")
                  eval alloptions=${varval}
                  ;;
               *)
                  eval "${varname}"=${varval}
                  ;;
            esac
         fi
      fi
   }; done
}

# DEFINE TRAPS

function clean_rdp {
   #rm -f $logfile >/dev/null 2>&1
   [ ] #use at end of entire script if you need to clean up tmpfiles
}

function CTRLC {
   #trap "CTRLC" 2
   [ ] #useful for controlling the ctrl+c keystroke
}

function CTRLZ {
   #trap "CTRLZ" 18
   [ ] #useful for controlling the ctrl+z keystroke
}

function parseFlag {
   flag=$1
   hasval=0
   case $flag in
      # INSERT FLAGS HERE
      "d" | "debug" | "DEBUG" | "dd" ) setdebug; ferror "debug level ${debug}";;
      "u" | "usage" | "help" ) usage; exit 1;;
      "V" | "fcheck" | "version" ) ferror "${scriptfile} version ${rdpversion}"; exit 1;;
      #"i" | "infile" | "inputfile" ) getval;infile1=$tempval;;
      "U" | "userfile" ) getval; userfile="${tempval}";;
      "gui" ) usinggui=1;;
   esac
  
   debuglev 10 && { [[ hasval -eq 1 ]] && ferror "flag: $flag = $tempval" || ferror "flag: $flag"; }
}

# DETERMINE LOCATION OF FRAMEWORK
while read flocation; do if [[ -x $flocation ]] && [[ $( $flocation --fcheck ) -ge 20151123 ]]; then frameworkscript=$flocation; break; fi; done <<EOFLOCATIONS
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
[[ -z "$frameworkscript" ]] && echo "$0: framework not found. Aborted." 1>&2 && exit 4

# REACT TO OPERATING SYSTEM TYPE
case $( uname -s ) in
   Linux) [ ];;
   *) echo "$scriptfile: 3. Indeterminate OS: $( uname -s )" 1>&2 && exit 3;;
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
rdpcommand=/usr/bin/xfreerdp
alloptions="/sec-rdp /cert-tofu"; #where defaults go. Will be added to by infile1 options
userfile=~/.bgirton.smith122.com # is configurable with -U flag
fullscreenborder=80px;

# options that may be in conffiles:
# rdpversion, rdpcommand, defaultoptions, userfile, fullscreenborder
conffile1=/etc/bgscripts/rdp.conf
conffile2=~/.config/bgscripts/rdp.conf

## REACT TO ROOT STATUS
#case $is_root in
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
#[[ "$setvalout" = "critical-fail" ]] && ferror "${scriptfile}: 4. mailer not found. Aborted." && exit 4

# VALIDATE PARAMETERS
# objects before the dash are options, which get filled with the optvals
# to debug flags, use option DEBUG. Variables set in framework: fallopts
validateparams infile1 - "$@"

# CONFIRM TOTAL NUMBER OF FLAGLESSVALS IS CORRECT
if [[ $thiscount -lt 1 ]];
then
   case "${usinggui}" in
      1) # gui
         # get a file, and continue from there.
         infile1="$( zenity --title="Open RDP File" --window-icon='/usr/share/icons/hicolor/scalable/apps/rdp.svg' --file-selection --file-filter="Remote desktop files | *.rdp *.rdpx" --file-filter="All files | *.* *" 2>/dev/null )"
         ;;
      *) # cli or other non-gui somehow
         displaymessage error "Please provide a file to use. There is nothing to do right now."
         exit 2
         ;;
   esac
fi

# CONFIGURE VARIABLES AFTER PARAMETERS

# ENSURE conffile exists
if test -f "${conffile1}";
then
   # master config file exists.
   # READ ETC-CONFIG FILE
   parse_config "${conffile1}"
fi # if it does not exist it is still not a problem. The builtin defaults will suffice.

if test -f "${conffile2}";
then
   # user-specific file exists.
   # READ USER-CONFIG FILE
   parse_config "${conffile2}"
fi # no announcements at all if user config file does not exist.

# READ RDP FILE
remember_IFS="${IFS}"; IFS=$'\n'
the_raw_data=($(cat "${infile1}"))
IFS="${remember_IFS}"

unhandled="unhandled:";
sizes=0;
#grep -viE "^$|^#" "${infile1}" | sed "s/[^\]#.*$//;' | while read line
#BASH BELOW
#while read -r line
for line in "${the_raw_data[@]}"
do
   debuglev 5 && ferror "$line"
   value=$( echo "${line##*:}" | tr -d '\r' )
   #read -p "Please type something here:" response < $thistty
   #echo "$response"
   case "${line}" in
      *screen\ mode\ id*)    screenmode="${value}";;
      use\ multimon*)        multimon="${value}";;
      desktopwidth*)        desktopwidth="${value}";((sizes+=10));;
      desktopheight*)        desktopheight="${value}";((sizes+=1));;
      session\ bpp*)        sessionbpp="${value}";;
      full\ address*)        fulladdress="${value}";; #should include port if necessary
      compression*)        compression="${value}";;
      displayconnectionbar*)    displayconnectionbar="${value}";; # guessing that this is /disp
      audiomode*)        audiomode="${value}";;
      audiocapturemode*)    audiocapturemode="${value}";;
      keyboardhook*)        unhandled="${unhandled}\n${line}";; #cannot find implementation in freerdp
      redirectclipboard*)    clipboard="${value}";;
      disable\ wallpaper*)    wallpaper="${value}";;
      allow\ font\ smoothing*)    fontsmoothing="${value}";;
      allow\ desktop\ composition*)    unhandled="${unhandled}\n${line}";; # provides aero but I never ever use aero
      disable\ full\ window\ drag*)    windowdrag="${value}";;
      disable\ menu\ anims*)    menuanims="${value}";;
      disable\ themes*)        themes="${value}";;
      *) debuglev 4 && ferror "Unknown option: ${line}";;
   esac
done
#BASH BELOW
#done < <( grep -viE "^$|^#" "${infile1}" | sed 's/[^\]#.*$//g;' )

#GET USER
getuser "${userfile}" thisuser thispassword

#FINISH PARSING DIRECTIVES FOR freerdp
[[ "${multimon}" = "1" ]] && alloptions="${alloptions} /multimon"
#echo "screenmode=${screenmode}"
if [[ "${screenmode}" = "1" ]];
then
   # screenmode 1 windowed
   case sizes in
      0) screenmode=2;; #abort and just do fullscreen
      1) alloptions="${alloptions} /h:${desktopheight}";;
      10) alloptions="${alloptions} /w:${desktopwidth}";;
      11) alloptions="${alloptions} /size:${desktopwidth}x${desktopheight}";;
      *) ferror "Did not understand sizing. Emulating fullscreen." && screenmode=2;;
   esac
fi
if [[ "${screenmode}" = "2" ]];
then
   # screenmode 2 fullscreen

   # on linux make that windowed but 20px border around window
   # xfreerdp has the "/f" flag though if I want to change it in the future
   getscreensize thiswidth thisheight
   fullscreenborder=${fullscreenborder%%px}
   ((thiswidth-=fullscreenborder)) && ((thisheight -=fullscreenborder))
   

   alloptions="${alloptions} /size:${thiswidth}x${thisheight}"
fi
[[ -n "${sessionbpp}" ]] && alloptions="${alloptions} /bpp:${sessionbpp}"
[[ -n "${fulladdress}" ]] && alloptions="${alloptions} /v:${fulladdress}"
[[ -n "${compression}" ]] && alloptions="${alloptions} -z"
[[ "${displayconnectionbar}" = "1" ]] && alloptions="${alloptions} /disp"
[[ -n "${audiomode}" ]] && alloptions="${alloptions} /audio-mode:${audiomode}"
[[ -n "${audiocapturemode}" ]] && alloptions="${alloptions} /mic"
[[ "${clipboard}" = "1" ]] && alloptions="${alloptions} +clipboard"
[[ "${wallpaper}" = "0" ]] && alloptions="${alloptions} /wallpaper" #because it is actually a disable-wallpaper flag
[[ "${fontsmoothing}" = "1" ]] && alloptions="${alloptions} /fonts"
[[ "${windowdrag}" = "0" ]] && alloptions="${alloptions} /window-drag"
[[ "${menuanims}" = "0" ]] && alloptions="${alloptions} /menu-anims"
[[ "${themes}" = "0" ]] && alloptions="${alloptions} /themes"
alloptionsfordebug="${alloptions} /u:${thisuser} /p:********"
alloptions="${alloptions} /u:${thisuser} /p:${thispassword}"

alloptions="${alloptions# }" # to trim leading space just to look nicer

## REACT TO BEING A CRONJOB
#if [[ $is_cronjob -eq 1 ]];
#then
#   [ ]
#else
#   [ ]
#fi

# SET TRAPS
#trap "CTRLC" 2
#trap "CTRLZ" 18
#trap "clean_rdp" 0

# MAIN LOOP
#{
   if debuglev 1;
   then
      displaymessage info "${rdpcommand} ${alloptionsfordebug}"
   else
      ${rdpcommand} ${alloptions}
      result="$?"
      case "${result}" in
         131) # invalid credentials
            displaymessage error "Invalid credentials. Check file ${userfile}."
            ;;
         *)
            displaymessage info "Result ${result}."
            ;;
      esac
   fi
#} | tee -a $logfile

# EMAIL LOGFILE
#$sendsh $sendopts "$server $scriptfile out" $logfile $interestedparties
