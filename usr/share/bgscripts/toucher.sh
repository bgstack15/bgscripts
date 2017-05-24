#!/bin/sh
# Call: toucher 0755 root:root /var/file

toucher_mode="${1}"
toucher_user="${2}"
toucher_file="${3}"

touch "${toucher_file}"; chmod "${toucher_mode}" "${toucher_file}"; chown "${toucher_user}" "${toucher_file}"; restorecon "${toucher_file}"
