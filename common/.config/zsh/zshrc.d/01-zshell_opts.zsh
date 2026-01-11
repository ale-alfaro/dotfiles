#!/usr/bin/env zsh

# General Options
# ------------------------------------------------------------------------------
## List jobs in the long format by default.
setopt LONG_LIST_JOBS

## Disable flow control and hence restore the ability to use C-s and C-q
setopt NO_FLOW_CONTROL

#######################################################
# ZSH Basic Options
#######################################################

# setopt autocd              # change directory just by typing its name
# setopt correct             # auto correct mistakes
# setopt interactivecomments # allow comments in interactive mode
setopt magicequalsubst # enable filename expansion for arguments of the form ‘anything=expression’
setopt nonomatch       # hide error message if there is no match for the pattern
setopt notify          # report the status of background jobs immediately
setopt numericglobsort # sort filenames numerically when it makes sense
setopt promptsubst     # enable command substitution in prompt
#######################################################
# History Configuration
#######################################################

## Enable globally shared history (same history in every shell)
setopt SHARE_HISTORY

## When writing out the history file, older duplicate commands are omitted
setopt HIST_SAVE_NO_DUPS

## Don't save commands prefixed with at least one space to history
setopt HIST_IGNORE_SPACE

## Don't directly execute commands when using history expansion
setopt HIST_VERIFY

## Max number of history lines in memory
HISTSIZE=25000

# Set up history file
if [[ ! -d "$XDG_DATA_HOME/zsh" ]]; then
  mkdir -p "$XDG_DATA_HOME/zsh"
fi
HISTFILE="$XDG_DATA_HOME/zsh/history"
# HISTFILE=~/.zsh_history
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

## Push and pop directories into a stack to go back to them quickly!
setopt AUTO_PUSHD        # Push the current directory visited on the stack.
setopt PUSHD_IGNORE_DUPS # Do not store duplicates in the stack.
setopt PUSHD_SILENT      # Do not print the directory stack after pushd or popd
#Used for chaining together glob operators
#Example:
# `print -rC1 b*.pro(#q:s/pro/shmo/)(#q.:s/builtin/shmiltin/)`
# This first those the glob 'b*.pro'
# Then substitutes the substring 'pro' with 'shmo'
# And lastly substitutes 'builtin' with 'shmiltin'

setopt EXTENDED_GLOB
