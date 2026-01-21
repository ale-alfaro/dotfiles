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
bindkey '^v' edit-command-line
# zle -N edit-command-line insert-files
# bindkey '^Xf' insert-files
zle -N predict-on
zle -N predict-off
bindkey '^X^Z' predict-on
bindkey '^Z' predict-off
