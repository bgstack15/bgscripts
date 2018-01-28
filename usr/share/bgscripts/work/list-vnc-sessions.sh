#!/bin/sh
# File: list-vnc-sessions.sh
# Location: /usr/share/bgscripts/work/list-vnc-sessions.sh
# Author: bgstack15
# Startdate: 2018-01-22
# Title: Script that Lists the Active VNC Sessions
# Purpose: To find the tcp port number of my previous session so I can reconnect
# History:
# Usage:
# Reference:
#    all original efforts
# Improve:
#    include parameters to change output columns and layout
# Document:

# Oneliner version
#{ echo "user pid Xdisplay port"; { ps -ef | awk '/Xvnc :[[:digit:]]+/ {print $1,$2,$9}' | while read tu tpid tvnc; do sudo netstat -tlpn | awk -v "tpid=${tpid}" '$0 ~ tpid {print $4;}' | sed -r -e 's/^.*://;' -e "s/^/${tu} ${tpid} ${tvnc} /;" ; done ; } | sort -k3 ; } | column -c4 -t

# FUNCTIONS
clean_tmp() {
   rm -rf "${tmpdir:-NOTHINGTODELETE}" 1>/dev/null 2>&1
}
# DEFINE VARIABLES
tmpdir="$( mktemp -d )"
trap 'clean_tmp ; trap "" {0..20} ; exit 0 ;' {0..20}
netstat_file="$( TMPDIR="${tmpdir}" mktemp )"

# FETCH PRIVILEGED OUTPUT
sudo netstat -tlpn > "${netstat_file}"

{ echo "user pid Xdisplay port"; { ps -ef | awk '/Xvnc :[[:digit:]]+/ {print $1,$2,$9}' | while read tu tpid tvnc; do awk -v "tpid=${tpid}" '$0 ~ tpid {print $4;}' "${netstat_file}" | sed -r -e 's/^.*://;' -e "s/^/${tu} ${tpid} ${tvnc} /;" ; done ; } | sort -k3 ; } | column -c4 -t
