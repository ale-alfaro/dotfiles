# Alias for FZF
# Link: https://github.com/junegunn/fzf
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

#######################################################
# Shell integrations
#######################################################
# ---- Atuin (better shell command history) -----
safe_source atuin init zsh

# ---- Starship (better prompt) -----
export STARSHIP_CONFIG=~/.config/starship/starship.toml
safe_source starship init zsh
# ---- Direnv (.envrc auto-loading) -----
safe_source direnv hook zsh

# Initialize First plguin, this plugin only adds more completions to the fpath so we call it before compload init
plugins=(
  zsh-users/zsh-syntax-highlighting
  zsh-users/zsh-autosuggestions
)
__init_plugins "${plugins[@]}"
