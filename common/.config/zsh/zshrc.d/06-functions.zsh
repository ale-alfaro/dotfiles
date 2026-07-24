#!/usr/bin/env zsh

tdl() {
  [[ -z $1 ]] && {
    echo "Usage: tdl <cmd> <[vsplit_pane_height]> <[bottom_pane_height>]"
    return 1
  }
  [[ -z $TMUX ]] && {
    echo "You must start tmux to use tdl."
    return 1
  }

  local current_dir="${PWD}"
  local editor_pane cmd_pane cmd2_pane
  local cmd="${1:?}"
  local vpane_width="${2:-30}"
  local hpane_height="$3"

  local cmd2=""
  if (($# > 3)); then
    shift 3
    cmd2="$*"
  fi
  # Use TMUX_PANE for the pane we're running in (stable even if active window changes)
  editor_pane="$TMUX_PANE"

  # Name the current window after the base directory name
  tmux rename-window -t "$editor_pane" "$(basename "$current_dir")"
  if [[ -n "$hpane_height" ]]; then
    ((hpane_height > 30)) && echo "hpane_height=30"
    ((hpane_height < 15)) && echo "hpane_height=15"
    tmux split-window -v -p "$hpane_height" -t "$editor_pane" -c "$current_dir" "${(z)${cmd2:-$SHELL}}"
  fi
  # Split window vertically - top 85%, bottom 15% (target editor pane explicitly)

  # Split editor pane horizontally - Cmd on right
  ((vpane_width > 50)) && echo "vpane_width=50"
  ((vpane_width < 20)) && echo "vpane_width=20"
  cmd_pane=$(tmux split-window -h -p "$vpane_width" -t "$editor_pane" -c "$current_dir" -P -F '#{pane_id}')

  # Run cmd in the right pane
  tmux send-keys -t "$cmd_pane" "$cmd" C-m

  # Run nvim in the left pane
  tmux send-keys -t "$editor_pane" "$EDITOR ." C-m

  # Select the nvim pane for focus
  tmux select-pane -t "$editor_pane"
}
alias tobs='tdl ~/.local/bin/obsidian'

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
  local -r gdbserver_cmd=$(
    cat <<-EOF
JLinkGDBServer \
  -select usb \
  -if swd \
  -speed auto \
  -device ${device} \
  -silent \
  -endian little \
  -singlerun \
  -nogui
EOF
  )
  local -r gdbclient_cmd=$(
    cat <<-EOF
  arm-zephyr-eabi-gdb-py \
  -ex='target remote :2331' \
  -ex='mon reset' \
  -ex='c' \
  --se=${elf}
EOF
  )
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
  tmux split-window -v -l 15% -t "$gdbclient_pane" -c "$current_dir" "$gdbserver_cmd"

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
