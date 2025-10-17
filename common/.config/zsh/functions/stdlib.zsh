#!/usr/bin/env zsh
#
## Set option for bash compatibility
## BASH_REMATCH stores the result of a regex expression
# setopt BASH_REMATCH
## Zsh arrays are 1-indexed by default. This options enable 0-indexed arrays which are compatible with bash
# setopt KSH_ARRAYS
# Usage: has <command>
#
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
        print "Command not found: $1 "
        return 1
  fi

  return 0
}

# Usage: join_args [args...]
#
# Joins all the passed arguments into a single string that can be evaluated by bash
#
# This is useful when one has to serialize an array of arguments back into a string
# join_args() {
#   printf '%q ' "$@"
# }

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


