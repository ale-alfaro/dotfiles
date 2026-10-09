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

#######################################################
# Job Options 
#######################################################
## Disable flow control and hence restore the ability to use C-s and C-q
setopt no_flow_control
setopt notify          # report the status of background jobs immediately
setopt monitor         # report the status of background jobs immediately
#######################################################
# History Configuration
#######################################################
setopt append_history         # Append history instead of replacing the history file.
setopt extended_history       # Save timestamps and command durations.
setopt hist_expire_dups_first # Expire duplicates first when trimming history.
setopt hist_find_no_dups      # Do not display an entry already found in a search.
setopt hist_ignore_all_dups   # Remove older duplicates when adding an entry.
setopt hist_ignore_dups       # Do not record an entry identical to the previous one.
setopt hist_ignore_space      # Do not record commands that start with a space.
setopt hist_reduce_blanks     # Remove extra blanks from stored commands.
setopt hist_save_no_dups      # Do not write duplicate entries to the history file.
setopt hist_verify            # Load history expansions into the editor before running them.

# Choose one immediate-write mode:
# setopt inc_append_history     # Write each command immediately for independent sessions.
setopt share_history        # Import and append commands across active sessions.
#######################################################
# History Configuration
#######################################################
setopt auto_cd              # Change directory by entering a directory name.
setopt auto_list            # List choices after an ambiguous completion.
setopt auto_pushd           # Push the previous directory onto the directory stack.
setopt bang_hist            # Enable csh-style history expansion with !.
setopt correct # auto correct mistakes
setopt interactive_comments # Allow comments in interactive shells.
setopt multios              # Use implicit tees or cats for multiple redirections.
setopt no_beep              # Do not beep on errors.
setopt prompt_subst         # Expand parameters and substitutions when drawing the prompt.
setopt pushd_ignore_dups    # Avoid duplicate entries in the directory stack.
setopt pushd_minus          # Exchange the meanings of + and - in stack indices.
#######################################################
# Glob Configuration 
#######################################################
#Example:
# `print -rC1 b*.pro(#q:s/pro/shmo/)(#q.:s/builtin/shmiltin/)`
# This first those the glob 'b*.pro'
# Then substitutes the substring 'pro' with 'shmo'
# And lastly substitutes 'builtin' with 'shmiltin'

setopt nonomatch       # hide error message if there is no match for the pattern
setopt numericglobsort # sort filenames numerically when it makes sense
setopt globdots
setopt extended_glob
setopt null_glob 
setopt glob_subst 
setopt glob_complete    # Show autocompletion menu with globs
setopt auto_list        # Automatically list choices on ambiguous completion.
setopt complete_in_word # Complete from both ends of a word.
