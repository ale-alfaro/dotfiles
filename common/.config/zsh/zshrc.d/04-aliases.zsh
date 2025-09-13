# ---- Editor -----
alias v="nvim"

# ---- Eza (better ls) -----
alias la="eza --icons=always --all --tree -L 5 --no-git"
alias ls="eza --icons=always --all --oneline --no-git"
# Alias For bat
# Link: https://github.com/sharkdp/bat
if [[ -x "$(command -v batman)" ]]; then
    alias cat='bat'
fi
if [[ -x "$(command -v batman)" ]]; then
    alias man='batman'
fi
# Alias for zellij
# Link: https://github.com/jesseduffield/lazygit
# alias zellij='zellij -l welcome'
if [[ -x "$(command -v zesh)" ]]; then
    alias zeshij='zesh cn $(zesh list | fzf)'
fi
# Alias for lazygit
# Link: https://github.com/jesseduffield/lazygit
alias lg='lazygit'

# Alias for FZF
# Link: https://github.com/junegunn/fzf
if [[ -x "$(command -v fzf)" ]]; then
    alias ff='fzf --preview "bat --style=numbers --color=always --line-range :500 {}"'
fi
