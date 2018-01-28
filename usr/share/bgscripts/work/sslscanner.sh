#!/bin/sh
# sslscanner.sh
# this utility will visit a website and display the issuer, subject, and dates of all the certs in the chain.
# Improve: accept --sni, [ file.ext | https://site:443 ]

# FUNCTIONS
clean_sslscanner() {
   rm -rf "${ss_tmpdir:-NOTHINGTODELETE}" 1>/dev/null 2>&1
}

get_openssl_format_site() {
   # call: get_openssl_format_site connect "${site}"
   local output=""
   local thistype="${1}"
   local input="${2}"
   case "${thistype}" in
      connect)
         # output = example.com:443
         output="$( echo "${input}" | sed -r -e 's/(.{0,8}:\/\/[^\/]+)\/.*/\1/;' -e 's/.{0,8}:\/\///;' -e '/:[0-9]+/!{s/$/:443/;}' )"
         ;;
      sni)
         # output = example.com
         output="$( echo "${input}" | sed -r -e 's/.{0,8}:\/\/([^\/]+).*/\1/;' -e 's/:[0-9]*$//;' )"
         ;;
      *)
         echo "get_openssl_format_site does not support \"${thistype}\" yet. Outputting empty string..." 1>&2
         ;;
   esac
   printf "%s" "${output}"
}

# VARIABLES
site="${1}"
connectsite="$( get_openssl_format_site connect "${site}" )"
test -z "${snisite}" && snisite="$( get_openssl_format_site sni "${site}" )"
ss_tmpdir="$( mktemp -d )"
trap '__ec=$? ; clean_sslscanner ; trap "" {0..20} ; exit ${__ec} ;' {0..20}
outputraw="$( TMPDIR="${ss_tmpdir}" mktemp )"
test -z "${VISUAL}" && VISUAL="$( which vi )"

# FETCH CERTS
echo "" | openssl s_client -showcerts -servername "${snisite}" -connect "${connectsite}" 1> "${outputraw}" 2>/dev/null

# DISPLAY CERTS
count_regcert=$( grep -cE -- "-----BEGIN CERTIFICATE" "${outputraw}" )
x=0 ; cat "${outputraw}" | { while test "${x}" -lt ${count_regcert} ; do openssl x509 -noout -issuer -subject -dates ; x=$(( x + 1 )) ; done ; }

${VISUAL} "${outputraw}"
