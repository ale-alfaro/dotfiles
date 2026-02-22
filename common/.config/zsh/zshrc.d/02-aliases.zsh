#!/usr/bin/env zsh

# ---- zsh-compatible Direnv stdlib helpers + other utilities for zsh scripts -----
[[ -r "$ZDOTDIR/helpers/stdlib.zsh" ]] && source "$ZDOTDIR/helpers/stdlib.zsh"
# Plugin Helper
[[ -r "$ZDOTDIR/helpers/plugin_helper.zsh" ]] && source "$ZDOTDIR/helpers/plugin_helper.zsh"

# source <(mise activate zsh)

compress(){
  tar -czf "${1%/}.tar.gz" "${1%/}"
}

alias decompress="tar -xzf"
# ---- Editor -----
alias v="n"
# Array to quoted list of strings
n() {
  if [[ "$#" -eq 0 ]]; then nvim; fi
  if [[ "$#" -eq 1 ]]; then
    case "$1" in
      nvim | zsh | direnv | hypr | wezterm)
        nvim "$XDG_CONFIG_HOME/$1"
        ;;
      sdk-ncs)
        nvim "$HOME/ncs"
        ;;
      *)
        if [[ -d "$1" ]]; then
          zd "$1" && nvim .
        else
          nvim "$1"
        fi
        ;;
    esac
  else
    nvim "$@"
  fi
}

# Navigate back to directories easily using the zsh directory stack feature
alias d='dirs -v'
for index ({1..9}) alias "$index"="cd +${index}"; unset index

#######################################################
# CLI Aliases
#######################################################
# Alias For bat
# Link: https://github.com/sharkdp/bat
alias wman='wikiman'
# has batman && alias man='batman'
# Alias for lazygit
# Link: https://github.com/jesseduffield/lazygit
alias lg='lazygit'
# -------------------------------------------
# 5. Suffix Aliases - Open Files by Extension
# -------------------------------------------
# Just type the filename to open it with the associated program
alias -s json=jqp
alias -s md=bat
alias -s txt=bat
alias -s log=bat
# alias -s py='$EDITOR'
alias -s c='$EDITOR'
alias -s h='$EDITOR'
alias -s hpp='$EDITOR'
alias -s cpp='$EDITOR'
# alias -s Kconfig='$EDITOR'
# alias -s py='$EDITOR'
alias -s conf='$EDITOR'
alias -s dts='$EDITOR'
alias -s html=open  # macOS: open in default browser

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
  alias -g C='| wlcopy'
elif [[ "$OSTYPE" == "macos"* ]]; then
  alias -g C='| pbcopy'
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
alias zcp='zmv -C'  # Copy with patterns
alias zln='zmv -L'  # Link with patterns


ai_commit(){
diff=$(git diff --cached | head -n 10)
if [ -z "$diff" ]; then
  echo "No changes in staging. Add changes first."
  exit 1
fi

local -r message=$(
  cat <<-EOF
  Please suggest a commit messages, given the following diff and using the template below,
  this is a non-interactive session, the message you output will be the one written to the commit message editor
  so be to the point and add any problems to the beggining of the message with a clear sign that something went wrong.

  **Output Format**
  Follow this output format and ONLY output raw commit messages without spacing, numbers or other decorations:
  <type>(<scope>): <description>.

  **Example**
  fix(app): add password regex pattern
  test(unit): add new test cases
  style: remove unused imports
  refactor(pages): extract common code to utils/wait.ts

  **Changes to analyze:**
  \$(git diff --cached --stat)
  \$(git diff --cached)


  **Recent Commits on Repo for Reference:**
  \$(git log -n 10 --pretty=format:'%h %s')
EOF
  )
  codex e -o /tmp/commit_msg "$message"
  git commit -e -F /tmp/commit_msg
}
