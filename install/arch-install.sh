# Determine the platform
OS=$(uname -s)

if [ "$OS" != "Linux" ]; then

    echo "This script is only for Linux"
    exit 1

fi


# Give people a chance to retry running the installation
catch_errors() {
  echo -e "\n\e[31mOmarchy installation failed!\e[0m"
  echo "You can retry by running: bash ~/.local/share/omarchy/install.sh"
  echo "Get help from the community: https://discord.gg/tXFUdasqhY"
}

trap catch_errors ERR

show_logo() {
  clear
  tte -i ~/.local/share/omarchy/logo.txt --frame-rate ${2:-120} ${1:-expand}
  echo
}

show_subtext() {
  echo "$1" | tte --frame-rate ${3:-640} ${2:-wipe}
  echo
}

# Install prerequisites
source arch_install/preflight/aur.sh
source arch_install/preflight/presentation.sh

# Configuration
show_logo beams 240
show_subtext "Let's install Omarchy! [1/5]"
source arch_install/config/identification.sh
source arch_install/config/config.sh
source arch_install/config/detect-keyboard-layout.sh
source arch_install/config/fix-fkeys.sh
source arch_install/config/network.sh
source arch_install/config/power.sh
source arch_install/config/timezones.sh
source arch_install/config/login.sh
source arch_install/config/nvidia.sh

# Development
show_logo decrypt 920
show_subtext "Installing terminal tools [2/5]"
source arch_install/development/terminal.sh
source arch_install/development/development.sh
source arch_install/development/nvim.sh
source arch_install/development/docker.sh
source arch_install/development/firewall.sh

# Desktop
 show_logo slice 60
 show_subtext "Installing desktop tools [3/5]"
 source arch_install/desktop/desktop.sh
 source arch_install/desktop/hyprlandia.sh
 source arch_install/desktop/theme.sh
 source arch_install/desktop/bluetooth.sh
 source arch_install/desktop/asdcontrol.sh
 source arch_install/desktop/fonts.sh
 source arch_install/desktop/printer.sh
#
# # Apps
# show_logo expand
# show_subtext "Installing default applications [4/5]"
# source arch_install/apps/webapps.sh
# source arch_install/apps/xtras.sh
# source arch_install/apps/mimetypes.sh

# Updates
show_logo highlight
show_subtext "Updating system packages [5/5]"
sudo updatedb
yay -Syu --noconfirm --ignore uwsm

# Reboot
