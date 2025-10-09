function fzfd
    cd (fd --type d | fzf)
end
bind \cf fzfd
