# Overwrite parts of the omarchy-menu with user-specific submenus.
# See $OMARCHY_PATH/bin/omarchy-menu for functions that can be overwritten.
#
# WARNING: Overwritten functions will obviously not be updated when Omarchy changes.
#
# Example of minimal system menu:
#
show_system_menu() {
  local options="󱄄  Logout\n󰜉  Restart"
  [[ ! -f ~/.local/state/omarchy/toggles/suspend-off ]] && options="$options\n󰒲  Suspend"
  omarchy-hibernation-available && options="$options\n󰤁  Hibernate"
  options="$options\n󰐥  Shutdown"
  case $(menu "System" "$options") in
  *Suspend*) systemctl suspend ;;
  *Hibernate*) systemctl hibernate ;;
  *Logout*) omarchy-system-logout ;;
  *Restart*) omarchy-system-reboot ;;
  *Shutdown*) omarchy-system-shutdown ;;
  *) back_to show_main_menu ;;
  esac
}
#
# Example of overriding just the about menu action: (Using zsh instead of bash (default))
#
#
show_learn_menu() {
  case $(menu "TMUX" "  Work\n  Obsidian\n  Rice") in
  *Work*) termux "$HOME/sibel/eng/fw" "work" ;;
  *Obsidian*) termux "${OBSIDIAN_HOME:-$HOME/Documents/Obsidian}" "obsidian" ;;
  *Rice*) termux "$HOME/dotfiles" "dotfiles" ;;
  *) show_main_menu ;;
  esac
}
