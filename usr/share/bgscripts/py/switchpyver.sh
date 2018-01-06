#!/bin/sh
# Script that converts the symlinks in a directory to the correct version of python libraries
inputdir="${1}" ; test -z "${inputdir}" && inputdir="$( dirname "$( readlink -f ${0} )" )"
! test -d "${inputdir}" && exit 0
pushd "${inputdir}" 1>/dev/null 2>&1
pyver="$( "$( which python )" -c 'import sys; print(sys.version[0]);' )"
for tf in $( find . -regex '.*.py2' );
do
   tl="$( basename ${tf} .py2 ).py"
   td="${tl}${pyver}"
   ln -sf "${td}" "${tl}" 1>/dev/null 2>&1
done
popd 1>/dev/null 2>&1
