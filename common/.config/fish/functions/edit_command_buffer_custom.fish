function edit_command_buffer_custom
    set -l tmp (mktemp)
    echo (commandline) > $tmp
    nvim $tmp
    commandline -r (cat $tmp)
    rm $tmp
end
bind \cx\ce edit_command_buffer_custom
