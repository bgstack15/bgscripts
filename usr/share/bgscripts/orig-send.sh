#!/bin/sh
# Filename: send.sh 2014-10-06
# Location: /usr/share/bgscripts/
# Author: bgstack15@gmail.com
# Startdate: 2014-10-06
# Title: Send.sh for Cross-Platform Use
# Purpose: To send files easily to myself or others
# History: 2015-11-09 switched method of sending html email on linux
#    2016-08-03 modified for /bin/sh for FreeBSD portability
#    2017-01-11 moved whole package to /usr/share/bgscripts
#    2017-01-25 fixed the From: field
# Usage: 
# Reference: ftemplate.sh 2014-08-04b; framework.sh 2014-08-04b
#    send.sh (2014-06-06/2014-08-13 revision)
#    using a linux sendmail-hook wrapper script: http://stackoverflow.com/questions/2591755/how-send-html-mail-using-linux-command-line
#    adding a \n to end of </html> in htmlize: http://community.spiceworks.com/topic/108939-exchange-puts-equal-signs-at-line-breaks
#    replaced sendmail-hook wrapper with new method: http://unix.stackexchange.com/questions/15405/how-do-i-send-html-email-using-linux-mail-command
fiversion="2014-08-04b" 
sendversion="2017-01-25a"

usage() {
   less -F >&2 <<ENDUSAGE
usage: send.sh [-s "subject line"] [-u] <infile> [-f fromuser] [email1 email2 email3 ...]"
 -u usage   Show this usage block."
 -s subject Override default subject. Default is filename of <infile>"
 -f from    Override default from: user. Default is \$USER@\$SERVER
 <infile>   The file to mail. Required if stdin not provided.
 email1...  Overrides default email addresses. Default is ${defaultuser}
Accepts stdin and will use the first line as the subject if not specified.
Example usage:
 send.sh -hs "algol cpuchk.sh out" /tmp/cpuchk.out root@hostname
 cat foobar.* | send.sh -h
Return values:
0 Normal
1 Help screen displayed
2 No input (file or stdin)
3 Incorrect OS type
4 Unable to find dependency
ENDUSAGE
}

# DEFINE FUNCTIONS
build_interestedparties() {
   people=
   for word in $opt1 $opt2 $opt3 $opt4 $opt5 $opt6 $opt7 $opt8 $opt9 ${opt10} ${opt11} ${opt12} ${opt13};
   do
      people=${people}${word}" "
   done
   displayedparties=${people%" "} #trim trailing space and use correct variable
   interestedparties=$( echo "$displayedparties" | sed "s!${defaultuser}!!g" ) #| read interestedparties
   interestedparties=${interestedparties}" ${defaultuser}" #always tack on default user
}

get_input() {
   [ -t 0 ]; sendstdin_piped=$? #manual check because stdin_piped might be defined by a calling script

   if test -f ${infile1};
   then
      [ ]; # File exists, so proceed normally
   else
      # File doesn't exist, so make it a part of the interestedparties
      interestedparties=${interestedparties}" "${infile1}

      # Check stdin. Gotta have something to read!
      if test "${sendstdin_piped}" = "1";
      then
         # stdin is piped, so let's read it!
         xj=0
         while read line;
         do
            xj=$( expr ${xj} + 1 )
            test ${xj} -eq 1 && { test "$subject" = "$( pwd )/" || test -z "$subject"; } && subject="$line"
            echo "$line" >> $tmpfile1
         done
         infile1="$tmpfile1"
         # if test ${xj} -gt 0; # feature not yet implemented, gotta say unh!
      else
         # file does not exist, and stdin not piped. No input!
         ferror "$scriptfile: 2. $infile1 invalid file. Aborted."
         exit 2
      fi
   fi
}

htmlize_file() {
   #assume $html = 1 already
   rm ${outfile1} 1>/dev/null 2>&1
   {
      printf "<html><body><pre>"
      #less-than becomes ampersand-lt-semicolon
      #greater-than becomes ampersand-gt-semicolon
      sed "s/</\&lt\;/g;s/>/\&gt\;/g;" $infile1
      printf "</pre></body></html>\n"
   } >> $outfile1
}

htmlize_if_necessary() {
   # linux-non-html
   if test "$html" = "1";
   then
      htmlize_file
      subject="${subject}
Mime-Version: 1.0
Content-Type: text/html"
   else
      cp -r $infile1 $outfile1 1>/dev/null 2>&1
   fi
}

htmlize_and_send() {
   # orig command:
   #mail -s "$( echo "${subject}" )" $interestedparties < $outfile1
   case $( uname -s ) in
      FreeBSD)
         htmlize_if_necessary
         mail -s "$( echo "${subject}" )" $interestedparties < $outfile1
         ;;
      Linux)
         #have to check if need to htmlize because it changes the command
         if test "$html" = "1";
         then
            htmlize_file
            cat <<EOF - ${outfile1} | sendmail -t
From: ${fromuser}
To: ${interestedparties}
Subject: ${subject}
Content-Type: text/html
Content-Transfer-Encoding: 8bit

EOF
         else
            #no, so do normal.
            htmlize_if_necessary
            mail -s "$( echo "${subject}" )" $interestedparties < $outfile1
         fi
         ;;
   esac
}

# DEFINE TRAPS

clean_send() {
   ps -ef | grep -iE "send|mail" | grep -vE "grep|vi" >/dev/null 2>&1 # just to slow it down
   rm -f $tmpfile1 $outfile1 >/dev/null 2>&1
   [ ] #use at end of entire script if you need to clean up tmpfiles
}

CTRLC() {
   #trap "CTRLC" 2
   clean_send
}

CTRLZ() {
   #trap "CTRLZ" 18
   clean_send
}

parseFlag() {
   flag=$1
   hasval=0
   case $flag in
      # INSERT FLAGS HERE
      "d" | "debug" | "DEBUG" | "dd" ) setdebug; ferror "debug level ${debug}";;
      "u" | "usage" | "help") usage; exit 1;;
      "s" | "subject") getval; subject=$tempval;;
      "h" | "html" | "HTML") html=1;;
      "f" | "from") getval; fromuser=$tempval;;
      "V" | "fcheck" | "version") ferror "${scriptfile} version ${sendversion}"; exit 1;;
   esac
   
   debuglev 10 && { test ${hasval} -eq 1 && ferror "flag: $flag = $tempval" || ferror "flag: $flag"; }
}

# DETERMINE LOCATION OF FRAMEWORK
while read flocation; do if test -x $flocation && test "$( $flocation --fcheck )" -ge 20151123; then frameworkscript=$flocation; break; fi; done <<EOFLOCATIONS
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
test -z "$frameworkscript" && echo "$0: framework not found. Aborted." 1>&2 && exit 4

# REACT TO OPERATING SYSTEM TYPE
case $( uname -s ) in
   Linux) [ ];;
   FreeBSD) [ ];;
   *) echo "$scriptfile: 3. Indeterminate OS: $( uname -s )" && exit 3;;
esac

# INITIALIZE VARIABLES
# variables set in framework:
# today server thistty scriptdir scriptfile scripttrim
# is_cronjob stdin_piped stdout_piped stderr_piped
# sendsh sendopts
. $frameworkscript
tmpfile1=~/.send.$$.$RANDOM.tmp
outfile1=~/.send.$$.$RANDOM.out
logfile= #not used
interestedparties= #will be defined later
fromuser="${USER}@$( hostname -f )" # can be modified by -f flag
defaultuser="bgstack15@gmail.com"

# SET CUSTOM SCRIPT AND VALUES
#setval 1 sendsh sendopts<<EOFSENDSH      # if $1="1" then setvalout="critical-fail" on failure
#/usr/share/bgscripts/send.sh -hs     #                setvalout maybe be "fail" otherwise
#/usr/local/bin/send.sh -hs               # on success, setvalout="valid-sendsh"
#/usr/bin/mail -s
#EOFSENDSH
#test "$setvalout" = "critical-fail" && ferror "${scriptfile}: 4. mailer not found. Aborted." && exit 4

# VALIDATE PARAMETERS
# objects before the dash are options, which get filled with the optvals
# to debug flags, use option DEBUG
validateparams infile1 - "$@"

# CONFIRM TOTAL NUMBER OF FLAGLESSVALS IS CORRECT
if test ${thiscount} -lt 2;
then
   #ferror "$scriptfile: 2. Fewer than 2 flaglessvals. Aborted."
   #exit 2
   opt1="${defaultuser}" #will be parsed into interestedparties
fi

# CONFIGURE VARIABLES AFTER PARAMETERS
test -z "$subject" && subject=$( fwhich "$infile1" )

# SET TRAPS
trap "CTRLC" 2
trap "CTRLZ" 18
#trap "clean_send" 0

# MAIN LOOP
#{
   build_interestedparties
   get_input
   #htmlize_if_necessary
   
   # send and/or debug 
   if debuglev 1;
   then
      ferror "mail -s \"$( echo "${subject}" )\" ${displayedparties} < $infile1"
      ferror "email not sent because of DEBUG flag"
   else
      htmlize_and_send
      #mail -s "$( echo "${subject}" )" $interestedparties < $outfile1
   fi
#} | tee -a $logfile

# EMAIL LOGFILE
#$sendsh $sendopts "$server $scriptfile out" $logfile $interestedparties
clean_send
