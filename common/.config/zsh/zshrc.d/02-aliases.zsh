#!/usr/bin/env zsh

compress() {
  tar -czf "${1%/}.tar.gz" "${1%/}"
}

alias decompress="tar -xzf"

ssh_agent_start() {
  eval "$(ssh-agent -s)"
  ssh-add ~/.ssh/id_ed25519_yubikey
}
alias sshstart="ssh_agent_start"
#######################################################
# CLI Aliases
#######################################################
# Alias For bat
alias lt='eza --tree --level=3 --long --icons --git'
alias lta='lt -a'
alias ls="eza --icons=always --oneline --no-git --all"
# Link: https://github.com/sharkdp/bat
alias wman='wikiman'
# has batman && alias man='batman'
# Alias for lazygit
# Link: https://github.com/jesseduffield/lazygit
alias lg='lazygit'
alias lzd='lazydocker'
alias minimax='NVIM_APPNAME=nvim-minimax nvim'
# -------------------------------------------
# 5. Suffix Aliases - Open Files by Extension
# -------------------------------------------
# Just type the filename to open it with the associated program
alias -s json=jqp
alias -s md=bat
alias -s txt=bat
alias -s log=bat
alias -s c='$EDITOR'
alias -s h='$EDITOR'
alias -s hpp='$EDITOR'
alias -s cpp='$EDITOR'
alias -s conf='$EDITOR'
alias -s dts='$EDITOR'
alias -s html=xdg-open

# -------------------------------------------
# 6. Global Aliases - Use Anywhere in Commands
# -------------------------------------------
# Redirect stderr to /dev/null
alias -g NE='2>/dev/null'

# Redirect stdout to /dev/null
alias -g NO='>/dev/null'

alias -g FZF='| fzf'

# Redirect both stdout and stderr to /dev/null
alias -g NUL='>/dev/null 2>&1'

# Pipe to jq
alias -g J='| jqp'

if [[ "$OSTYPE" == "linux"* ]]; then
  open() {
    xdg-open "$@" >/dev/null 2>&1 &
  }
  alias -g CP='| wl-copy'
elif [[ "$OSTYPE" == "macos"* ]]; then
  alias -g CP='| pb-copy'
fi

# -------------------------------------------
# 7. zmv - Advanced Batch Rename/Move
# -------------------------------------------
# Enable zmv
autoload -Uz zmv

# Usage examples:
# zmv '(*).log' '$1.txt'           # Rename .log to .txt
# zmv -w '*.log' '*.txt'           # Same thing, simpler syntax
# zmv -n '(*).log' '$1.txt'        # Dry run (preview changes)
# zmv -i '(*).log' '$1.txt'        # Interactive mode (confirm each)

# Helpful aliases for zmv
alias mmv='noglob zmv -W'
alias zcp='zmv -C' # Copy with patterns
alias zln='zmv -L' # Link with patterns

# Navigate back to directories easily using the zsh directory stack feature
alias d='dirs -v'
for index in {1..9}; do alias "$index"="builtin cd +${index}"; done
# Enable the help command
autoload -Uz run-help
((${+aliases[run - help]})) && unalias run-help
alias help=run-help

tdl() {
  [[ -z $1 ]] && {
    echo "Usage: tdl <c|cx|codex|other_ai> [<second_ai>]"
    return 1
  }
  [[ -z $TMUX ]] && {
    echo "You must start tmux to use tdl."
    return 1
  }

  local current_dir="${PWD}"
  local editor_pane ai_pane ai2_pane
  local ai="$1"
  local ai2="$2"

  # Use TMUX_PANE for the pane we're running in (stable even if active window changes)
  editor_pane="$TMUX_PANE"

  # Name the current window after the base directory name
  tmux rename-window -t "$editor_pane" "$(basename "$current_dir")"

  # Split window vertically - top 85%, bottom 15% (target editor pane explicitly)
  tmux split-window -v -p 15 -t "$editor_pane" -c "$current_dir"

  # Split editor pane horizontally - AI on right 30% (capture new pane ID directly)
  ai_pane=$(tmux split-window -h -p 30 -t "$editor_pane" -c "$current_dir" -P -F '#{pane_id}')

  # If second AI provided, split the AI pane vertically
  if [[ -n $ai2 ]]; then
    ai2_pane=$(tmux split-window -v -t "$ai_pane" -c "$current_dir" -P -F '#{pane_id}')
    tmux send-keys -t "$ai2_pane" "$ai2" C-m
  fi

  # Run ai in the right pane
  tmux send-keys -t "$ai_pane" "$ai" C-m

  # Run nvim in the left pane
  tmux send-keys -t "$editor_pane" "$EDITOR ." C-m

  # Select the nvim pane for focus
  tmux select-pane -t "$editor_pane"
}
alias aish='tdl'
