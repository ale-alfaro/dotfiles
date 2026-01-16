#!/usr/bin/env zsh
#ZSHOPTIONS(1)
#SPECIFYING_OPTIONS
#       Options are primarily referred to by name.  These names are case insensitive and underscores are ignored.  For example, ‘allexport' is equivalent to ‘A__lleXP_ort'.
#
#       The  sense  of an option name may be inverted by preceding it with ‘no', so ‘setopt No_Beep' is equivalent to ‘unsetopt beep'.  This inversion can only be done once, so ‘nonobeep'
#       is not a synonym for ‘beep'.  Similarly, ‘tify' is not a synonym for ‘nonotify' (the inversion of ‘notify').
#
#       Some options also have one or more single letter names.  There are two sets of single letter options: one used by default, and another used to emulate sh/ksh (used when the SH_OP‐
#       TION_LETTERS option is set).  The single letter options can be used on the shell command line, or with the set, setopt and unsetopt builtins, as normal Unix  options  preceded  by
#       ‘-'.
#
#       The  sense of the single letter options may be inverted by using ‘+' instead of ‘-'.  Some of the single letter option names refer to an option being off, in which case the inver‐
#       sion of that name refers to the option being on.  For example, ‘+n' is the short name of ‘exec', and ‘-n' is the short name of its inversion, ‘noexec'.
#
#       In strings of single letter options supplied to the shell at startup, trailing whitespace will be ignored; for example the string ‘-f    ' will be treated just as  ‘-f',  but  the
#       string ‘-f i' is an error.  This is because many systems which implement the ‘#!' mechanism for calling scripts do not strip trailing whitespace.
#
#       It is possible for options to be set within a function scope.  See the description of the option LOCAL_OPTIONS below.
# General Options
# ------------------------------------------------------------------------------
## Disable flow control and hence restore the ability to use C-s and C-q
setopt no_flow_control

#######################################################
# ZSH Basic Options
#######################################################

# setopt autocd              # change directory just by typing its name
setopt correct # auto correct mistakes
# setopt interactivecomments # allow comments in interactive mode
setopt magicequalsubst # enable filename expansion for arguments of the form ‘anything=expression’
setopt nonomatch       # hide error message if there is no match for the pattern
setopt notify          # report the status of background jobs immediately
setopt monitor         # report the status of background jobs immediately
setopt numericglobsort # sort filenames numerically when it makes sense
setopt promptsubst     # enable command substitution in prompt
setopt globdots
#######################################################
# History Configuration
#######################################################
#zsh sessions will append their history list to the history file, rather than replace it.
setopt appendhistory
#  If a new command line being added to the history list duplicates an older one, the older command is removed from the list (even if it is not the previous event).
setopt hist_ignore_all_dups
# When searching for history entries in the line editor, do not display duplicates of a line previously found, even if the duplicates are not contiguous.
setopt hist_find_no_dups
## Enable globally shared history (same history in every shell)
setopt share_history

## When writing out the history file, older duplicate commands are omitted
setopt hist_save_no_dups

## Don't save commands prefixed with at least one space to history
setopt hist_ignore_space

## Don't directly execute commands when using history expansion
setopt hist_verify

## Max number of history lines in memory
HISTSIZE=25001

# Set up history file
HISTFILE="$XDG_DATA_HOME/zsh/history"

if [[ ! -f "$HISTFILE" ]]; then
  [[ ! -d $(dirname $HISTFILE) ]] && mkdir -p $(dirname $HISFILE)
fi

## Push and pop directories into a stack to go back to them quickly!
setopt auto_pushd        # Push the current directory visited on the stack.
setopt pushd_ignore_dups # Do not store duplicates in the stack.
setopt pushd_silent      # Do not print the directory stack after pushd or popd
#Used for chaining together glob operators
#Example:
# `print -rC1 b*.pro(#q:s/pro/shmo/)(#q.:s/builtin/shmiltin/)`
# This first those the glob 'b*.pro'
# Then substitutes the substring 'pro' with 'shmo'
# And lastly substitutes 'builtin' with 'shmiltin'

setopt extended_glob
