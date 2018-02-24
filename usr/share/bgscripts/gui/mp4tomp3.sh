#!/bin/sh
# Filename: mp4tomp3.sh
# Location: /usr/share/bgscripts/gui/
# Author: bgstack15@gmail.com
# Startdate: 2016-02-18 13:24:41
# Title: Script that Converts an MP4 file to MP3
# Purpose: Converts specified mp4 files to mp3
# Package: bgscripts
# History: 
#    2017-11-12 Added to bgscripts package
# Usage: 
# Reference: ftemplate.sh 2016-02-02a; framework.sh 2016-02-02a
#    http://stackoverflow.com/questions/29034081/find-the-closest-value-from-given-value-from-file-bash
# Improve:
fiversion="2016-02-02a"
mp4tomp3version="2016-11-11a"

usage() {
   less -F >&2 <<ENDUSAGE
usage: mp4tomp3.sh [-duV] file1 [ file2 file3 ... ]
version ${mp4tomp3version}
 -d debug   Show debugging info, including parsed variables.
 -u usage   Show this usage block.
 -V version Show script version number.
 [ filenames ]   Currently only converts .mp4 files to .mp3. It selects the closest bitrate from the built-in option list.
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
function getbitrate {
   # do some awk magic.
   # given "$1" as $filename and already validated as a file
   filename="$1"
   temprate=$( ${ffmpeg} -i "${filename}" 2>&1 | grep -iE "Stream.*Audio" | grep -oE "[0-9]{1,4} [a-z]{1,2}\/s" | grep -oE "[0-9]*" )

   #debuglev 5 && ferror "temprate=${temprate}"
   # match bitrate to closest in this set of presets
   # adapted from http://stackoverflow.com/questions/29034081/find-the-closest-value-from-given-value-from-file-bash
   # 64 128 160 192 256 320
   echo "
64
96
128
160
192
256
320
" | tr '\n' ' ' | awk -v target="${temprate}" '
function abs(val) { return (val < 0 ? -1*val : val) }

{
   min = abs($1 - target)
   min_idx = 1
   for (i=2; i<=NF; i++) {
      diff = abs($i - target)
      if (diff < min ) {
         min = diff
         min_idx = i
      }
   }
   print $min_idx
} 
' | sed '/^$/d' # trim empty lines
   
   #echo "$temprate"
}

function getmp3name {
   # convert any *.MP4, *.mp4 to a .mp3 name
   filename="$1"
   echo "${filename}" | sed 's/\.mp4$/\.mp3/i;'
}

# DEFINE TRAPS

function clean_mp4tomp3 {
   #rm -f $logfile >/dev/null 2>&1
   : #use at end of entire script if you need to clean up tmpfiles
}

function CTRLC {
   #trap "CTRLC" 2
   : #useful for controlling the ctrl+c keystroke
}

function CTRLZ {
   #trap "CTRLZ" 18
   : #useful for controlling the ctrl+z keystroke
}

function parseFlag {
   flag=$1
   hasval=0
   case $flag in
      # INSERT FLAGS HERE
      "d" | "debug" | "DEBUG" | "dd" ) setdebug; ferror "debug level ${debug}";;
      "u" | "usage" | "help") usage; exit 1;;
      "V" | "fcheck" | "version") ferror "${scriptfile} version ${mp4tomp3version}"; exit 1;;
      #"i" | "infile" | "inputfile") getval;infile1=$tempval;;
   esac
   
   debuglev 10 && { [[ hasval -eq 1 ]] && ferror "flag: $flag = $tempval" || ferror "flag: $flag"; }
}

# DETERMINE LOCATION OF FRAMEWORK
while read flocation; do if [[ -x $flocation ]] && [[ $( $flocation --fcheck ) -ge 20151123 ]]; then frameworkscript=$flocation; break; fi; done <<EOFLOCATIONS
./framework.sh
${scriptdir}/framework.sh
/usr/local/share/bgscripts/framework.sh
/usr/share/bgscripts/framework.sh
EOFLOCATIONS
[[ -z "$frameworkscript" ]] && echo "$0: framework not found. Aborted." 1>&2 && exit 4

# REACT TO OPERATING SYSTEM TYPE
case $( uname -s ) in
   AIX) : ;;
   Linux) : ;;
   FreeBSD) : ;;
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

## REACT TO ROOT STATUS
#case $is_root in
#   1) # proper root
#      : ;;
#   sudo) # sudo to root
#      : ;;
#   "") # not root at all
#      #ferror "${scriptfile}: 5. Please run as root or sudo. Aborted."
#      #exit 5
#      :
#      ;;
#esac

# SET CUSTOM SCRIPT AND VALUES
#setval 1 sendsh sendopts<<EOFSENDSH      # if $1="1" then setvalout="critical-fail" on failure
#/usr/local/bin/bgscripts/send.sh -hs     #                setvalout maybe be "fail" otherwise
#/usr/local/bin/send.sh -hs               # on success, setvalout="valid-sendsh"
#/usr/bin/mail -s
#EOFSENDSH
#[[ "$setvalout" = "critical-fail" ]] && ferror "${scriptfile}: 4. mailer not found. Aborted." && exit 4
setval 1 ffmpeg <<EOFFFMPEG
/usr/local/bin/ffmpeg
/usr/bin/ffmpeg
/bin/ffmpeg
/usr/local/bin/avconv
/usr/bin/avconv
/bin/avconv
EOFFFMPEG
test "${setvalout}" = "critical-fail" && ferror "${scriptfile}: 4. ffmpeg or avconv not found. Aborted." && exit 4

# VALIDATE PARAMETERS
# objects before the dash are options, which get filled with the optvals
# to debug flags, use option DEBUG. Variables set in framework: fallopts
validateparams - "$@"

# CONFIRM TOTAL NUMBER OF FLAGLESSVALS IS CORRECT
if [[ $thiscount -lt 1 ]];
then
   ferror "${scriptfile}: 2. Please specify at least one file. Aborted."
   exit 2
fi

# CONFIGURE VARIABLES AFTER PARAMETERS

## READ CONFIG FILE TEMPLATE
#grep -viE "^$|^#" "${infile1}" | sed "s/[^\]#.*$//;' | while read line
##BASH BELOW
##while read -r line
#do
#   echo "$line"
#   read -p "Please type something here:" response < $thistty
#   echo "$response"
#done
##BASH BELOW
##done < <( grep -viE "^$|^#" "${infile1}" | sed 's/[^\]#.*$//g;' )

## REACT TO BEING A CRONJOB
#if [[ $is_cronjob -eq 1 ]];
#then
#   :
#else
#   :
#fi

# SET TRAPS
#trap "CTRLC" 2
#trap "CTRLZ" 18
#trap "clean_mp4tomp3" 0

# MAIN LOOP
#{
   x=1
   while [[ x -le thiscount ]];
   do
      eval "word=\${opt$x}"
      debuglev 7 && ferror "file=${word}"
      ((x+=1))
      if [[ -f "${word}" ]];
      then
         bitrate=$( getbitrate "${word}" )
         mp3name=$( getmp3name "${word}" )
         debuglev 1 && ferror ${ffmpeg} -y -i \""${word}"\" -b:a "${bitrate}k" \""${mp3name}"\" || \
            ${ffmpeg} -y -i "${word}" -b:a "${bitrate}k" "${mp3name}"
      else
         ferror "Invalid file \"${word}\" skipped."
      fi
   done
   :
#} | tee -a $logfile

# EMAIL LOGFILE
#$sendsh $sendopts "$server $scriptfile out" $logfile $interestedparties
