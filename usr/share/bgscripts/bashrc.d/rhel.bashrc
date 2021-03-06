# File: /usr/share/bgscripts/bashrc.d/rhel.bashrc

_command_dnf=yum
which dnf 1>/dev/null 2>&1 && _command_dnf="$( which dnf 2>/dev/null )"

# update-repo command for dnf update just one repository
alias update-repo=_update_repo
_update_repo() {
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
   COMPREPLY=( $( grep -hoiE -- "^\[.*\]" /etc/yum.repos.d/* 2>/dev/null | tr -d '[]' | grep -E "^${2:-.*}" ) )
   return 0
} &&
complete -F _repo_lists -o filenames update-repo

# Reference: https://github.com/folkswithhats/fedy/issues/167
alias clean-oldkernel=_clean_oldkernel
_clean_oldkernel() {
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

# Disused autocomplete. Consider for deletion after 2018-02.
#_cd_mnt() {
#   local cur
#   _init_completion || return
#   finish=$( shift; echo "$@" | sed 's!cdmnt!!;s! $!!;' )
#   #echo "dollar-at=$@" >/dev/pts/1
#   #echo "finish=${finish}" >/dev/pts/1
#   local IFS=$'\r\n'
#   COMPREPLY=( $( cd /mnt/scripts; compgen -d "${finish:-$2}" | sed -e 's!$!/!;' ) )
#   return 0
#} &&
#complete -F _cd_mnt -o nospace cdmnt
