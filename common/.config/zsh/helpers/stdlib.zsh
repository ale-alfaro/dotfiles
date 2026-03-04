#!/usr/bin/env zsh
#
## Set option for bash compatibility
## BASH_REMATCH stores the result of a regex expression
# setopt BASH_REMATCH
## Zsh arrays are 1-indexed by default. This options enable 0-indexed arrays which are compatible with bash
# setopt KSH_ARRAYS
# Usage: has <command>

# Usage: log_status [<message> ...]
#
# Logs a status message. Acts like echo,
# but wraps output in the standard direnv log format
# and directs it to stderr rather than stdout.
#
# Example:
#
#    log_status "Loading ..."
#
log_status() {
  print "$*"
}

# Usage: log_error [<message> ...]
#
# Logs an error message. Acts like echo,
# but wraps output in the standard direnv log format
# and directs it to stderr rather than stdout.
#
# Example:
#
#    log_error "Unable to find specified directory!"

error() {
  print "error: $*"
  exit 1
}
# Returns 0 if the <command> is available. Returns 1 otherwise. It can be a
# binary in the PATH or a shell function.
#
# Example:
#
#    if has curl; then
#      echo "Yes we do"
#    fi
#
has() {
  type "$1" &>/dev/null || {
    error "Command not found: $1 "
    return 1
  }
  return 0
}

safe_source() {
  cmd="$1"
  type "$cmd" &>/dev/null || {
    error "Command not found: $cmd "
    return 1
  }
  shift
  source <($cmd "$@")
}
# Usage: join_args [args...]
#
# Joins all the passed arguments into a single string that can be evaluated by bash
#
# This is useful when one has to serialize an array of arguments back into a string
join_args() {
  printf '%q ' "$@"
}

# Usage: expand_path <rel_path> [<relative_to>]
#
# Outputs the absolute path of <rel_path> relative to <relative_to> or the
# current directory.
#
# Example:
#
#    cd /usr/local/games
#    expand_path ../foo
#    # output: /usr/local/foo
#
expand_path() {
  REPLY=.
  realpath "$1"
  REPLY=${REPLY:-/}
}
append_path () {
  case ":$PATH:" in
    *:"$1":*)
      ;;
    *)
      PATH="${PATH:+$PATH:}$1"
  esac
}

# Usage: PATH_add <path> [<path> ...]
#
# Prepends the expanded <path> to the PATH environment variable, in order.
# It prevents a common mistake where PATH is replaced by only the new <path>,
# or where a trailing colon is left in PATH, resulting in the current directory
# being considered in the PATH.  Supports adding multiple directories at once.
#
# Example:
#
#    pwd
#    # output: /my/project
#    PATH_add bin
#    echo $PATH
#    # output: /my/project/bin:/usr/bin:/bin
#    PATH_add bam boum
#    echo $PATH
#    # output: /my/project/bam:/my/project/boum:/my/project/bin:/usr/bin:/bin
#
PATH_add() {
  path_add PATH "$@"
}



# Usage: semver_search <directory> <folder_prefix> <partial_version>
#
# Search a directory for the highest version number in SemVer format (X.Y.Z).
#
# Examples:
#
# $ tree .
# .
# |-- dir
#     |-- program-1.4.0
#     |-- program-1.4.1
#     |-- program-1.5.0
# $ semver_search "dir" "program-" "1.4.0"
# 1.4.0
# $ semver_search "dir" "program-" "1.4"
# 1.4.1
# $ semver_search "dir" "program-" "1"
# 1.5.0
#
semver_search() {
  local version_dir=${1:-}
  local prefix=${2:-}
  local partial_version=${3:-}
  # Look for matching versions in $version_dir path
  # Strip possible "/" suffix from $version_dir, then use that to
  # strip $version_dir/$prefix prefix from line.
  # Sort by version: split by "." then reverse numeric sort for each piece of the version string
  # The first one is the highest
  find "$version_dir" -maxdepth 1 -mindepth 1 -type d -name "${prefix}${partial_version}*" |
    while IFS= read -r line; do echo "${line#"${version_dir%/}"/"${prefix}"}"; done |
    sort -t . -k 1,1rn -k 2,2rn -k 3,3rn |
    head -1
}

arr2quotes(){
    emulate -L zsh
    typeset -U ar
    local ar=()

    if [[ $# == 0 ]]; then
        # Listen to STDIN if no arguments are provided
        ar=( ${(f)$(<&0)} )
    fi

    while [[ $# > 0 ]]; do
        if [[ -r "$1" && -f "$1" ]]; then
            # A readable file.
            ar=(
                $ar[@]
                "${(fq)$(<$1)}"
            )
        elif [[ ${(Pt)1} = "array" ]]; then
            ar=(
                $ar[@]
                ${(Pq)1}
            )
        else
            echo "Do not understand: $1" >&2
            echo "Arguments need to be files, names of arrays, or standard input." >&2
            echo 'Arrays must be referenced by name, so use `array` instead of `$array`.' >&2
            return 1
        fi
        shift
    done

    print ${(j:, :)${(qq)ar[@]}}
}
