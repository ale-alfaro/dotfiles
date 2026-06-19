tdl() {
  [[ -z $1 ]] && {
    echo "Usage: tdl <c|cx|codex|other_ai> [<second_ai>]"
    return 1
  }
  [[ -z $TMUX ]] && {
    echo "You must start tmux to use tdl."
    return 1
  }

  local current_dir="${PWD}"
  local editor_pane ai_pane ai2_pane
  local ai="$1"
  local ai2="$2"

  # Use TMUX_PANE for the pane we're running in (stable even if active window changes)
  editor_pane="$TMUX_PANE"

  # Name the current window after the base directory name
  tmux rename-window -t "$editor_pane" "$(basename "$current_dir")"

  # Split window vertically - top 85%, bottom 15% (target editor pane explicitly)
  tmux split-window -v -p 15 -t "$editor_pane" -c "$current_dir"

  # Split editor pane horizontally - AI on right 30% (capture new pane ID directly)
  ai_pane=$(tmux split-window -h -p 30 -t "$editor_pane" -c "$current_dir" -P -F '#{pane_id}')

  # If second AI provided, split the AI pane vertically
  if [[ -n $ai2 ]]; then
    ai2_pane=$(tmux split-window -v -t "$ai_pane" -c "$current_dir" -P -F '#{pane_id}')
    tmux send-keys -t "$ai2_pane" "$ai2" C-m
  fi

  # Run ai in the right pane
  tmux send-keys -t "$ai_pane" "$ai" C-m

  # Run nvim in the left pane
  tmux send-keys -t "$editor_pane" "$EDITOR ." C-m

  # Select the nvim pane for focus
  tmux select-pane -t "$editor_pane"
}
alias aish='tdl'

# Create multiple tdl windows with one per subdirectory in the current directory
# Usage: tdlm <c|cx|codex|other_ai> [<second_ai>]
tdlm() {
  [[ -z $1 ]] && {
    echo "Usage: tdlm <c|cx|codex|other_ai> [<second_ai>]"
    return 1
  }
  [[ -z $TMUX ]] && {
    echo "You must start tmux to use tdlm."
    return 1
  }

  local ai="$1"
  local ai2="$2"
  local base_dir="$PWD"
  local first=true

  # Rename the session to the current directory name (replace dots/colons which tmux disallows)
  tmux rename-session "$(basename "$base_dir" | tr '.:' '--')"

  for dir in "$base_dir"/*/; do
    [[ -d $dir ]] || continue
    local dirpath="${dir%/}"

    if $first; then
      # Reuse the current window for the first project
      tmux send-keys -t "$TMUX_PANE" "cd '$dirpath' && tdl $ai $ai2" C-m
      first=false
    else
      local pane_id=$(tmux new-window -c "$dirpath" -P -F '#{pane_id}')
      tmux send-keys -t "$pane_id" "tdl $ai $ai2" C-m
    fi
  done
}

# alias gdb-load='arm-none-eabi-gdb-py --eval-command="target remote localhost:2331"  --ex="mon reset" --ex="load" --ex="mon reset"  --se '
# Create a multi-pane swarm layout with the same command started in each pane (great for AI)
# Usage: tsl <pane_count> <command>
tgdb() {
  [[ -z $1 || -z $2 ]] && {
    echo "Usage: tgdb <elf> <nRF5340_xxAA_APP>"
    return 1
  }
  [[ -z $TMUX ]] && {
    echo "You must start tmux to use tsl."
    return 1
  }

  local elf="${1:?}"
  local device="${2:?}"
  local gdbserver_cmd="JLinkGDBServer \
  -select usb \
  -if swd \
  -speed auto \
  -device ${device} \
  -silent \
  -endian little \
  -singlerun \
  -nogui"
  local gdbclient_cmd="arm-zephyr-eabi-gdb-py \
  -ex='target remote :2331' \
  -ex='mon reset' \
  -ex='c' \
  --se=${elf}"
  local current_dir="${PWD}"

  # Use TMUX_PANE for the pane we're running in (stable even if active window changes)
  gdbclient_pane="$TMUX_PANE"

  # Name the current window after the base directory name
  tmux rename-window -t "$gdbclient_pane" "$(basename "$current_dir")"

  # Optional extra command for the right pane (e.g. RTT/serial monitor)
  local cmd=""
  if (($# > 2)); then
    shift 2
    cmd="$*"
  fi

  # Bottom pane runs the GDB server directly so it never races against shell startup.
  # Trailing `exec $SHELL` keeps the pane alive (showing any error) if the server exits.
  tmux split-window -v -l 15% -t "$gdbclient_pane" -c "$current_dir" "$gdbserver_cmd; exec ${SHELL}"

  # Right pane: extra command if given, otherwise a plain shell
  if [[ -n $cmd ]]; then
    tmux split-window -h -l 30% -t "$gdbclient_pane" -c "$current_dir" "$cmd; exec ${SHELL}"
  else
    tmux split-window -h -l 30% -t "$gdbclient_pane" -c "$current_dir"
  fi

  # GDB client runs in the original (already-ready) pane, so send-keys is reliable here
  tmux send-keys -t "$gdbclient_pane" "$gdbclient_cmd" C-m
  tmux select-pane -t "$gdbclient_pane"
}

tgdbrtt() {
  [[ -z $1 || -z $2 ]] && {
    echo "Usage: tgdbrtt <elf> <nRF5340_xxAA_APP>"
    return 1
  }
  local rtt_cmd="nc localhost 19021"
  local pane_id=$(tmux new-window -c "${PWD}" -P -F '#{pane_id}')
  tmux send-keys -t "$pane_id" "tgdb $1 $2 $rtt_cmd" C-m
}

tgdbserial() {
  [[ -z $1 || -z $2 || -z $3 ]] && {
    echo "Usage: tgdbserial <elf> <nRF5340_xxAA_APP> <serial_port>"
    return 1
  }
  local serial_cmd="minicom -D ${3:?}"
  local pane_id=$(tmux new-window -c "${PWD}" -P -F '#{pane_id}')
  tmux send-keys -t "$pane_id" "tgdb $1 $2 $serial_cmd" C-m
}
ssh_agent_start() {
  eval "$(ssh-agent -s)"
  ssh-add ~/.ssh/id_ed25519_yubikey
  if ! command -v dots-toggle; then
    touch ~/.local/state/dots/toggles/ssh-agent
  else
    dots-toggle ssh-agent
  fi
}
alias sshstart="ssh_agent_start"
