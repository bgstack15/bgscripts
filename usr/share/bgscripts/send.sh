#!/bin/sh
# Filename: send.sh 2017-04-15
# Location: 
# Author: bgstack15@gmail.com
# Startdate: 2017-04-15 20:42:07
# Title: 
# Purpose: 
# Package: 
# History: 
#   send.sh 2014-10-06 edition, which was a rewrite of the 2014-06-06/2014-08-13 original edition
# Usage: 
# Reference: ftemplate.sh 2017-01-11a; framework.sh 2017-01-11a
# Improve:
fiversion="2017-01-17a"
sendversion="2017-04-15a"

usage() {
   less -F >&2 <<ENDUSAGE
usage: send.sh [-duV] [-h|-H] [-s "subject line"] <infile> [email1 ...]
version ${sendversion}
 -d debug   Show debugging info, including parsed variables.
 -u usage   Show this usage block.
 -V version Show script version number.
 -h html    Add html headers, and edit the contents to include the <html> tags.
 -H         Add html headers, and assume content is already html format.
 <infile>   The file to mail. Required if stdin not provided.
 email1...  Overrides default email addresses. Default is ${defaultemail}
Accepts stdin and will use the first line as the subject if not specified.
Example usage:
 send.sh -hs "example subject" /tmp/file.log root@hostname
 cat *.log | send.sh -h
 
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

parse_flaglessvals() {
   # goals: save first valid file to infile1. save rest as emails for emaillist
   _x=0; _hasvalidfile=0; _emaillist=
   while test $_x -lt $thiscount;
   do
      _x=$(( _x + 1 ))
      eval _thisitem=\${opt${_x}}
      # check if a valid file
      debuglev 9 && ferror "Parsing item ${_thisitem}"
      if test -f "${_thisitem}";
      then
         if test "${_hasvalidfile}" = "0";
         then
            infile1="${_thisitem}"
            _hasvalidfile=1
         fi
      else
         # assume it is an email address, so add it to emaillist
         _emaillist="${_emaillist} ${_thisitem}"
      fi
   done
   displayedemaillist="$( echo "${_emaillist}" | sed 's/^ //;' )"
   emaillist="$( echo "${displayedemaillist}" | sed -r -e "s^${defaultemail}^^g;" -e 's/ +/ /g;' ) ${defaultemail}"
}

assemble_content() {
   # will send to stdout the contents of _tmpfile1
   _tmpfile1="$( mktemp )"
   [ -t 0 ]; sendstdin_piped=$? # manual check beacuse stdin_piped might be defined by a calling script

   if test -f "${infile1}";
   then
      # file exists
      cat "${infile1}" > "${_tmpfile1}"
   else
      # file does not exist, so assume it is part of the emaillist
      emaillist="${emaillist} ${infile1}"

      # check stdin. We need to have content to send!
      _xj=0
      if test "${sendstdin_piped}" = "1";
      then
         _xj=0
         while read _line;
         do
            _xj=$(( _xj + 1 ))
            test ${_xj} -eq 1 && { test "${subject}" = "$( pwd )/" || test -z "${subject}"; } && subject="${_line}"
            echo "${_line}" >> "${_tmpfile1}"
         done
         #infile1="${_tmpfile1}"
      else
         # file does not exist, and there is no stdin. So there is no input!
         ferror "${scriptfile}: 2. ${infile1} invalid file, and no standard input. Aborted."
         exit 2
      fi
   fi
   cat "${_tmpfile1}"
}

htmlize() {
   # takes stdin and transforms it based on htmltype value
   case "${htmltype}" in
      1)
         echo "<html><body><pre>"
         sed -r -e 's/</\&lt/g;' -e 's/>/\&gt;/g;' -e 's/\&/\&amp;/g;'
         echo "</pre></body></html>"
         headers="
Mime-Version: 1.0
Content-Type: text/html
Content-Transfer-Encoding: 8bit"
         ;;
      2)
         cat
         headers="
Mime-Version: 1.0
Content-Type: text/html
Content-Transfer-Encoding: 8bit"
         ;;
      *)
         ferror "htmlize: Ignoring unknown parameters: $@"
         cat
         ;;
   esac
}

_send() {
   _subject="${1}"
   _headers="${2}"
   _emaillist="${3}"
   _file="${4}"
   _fromemail="${5}"
   echo "subject=${_subject}"
   echo "headers=${_headers}"
   echo "emaillist=${_emaillist}"
   echo "file=${_file}"
   echo "fromemail=${_fromemail}"

   case "${sender}" in
      mail)
         #mail -s "${_subject}${_headers}"
         cat <<EOF - "${_file}" | sendmail -t
From: ${_fromemail}
To: ${_emaillist}
Subject: ${_subject}${_headers}

EOF
         ;;
   esac
}

# DEFINE TRAPS

clean_send() {
   #use at end of entire script if you need to clean up tmpfiles
   ps -ef | grep -iE "[s]end" | grep -viE "grep|vi" 1>/dev/null 2>&1
   rm -f ${tmpfile1} ${tmpfile2} ${outfile1} 1>/dev/null 2>&1
}

CTRLC() {
   #trap "CTRLC" 2
   [ ] #useful for controlling the ctrl+c keystroke
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
      "u" | "usage" | "help" ) usage; exit 1;;
      "V" | "fcheck" | "version" ) ferror "${scriptfile} version ${sendversion}"; exit 1;;
      "s" | "subject" ) getval; subject="${tempval}";;
      "h" | "html" ) htmltype=1;;
      "H" | "HTML" ) htmltype=2;;
      "f" | "from" ) getval; fromemail="${tempval}";;
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
infile1= # will be specified or will use stdin
outfile1=
logfile=${scriptdir}/${scripttrim}.${today}.out
emaillist=
defaultemail="bgstack15@gmail.com"
tmpfile1="$( mktemp )"
tmpfile2="$( mktemp )"
htmltype=0
subject=
fromemail=
headers=   # adjusted if need to send html contents
sender=mail

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
#if test ${thiscount} -lt 1;
#then
#   #ferror "${scriptfile}: 2. Fewer than 2 flaglessvals. Aborted."
#   #exit 2
#fi

# CONFIGURE VARIABLES AFTER PARAMETERS

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
trap "CTRLZ" 18
trap "clean_send" 0

# MAIN LOOP
#{
   # BUILD EMAIL LIST
   parse_flaglessvals # outputs vars emaillist, displayedemaillist, infile1

   # ASSEMBLE CONTENT
   assemble_content > "${tmpfile1}"
   htmlize < "${tmpfile1}" > "${tmpfile2}"

   debuglev 3 && ferror "Emailing ${displayedemaillist}"
   debuglev 11 && {
      ferror "Contents of file follows"
      ferror "------------------------"
      cat "${tmpfile2}" 1>&2
      ferror "------------------------"
   }
   debuglev 4 && {
      ferror "subject=${subject}"
      ferror "headers=${headers}"
   }

   _send "${subject}" "${headers}" "${emaillist}" "${tmpfile2}" "${fromemail}"
#} | tee -a ${logfile}

# EMAIL LOGFILE
#${sendsh} ${sendopts} "${server} ${scriptfile} out" ${logfile} ${interestedparties}

## STOP THE READ CONFIG FILE
#exit 0
#fi; done; }
