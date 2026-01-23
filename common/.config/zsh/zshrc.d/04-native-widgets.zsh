# +---------+
# | Widgets |
# +---------+
# autoloading functions
## Enable vi mode
bindkey -v
export KEY_TIMEOUT=1

# create a zkbd compatible hash;
# to add other keys to this hash, see: man 5 terminfo
typeset -g -A key

key[Home]="${terminfo[khome]}"
key[End]="${terminfo[kend]}"
key[Insert]="${terminfo[kich1]}"
key[Backspace]="${terminfo[kbs]}"
key[Delete]="${terminfo[kdch1]}"
key[Up]="${terminfo[kcuu1]}"
key[Down]="${terminfo[kcud1]}"
key[Left]="${terminfo[kcub1]}"
key[Right]="${terminfo[kcuf1]}"
key[PageUp]="${terminfo[kpp]}"
key[PageDown]="${terminfo[knp]}"
key[ShiftTab]="${terminfo[kcbt]}"

# setup key accordingly
[[ -n "${key[Home]}"      ]] && bindkey -- "${key[Home]}"      beginning-of-line
[[ -n "${key[End]}"       ]] && bindkey -- "${key[End]}"       end-of-line
[[ -n "${key[Insert]}"    ]] && bindkey -- "${key[Insert]}"    overwrite-mode
[[ -n "${key[Backspace]}" ]] && bindkey -- "${key[Backspace]}" backward-delete-char
[[ -n "${key[Delete]}"    ]] && bindkey -- "${key[Delete]}"    delete-char
[[ -n "${key[Up]}"        ]] && bindkey -- "${key[Up]}"        up-line-or-history
[[ -n "${key[Down]}"      ]] && bindkey -- "${key[Down]}"      down-line-or-history
[[ -n "${key[Left]}"      ]] && bindkey -- "${key[Left]}"      backward-char
[[ -n "${key[Right]}"     ]] && bindkey -- "${key[Right]}"     forward-char
[[ -n "${key[PageUp]}"    ]] && bindkey -- "${key[PageUp]}"    beginning-of-buffer-or-history
[[ -n "${key[PageDown]}"  ]] && bindkey -- "${key[PageDown]}"  end-of-buffer-or-history
[[ -n "${key[ShiftTab]}"  ]] && bindkey -- "${key[ShiftTab]}"  reverse-menu-complete

bindkey -M viins "^q" push-input

# Finally, make sure the terminal is in application mode, when zle is
# active. Only then are the values from $terminfo valid.
if (( ${+terminfo[smkx]} && ${+terminfo[rmkx]} )); then
	autoload -Uz add-zle-hook-widget
	function zle_application_mode_start { echoti smkx }
	function zle_application_mode_stop { echoti rmkx }
	add-zle-hook-widget -Uz zle-line-init zle_application_mode_start
	add-zle-hook-widget -Uz zle-line-finish zle_application_mode_stop
fi

autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search

[[ -n "${key[Up]}"   ]] && bindkey -- "${key[Up]}"   up-line-or-beginning-search
[[ -n "${key[Down]}" ]] && bindkey -- "${key[Down]}" down-line-or-beginning-search


# By default, Ctrl+d will not close your shell if the command line is filled, this fixes it:
exit_zsh() { exit }
zle -N exit_zsh
bindkey '^D' exit_zsh

autoload -U edit-command-line
zle -N edit-command-line
bindkey '^V' edit-command-line

bindkey -M viins jj vi-cmd-mode

# Add Vi text-objects for brackets and quotes
autoload -Uz select-bracketed select-quoted
zle -N select-quoted
zle -N select-bracketed
for km in viopp visual; do
  bindkey -M $km -- '-' vi-up-line-or-history
  for c in {a,i}${(s..)^:-\'\"\`\|,./:;=+@}; do
    bindkey -M $km $c select-quoted
  done
  for c in {a,i}${(s..)^:-'()[]{}<>bB'}; do
    bindkey -M $km $c select-bracketed
  done
done

# Emulation of vim-surround
autoload -Uz surround
zle -N delete-surround surround
zle -N add-surround surround
zle -N change-surround surround
bindkey -M vicmd gr change-surround
bindkey -M vicmd gd delete-surround
bindkey -M vicmd ga add-surround
bindkey -M visual ga add-surround

# Make CTRL-Z background things and unbackground them.
# Based off https://github.com/wincent/wincent/commit/30b502d811fbf4ca058db3a6f006aaecab68f6b7
function fg-bg() {
	if [[ $#BUFFER -eq 0 ]]; then
		local backgroundProgram="$(jobs | tail -n 1 | awk '{print $4}')"
		case "$backgroundProgram" in
			"nc"|"ncat"|"netcat"|"resize-netcat-listener"|"rnc")
				# Make sure that /dev/tty is given to the stty command by doing </dev/tty
				terminal-size-clip < /dev/tty
				stty raw -echo < /dev/tty; fg
				;;
			*)
				fg
				;;
		esac
	else
		zle push-input
	fi
}
zle -N fg-bg
bindkey '^Z' fg-bg


bd_zsh="$ZDOTDIR/plugins/bd.zsh"
[[ -f "$bd_zsh" ]] && source "$bd_zsh"


# plugins=(
#   jeffreytse/zsh-vi-mode
# )
# __init_plugins "${plugins[@]}"
#
# zvm_after_init_commands+=(fzf_init)

[[ -r "$ZDOTDIR/plugins/fzf-widget.zsh" ]] && source "$ZDOTDIR/plugins/fzf-widget.zsh"
