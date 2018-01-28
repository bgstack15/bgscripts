#!/bin/sh
# Filename: sizer.sh
# Location: /usr/share/bgscripts/sizer.sh
# Author: bgstack15
# Startdate: 2018-01-20 15:35
# Title: Script that Calculates Total Size Used of each File Extension
# Purpose: To help me manage files
# History:
# Usage:
#    takes one parameter, the directory to evaluate:
#    ./sizer.sh /mnt/public/Music
#    Environment variables:
#    SIZER_SORT if non-null, will make sizer pipe through sort -n
#    SIZER_HUMAN if nonull, will use kMG notation
# Reference:
#    https://www.gnu.org/software/gawk/manual/html_node/Format-Modifiers.html#Format-Modifiers
#    Running Linux, 3rd Ed., Welsh, Dalheimer, Kaufman page 444
#    https://www.linuxquestions.org/questions/programming-9/convert-number-into-human-readables-in-bash-or-perl-4175479594/#post5039962
# Improve:
# Document:

if test -n "${1}";
then
   td="${1}"
else
   td=.
fi

find "${td}"/ ! -type d -printf "%s %f\n" | perl -e '
while (<STDIN>) {
   if (/^([0-9]+)\s(.*)(\..{1,10})$/) {
      $ext = lc $3; $size{$ext} += $1;
   }
}

# show summary
foreach $thisext (sort(keys %size)) {
   print "$size{$thisext} $thisext\n";
}
' | {
   # SORT IF DESIRED
   if test -n "${SIZER_SORT}";
   then
      sort -n
   else
      cat
   fi
} | {
   # USE HUMAN NUMBERS IF DESIRED
   if test -n "${SIZER_HUMAN}"
   then
      awk '
$1 < 1024^1 {                        print ; next }
$1 < 1024^2 { $1=$1/1024           ; printf "%-.1fk %s\n", $1, $2; next }
$1 < 1024^3 { $1=$1/1024/1024      ; printf "%-.1fM %s\n", $1, $2; next }
$1 < 1024^4 { $1=$1/1024/1024/1024 ; printf "%-.1fG %s\n", $1, $2; next }
'
   else
      cat
   fi
}
