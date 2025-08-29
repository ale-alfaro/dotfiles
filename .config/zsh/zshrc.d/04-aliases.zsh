
# ---- Editor -----
alias v="nvim"
alias nvim_pre='~/.local/nvim-0_12-prerelease/bin/nvim'

alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
alias ......="cd ../../../../.."
alias cl='clear'
# ---- Eza (better ls) -----
alias la="eza --icons=always --all --tree -L 5 --no-git"
alias ls="eza --icons=always --all --oneline --no-git"
# Alias For bat
# Link: https://github.com/sharkdp/bat
if [[ -x "$(command -v bat)" ]]; then
    alias cat='bat'
fi

# Alias for zellij
# Link: https://github.com/jesseduffield/lazygit
if [[ -x "$(command -v zellij)" ]]; then
    alias zellij='zellij -l welcome'
fi
# Alias for lazygit
# Link: https://github.com/jesseduffield/lazygit
if [[ -x "$(command -v lazygit)" ]]; then
    alias lg='lazygit'
fi

# Alias for FZF
# Link: https://github.com/junegunn/fzf
if [[ -x "$(command -v fzf)" ]]; then
    alias fzf='fzf --preview "bat --style=numbers --color=always --line-range :500 {}"'
    # Alias to fuzzy find files in the current folder(s), preview them, and launch in an editor
	if [[ -x "$(command -v xdg-open)" ]]; then
		alias preview='open $(fzf --info=inline --query="${@}")'
	else
		alias preview='edit $(fzf --info=inline --query="${@}")'
	fi
fi
A

