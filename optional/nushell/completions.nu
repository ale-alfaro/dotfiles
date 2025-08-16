def "nu-complete zoxide import" [] {
  ["autojump", "z"]
}

def "nu-complete zoxide shells" [] {
  ["bash", "elvish", "fish", "nushell", "posix", "powershell", "xonsh", "zsh"]
}

def "nu-complete zoxide hooks" [] {
  ["none", "prompt", "pwd"]
}

# Add a new directory or increment its rank
export extern "zoxide add" [
  ...paths: path
]

# Edit the database
export extern "zoxide edit" [ ]

# Import entries from another application
export extern "zoxide import" [
  --from: string@"nu-complete zoxide import"  # Application to import from
  --merge                                     # Merge into existing database
]

# Generate shell configuration
export extern "zoxide init" [
  shell: string@"nu-complete zoxide shells"
  --no-cmd                                    # Prevents zoxide from defining the `z` and `zi` commands
  --cmd: string                               # Changes the prefix of the `z` and `zi` commands [default: z]
  --hook: string@"nu-complete zoxide hooks"   # Changes how often zoxide increments a directory's score [default: pwd]
]

# Search for a directory in the database
export extern "zoxide query" [
  ...keywords: string
  --all(-a)             # Show unavailable directories
  --interactive(-i)     # Use interactive selection
  --list(-l)            # List all matching directories
  --score(-s)           # Print score with results
  --exclude: path       # Exclude the current directory
]

# Remove a directory from the database
export extern "zoxide remove" [
  ...paths: path
]

export extern zoxide [
  --help(-h)            # Print help
  --version(-V)         # Print version
]
# Nushell Environment Config File
#
# version = "0.95.0"


# If you want previously entered commands to have a different prompt from the usual one,
# you can uncomment one or more of the following lines.
# This can be useful if you have a 2-line prompt and it's taking up a lot of space
# because every command entered takes up 2 lines instead of 1. You can then uncomment
# the line below so that previously entered commands show with a single `🚀`.
# $env.TRANSIENT_PROMPT_COMMAND = {|| "🚀 " }
# $env.TRANSIENT_PROMPT_INDICATOR = {|| "" }
# $env.TRANSIENT_PROMPT_INDICATOR_VI_INSERT = {|| "" }
# $env.TRANSIENT_PROMPT_INDICATOR_VI_NORMAL = {|| "" }
# $env.TRANSIENT_PROMPT_MULTILINE_INDICATOR = {|| "" }
# $env.TRANSIENT_PROMPT_COMMAND_RIGHT = {|| "" }

# Specifies how environment variables are:
# - converted from a string to a value on Nushell startup (from_string)
# - converted from a value back to a string when running external commands (to_string)
# Note: The conversions happen *after* config.nu is loaded
