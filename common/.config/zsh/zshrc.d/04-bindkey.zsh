# +---------+
# | BINDING |
# +---------+
## ATTENTION: DISABLE AUTO_FORMATTING IN NEOVIM OR THE BOTTOM KEYMAPPING DEFITIONS WILL BREAK 
## Enable vi mode
bindkey -v

## Enable edit-command-line widget for vi mode
autoload -U edit-command-line
zle -N edit-command-line
# Option to enable CTRL+V to enter vi-mode on all modes or only in cmd mode
bindkey "^v" edit-command-line
# bindkey -M vicmd '^v' edit-command-line
#
# Other options
# bindkey -M vicmd '^X^E' edit-command-line
# Enter in insert mode with CTRL+X CTRL+E
# bindkey -M viins '^X^E' edit-command-line
#
# ## Lower mode switching delay to 10ms
KEYTIMEOUT=1

# +------------------------------------+
# | Using terminfo in Application Mode |
# +------------------------------------+

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
key[Shift-Tab]="${terminfo[kcbt]}"
key[CTRLL]="${terminfo[kLFT5]}"
key[CTRLR]="${terminfo[kRIT5]}"

# setup key accordingly
[[ -n "${key[Home]}"      ]] && bindkey -- "${key[Home]}"       beginning-of-line
[[ -n "${key[End]}"       ]] && bindkey -- "${key[End]}"        end-of-line
[[ -n "${key[Insert]}"    ]] && bindkey -- "${key[Insert]}"     overwrite-mode
[[ -n "${key[Backspace]}" ]] && bindkey -- "${key[Backspace]}"  backward-delete-char
[[ -n "${key[Delete]}"    ]] && bindkey -- "${key[Delete]}"     delete-char
[[ -n "${key[Up]}"        ]] && bindkey -- "${key[Up]}"         up-line-or-history
[[ -n "${key[Down]}"      ]] && bindkey -- "${key[Down]}"       down-line-or-history
[[ -n "${key[Left]}"      ]] && bindkey -- "${key[Left]}"       backward-char
[[ -n "${key[Right]}"     ]] && bindkey -- "${key[Right]}"      forward-char
[[ -n "${key[PageUp]}"    ]] && bindkey -- "${key[PageUp]}"     beginning-of-buffer-or-history
[[ -n "${key[PageDown]}"  ]] && bindkey -- "${key[PageDown]}"   end-of-buffer-or-history
[[ -n "${key[Shift-Tab]}" ]] && bindkey -- "${key[Shift-Tab]}"  reverse-menu-complete
[[ -n "${key[CRTLL]}"     ]] && bindkey -- "${key[CRTLL]}"      backward-word
[[ -n "${key[CRTLR]}"     ]] && bindkey -- "${key[CRTLR]}"      forward-word


# # Finally, make sure the terminal is in application mode, when zle is active. Only then are the values from $terminfo valid.
# # Downside: when a CLI / TUI doesn't use application mode, some keys won't work.
if (( ${+terminfo[smkx]} && ${+terminfo[rmkx]} )); then
	autoload -Uz add-zle-hook-widget
	function zle_application_mode_start { echoti smkx }
	function zle_application_mode_stop { echoti rmkx }
	add-zle-hook-widget -Uz zle-line-init zle_application_mode_start
	add-zle-hook-widget -Uz zle-line-finish zle_application_mode_stop
fi

# Remove some default bindkeys
# bindkey -r '^c'
# bindkey -r '^l' # Clear screen
# bindkey -r '^h'

# bindkey -s '^Z' 'fg\n'
