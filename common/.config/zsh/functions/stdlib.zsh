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
  # exit 1
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
  type "$1" &>/dev/null
  if (( $? != 0 )); then
        error "Command not found: $1 "
  fi

  return 0
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
# --- vendored from https://github.com/bashup/realpaths
# realpath.dirname() {
#   REPLY=.
#   ! [[ $1 =~ /+[^/]+/*$|^//$ ]] || REPLY="${1%"${BASH_REMATCH[0]}"}"
#   REPLY=${REPLY:-/}
# }
# realpath.basename() {
#   REPLY=/
#   ! [[ $1 =~ /*([^/]+)/*$ ]] || REPLY="${BASH_REMATCH[1]}"
# }
#
# realpath.absolute() {
#   REPLY=$PWD
#   # local eg=extglob
#   # ! shopt -q $eg || eg=
#   # ${eg:+shopt -s $eg}
#   while (($#)); do case $1 in
#     // | //[^/]*)
#       REPLY=//
#       set -- "${1:2}" "${@:2}"
#       ;;
#     /*)
#       REPLY=/
#       set -- "${1##+(/)}" "${@:2}"
#       ;;
#     */*) set -- "${1%%/*}" "${1##"${1%%/*}"+(/)}" "${@:2}" ;;
#     '' | .) shift ;;
#     ..)
#       realpath.dirname "$REPLY"
#       shift
#       ;;
#     *)
#       REPLY="${REPLY%/}/$1"
#       shift
#       ;;
#     esac done
#   # ${eg:+shopt -u $eg}
# }

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

# Usage: path_add <varname> <path> [<path> ...]
#
# Works like PATH_add except that it's for an arbitrary <varname>.
path_add() {
  local var_name="$1"
  shift

  # Get the current value of the variable and split it into an array
  typeset -a current_paths
  IFS=: read -r current_paths <<<"${(P)var_name}" # (P) parameter expansion to get value of var_name

  local new_paths=()
  for p in "$@"; do
    local abs_path=$(realpath "$p")
    # Add to new_paths only if it's not already in current_paths or new_paths
    local found=0
    for existing_path in "${current_paths[@]}"; do
      if [[ "$existing_path" == "$abs_path" ]]; then
        found=1
        break
      fi
    done
    if [[ "$found" -eq 0 ]]; then
      for existing_new_path in "${new_paths[@]}"; do
        if [[ "$existing_new_path" == "$abs_path" ]]; then
          found=1
          break
        fi
      done
    fi

    if [[ "$found" -eq 0 ]]; then
      new_paths+=("$abs_path")
    fi
  done

  # Prepend the new paths to the existing paths
  local final_paths=("${new_paths[@]}" "${current_paths[@]}")

  # Join back all the paths
  local joined_path=$(
    IFS=:
    echo "${final_paths[*]}"
  )

  # And finally export back the result to the original variable
  export "$var_name=$joined_path"
}

# Usage: MANPATH_add <path>
#
# Prepends a path to the MANPATH environment variable while making sure that
# `man` can still lookup the system manual pages.
#
# If MANPATH is not empty, man will only look in MANPATH.
# So if we set MANPATH=$path, mpath_arrayan will only look in $path.
# Instead, prepend to `man -w` (which outputs man's default paths).
#
MANPATH_add() {
  local old_paths="${MANPATH:-$(man -w)}"
  local dir
  dir=$(expand_path "$1")
  export "MANPATH=$dir:$old_paths"
}

# Usage: PATH_rm <pattern> [<pattern> ...]
# Removes directories that match any of the given shell patterns from
# the PATH environment variable. Order of the remaining directories is
# preserved in the resulting PATH.
#
# Bash pattern syntax:
#   https://www.gnu.org/software/bash/manual/html_node/Pattern-Matching.html
#
# Example:
#
#   echo $PATH
#   # output: /dontremove/me:/remove/me:/usr/local/bin/:...
#   PATH_rm '/remove/*'
#   echo $PATH
#   # output: /dontremove/me:/usr/local/bin/:...
#
# PATH_rm() {
#   path_rm PATH "$@"
# }

# Usage: path_rm <varname> <pattern> [<pattern> ...]
#
# Works like PATH_rm except that it's for an arbitrary <varname>.
# path_rm() {
#   local path i discard var_name="$1"
#   # split existing paths into an array
#   # typeset -a path_array
#   declare -a path_array
#   IFS=: read -ra path_array <<<"${!1}"
#   shift
#
#   patterns=("$@")
#   results=()
#
#   # iterate over path entries, discard entries that match any of the patterns
#   # shellcheck disable=SC2068
#   for path in ${path_array[@]+"${path_array[@]}"}; do
#     discard=false
#     # shellcheck disable=SC2068
#     for pattern in ${patterns[@]+"${patterns[@]}"}; do
#       if [[ "$path" == +($pattern) ]]; then
#         discard=true
#         break
#       fi
#     done
#     if ! $discard; then
#       results+=("$path")
#     fi
#   done
#
#   # join the result paths
#   result=$(
#     IFS=:
#     echo "${results[*]}"
#   )
#
#   # and finally export back the result to the original variable
#   export "$var_name=$result"
# }

# Usage: load_prefix <prefix_path>
#
# Expands some common path variables for the given <prefix_path> prefix. This is
# useful if you installed something in the <prefix_path> using
# $(./configure --prefix=<prefix_path> && make install) and want to use it in
# the project.
#
# Variables set:
#
#    CPATH
#    LD_LIBRARY_PATH
#    LIBRARY_PATH
#    MANPATH
#    PATH
#    PKG_CONFIG_PATH
#
# Example:
#
#    ./configure --prefix=$HOME/rubies/ruby-1.9.3
#    make && make install
#    # Then in the .envrc
#    load_prefix ~/rubies/ruby-1.9.3
#
load_prefix() {
  abs=$(realpath "$1")
  # MANPATH_add "$REPLY/man"
  # MANPATH_add "$REPLY/share/man"
  # path_add CPATH "$REPLY/include"
  path_add LD_LIBRARY_PATH "$abs/lib"
  path_add LIBRARY_PATH "$abs/lib"
  PATH_add "$abs/bin"
  # path_add PKG_CONFIG_PATH "$REPLY/lib/pkgconfig"
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

# Usage: use node [<version>]
#
# Loads the specified NodeJS version into the environment.
#
# If a partial NodeJS version is passed (i.e. `4.2`), a fuzzy match
# is performed and the highest matching version installed is selected.
#
# If no version is passed, it will look at the '.nvmrc' or '.node-version'
# files in the current directory if they exist.
#
# Environment Variables:
#
# - $NODE_VERSIONS (required)
#   Points to a folder that contains all the installed Node versions. That
#   folder must exist.
#
# - $NODE_VERSION_PREFIX (optional) [default="node-v"]
#   Overrides the default version prefix.
#
use_nvim() {
  local version="$1"
  local nvim_version_prefix="nvim-v"
  local search_version
  local nvim_prefix

  if [[ -z ${NVIM_HOME} || ! -d ${NVIM_HOME} ]]; then
    error "You must specify a $NVIM_HOME environment variable and the directory specified must exist!"
  fi
  #   ${var#pattern} - If the pattern match the beginning of the value of var, the match is deleted and the rest is expanded. Use ## to match larger matching pattern.
  #   Aka we are removing the prefix 'v'
  version=${version#v}

  if [[ -z $version ]]; then
    error "I do not know which NodeJS version to load because one has not been specified!"
  fi

  # Search for the highest version matching $version in the folder
  search_version=$(semver_search "$NVIM_HOME" "${nvim_version_prefix}" "${version}")
  nvim_prefix="${NVIM_HOME}/${nvim_version_prefix}${search_version}"

  if [[ ! -d $nvim_prefix ]]; then
      error "Unable to find NodeJS version ($version) in ($NVIM_HOME)!"
  fi
  nvim_exe=${nvim_prefix}/bin/nvim 
  if [[ ! -x $nvim_exe ]]; then
      error "Unable to load Neovim (nvim) for version ($version) in ($NVIM_HOME)!"
  fi

  load_prefix "$nvim_prefix"

  version_read=$(nvim --version)

  if [[ ! -z $version_read ]]; then
    log_status "Successfully loaded Neovim $version_read, from prefix ($nvim_prefix)"
  else
    error "Failed to load Neovim $version_read, from prefix ($nvim_prefix)"
  fi
}

