# +---------+
# | BINDING |
# +---------+
# ---- zsh-compatible Direnv stdlib helpers + other utilities for zsh scripts -----
source "$ZDOTDIR/helpers/stdlib.zsh"
# Plugin Helper
source "$ZDOTDIR/helpers/plugin_helper.zsh"

# autoloading functions
#######################################################
# Zsh Plugins
#######################################################
# Initialize First plguin, this plugin only adds more completions to the fpath so we call it before compload init
plugins=(
  zsh-users/zsh-completions
  zsh-users/zsh-syntax-highlighting
  zsh-users/zsh-autosuggestions
  Aloxaf/fzf-tab
  jeffreytse/zsh-vi-mode
)
__init_plugins "${plugins[@]}"

has fzf && zvm_after_init_commands+=(fzf_init)

fzf_init() {
  # Fzf eza -lh --group-directories-first --icons=auto
  export FZF_DEFAULT_OPTS='--height 40% --layout=reverse'
  export FZF_DEFAULT_COMMAND='fd --strip-cwd-prefix -tf -Hp' # find files
  export FZF_ALT_C_COMMAND='fd --strip-cwd-prefix -td -Hp'   # fuzzy cd
  export FZF_CTRL_T_COMMAND='fd --strip-cwd-prefix     -Hp'  # find everything
  # eza -lh --group-directories-first --icons=auto
  export FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS \
      --info=default\
      --ansi \
      --layout=reverse \
      --border=rounded \
      --color=bg+:#3B4252, \
      --color=bg:#2E3440,\
      --color=spinner:#81A1C1,\
      --color=hl:#616E88,\
      --color=fg:#D8DEE9,\
      --color=header:#616E88,\
      --color=info:#81A1C1,\
      --color=pointer:#81A1C1,\
      --color=marker:#81A1C1,\
      --color=fg+:#D8DEE9,\
      --color=prompt:#81A1C1,\
      --color=hl+:#81A1C1"

  source <(fzf --zsh)
  source "$ZDOTDIR/shell_integrations/fzf-completions.zsh"
  source "$ZDOTDIR/shell_integrations/fzf-widgets.zsh"

}
## Enable vi mode
bindkey -v
autoload -Uz edit-command-line
zle -N edit-command-line
# Option to enable CTRL+V to enter vi-mode on all modes or only in cmd mode
bindkey "^v" edit-command-line
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

