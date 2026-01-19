# ---- zsh-compatible Direnv stdlib helpers + other utilities for zsh scripts -----
source "$ZDOTDIR/helpers/stdlib.zsh"
# Plugin Helper
source "$ZDOTDIR/helpers/plugin_helper.zsh"
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
# Alias for FZF
# Link: https://github.com/junegunn/fzf
fzf_init() {
  source <(fzf --zsh)
  export FZF_CTRL_R_OPTS="
    --color header:italic
    --height=80%
    --bind 'ctrl-y:execute-silent(fc -l {2..} | wl-copy)+abort'
    --header 'CTRL-Y: Copy command into clipboard, CTRL-/: Toggle line wrapping, CTRL-R: Toggle sorting by relevance'
    "

  export FZF_CTRL_T_OPTS="
    --walker-skip .git,node_modules,target
    --preview 'bat -n --color=always {}'
    --height=80%
    "

  export FZF_ALT_C_OPTS="
    --walker-skip .git,node_modules,target
    --preview 'eza -lh --group-directories-first --icons=auto'
    --height=80%
    --bind 'ctrl-/:change-preview-window(down|hidden|)'
    --header 'CTRL-/: Toggle preview window position'
    "
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
  if has eza; then
    fzf_preview_cmd='eza -lh --group-directories-first --icons=auto'
  else
    fzf_preview_cmd='ls --color $realpath'
  fi

  # zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza --icons=always --oneline --no-git --all'
  # zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'eza --icons=always --oneline --no-git --all'
  if has fd && has rg; then
    ff() {
      fd --type file |
        fzf --prompt 'Files> ' \
          --header 'ALT-D: Switch between Files/Directories' \
          --bind 'alt-d:transform:[[ ! $FZF_PROMPT =~ Files ]] &&
                      echo "change-prompt(Files> )+reload(fd --type file)" ||
                      echo "change-prompt(Directories> )+reload(fd --type directory)"' \
          --preview '[[ $FZF_PROMPT =~ Files ]] && bat --color=always {} || tree -C {}' \
          --bind 'enter:become(nvim {})'
    }
  else
    alias ff="fzf --preview 'bat --style=numbers --color=always {}'"
  fi
}
#######################################################
# App Environment Variables
#######################################################
#
export RIPGREP_CONFIG_PATH="${XDG_CONFIG_HOME}/ripgrep/ripgreprc"

#Initialize Node Version manager
if [[ "$OSTYPE" == "darwin"* ]]; then
  export NVM_DIR="$HOME/.nvm"
  [ -s "$(brew --prefix nvm)/nvm.sh" ] && \. "$(brew --prefix nvm)/nvm.sh"                                       # This loads nvm
  [ -s "$(brew --prefix nvm)/etc/bash_completion.d/nvm" ] && \. "$(brew --prefix nvm)/etc/bash_completion.d/nvm" # This loads nvm bash_completion
else
  export NVM_DIR="$XDG_CONFIG_HOME/nvm"
  source "$ZDOTDIR/shell_integrations/zsh-nvm.zsh"
fi
export npm_config_prefix="$HOME/.local"

# if has gemini && test -z "${GEMINI_CLI_SYSTEM_SETTINGS_PATH}"; then
#   export GEMINI_CLI_SYSTEM_SETTINGS_PATH="${XDG_CONFIG_HOME:-$HOME/.config}/gemini/settings.json"
# fi
#######################################################
# App Aliases
#######################################################
if has eza; then
  alias lt='eza --tree --level=3 --long --icons --git'
  alias lta='lt -a'
  alias ls="eza --icons=always --oneline --no-git --all"
fi
# Alias For bat
# Link: https://github.com/sharkdp/bat
if has bat; then
  export BAT_THEME=ansi
fi
has wikiman && alias wman='wikiman'
# has batman && alias man='batman'
# Alias for lazygit
# Link: https://github.com/jesseduffield/lazygit
has lazygit && alias lg='lazygit'
if has zoxide; then
  safe_source zoxide init zsh
  zv() {
    zoxide query -l $1 | fzf --bind 'enter:become(nvim {})'
  }
  alias cd="zd"
  zd() {
    if [ $# -eq 0 ]; then
      builtin cd ~ && return
    elif [ -d "$1" ]; then
      builtin cd "$1"
    else
      z "$@" && printf "\U000F17A9 " && pwd || echo "Error: Directory not found"
    fi
  }
fi
# Alias for just (command runner)
if has just; then
  alias j='just'
  export JUST_CHOOSER="fzf --exact"
  if [[ ! -z "${JUST_HOME}" ]]; then
    # alias .j='just --justfile ~/.config/just/Justfile --working-directory .'
    alias .j='just -g'
    user_justfiles="${JUST_HOME}/.user"
    if [[ -d "$user_justfiles" ]]; then
      for file in $user_justfiles/*.just; do
        for recipe in $(just --justfile $file --summary); do
          alias $recipe="just --justfile $file --working-directory . $recipe"
        done
      done
    fi
  fi
fi

#######################################################
# App Completions
#######################################################
# ------------------------------------------------------------------------------
## fzf
# ------------------------------------------------------------------------------
# Homebrew completions (MacOS)
# ------------------------------------------------------------------------------
if [[ "$OSTYPE" == "darwin"* ]]; then
  if has brew; then
    FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"
  fi
fi
# --- Completion from CLI tools ---
# if has prek; then
#   eval "$(COMPLETE=zsh prek completion)"
# fi

export OBSIDIAN_HOME="${HOME}/Documents/Obsidian"
if has codex && test -z "${CODEX_HOME}"; then
  eval "$(codex completion zsh)"
  export CODEX_HOME="${XDG_CONFIG_HOME}/codex"
fi
# --- Optional completions from CLI tools ---
if [[ ! -z "$JJ_COMPLETIONS" ]]; then
  if has jj; then
    eval "$(jj util completion zsh)"
  fi
fi
[[ ! -z "$BW_CLI_COMPLETIONS" ]] && has bw && eval "$(bw completion --shell zsh)"
has nrfutil && [[ -r "${HOME}/.nrfutil/share/nrfutil-completion/scripts/zsh/setup.zsh" ]] && . "${HOME}/.nrfutil/share/nrfutil-completion/scripts/zsh/setup.zsh"

# Load custom generated manually or through MAN pages
fpath+=("$HOME/.local/share/zsh/site" "$ZDOTDIR/completions/src" $fpath)

#######################################################
# Shell integrations
#######################################################
bd_zsh="$ZDOTDIR/shell_integrations/bd.zsh"
[[ -f "$bd_zsh" ]] && source "$bd_zsh"
# ---- Atuin (better shell command history) -----
safe_source atuin init zsh

# ---- Starship (better prompt) -----
export STARSHIP_CONFIG=~/.config/starship/starship.toml
safe_source starship init zsh
# ---- Direnv (.envrc auto-loading) -----
safe_source direnv hook zsh

# ---- Wezterm (terminal emulator) ---
# if [[ $TERM_PROGRAM == "WezTerm" ]]; then
#   echo "Enabling wezterm shell integration"
#   . "$ZDOTDIR/shell_integrations/wezterm.sh"
# elif [[ $TERM_PROGRAM == "ghostty" ]]; then
#   if [[ -n $GHOSTTY_RESOURCES_DIR ]]; then
#     echo "Enabling ghostty shell integration"
#     source "$GHOSTTY_RESOURCES_DIR/shell-integration/zsh/ghostty-integration"
#   fi
# else
#   echo "Unsupported TERM_PROGRAM=$TERM_PROGRAM"
# fi

nvimv use nightly
