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
)
__init_plugins "${plugins[@]}"

# preview directory's content with eza when completing cd
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
# custom fzf flags
# NOTE: fzf-tab does not follow FZF_DEFAULT_OPTS by default
zstyle ':fzf-tab:*' fzf-flags --color=fg:1,fg+:2 --bind=tab:accept
#######################################################
# App Environment Variables
#######################################################
#
export BAT_THEME=ansi
export RIPGREP_CONFIG_PATH="${XDG_CONFIG_HOME}/ripgrep/ripgreprc"
export FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS \
    --info=default\
    --ansi \
    --layout=reverse \
    --border=rounded \
    --color=border:#27a1b9 \
    --color=fg:#c0caf5 \
    --color=gutter:#16161e \
    --color=header:#ff9e64 \
    --color=hl+:#2ac3de \
    --color=hl:#2ac3de \
    --color=info:#545c7e \
    --color=marker:#ff007c \
    --color=pointer:#ff007c \
    --color=prompt:#2ac3de \
    --color=query:#c0caf5:regular \
    --color=scrollbar:#27a1b9 \
    --color=separator:#ff9e64 \
    --color=spinner:#ff007c \
    "

export FZF_CTRL_R_OPTS="
  --color header:italic
  --height=80%
  --bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort'
  --header 'CTRL-Y: Copy command into clipboard, CTRL-/: Toggle line wrapping, CTRL-R: Toggle sorting by relevance'
  "

export FZF_CTRL_T_OPTS="
  --walker-skip .git,node_modules,target
  --preview 'bat -n --color=always {}'
  --height=80%
  --bind 'ctrl-/:change-preview-window(down|hidden|)'
  --header 'CTRL-/: Toggle preview window position'
  "

export FZF_ALT_C_OPTS="
  --walker-skip .git,node_modules,target
  --preview 'tree -C {}'
  --height=80%
  --bind 'ctrl-/:change-preview-window(down|hidden|)'
  --header 'CTRL-/: Toggle preview window position'
  "

export npm_config_prefix="$HOME/.local"
export OBSIDIAN_HOME="${HOME}/Documents/Obsidian"
if has codex && test -z "${CODEX_HOME}"; then
  eval "$(codex completion zsh)"
  export CODEX_HOME="${XDG_CONFIG_HOME}/codex"
fi

if has gemini && test -z "${GEMINI_CLI_SYSTEM_SETTINGS_PATH}"; then
  export GEMINI_CLI_SYSTEM_SETTINGS_PATH="${XDG_CONFIG_HOME:-$HOME/.config}/gemini/settings.json"
fi
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
  alias cat='bat'
fi
if has wikiman; then
  alias man='wikiman'
elif has batman; then
  alias man='batman'
fi
# Alias for lazygit
# Link: https://github.com/jesseduffield/lazygit
if has lazygit; then
  alias lg='lazygit'
fi
# Alias for FZF
# Link: https://github.com/junegunn/fzf
if has fzf; then
  alias ff="fzf --preview 'bat --style=numbers --color=always {}'"
  vf() {
    fd --type file |
      fzf --prompt 'Files> ' \
        --header 'ALT-D: Switch between Files/Directories' \
        --bind 'alt-d:transform:[[ ! $FZF_PROMPT =~ Files ]] &&
                  echo "change-prompt(Files> )+reload(fd --type file)" ||
                  echo "change-prompt(Directories> )+reload(fd --type directory)"' \
        --preview '[[ $FZF_PROMPT =~ Files ]] && bat --color=always {} || tree -C {}' \
        --bind 'enter:become(nvim {})'
  }
fi
if has zoxide; then
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
eval "$(fzf --zsh)"

zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'
# --- Completion from CLI tools ---
# if has prek; then
#   eval "$(COMPLETE=zsh prek completion)"
# fi

# --- Optional completions from CLI tools ---
if [[ ! -z "$JJ_COMPLETIONS" ]]; then
  if has jj; then
    eval "$(jj util completion zsh)"
  fi
fi
if [[ ! -z "$BW_CLI_COMPLETIONS" ]]; then
  if has bw; then
    eval "$(bw completion --shell zsh)"
  fi
fi
if has nrfutil; then
  [[ -r "${HOME}/.nrfutil/share/nrfutil-completion/scripts/zsh/setup.zsh" ]] && . "${HOME}/.nrfutil/share/nrfutil-completion/scripts/zsh/setup.zsh"
fi

# Load custom generated manually or through MAN pages
fpath+=("$HOME/.local/share/zsh/site" "$ZDOTDIR/completions/src" $fpath)

#######################################################
# Shell integrations
#######################################################

# Quickly go back to a specific parent directory instead of typing cd ../../.. redundantly
# Example usage:
# $ mkdir -p a/b/c/d
# $ cd a/b/c/d
# $ bd b
# $ ls
# c
# $ cd c/d
# $ bd 2
# $ ls
# c

bd_zsh="$ZDOTDIR/shell_integrations/bd.zsh"
if [[ -f "$bd_zsh" ]]; then
  source "$bd_zsh"
fi
# ---- Atuin (better shell command history) -----
eval "$(atuin init zsh)"

# ---- Starship (better prompt) -----
export STARSHIP_CONFIG=~/.config/starship/starship.toml
eval "$(starship init zsh)"
# ---- Direnv (.envrc auto-loading) -----
eval "$(direnv hook zsh)"

# ---- zoxide (better cd) -----
if has zoxide; then
  eval "$(zoxide init zsh --cmd zd)"
else
  echo ERROR: Could not load zoxide shell integration.
fi

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

# Initialize Node Version manager
# if [[ "$OSTYPE" == "darwin"* ]]; then
#   export NVM_DIR="$HOME/.nvm"
#   [ -s "$(brew --prefix nvm)/nvm.sh" ] && \. "$(brew --prefix nvm)/nvm.sh"                                       # This loads nvm
#   [ -s "$(brew --prefix nvm)/etc/bash_completion.d/nvm" ] && \. "$(brew --prefix nvm)/etc/bash_completion.d/nvm" # This loads nvm bash_completion
# else
#   export NVM_DIR="$XDG_CONFIG_HOME/nvm"
#   source "$ZDOTDIR/shell_integrations/zsh-nvm.zsh"
# fi

nvimv use nightly
