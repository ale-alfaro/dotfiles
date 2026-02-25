#!/usr/bin/env zsh

# +-----+
# | Git |
# +-----+

function fgf() {
    local -r prompt_add="Add > "
    local -r prompt_reset="Reset > "

    local -r git_root_dir=$(git rev-parse --show-toplevel)
    local -r git_unstaged_files="git ls-files --modified --deleted --other --exclude-standard --deduplicate $git_root_dir"

    local git_staged_files='git status --short | grep "^[A-Z]" | awk "{print \$NF}"'

    local -r git_reset="git reset -- {+}"
    local -r enter_cmd="($git_unstaged_files | grep {} && git add {+}) || $git_reset"

    local -r preview_status_label="[ Status ]"
    local -r preview_status="git status --short"

    local -r header=$(
        cat <<-EOF
		> CTRL-S to switch between Add Mode and Reset mode
		> CTRL_T for status preview | CTRL-F for diff preview | CTRL-B for blame preview
		> ALT-E to open files in your editor
		> ALT-C to commit | ALT-A to append to the last commit
		EOF
    )

    local -r add_header=$(
        cat <<-EOF
		$header
		> ENTER to add files
		> ALT-P to add patch
	EOF
    )

    local -r reset_header=$(
        cat <<-EOF
		$header
		> ENTER to reset files
		> ALT-D to reset and checkout files
	EOF
    )

    local -r mode_reset="change-prompt($prompt_reset)+reload($git_staged_files)+change-header($reset_header)+unbind(alt-p)+rebind(alt-d)"
    local -r mode_add="change-prompt($prompt_add)+reload($git_unstaged_files)+change-header($add_header)+rebind(alt-p)+unbind(alt-d)"

    eval "$git_unstaged_files" | fzf \
        --multi \
        --reverse \
        --no-sort \
        --prompt="Add > " \
        --preview-label="$preview_status_label" \
        --preview="$preview_status" \
        --header "$add_header" \
        --header-first \
        --bind='start:unbind(alt-d)' \
        --bind="ctrl-t:change-preview-label($preview_status_label)" \
        --bind="ctrl-t:+change-preview($preview_status)" \
        --bind='ctrl-f:change-preview-label([ Diff ])' \
        --bind='ctrl-f:+change-preview(git diff --color=always {} | sed "1,4d")' \
        --bind='ctrl-b:change-preview-label([ Blame ])' \
        --bind='ctrl-b:+change-preview(git blame --color-by-age {})' \
        --bind="ctrl-s:transform:[[ \$FZF_PROMPT =~ '$prompt_add' ]] && echo '$mode_reset' || echo '$mode_add'" \
        --bind="enter:execute($enter_cmd)" \
        --bind="enter:+reload([[ \$FZF_PROMPT =~ '$prompt_add' ]] && $git_unstaged_files || $git_staged_files)" \
        --bind="enter:+refresh-preview" \
        --bind='alt-p:execute(git add --patch {+})' \
        --bind="alt-p:+reload($git_unstaged_files)" \
        --bind="alt-d:execute($git_reset && git checkout {+})" \
        --bind="alt-d:+reload($git_staged_files)" \
        --bind='alt-c:execute(git commit)+abort' \
        --bind='alt-a:execute(git commit --amend)+abort' \
        --bind='alt-e:execute(${EDITOR:-vim} {+})' \
        --bind='f1:toggle-header' \
        --bind='f2:toggle-preview' \
        --bind='ctrl-y:preview-up' \
        --bind='ctrl-e:preview-down' \
        --bind='ctrl-u:preview-half-page-up' \
        --bind='ctrl-d:preview-half-page-down'
}

function fgc() {
    local -r git_log=$(
        cat <<-EOF
		git log --graph --color --format="%C(white)%h - %C(green)%cs - %C(blue)%s%C(red)%d"
	EOF
    )

    local -r git_log_all=$(
        cat <<-EOF
		git log --all --graph --color --format="%C(white)%h - %C(green)%cs - %C(blue)%s%C(red)%d"
	EOF
    )

    local get_hash
    read -r -d '' get_hash <<-'EOF'
		echo {} | grep -o "[a-f0-9]\{7\}" | sed -n "1p"
	EOF

    local -r git_show="[[ \$($get_hash) != '' ]] && git show --color \$($get_hash)"
    local -r git_show_subshell=$(
        cat <<-EOF
		[[ \$($get_hash) != '' ]] && sh -c "git show --color \$($get_hash) | less -R"
	EOF
    )

    local -r git_checkout="[[ \$($get_hash) != '' ]] && git checkout \$($get_hash)"
    local -r git_reset="[[ \$($get_hash) != '' ]] && git reset \$($get_hash)"
    local -r git_rebase_interactive="[[ \$($get_hash) != '' ]] && git rebase --interactive \$($get_hash)"
    local -r git_cherry_pick="[[ \$($get_hash) != '' ]] && git cherry-pick \$($get_hash)"

    local -r header=$(
        cat <<-EOF
		> ENTER to display the diff with less
	EOF
    )

    local -r header_branch=$(
        cat <<-EOF
		$header
		> CTRL-S to switch to All Commits mode
		> ALT-C to checkout the commit | ALT-R to reset to the commit
		> ALT-I to rebase interactively until the commit
	EOF
    )

    local -r header_all=$(
        cat <<-EOF
		$header
		> CTRL-S to switch to Branch Commits mode
		> ALT-P to cherry pick
	EOF
    )

    local -r reset_header=$(
        cat <<-EOF
		$header
		> ENTER to reset files
		> ALT-D to reset and checkout files
	EOF
    )

    local -r branch_prompt='Branch > '
    local -r all_prompt='All > '

    local -r mode_all="change-prompt($all_prompt)+reload($git_log_all)+change-header($header_all)+unbind(alt-c)+unbind(alt-r)+unbind(alt-i)+rebind(alt-p)"
    local -r mode_branch="change-prompt($branch_prompt)+reload($git_log)+change-header($header_branch)+rebind(alt-c)+rebind(alt-r)+rebind(alt-i)+unbind(alt-p)"

    eval "$git_log" | fzf \
        --ansi \
        --reverse \
        --no-sort \
        --prompt="$branch_prompt" \
        --header-first \
        --header="$header_branch" \
        --preview="$git_show" \
        --bind='start:unbind(alt-p)' \
        --bind="ctrl-s:transform:[[ \$FZF_PROMPT =~ '$branch_prompt' ]] && echo '$mode_all' || echo '$mode_branch'" \
        --bind="enter:execute($git_show_subshell)" \
        --bind="alt-c:execute($git_checkout)+abort" \
        --bind="alt-r:execute($git_reset)+abort" \
        --bind="alt-i:execute($git_rebase_interactive)+abort" \
        --bind="alt-p:execute($git_cherry_pick)+abort" \
        --bind='f1:toggle-header' \
        --bind='f2:toggle-preview' \
        --bind='ctrl-y:preview-up' \
        --bind='ctrl-e:preview-down' \
        --bind='ctrl-u:preview-half-page-up' \
        --bind='ctrl-d:preview-half-page-down'
}

function fgb() {
    local -r git_branches="git branch --all --color --format=$'%(HEAD) %(color:yellow)%(refname:short)\t%(color:green)%(committerdate:short)\t%(color:blue)%(subject)' | column --table --separator=$'\t'"
    local -r get_selected_branch='echo {} | sed "s/^[* ]*//" | awk "{print \$1}"'
    local -r git_log="git log \$($get_selected_branch) --graph --color --format='%C(white)%h - %C(green)%cs - %C(blue)%s%C(red)%d'"
    local -r git_diff='git diff --color $(git branch --show-current)..$(echo {} | sed "s/^[* ]*//" | awk "{print \$1}")'
    local -r git_show_subshell=$(
        cat <<-EOF
		[[ \$($get_selected_branch) != '' ]] && sh -c "git show --color \$($get_selected_branch) | less -R"
	EOF
    )
    local -r header=$(
        cat <<-EOF
	> ALT-M to merge with current * branch | ALT-R to rebase with current * branch
	> ALT-C to checkout the branch
	> ALT-D to delete the merged local branch | ALT-X to force delete the local branch
	> ENTER to open the diff with less
	EOF
    )

    eval "$git_branches" |
        fzf \
            --ansi \
            --reverse \
            --no-sort \
            --preview-label '[ Commits ]' \
            --preview "$git_log" \
            --header-first \
            --header="$header" \
            --bind="alt-c:execute(git checkout \$($get_selected_branch))" \
            --bind="alt-c:+reload($git_branches)" \
            --bind="alt-m:execute(git merge \$($get_selected_branch))" \
            --bind="alt-r:execute(git rebase \$($get_selected_branch))" \
            --bind="alt-d:execute(git branch --delete \$($get_selected_branch))" \
            --bind="alt-d:+reload($git_branches)" \
            --bind="alt-x:execute(git branch --delete --force \$($get_selected_branch))" \
            --bind="alt-x:+reload($git_branches)" \
            --bind="enter:execute($git_show_subshell)" \
            --bind='ctrl-f:change-preview-label([ Diff ])' \
            --bind="ctrl-f:+change-preview($git_diff)" \
            --bind='ctrl-i:change-preview-label([ Commits ])' \
            --bind="ctrl-i:+change-preview($git_log)" \
            --bind='f1:toggle-header' \
            --bind='f2:toggle-preview' \
            --bind='ctrl-y:preview-up' \
            --bind='ctrl-e:preview-down' \
            --bind='ctrl-u:preview-half-page-up' \
            --bind='ctrl-d:preview-half-page-down'
}

# +--------+
# | Pacman |
# +--------+

# TODO can improve that with a bind to switch to what was installed
fpac() {
    pacman -Slq | fzf --multi --reverse --preview 'pacman -Si {1}' | xargs -ro sudo pacman -S
}

fyay() {
    yay -Slq | fzf --multi --reverse --preview 'yay -Si {1}' | xargs -ro yay -S
}

# +-------+
# | Other |
# +-------+

# List install files for dotfiles
fdot() {
    file=$(fd "$DOTFILES/.*/.config" -exec basename {} ';' | sort | uniq | nl | fzf | cut -f 2)
    [ -n "$file" ] && "$EDITOR" "$DOTFILES/install/$file"
}

# List projects
fwork() {
    result=$(fd ~/sibel/eng/* -t d --format {\} | sort | uniq | nl | fzf | cut -f 2)
    [ -n "$result" ] && cd ~/workspace/$result
}

# Open pdf with Zathura
fpdf() {
    result=$(find -type f -name '*.pdf' | fzf --bind "ctrl-r:reload(find -type f -name '*.pdf')" --preview "pdftotext {} - | less")
    [ -n "$result" ] && nohup zathura "$result" &>/dev/null &
    disown
}

# Open freemind mindmap
fobs() {
    local folders=("$OBSIDIAN_HOME/Sibel-Work" "$OBSIDIAN_HOME/Personal-Geek")

    files=""
    for root in ${folders[@]}; do
        files="$files $(find $root -name '*.md')"
    done
    result=$(echo "$files" | fzf -m --height 60% --border sharp | tr -s "\n" " ")
    [ -n "$result" ] && nohup obsidian $(echo $result) &>/dev/null &
    disown
}

# Search and find directories in the dir stack
fpop() {
    # Only work with alias d defined as:

    d | fzf --height="20%" | cut -f 1 | source /dev/stdin
}

# Find in File using ripgrep
fif() {
    if [ ! "$#" -gt 0 ]; then return 1; fi
    rg --files-with-matches --no-messages "$1" |
        fzf --preview "highlight -O ansi -l {} 2> /dev/null \
      | rg --colors 'match:bg:yellow' --ignore-case --pretty --context 10 '$1' \
      || rg --ignore-case --pretty --context 10 '$1' {}"
}

# Search through all man pages
function fmanpage() {
    man -k . | fzf -q "$1" --prompt='man> ' --preview $'echo {} | tr -d \'()\' | awk \'{printf "%s ", $2} {print $1}\' | xargs -r man' | tr -d '()' | awk '{printf "%s ", $2} {print $1}' | xargs -r man
}

fman() {
    manpage="echo {} | sed 's/\([[:alnum:][:punct:]]*\) (\([[:alnum:]]*\)).*/\2 \1/'"
    batman="${manpage} | xargs -r man | col -bx | bat --language=man --plain --color always --theme=\"Monokai Extended\""
    man -k . | sort |
        awk -v cyan=$(tput setaf 6) -v blue=$(tput setaf 4) -v res=$(tput sgr0) -v bld=$(tput bold) '{ $1=cyan bld $1; $2=res blue $2; } 1' |
        fzf \
            -q "$1" \
            --ansi \
            --tiebreak=begin \
            --prompt=' Man > ' \
            --preview-window '50%,rounded,<50(up,85%,border-bottom)' \
            --preview "${batman}" \
            --bind "enter:execute(${manpage} | xargs -r man)" \
            --bind "alt-c:+change-preview(cht.sh {1})+change-prompt(ﯽ Cheat > )" \
            --bind "alt-m:+change-preview(${batman})+change-prompt( Man > )" \
            --bind "alt-t:+change-preview(tldr --color=always {1})+change-prompt(ﳁ TLDR > )"
    zle reset-prompt
}

# Icon used is nerdfont
#
fzf-nav-widget() {
    # Store the STDOUT of fzf in a variable
    selection=$(
        find -type d | fzf --multi --height=80% --border=sharp \
            --preview='tree -C {}' --preview-window='45%,border-sharp' \
            --prompt='Dirs > ' \
            --bind='del:execute(rm -ri {+})' \
            --bind='ctrl-p:toggle-preview' \
            --bind='ctrl-d:change-prompt(Dirs > )' \
            --bind='ctrl-d:+reload(find -type d)' \
            --bind='ctrl-d:+change-preview(tree -C {})' \
            --bind='ctrl-d:+refresh-preview' \
            --bind='ctrl-f:change-prompt(Files > )' \
            --bind='ctrl-f:+reload(find -type f)' \
            --bind='ctrl-f:+change-preview(cat {})' \
            --bind='ctrl-f:+refresh-preview' \
            --bind='ctrl-a:select-all' \
            --bind='ctrl-x:deselect-all' \
            --header '
    CTRL-D to display directories | CTRL-F to display files
    CTRL-A to select all | CTRL-x to deselect all
    ENTER to edit | DEL to delete
    CTRL-P to toggle preview
    '
    )

    # Determine what to do depending on the selection
    if [ -d "$selection" ]; then
        cd "$selection" || exit
    else
        eval "$EDITOR $selection"
    fi
    zle reset-prompt
}
