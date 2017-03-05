# File: /usr/share/bgscripts/bashrc.d/rhel.bashrc

_command_dnf=yum
which dnf 1>/dev/null 2>&1 && _command_dnf="$( which dnf 2>/dev/null )"

# update-repo command for dnf update just one repository
update-repo() {
   case "${_command_dnf}" in
      *dnf)
         for source in "$@"; do
            sudo "${_command_dnf}" check-update -q --refresh --disablerepo=* --enablerepo="${source}"
         done
         ;;
      *yum)
         for source in "$@"; do
            sudo "${_command_dnf}" clean metadata -q --disablerepo=* --enablerepo="${source}" -q; yum check-update -q --disablerepo=* --enablerepo="${source}"
         done
         ;;
   esac
}

# autocomplete for update-repo
_repo_lists() {
   local cur
   _init_completion || return
   COMPREPLY=( $( grep -hoiE -- "^\[.*\]" /etc/yum.repos.d/* | tr -d '[]' | grep -E "^${2:-.*}" ) )
   return 0
} &&
complete -F _repo_lists -o filenames update-repo

# Reference: https://github.com/folkswithhats/fedy/issues/167
clean-oldkernel() {
   case "${_command_dnf}" in
      *yum)
         package-cleanup --oldkernel --count="${1}"
         ;;
      *dnf)
         _oldkernels="$( "${_command_dnf}" repoquery --installonly --latest-limit -"${1}" -q )"
         test -n "${_oldkernel}" && "${_command_dnf}" erase "${_oldkernels}" || \
            echo "Nothing to do."
         ;;
      *)
         echo "Package manager unrecognized: ${_command_dnf}. Aborted."
         ;;
   esac
}

_cd_mnt() {
   local cur
   _init_completion || return
   finish=$( shift; echo "$@" | sed 's!cdmnt!!;s! $!!;' )
   #echo "dollar-at=$@" >/dev/pts/1
   #echo "finish=${finish}" >/dev/pts/1
   local IFS=$'\r\n'
   COMPREPLY=( $( cd /mnt/scripts; compgen -d "${finish:-$2}" | sed -e 's!$!/!;' ) )
   return 0
} &&
complete -F _cd_mnt -o nospace cdmnt
