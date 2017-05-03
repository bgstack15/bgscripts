# File: /usr/share/bgscripts/bashrc.d/debian.bashrc

# update-repo command for apt-get update just one repository
# Reference: http://askubuntu.com/questions/65245/apt-get-update-only-for-a-specific-repository/197532#197532
update-repo() {
   for source in "$@"; do
      sudo apt-get update -o Dir::Etc::sourcelist="sources.list.d/${source}.list" \
         -o Dir::Etc::sourceparts="-" -o APT::Get::List-Cleanup="0"    
   done
}

# autocomplete for update-repo
_ppa_lists() {
   local cur
   _init_completion || return
   COMPREPLY=( $( find /etc/apt/sources.list.d/ -name "*${cur}*.list" \
      -exec basename {} \; 2>/dev/null | sed 's!\.list$!!;' 2>/dev/null ) )
   return 0
} &&
complete -F _ppa_lists update-repo

# for bounce.sh
_bounce_autocomplete() {
   local cur prev words cword;
   _init_completion || return
   _tmpfile1="$( mktemp )"
   case "${prev}" in
      -n|--network)
         _available_interfaces; echo "${COMPREPLY[@]}" > "${_tmpfile1}"
         ;;
      -s|--service)
         _services; echo "${COMPREPLY[@]}" >> "${_tmpfile1}"
         ;;
      -m|--mount)
         awk '$3 ~ /cifs|nfs/{print $2}' /etc/fstab >> "${_tmpfile1}"
         ;;
      *)
         printf -- "-m\n-n\n-s\n--network\n--service\n--mount" >> "${_tmpfile1}"
         ;;
   esac
   COMPREPLY=($( compgen -W "$( cat ${_tmpfile1} )" -- "$cur" ))
   command rm -rf "${_tmpfile1}" 1>/dev/null 2>&1
   return 0
}
complete -F _bounce_autocomplete bounce
