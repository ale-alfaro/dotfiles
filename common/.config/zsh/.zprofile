#!/usr/bin/env zsh
# $ZDOTDIR/.zprofile: Gets loaded for login shells IN MACOS-only
# ------------------------------------------------------------------------------
#
if [[ "$OSTYPE" == "darwin"* ]]; then
  source ~/.zshenv
  if [[ -e "/opt/homebrew/bin/brew" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  else
    echo ERROR: Could not find brew. Skip setting up brew shellenv.
  fi
else
  echo ".zprofile should run only on MacOS"
  return
fi
# PATH extensions
# ------------------------------------------------------------------------------
# PATH is extended here in ~/.zprofile instead of ~/.zshenv (the more "correct"
# place) because sometimes /etc/zprofile exports PATH, overriding modifications
# made in ~/.zshenv. ~/.zprofile runs after /etc/zprofile. This ensures user
# PATH additions are available in all login shells.

# Add dir for user specific executables (recommended in XDG spec) to PATH
# Spec: https://specifications.freedesktop.org/basedir-spec/latest/index.html
# ------------------------------------------------------------------------------
# Make sure directories actually exist
user_specific_exe_dir="$HOME/.local/bin"
if [[ ! -d "$user_specific_exe_dir" ]]; then
  mkdir -p "$user_specific_exe_dir"
fi
export PATH="$user_specific_exe_dir:$PATH"

# cargo
# ------------------------------------------------------------------------------
export PATH="$PATH:$HOME/.cargo/bin"

# Go
# ------------------------------------------------------------------------------
export GOROOT="/usr/local/go"
export GOPATH="$HOME/go"
export JUST_HOME=$XDG_CONFIG_HOME/just

# Go
# ------------------------------------------------------------------------------
# export PATH="$PATH:$HOME/.local/share/uv/"
# Justfiles (Better makefiles)
# ------------------------------------------------------------------------------

# The incantation `typeset -U path', where the -U stands for unique, tells the shell that it should not add anything to $path if it's there already. To be precise, it keeps only the left-most occurrence, so if you added something at the end it will disappear and if you added something at the beginning, the old one will disappear. Thus the following works nicely in .zshenv:
# Read more at:https://zsh.sourceforge.io/Guide/zshguide02.html#l24 - 2.5.11 Path
# typeset -U path PATH
# path=($GOROOT/bin $GOPATH/bin $ZDOTDIR/functions $path)
# export PATH
