#!/bin/sh
# Filename: changelog.sh
# Author: bgstack15@gmail.com
# Startdate: 2017-01-27 10:11:06
# Title: Script that Converts the Format of Changelogs
# Purpose: 
# Package: 
# History: 
#    2017-11-11a Added FreeBSD location support
# Usage: 
# Reference: ftemplate.sh 2017-01-11a; framework.sh 2017-01-11a
#    date format https://www.debian.org/doc/debian-policy/ch-source.html#s-dpkgchangelog
# Improve:
#  x use functions
#  x allow -i infile, -o outfile, -o stdout, -i stdin
#  x if outfile is spec, replace any existing changelog. Do not overwrite rest of file.
#  x sanity check for filename and requested output
#  x -f force and ignore sanity check
#  x auto-select output type based on thisflavor.
fiversion="2017-01-17a"
changelogversion="2017-11-11a"

usage() {
   less -F >&2 <<ENDUSAGE
usage: changelog.sh [-duV] [-f] [-i infile] [-o outfile] [ rpm | (deb|dpkg) ] [ -p packagename ]
version ${changelogversion}
 -d debug   Show debugging info, including parsed variables.
 -u usage   Show this usage block.
 -V version Show script version number.
 -f force   Just overwrite the relevant parts of the outfile, regardless of type.
 -i infile  File to be converted. 'stdin' is available as an option.
 -o outfile Output file. If a .spec, replace any %changelog present. Default is stdout.
 -p packagename Name to use if output is deb. Can be determined if an understandable filename.
Return values:
0 Normal
1 Help or version info displayed
2 Count or type of flaglessvals is incorrect
3 Incorrect OS type
4 Unable to find dependency
5 Not run as root or sudo
6 Invalid type for outfile. Can be ignored with the --force flag.
ENDUSAGE
}

# DEFINE FUNCTIONS
function outputtodeb {
   # call: outputtodeb "${packagename}" < "${infile}"
   # reads stdin and performs changes
   #  must provide packagename because a spec file does not include it in the %changelog
   _packagename="${1}"
   _file1=$( mktemp )
   _file2=$( mktemp )
   { echo ""; 
   sed -e '
1,/^%changelog/d
' ; echo ""; } > "${_file1}"
   while true;
   do
      sed -n -e '1,/^$/p' ${_file1} > "${_file2}" # get each paragraph
      test $( wc -l < ${_file2} ) -lt 2 && break
      sed -i -e '1,/^$/d' ${_file1} # delete first paragraph which we will now examine
      entryline="$( grep -E '^\* ([A-Z][a-z]{2,3} ?){2}[0-3][0-9] [0-9]{4}' "${_file2}" )"
      entrydate="$( echo "${entryline}" | grep -oE '([A-Z][a-z]{2,3} ?){2}[0-3][0-9] [0-9]{4}' )"
      entryversion="$( echo "${entryline}" | awk -e '{ print $NF }' )"
      entryperson="$( echo "${entryline}" | sed -e "s/\s*\*\s*${entrydate}//;s/${entryversion}//;s/^ *//;s/ *$//;" )"
      entrystability=stable
      printf "%s (%s) %s;\n\n" "${_packagename}" "${entryversion}" "${entrystability}"
      sed -n -e 's/^- /  * /p;' "${_file2}"
      printf "\n -- %s  %s\n\n" "${entryperson}" "$( date -R --date "${entrydate}" )"
   done

   rm -rf "${_file1}" "${_file2}"
}

function outputtorpm {
   # call: outputtorpm
   # reads stdin and performs changes
   _file1=$( mktemp )
   _file2=$( mktemp )
   { 
   sed -e '
/^\s*$/d
/^ -- .*$/a\FOOQUX
' | \
   sed -e '
s/^FOOQUX.*$//;
'; echo ""; } > "${_file1}"
   while true;
   do
      sed -n -e '1,/^$/p' ${_file1} > "${_file2}" # get each paragraph
      test $( wc -l < ${_file2} ) -lt 2 && break
      sed -i -e '1,/^$/d' ${_file1} # delete the first paragraph which we will now examine
      entrypackagename="$( head -n1 "${_file2}" | awk '{print $1}' )" # not actually needed
      entryversion="$( head -n1 "${_file2}" | grep -oiE "\(.*\)" | tr -d '()' )"; sed -i -e '1d' "${_file2}"
      entryline="$( grep -iE -- '^ -- .*' "${_file2}" | sed -e 's/^ -- //;' )"; sed -i -e '/^ -- .*/d;' "${_file2}"
      entrydate="$( echo "${entryline}" | grep -oIE -- "  [A-Z][a-z]{2}, [0-3 ][0-9] [A-Z][a-z]{2} [0-9]{4} [0-2 ][0-9]:[0-5][0-9]:[0-5][0-9] [-+][0-9]{4}" | sed -e 's/^ *//;')"
      entryperson="$( echo "${entryline}" | sed -e "s/${entrydate}//;" | sed -e 's/ *$//;' )"
      printf "* %s %s %s\n" "$(date --date "${entrydate}" "+%a %b %d %Y" )" "${entryperson}" "${entryversion}"
      sed -n -e 's/^\s\{0,4\}\*\? /- /p;' "${_file2}"
      printf "\n"
   done

   rm -rf "${_file1}" "${_file2}"
}

# DEFINE TRAPS

clean_changelog() {
   rm -rf "${tmpfile1}" 1>/dev/null 2>&1
   #use at end of entire script if you need to clean up tmpfiles
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
      "u" | "usage" | "help" | "h" ) usage; exit 1;;
      "V" | "fcheck" | "version" ) ferror "${scriptfile} version ${changelogversion}"; exit 1;;
      "f" | "force" ) force=1;;
      "i" | "infile" | "inputfile" ) getval; infile=${tempval};;
      "o" | "outfile" | "outputfile" ) getval; outfile="${tempval}";;
      "p" | "package" | "packagename" ) getval; packagename="${tempval}";;
   esac
   
   debuglev 10 && { test ${hasval} -eq 1 && ferror "flag: ${flag} = ${tempval}" || ferror "flag: ${flag}"; }
}

# DETERMINE LOCATION OF FRAMEWORK
while read flocation; do if test -e ${flocation} && test "$( sh ${flocation} --fcheck 2>/dev/null )" -ge 20170111; then frameworkscript="${flocation}"; break; fi; done <<EOFLOCATIONS
/usr/local/share/bgscripts/framework.sh
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
force=0 # can be changed with --force flag
infile=
outfile=
logfile=${scriptdir}/${scripttrim}.${today}.out
tmpfile1="$( mktemp )"
interestedparties="bgstack15@gmail.com"
packagename= # will be calculated or provided by flagvals.

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
validateparams type - "$@"

# CONFIRM TOTAL NUMBER OF FLAGLESSVALS IS CORRECT
#if test ${thiscount} -lt 1;
#then
#   ferror "${scriptfile}: 2. Gotta say unh! Please provide rpm or deb format. The ability to auto-detect is not yet implemented. Aborted."
#   exit 2
#fi

# CONFIGURE VARIABLES AFTER PARAMETERS
case "${type}" in
   rpm)
      :
      ;;
   deb|dpkg)
      type=deb
      ;;
   "")
      # unknown type, so maybe use thisflavor
      debuglev 1 && ferror "Info: Using thisflavor to determine type."
      case "${thisflavor}" in
         centos|redhat|fedora|korora) type=rpm;;
         *ubuntu|debian) type=deb;;
         *) ferror "${scriptfile}: 2. Unknown type: ${type}. Aborted."; exit 2;;
      esac
      ;;
   *)
      ferror "${scriptfile}: 2. Unknown type: ${type}. Aborted."; exit 2
      ;;
esac
if ! test -f "${infile}" && test "${infile}" != "stdin";
then
   ferror "${scriptfile}: 4. No input file given. Use '-i stdin' for stdin. Aborted."
   exit 4
fi

## START READ CONFIG FILE TEMPLATE
#oIFS="${IFS}"; IFS=$'\n'
#infiledata=$( ${sed} ':loop;/^\/\*/{s/.//;:ccom;s,^.[^*]*,,;/^$/n;/^\*\//{s/..//;bloop;};bccom;}' "${infile}") #the crazy sed removes c style multiline comments
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
#trap "CTRLC" 2
#trap "CTRLZ" 18
trap "clean_changelog" 0

# MAIN LOOP
#{
   debuglev 3 && ferror "output type ${type}"
   #case "${infile}" in
   #   -|stdin) echo "FOUND IT!" ;;
   #   *) echo "nope" ;;
   #esac
   
   case "${type}" in
      deb)
         # Get package name
         case "${packagename}" in
            "")
               # need to calculate from directory or input filename.
               if echo "${infile}" | grep -qiE "\.spec$" 2>/dev/null;
               then
                  packagename="$( sed -n -e 's/^[Nn]ame:\s*//p;' "${infile}" )"
               fi
               ;;
            *)
               : # assume it is defined
               ;;
         esac
         case "${infile}" in
            stdin|std|-)
               outputtodeb > "${tmpfile1}"
               ;;
            *)
               outputtodeb "${packagename}" < "${infile}" > "${tmpfile1}"
               ;;
         esac
         ;;
      rpm)
         case "${infile}" in
            stdin|std|-)
               outputtorpm > "${tmpfile1}"
               ;;
            *)
               outputtorpm < "${infile}" > "${tmpfile1}"
               ;;
         esac
         ;;
   esac

   ### Manipulate output
   case "${outfile}" in
      stdout|std|-|"")
         cat "${tmpfile1}"
         ;;
      *)
         if echo "${outfile}" | grep -qiE "\.spec$" 2>/dev/null;
         then
            # this is a spec file, so let's replace any %changelog, which is always at the end of the file.
            if test "${force}" = "1" || test "${type}" = "rpm";
            then
               sed -n -e '1,/^\%changelog$/p;' "${outfile}"
               cat "${tmpfile1}" >> "${outfile}"
            else
               ferror "${scriptfile}: 6. Invalid type ${type} for outfile ${outfile}. Try again with --force flag."
               exit 6
            fi
         elif echo "${outfile}" | grep -qiE "debian.{0,15}\/changelog$" 2>/dev/null;
         then
            # debian/changelog format
            cat "${tmpfile1}" > "${outfile}"
         else
            #some other type of file, so replace contents, I guess
            cat "${tmpfile1}" > "${outfile}"
         fi
   esac

#} | tee -a ${logfile}

# EMAIL LOGFILE
#${sendsh} ${sendopts} "${server} ${scriptfile} out" ${logfile} ${interestedparties}

## STOP THE READ CONFIG FILE
#exit 0
#fi; done; }
