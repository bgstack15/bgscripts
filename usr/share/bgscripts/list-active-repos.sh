#!/bin/sh
# File: list-active-repos.sh

indir=/etc/yum.repos.d/
infiles='.*\.repo'
tmpdir=$( mktemp -d )
tmpfile1=$( TMPDIR="${tmpdir}" mktemp )
tmpfile2=$( TMPDIR="${tmpdir}" mktemp )
test -z LAR_SHOWFILENAME && LAR_SHOWFILENAME=0
. /usr/share/bgscripts/framework.sh || { echo "Need framework. Aborted." ; exit 1 ; }

clean_list_active_repos() {
   rm -rf "${tmpdir:-NOTHINGTODEL}" 1>/dev/null 2>&1
}

trap 'clean_list_active_repos ; trap "" {0..20}; exit 0;' {0..20}

# list all repository files
find "${indir}" -type f -regextype grep -regex "${infiles}" > "${tmpfile1}"

#cat "${tmpfile1}"
for thisfile in $( cat "${tmpfile1}" );
do

   # Prepare filename for display
   extra=""
   fistruthy "${LAR_SHOWFILENAME}" && extra="${thisfile} "

   awk -v "extra=${extra}" '
BEGIN {a=0;name="";b=-1;}
/^\s*\[/ {oldname=name;name=$0;if (b!=a) print extra oldname; a=a+1;}
ENDFILE{if (b!=a) print extra name;}
/^\s*enabled\s*=\s*0\s*$/ {b=a;}
' "${thisfile}" \
   | sed -r -e 's/\[|\]//g;' \
   | { if fistruthy "${LAR_SHOWFILENAME}";
      then
        # Only show filenames for files with active repos
        awk 'NF>=2 {print}'
      else
        cat
      fi
     } \
   | sed -r -e '/^\s*$/d' 

done

exit 0
