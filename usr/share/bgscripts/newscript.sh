#!/bin/sh
# File: /usr/share/bgscripts/newscript.sh
# Author: bgstack15@gmail.com
# Startdate: 2015-11-06 15:14:01
# Title: Newscript: Script that Copies template.sh to a specified file
# Purpose: To simplify making a new script file
# History: 
# Usage: 
# Reference: 
# Improve:
fiversion="2014-12-03a"
newscriptversion="2017-01-17a"

usage() {
   less -F >&2 <<ENDUSAGE
usage: newscript.sh [-udVf] <outfile>
version ${newscriptversion}
 -u usage   Show this usage block.
 -d debug   Show parameters while being parsed.
 -f force   overwrite existing <outfile>. By default, it will fail.
Return values:
0 Normal
1 Help or version info displayed
2 Count or type of flaglessvals is incorrect
3 Incorrect OS type
4 Unable to find dependency
5 File already exists but --force was not used
ENDUSAGE
}

# DEFINE FUNCTIONS

parseFlag() {
   flag=$1
   hasval=0
   case $flag in
      # INSERT FLAGS HERE
      "d" | "debug" | "DEBUG" | "dd" ) setdebug; ferror "debug level ${debug}";;
      "u" | "usage" | "help") usage; exit 1;;
      "V" | "fcheck" | "version") echo "${scriptfile} version ${newscriptversion}"; exit 1;;
      "f" | "force") force=1;;
   esac
   
      debuglev 10 && { test ${hasval} -eq 1 && ferror "flag: $flag = $tempval" || ferror "flag: $flag"; }
}

# DETERMINE LOCATION OF FRAMEWORK
while read flocation; do if test -x $flocation && test "$( $flocation --fcheck )" -ge 20160803; then frameworkscript=$flocation; break; fi; done <<EOFLOCATIONS
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
   Linux) myeditor=/usr/bin/vi;;
   FreeBSD) myeditor=/usr/local/bin/vim;;
   *) ferror "$scriptfile: 3. Indeterminate OS: $( uname -s )" && exit 3;;
esac

# INITIALIZE VARIABLES
# variables set in framework:
# today server thistty scriptdir scriptfile scripttrim
# is_cronjob stdin_piped stdout_piped stderr_piped
# sendsh sendopts
. $frameworkscript
infile= # defined below
outfile= # defined by user on cli. required.
logfile=${scriptdir}/${scripttrim}.${today}.out
interestedparties="root"
#myeditor=/usr/bin/vi # works on CentOS
now=$( date "+%Y-%m-%d %T" )
      chmodcmd=/usr/bin/chmod

# DETERMINE LOCATION OF TEMPLATE
setval 1 infile <<EOFINFILE
./ftemplate.sh
${scriptdir}/ftemplate.sh
~/bin/bgscripts/ftemplate.sh
~/bin/ftemplate.sh
~/bgscripts/ftemplate.sh
~/ftemplate.sh
/usr/local/bin/bgscripts/ftemplate.sh
/usr/local/bin/ftemplate.sh
/usr/bin/bgscripts/ftemplate.sh
/usr/bin/ftemplate.sh
/bin/bgscripts/ftemplate.sh
/usr/share/bgscripts/ftemplate.sh
EOFINFILE
[ ];
test "$setvalout" = "critical-fail" && ferror "$scriptfile: 4. template not found. Aborted." && exit 4

# VALIDATE PARAMETERS
# objects before the dash are options, which get filled with the optvals
# to debug flags, use option DEBUG
validateparams outfile - "$@"

# CONFIRM TOTAL NUMBER OF FLAGLESSVALS IS CORRECT
if test $thiscount -lt 1;
then
   ferror "$scriptfile: 2. Fewer than 1 flaglessval. Aborted."
   exit 2
fi

# CONFIGURE VARIABLES AFTER PARAMETERS
scriptdashless="$( echo "${outfile}" | tr -d '-' )"
myscripttrim="${scriptdashless%.sh}"

# MAIN LOOP
#{
   if test ! -f ${infile};
   then
      ferror "${scriptfile}: 4. Cannot find ${infile}. Aborted."
      exit 4
   fi
   if test -f ${outfile} && test ! "${force}" = "1";
   then   
      ferror "${scriptfile}: 5. File ${outfile} exists but --force was not used. Aborted."
      exit 5
   fi

   # template file exists and outfile does not exist or will be forced

   # perform a few changes to template while making new file
   sed "s!SCRIPTNAME!${outfile}!g;s/SCRIPTTRIM/${myscripttrim}/g;s/INSERTDATE/${today}/g;s/INSERTLONGDATE/${now}/g;" < ${infile} > ${outfile}

   # keep file permissions as template. We are assuming Framework maintains valid file perms for its template file.
   ${chmodcmd} --ref "${infile}" "${outfile}"

   # load my editor with the file
   ${myeditor} "${outfile}"

#} | tee -a $logfile

# EMAIL LOGFILE
#$sendsh $sendopts "$server $scriptfile out" $logfile $interestedparties
