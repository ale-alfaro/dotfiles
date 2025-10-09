if status is-interactive
    # Core environment, shared across macOS and Arch Linux
    set -x XDG_CACHE_HOME $HOME/.cache
    set -x XDG_CONFIG_HOME $HOME/.config
    set -x XDG_DATA_HOME $HOME/.local/share
    set -x XDG_STATE_HOME $HOME/.local/state

    set -x EDITOR nvim
    set -x VISUAL nvim
    set -x PAGER less

    set os (uname)
    if test "$os" = Darwin
        fish_add_path /opt/homebrew/bin /opt/homebrew/sbin
    else if test "$os" = Linux
        fish_add_path /usr/local/bin /usr/local/sbin
    end

    fish_add_path $HOME/dotfiles/common/bin $HOME/.local/bin

    if type -q direnv
        direnv hook fish | source
    end

    set -g fish_key_bindings fish_vi_key_bindings

    if type -q starship
        starship init fish | source
    end

    if type -q atuin
        atuin init fish | source
    end

    if type -q fzf
        if type -q fisher
            fisher install PatrickF1/fzf.fish
        end
    end

    alias gs='git status'
    alias gl='git pull'
    alias gp='git push'
    alias lg='lazygit'
    alias cat='bat'
    alias ll='ls -lah'
    alias la='ls -A'
    alias l='ls -CF'

    if type -q zoxide
        zoxide init fish | source
    end

    if not functions -q nvm
        if type -q fisher
            fisher install jorgebucaran/nvm.fish
        end
    end

end
