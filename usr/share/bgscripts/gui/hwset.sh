#!/bin/sh
# Filename: hwset.sh
# Location: /usr/share/bgscripts/hwset.sh
# Author: bgstack15@gmail.com
# Startdate: 2017-11-10 19:41:58
# Title: Script that Adjusts Hardware Settings
# Purpose: Provide programmatic ways to adjust screen brightness, volume, etc.
# Package: bgscripts
# History: 
# Usage: 
#    configure your display manager to react to key combinations, like vol-up to execute: hwset.sh vol up
# Reference: ftemplate.sh 2017-11-10a; framework.sh 2017-11-10a
# Improve:
#    Provide better 'screen 0' detection. Right now it is hard-coded to use display LVDS.
fiversion="2017-11-10a"
hwsetversion="2017-11-10a"

usage() {
   less -F >&2 <<ENDUSAGE
usage: hwset.sh [-duV] [-c conffile] PIECE ACTION VALUE
version ${hwsetversion}
 -d debug   Show debugging info, including parsed variables.
 -u usage   Show this usage block.
 -V version Show script version number.
 -c conf    Read in this config file.
PIECE   vol | bright
ACTION  up | down | set | mute
VALUE [vol: 0-100] [bright: 0.0-1.0]
Use this tool to adjust volume or brightness.
Examples:
hwset vol up
hweset vol mute
hwset bright set 0.8
Return values:
 0 Normal
 1 Help or version info displayed
 2 Count or type of flaglessvals is incorrect
 3 Incorrect OS type
 4 Unable to find dependency
 5 Not run as root or sudo
ENDUSAGE
}

# DEFINE FUNCTIONS
vol_up() {
   # call: vol_down "${HWSET_SND_INCREMENT}"
   local increment="${1}"
   mixer vol +${increment}
}

vol_down() {
   # call: vol_down "${HWSET_SND_INCREMENT}"
   local increment="${1}"
   mixer vol -${increment}
}

vol_set() {
   # call: vol_set value
   local value="${1}"
   mixer vol "${value}"
}

vol_mute() {
   # this function toggles the mute state between volume 0 and whatever it was before
   # will ignore any parameters as they are unneeded

   # get saved volume from temp file
   local saved_level="$( awk 'BEGIN{FS="=";} /VOL_REGULAR_LEVEL=/{print $2}' "${HWSET_SND_TEMP_FILE}" 2>/dev/null )"
   local current_level="$( mixer vol | awk '{print $NF}' )"

   debuglev 3 && ferror "saved: ${saved_level}\tcurrent: ${current_level}"

   # logic: if current level is other than "0:0", save current level and set to 0
   # logic: if current level is "0:0", set to saved level.
   if echo "${current_level}" | grep -qE "^0:0$";
   then
      # the current level is zero
      if test -z "${saved_level}" || echo "${saved_level}" | grep -qvE "[0-9]+:[0-9]+";
      then
         # nothing to revert to, so set to a basic level
         mixer vol 70
      else
         mixer vol "${saved_level}"
      fi
   else
      # current level is not zero
      echo "VOL_REGULAR_LEVEL=${current_level}" > "${HWSET_SND_TEMP_FILE}"
      mixer vol "0:0"
   fi
}

bright_get() {
   #local this_screen="$( xrandr --listactivemonitors | tail -n +2 | grep LVDS | awk '{print $NF}' )"
   xrandr --verbose --screen 0 | grep Brightness | awk '{print $NF}'
}

bright_safe() {
   # call: new_brightness="$( bright_safe "${new_brightness}" )"
   # this function makes sure the new brightness is not lower than the min and not higher than the max
   local requested_brightness="${1}"
   local output="$( echo "${requested_brightness}" | grep -oE '^-?[0-9]\.[0-9]{0,3}$' )"
   if test -n "${output}";
   then
      # so it is a proper decimal number for a brightness value
      local lt_min="$( printf '%f<%f\n' "${requested_brightness}" "${HWSET_BRIGHTNESS_MIN}" | bc )"
      local gt_max="$( printf '%f>%f\n' "${requested_brightness}" "${HWSET_BRIGHTNESS_MAX}" | bc )"
      test "${gt_max}" = "1" && output="${HWSET_BRIGHTNESS_MAX}"
      test "${lt_min}" = "1" && output="${HWSET_BRIGHTNESS_MIN}"
      #echo "lt=${lt} gt=${gt}"
      echo "${output}"
   else
      # invalid input, so provide a safe number
      echo "${HWSET_BRIGHTNESS_MAX:-1.0}"
   fi
}

bright_up() {
   # call: bright_up "${HWSET_BRIGHTNESS_INCREASE_SIZE}"
   local current_brightness="$( bright_get )"
   local increment="${1}"
   local new_brightness="$( printf '%0.2f' "$( printf 'scale=3;%0.2f+%0.2f\n' "${current_brightness}" "${increment}" | bc )" )"
   new_brightness="$( bright_safe "${new_brightness}" )"
   debuglev 1 && ferror "current brightness:\"${current_brightness}\" new:\"${new_brightness}\""
   xrandr --output LVDS1 --brightness "${new_brightness}"
}

bright_down() {
   # call: bright_down "${HWSET_BRIGHTNESS_INCREASE_SIZE}"
   local current_brightness="$( bright_get )"
   local increment="${1}"
   local new_brightness="$( printf '%0.2f' "$( printf 'scale=3;%0.2f-%0.2f\n' "${current_brightness}" "${increment}" | bc )" )"
   new_brightness="$( bright_safe "${new_brightness}" )"
   debuglev 1 && ferror "current brightness:\"${current_brightness}\" new:\"${new_brightness}\""
   xrandr --output LVDS1 --brightness "${new_brightness}"
}

bright_set() {
   # call: bright_set "${value}"
   local value="${1}"
   xrandr --output LVDS1 --brightness "${value}"
}

# DEFINE TRAPS

clean_hwset() {
   # use at end of entire script if you need to clean up tmpfiles
   #rm -f ${tmpfile} 1>/dev/null 2>&1
   :
}

CTRLC() {
   # use with: trap "CTRLC" 2
   # useful for controlling the ctrl+c keystroke
   :
}

CTRLZ() {
   # use with: trap "CTRLZ" 18
   # useful for controlling the ctrl+z keystroke
   :
}

parseFlag() {
   flag="$1"
   hasval=0
   case ${flag} in
      # INSERT FLAGS HERE
      "d" | "debug" | "DEBUG" | "dd" ) setdebug; ferror "debug level ${debug}";;
      "u" | "usage" | "help" | "h" ) usage; exit 1;;
      "V" | "fcheck" | "version" ) ferror "${scriptfile} version ${hwsetversion}"; exit 1;;
      #"i" | "infile" | "inputfile" ) getval; infile1=${tempval};;
      "c" | "conf" | "conffile" | "config" ) getval; conffile="${tempval}";;
   esac
   
   debuglev 10 && { test ${hasval} -eq 1 && ferror "flag: ${flag} = ${tempval}" || ferror "flag: ${flag}"; }
}

# DETERMINE LOCATION OF FRAMEWORK
while read flocation; do if test -x ${flocation} && test "$( ${flocation} --fcheck )" -ge 20170608; then frameworkscript="${flocation}"; break; fi; done <<EOFLOCATIONS
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
/usr/local/share/bgscripts/framework.sh
/usr/share/bgscripts/framework.sh
EOFLOCATIONS
test -z "${frameworkscript}" && echo "$0: framework not found. Aborted." 1>&2 && exit 4

# INITIALIZE VARIABLES
# variables set in framework:
# today server thistty scriptdir scriptfile scripttrim
# is_cronjob stdin_piped stdout_piped stderr_piped sendsh sendopts
. ${frameworkscript} || echo "$0: framework did not run properly. Continuing..." 1>&2
infile1=
outfile1=
logfile=${scriptdir}/${scripttrim}.${today}.out
define_if_new interestedparties "bgstack15@gmail.com"
# SIMPLECONF
define_if_new default_conffile "/usr/local/etc/bgscripts/hwset.conf"
define_if_new defuser_conffile ~/.config/hwset/hwset.conf

# REACT TO OPERATING SYSTEM TYPE
case $( uname -s ) in
   FreeBSD) [ ];;
   *) echo "${scriptfile}: 3. Indeterminate or unsupported OS: $( uname -s )" 1>&2 && exit 3;;
esac

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
validateparams piece action value - "$@"

# CONFIRM TOTAL NUMBER OF FLAGLESSVALS IS CORRECT
#if test ${thiscount} -lt 2;
#then
#   ferror "${scriptfile}: 2. Fewer than 2 flaglessvals. Aborted."
#   exit 2
#fi

# LOAD CONFIG FROM SIMPLECONF
# This section follows a simple hierarchy of precedence, with first being used:
#    1. parameters and flags
#    2. environment
#    3. config file
#    4. default user config: ~/.config/script/script.conf
#    5. default config: /etc/script/script.conf
if test -f "${conffile}";
then
   get_conf "${conffile}"
else
   if test "${conffile}" = "${default_conffile}" || test "${conffile}" = "${defuser_conffile}"; then :; else test -n "${conffile}" && ferror "${scriptfile}: Ignoring conf file which is not found: ${conffile}."; fi
fi
test -f "${defuser_conffile}" && get_conf "${defuser_conffile}"
test -f "${default_conffile}" && get_conf "${default_conffile}"

# CONFIGURE VARIABLES AFTER PARAMETERS
define_if_new HWSET_SND_INCREMENT=8
define_if_new HWSET_SND_MUTE_LEVEL=0
define_if_new HWSET_SND_TEMP_FILE=/tmp/hwset/snd.level
define_if_new HWSET_BRIGHTNESS_INCREMENT=0.08
define_if_new HWSET_BRIGHTNESS_MAX=1.0
define_if_new HWSET_BRIGHTNESS_MIN=0.1

## REACT TO BEING A CRONJOB
#if test ${is_cronjob} -eq 1;
#then
#   [ ]
#else
#   [ ]
#fi

# SET TRAPS
#trap "CTRLC" 2
#trap "CTRLZ" 18
#trap "clean_hwset" 0

# DEBUG SIMPLECONF
debuglev 5 && {
   ferror "Using values"
   # used values: EX_(OPT1|OPT2|VERBOSE)
   set | grep -iE "^HWSET_" 1>&2
}

# make temp files
if test -n "${HWSET_SND_TEMP_FILE}"
then
   tempdir="$( dirname "${HWSET_SND_TEMP_FILE}" )"
   mkdir -p "${tempdir}" && touch "${HWSET_SND_TEMP_FILE}"
fi

# MAIN LOOP
#{
   debuglev 2 && ferror "piece:\"${piece}\" action:\"${action}\" value:\"${value}\""
   case "${piece}" in
      vol|volume)
         case "${action}" in
            up|down|mute)
               debuglev 1 && ferror vol_${action} "${value:-$HWSET_SND_INCREMENT}"
               vol_${action} "${value:-$HWSET_SND_INCREMENT}"
               ;;
            set)
               if test -z "${value}";
               then
                  # you ran hwset vol set, without a value
                  # do nothing, silently
                  debuglev 1 && ferror "Cannot set vol to \"\". Skipped."
               else
               debuglev 1 && ferror vol_${action} "${value}"
               vol_${action} "${value}"
               fi
               ;;
            *)
               ferror "${scripttrim}: piece ${piece} was given unknown action ${action}. Aborted."
               exit 2
               ;;
         esac
         ;;
      bright|brightness)
         case "${action}" in
            up|down)
               debuglev 1 && ferror bright_${action} "${value:-${HWSET_BRIGHTNESS_INCREMENT}}"
               bright_${action} "${value:-${HWSET_BRIGHTNESS_INCREMENT}}"
               ;;
            set)
               if test -z "${value}";
               then
                  # you ran hwset bright set, without a value
                  # do nothing, silently
                  debuglev 1 && ferror "Cannot set brightness to \"\". Skipped."
               else
                  debuglev 1 && ferror bright_${action} "${value}"
                  bright_${action} "${value}"
               fi
               ;;
            *)
               ferror "${scripttrim}: piece ${piece} was given unknown action ${action}. Aborted."
               ;;
         esac
         ;;
      *)
         ferror "${scripttrim}: Unknown piece ${piece}. Aborted."
         exit 2
         ;;
   esac
#} | tee -a ${logfile}

# EMAIL LOGFILE
#${sendsh} ${sendopts} "${server} ${scriptfile} out" ${logfile} ${interestedparties}

## STOP THE READ CONFIG FILE
#exit 0
#fi; done; }
