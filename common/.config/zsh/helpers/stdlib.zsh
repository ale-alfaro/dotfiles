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


# Transcode any image to JPG image that's great for shrinking wallpapers
img2jpg() {
  magick $1 -quality 95 -strip ${1%.*}.jpg
}

# Transcode any image to JPG image that's great for sharing online without being too big
img2jpg-small() {
  magick $1 -resize 1080x\> -quality 95 -strip ${1%.*}.jpg
}

# Transcode any image to compressed-but-lossless PNG
img2png() {
  magick "$1" -strip -define png:compression-filter=5 \
    -define png:compression-level=9 \
    -define png:compression-strategy=1 \
    -define png:exclude-chunk=all \
    "${1%.*}.png"
}

convert_rst_to_md() {
  filename="${1%.*}"
  echo "Converting $1 to $filename.md"
  pandoc "$1" -f rst -t markdown -o "${filename}.md"
}

convert_rst_to_md_dir(){

  dir="${1:-$PWD}"
  # Non-recursively
  for rst in "${dir}/*.rst"; do pandoc "$rst" -f rst -t markdown -o "${rst%.*}.md"; done

  # Recursively (if your shell supports double-star globs)
  # for rst in **/*.rst; do pandoc "$rst" -f rst -t markdown -o "${rst%.*}.md"; done
  # dir="${1:-$PWD}"
  # FILES=dir/*.rst
  # for f in $FILES; do
  #   convert_rst_to_md f
  # done
}


_err() {
}


