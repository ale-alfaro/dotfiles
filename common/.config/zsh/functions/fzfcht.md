# Examples

```zsh

# filename: bi
#!/usr/bin/env zsh
# Fully manage brew installation and suppression, and then some.
# needs zsh, jq, bat
# Inspired by:
# - https://github.com/raycast/extensions/tree/main/extensions/brew
# - https://github.com/junegunn/fzf/wiki/examples#dnf

readonly wait_click="echo $'\n\e[34mPress any key to continue...' && read -rsk 1"
readonly jq_all='
	(. | map(.cask_tokens) | flatten | map(split("/")[-1] + " (cask)"))[]
	, (. | map(.formula_names) | flatten)[]
'

readonly jq_installed='(.formulae[] | .name), (.casks[] | .token + " (cask)")'

readonly tmp_file="$(mktemp)"
trap "rm -f $tmp_file" EXIT

readonly reload="reload%case \$(cat $tmp_file) in
	install) { echo Install mode; brew tap-info --json --installed | jq --raw-output '$jq_all' | sort } ;;
	*) { echo Remove mode; brew info --json=v2 --installed | jq --raw-output '$jq_installed' | sort } ;;
esac%"


readonly state="cat $tmp_file"

readonly nextstate="execute-silent%case \$(cat $tmp_file) in install) echo rm > $tmp_file ;; *) echo install > $tmp_file ;; esac%"

readonly bold="\e[1m"
readonly reset="\e[0m"
readonly italic="\e[3m"
readonly gray="\e[30m"
readonly c="\e[1;36m"
readonly d="\e[1;37m"

readonly help="\
\
${bold}${c}[${d}B${c}]${d}rew ${c}[${d}I${c}]${d}nteractive${reset}

${italic}Tab${reset}     Switch between install mode and remove mode
${italic}Enter${reset}   Select formula or cask for installation or deletion (depends on mode)

${italic}ctrl-s${reset}  Show formula or cask installation [s]ource code
${italic}ctrl-j${reset}  Show formula or cask [J]SON information
${italic}crtl-e${reset}  [E]dit formula or cask source code

${italic}?${reset}       Help (this page)
${italic}ESC${reset}     Quit


It is also advised you use auto-updates, this can be done with:

    brew autoupdate start --upgrade --cleanup --enable-notification

"

echo install > $tmp_file

{ echo "Install mode (? for help)"; brew tap-info --json --installed | jq --raw-output "$jq_all" | sort } |
	fzf --reverse --header-lines=1  --header-first --prompt="$ " \
		--bind="enter:execute(
			if [[ '{2}' == '(cask)' ]]; then
				brew \$($state) --cask {1}
			else
				brew \$($state) {1}
			fi
			$wait_click)+$reload" \
		--bind='ctrl-s:preview(
			bat --color=always $(brew edit --print-path {1}) --style=header
		)' \
		--bind="ctrl-j:preview:brew info --json=v2 {1} | jq '
			(.formulae + .casks)[0] | with_entries(select(try (.value | length > 0)))
		' | bat --plain --language=json --color=always" \
		--bind="ctrl-e:execute:
			EDITOR='code --wait' brew edit {1}
			bat --color=always --language=markdown --plain <<-MD
				To install the formulae (or cask) you edited with your changes, use:

				    brew reinstall --build-from-source {1}
			MD
			$wait_click" \
		--bind="tab:$nextstate+$reload" \
		--bind="?:preview:printf '$help'" \
		--preview='brew info {1} | bat --color=always --language=Markdown --style=plain' \
		--preview-window='bottom,wrap,<13(right)'

```

# FZFCHT - Quick Cheat Sheet for all FZF bindings

KEY/EVENT BINDINGS
       --bind option allows you to bind a key or an event to one or more actions. You can use it to customize key bindings or implement dynamic behaviors.

       --bind takes a comma-separated list of binding expressions. Each binding expression is KEY:ACTION or EVENT:ACTION. 
       You can bind actions to multiple keys and events by writing comma-separated list of keys and events before the colon. e.g. KEY1,KEY2,EVENT1,EVENT2:ACTION.

       e.g.
            fzf --bind=ctrl-j:accept,ctrl-k:kill-line

            # Load 'ps -ef' output on start and reload it on CTRL-R
            fzf --bind 'start,ctrl-r:reload:ps -ef'
AVAILABLE KEYS: (SYNONYMS):
       ctrl-[a-z]
       ctrl-space
       ctrl-delete
       ctrl-\
       ctrl-]
       ctrl-^         (ctrl-6)
       ctrl-/         (ctrl-_)
       ctrl-alt-[a-z]
       alt-[*]        (Any case-sensitive single character is allowed)
       f[1-12]
       enter          (return ctrl-m)
       space
       backspace      (bspace bs)
       alt-up
       alt-down
       alt-left
       alt-right
       alt-enter
       alt-space
       alt-backspace  (alt-bspace alt-bs)
       tab
       shift-tab      (btab)
       esc
       delete         (del)
       up
       down
       left
       right
       home
       end
       insert
       page-up        (pgup)
       page-down      (pgdn)
       shift-up
       shift-down
       shift-left
       shift-right
       shift-delete
       alt-shift-up
       alt-shift-down
       alt-shift-left
       alt-shift-right
       left-click
       right-click
       double-click
       scroll-up
       scroll-down
       preview-scroll-up
       preview-scroll-down
       shift-left-click
       shift-right-click
       shift-scroll-up
       shift-scroll-down
       or any single character



 AVAILABLE EVENTS:
       start
              Triggered only once when fzf finder starts. Since fzf consumes the input stream asynchronously, the input list is not available unless you use --sync.

              e.g.
                   # Move cursor to the last item and select all items
                   seq 1000 | fzf --multi --sync --bind start:last+select-all

       load
              Triggered when the input stream is complete and the initial processing of the list is complete.

              e.g.
                   # Change the prompt to "loaded" when the input stream is complete
                   (seq 10; sleep 1; seq 11 20) | fzf --prompt 'Loading> ' --bind 'load:change-prompt:Loaded> '

       resize
              Triggered when the terminal size is changed.

              e.g.
                   fzf --bind 'resize:transform-header:echo Resized: ${FZF_COLUMNS}x${FZF_LINES}'

       result
              Triggered when the filtering for the current query is complete and the result list is ready.

              e.g.
                   # Put the cursor on the second item when the query string is empty
                   # * Note that you can't use 'change' event in this case because the second position may not be available
                   fzf --sync --bind 'result:transform:[[ -z {q} ]] && echo "pos(2)"'
       change
              Triggered whenever the query string is changed

              e.g.
                   # Move cursor to the first entry whenever the query is changed
                   fzf --bind change:first
       focus
              Triggered when the focus changes due to a vertical cursor movement or a search result update.

              e.g.
                   fzf --bind 'focus:transform-preview-label:echo [ {} ]' --preview 'cat {}'

                   # Any action bound to the event runs synchronously and thus can make the interface sluggish
                   # e.g. lolcat isn't one of the fastest programs, and every cursor movement in
                   #      fzf will be noticeably affected by its execution time
                   fzf --bind 'focus:transform-preview-label:echo [ {} ] | lolcat -f' --preview 'cat {}'

                   # Beware not to introduce an infinite loop
                   seq 10 | fzf --bind 'focus:up' --cycle
       multi
              Triggered when the multi-selection has changed.

       one
              Triggered when there's only one match. one:accept binding is comparable to --select-1 option, but the difference is that --select-1 is only effective before the interactive finder starts but one event is triggered by the interactive finder.

              e.g.
                   # Automatically select the only match
                   seq 10 | fzf --bind one:accept

       zero
              Triggered when there's no match. zero:abort binding is comparable to --exit-0 option, but the difference is that --exit-0 is only effective before the interactive finder starts but zero event is triggered by the interactive finder.

              e.g.
                   # Reload the candidate list when there's no match
                   echo $RANDOM | fzf --bind 'zero:reload(echo $RANDOM)+clear-query' --height 3

       backward-eof
              Triggered when the query string is already empty and you try to delete it backward.

              e.g.
                   fzf --bind backward-eof:abort

                fzf --bind backward-eof:abort
       jump
              Triggered when successfully jumped to the target item in jump mode.

              e.g.
                   fzf --bind space:jump,jump:accept

       jump-cancel
              Triggered when jump mode is cancelled.

              e.g.
                   fzf --bind space:jump,jump:accept,jump-cancel:abort

       click-header
              Triggered when a mouse click occurs within the header. Sets FZF_CLICK_HEADER_LINE and FZF_CLICK_HEADER_COLUMN environment variables starting from 1. It optionally sets FZF_CLICK_HEADER_WORD and FZF_CLICK_HEADER_NTH if clicked on a word.

              e.g.
                   # Click on the header line to limit search scope
                   ps -ef | fzf --style full --layout reverse --header-lines 1 \
                                --header-lines-border bottom --no-list-border \
                                --color fg:dim,nth:regular \
                                --bind 'click-header:transform-nth(
                                          echo $FZF_CLICK_HEADER_NTH
                                        )+transform-prompt(
                                          echo "$FZF_CLICK_HEADER_WORD> "
                                        )'

       click-footer
              Triggered when a mouse click occurs within the footer. Sets FZF_CLICK_FOOTER_LINE and FZF_CLICK_FOOTER_COLUMN environment variables starting from 1. It optionally sets FZF_CLICK_FOOTER_WORD if clicked on a word.

 AVAILABLE ACTIONS:
       A key or an event can be bound to one or more of the following actions.

         ACTION:                      DEFAULT BINDINGS (NOTES):
           abort                        ctrl-c  ctrl-g  ctrl-q  esc
           accept                       enter   double-click
           accept-non-empty             (same as accept except that it prevents fzf from exiting without selection)
           accept-or-print-query        (same as accept except that it prints the query when there's no match)
           backward-char                ctrl-b  left
           backward-delete-char         ctrl-h  bspace
           backward-delete-char/eof     (same as backward-delete-char except aborts fzf if query is empty)
           backward-kill-word           alt-bs
           backward-word                alt-b   shift-left
           become(...)                  (replace fzf process with the specified command; see below for the details)
           beginning-of-line            ctrl-a  home
           bell                         (ring the terminal bell)
           bg-cancel                    (cancel background transform processes)
           cancel                       (clear query string if not empty, abort fzf otherwise)
           change-border-label(...)     (change --border-label to the given string)
           change-ghost(...)            (change ghost text to the given string)
           change-header(...)           (change header to the given string; doesn't affect --header-lines)
           change-header-label(...)     (change --header-label to the given string)
           change-input-label(...)      (change --input-label to the given string)
           change-list-label(...)       (change --list-label to the given string)
           change-multi                 (enable multi-select mode with no limit)
           change-multi(...)            (enable multi-select mode with a limit or disable it with 0)
           change-nth(...)              (change --nth option; rotate through the multiple options separated by '|')
           change-pointer(...)          (change --pointer option)
           change-preview(...)          (change --preview option)
           change-preview-label(...)    (change --preview-label to the given string)
           change-preview-window(...)   (change --preview-window option; rotate through the multiple option sets separated by '|')
           change-prompt(...)           (change prompt to the given string)
           change-query(...)            (change query string to the given string)
           clear-screen                 ctrl-l
           clear-multi                  (clear multi-selection)
           close                        (close preview window if open, abort fzf otherwise)
           clear-query                  (clear query string)
           delete-char                  del
           delete-char/eof              ctrl-d (same as delete-char except aborts fzf if query is empty)
           deselect
           deselect-all                 (deselect all matches; to also clear non-matched selections, use clear-multi)
           disable-search               (disable search functionality)
           down                         ctrl-j  ctrl-n  down
           enable-search                (enable search functionality)
           end-of-line                  ctrl-e  end
           exclude                      (exclude the current item from the result)
           exclude-multi                (exclude the selected items or the current item from the result)
           execute(...)                 (see below for the details)
           execute-silent(...)          (see below for the details)
           first                        (move to the first match; same as pos(1))
           forward-char                 ctrl-f  right
           forward-word                 alt-f   shift-right
           ignore
           jump                         (EasyMotion-like 2-keystroke movement)
           kill-line
           kill-word                    alt-d
           last                         (move to the last match; same as pos(-1))
           next-history                 (ctrl-n on --history)
           next-selected                (move to the next selected item)
           page-down                    pgdn
           page-up                      pgup
           half-page-down
           half-page-up
           hide-header
           hide-input
           hide-preview
           offset-down                  (similar to CTRL-E of Vim)
           offset-up                    (similar to CTRL-Y of Vim)
           offset-middle                (place the current item is in the middle of the screen)
           pos(...)                     (move cursor to the numeric position; negative number to count from the end)
           prev-history                 (ctrl-p on --history)
           prev-selected                (move to the previous selected item)
           preview(...)                 (see below for the details)
           preview-down                 shift-down
           preview-up                   shift-up
           preview-page-down
           preview-page-up
           preview-half-page-down
           preview-half-page-up
           preview-bottom
           preview-top
           print(...)                   (add string to the output queue and print on normal exit)
           put                          (put the character to the prompt)
           put(...)                     (put the given string to the prompt)
           refresh-preview
           rebind(...)                  (rebind bindings after unbind)
           reload(...)                  (see below for the details)
           reload-sync(...)             (see below for the details)
           replace-query                (replace query string with the current selection)
           search(...)                  (trigger fzf search with the given string)
           select
           select-all                   (select all matches)with ble
           show-header
           show-input
           show-preview
           toggle                       (right-click)
           toggle-all                   (toggle all matches)
           toggle-in                    (--layout=reverse* ? toggle+up : toggle+down)
           toggle-out                   (--layout=reverse* ? toggle+down : toggle+up)
           toggle-bind
           toggle-header
           toggle-hscroll
           toggle-input
           toggle-multi-line
           toggle-preview
           toggle-preview-wrap
           toggle-search                (toggle search functionality)
           toggle-sort
           toggle-track                 (toggle global tracking option (--track))
           toggle-track-current         (toggle tracking of the current item)
           toggle-wrap                  ctrl-/  alt-/
           toggle+down                  ctrl-i  (tab)
           toggle+up                    btab    (shift-tab)
           track-current                (track the current item; automatically disabled if focus changes)
           transform(...)               (transform states using the output of an external command)
           transform-border-label(...)  (transform border label using an external command)
           transform-ghost(...)         (transform ghost text using an external command)
           transform-header(...)        (transform header using an external command)
           transform-header-label(...)  (transform header label using an external command)
           transform-input-label(...)   (transform input label using an external command)
           transform-list-label(...)    (transform list label using an external command)
           transform-nth(...)           (transform nth using an external command)
           transform-pointer(...)       (transform pointer using an external command)
           transform-preview-label(...) (transform preview label using an external command)
           transform-prompt(...)        (transform prompt string using an external command)
           transform-query(...)         (transform query string using an external command)
           transform-search(...)        (trigger fzf search with the output of an external command)
           trigger(...)                 (trigger actions bound to a comma-separated list of keys and events)
           unbind(...)                  (unbind bindings)
           unix-line-discard            ctrl-u
           unix-word-rubout             ctrl-w
           untrack-current              (stop tracking the current item; no-op if global tracking is enabled)
           up                           ctrl-k  ctrl-p  up
           yank                         ctrl-y

       Each transform* action has a corresponding bg-transform* variant that runs the command in the background.

   ACTION COMPOSITION
       Multiple actions can be chained using + separator.

       e.g.
            fzf --multi --bind 'ctrl-a:select-all+accept'
            fzf --multi --bind 'ctrl-a:select-all' --bind 'ctrl-a:+accept'

       Any action after a terminal action that exits fzf, such as accept or abort, is ignored.

  ACTION ARGUMENT
       An action denoted with (...) suffix takes an argument.

       e.g.
            fzf --bind 'ctrl-a:change-prompt(NewPrompt> )'
            fzf --bind 'ctrl-v:preview(cat {})' --preview-window hidden

       If the argument contains parentheses, fzf may fail to parse the expression. In that case, you can use any of the following alternative notations to avoid parse er
rors.

           action-name[...]
           action-name{...}
           action-name<...>
           action-name~...~
           action-name!...!
           action-name@...@
           action-name#...#
           action-name$...$
           action-name%...%
           action-name^...^
           action-name&...&
           action-name*...*
           action-name;...;
           action-name/.../
           action-name|...|
           action-name:...
              The last one is the special form that frees you from parse errors as it does not expect the closing character. The catch is that it should be the last one in the comma-separated list of key-action pairs.

COMMAND EXECUTION
       With execute(...) action, you can execute arbitrary commands without leaving fzf. For example, you can turn fzf into a simple file browser by binding enter key to less command like follows.

           `fzf --bind "enter:execute(less {})"`

       You can use the same placeholder expressions as in --preview.

       fzf switches to the alternate screen when executing a command. However, if the command is expected to complete quickly, and you are not interested in its output, you might want to use execute-silent instead, which silently executes the command without the switching. Note that fzf will not be responsive until the  command  is  complete. For asynchronous execution, start your command as a background process (i.e. appending &).

       On *nix systems, fzf runs the command with $SHELL -c if SHELL is set, otherwise with sh -c, so in this case make sure that the command is POSIX-compliant.

       become(...) action is similar to execute(...), but it replaces the current fzf process with the specified command using execve(2) system call.

           fzf --bind "enter:become(vim {})"

RELOAD INPUT
    reload(...) action is used to dynamically update the input list without restarting fzf. It takes the same command template with placeholder expressions as execute(...).

       See https://github.com/junegunn/fzf/issues/1750 for more info.

       e.g.
            # Update the list of processes by pressing CTRL-R
            ps -ef | fzf --bind 'ctrl-r:reload(ps -ef)' --header 'Press CTRL-R to reload' \
                         --header-lines=1 --layout=reverse

            # Integration with ripgrep
            RG_PREFIX="rg --column --line-number --no-heading --color=always --smart-case "
            INITIAL_QUERY="foobar"
            FZF_DEFAULT_COMMAND="$RG_PREFIX '$INITIAL_QUERY'" \
              fzf --bind "change:reload:$RG_PREFIX {q} || true" \
                  --ansi --disabled --query "$INITIAL_QUERY"

       reload-sync(...) is a synchronous version of reload that replaces the list only when the command is complete. This is useful when the command takes a while to pro
duce the initial output and you don't want fzf to run against an empty list while the command is running.

       e.g.
            # You can still filter and select entries from the initial list for 3 seconds
            seq 100 | fzf --bind 'load:reload-sync(sleep 3; seq 1000)+unbind(load)'
   TRANSFORM ACTIONS
       Actions with transform- prefix are used to transform the states of fzf using the output of an external command. The output of these commands are expected to be a single line of text.

       e.g.
           fzf --bind 'focus:transform-header:file --brief {}'

       transform(...) action runs an external command that should print a series of actions to be performed. The output should be in the same format as the payload of HTTP POST request to the --listen server.

       e.g.
           # Disallow selecting an empty line
           echo -e "1. Hello\n2. Goodbye\n\n3. Exit" |
             fzf --height '~100%' --reverse --header 'Select one' \
                 --bind 'enter:transform:[[ -n {} ]] &&
                           echo accept ||
                           echo "change-header:Invalid selection"'

       A  common  mistake  when writing a transform action is not escaping placeholder expressions when passing them back to fzf. In the following example, if you don't escape {}, fzf will immediately replace it with the single-quoted string of the current item. This causes single quotes to appear in the header and footer, and the script
       will break if any item contains double-quote characters.

           fzf --bind 'focus:transform:[[ $FZF_ACTION =~ up ]] &&
                       echo "change-header()+transform-footer:echo \{}" ||
                       echo "change-footer()+transform-header:echo \{}"'

   TRANSFORM IN THE BACKGROUND
       Transform actions are synchronous, meaning fzf becomes unresponsive while the command runs. To avoid this, each transform* action has a corresponding bg-transform* variant that runs in the background. Unless you need to chain multiple transform actions where later ones depend on earlier results, prefer using  the  bg  variant.  To
       cancel currently running background transform processes, use bg-cancel action.

   PREVIEW BINDING
       With preview(...) action, you can specify multiple different preview commands in addition to the default preview command given by --preview option.

       e.g.
            # Default preview command with an extra preview binding
            fzf --preview 'file {}' --bind '?:preview:cat {}'

            # A preview binding with no default preview command
            # (Preview window is initially empty)
            fzf --bind '?:preview:cat {}'

            # Preview window hidden by default, it appears when you first hit '?'
            fzf --bind '?:preview:cat {}' --preview-window hidden
