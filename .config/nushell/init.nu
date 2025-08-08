# ~/.config/nushell/init.nu
#
# Init module that exports commands and environment variables wanted at startup

# commands
export def egd [...rest] {
    with-env [GIT_EXTERNAL_DIFF 'difft'] { git diff $rest }
}

# we need to export the env we create with load-env
# because we are `use`-ing here and not `source`-ing this file
export-env {
    load-env {
        BROWSER: "arc"
        CARGO_TARGET_DIR: "~/.cargo/target"
        EDITOR: "nvim"
        VISUAL: "nvim"
        PAGER: "less"
        XDG_CONFIG_HOME: "/Users/alealfaro/.config"
        SHELL: "nu"
        HOSTNAME:  (hostname | split row '.' | first | str trim)
        SHOW_USER: true
        LS_COLORS: ([
             "di=01;34;2;102;217;239"
             "or=00;40;31"
             "mi=00;40;31"
             "ln=00;36"
             "ex=00;32"
        ] | str join (char env_sep))
    }
}
