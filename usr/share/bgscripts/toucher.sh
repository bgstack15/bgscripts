#!/bin/sh
# Call: toucher root:root 0755 /var/file

toucher_user="${1}"
toucher_mode="${2}"
toucher_file="${3}"

touch "${toucher_file}"; chown "${toucher_user}" "${toucher_file}"; chmod "${toucher_mode}" "${toucher_file}"; restorecon "${toucher_file}"
