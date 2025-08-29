
pluginRepos=("hiasr/vim-zellij-navigator@0.3.0" "laperlej/zellij-sessionizer" "karimould/zellij-forgot" "fresh2dev/zellij-autolock" )
IFS=":"  # Set Internal Field Separator for joining
export PLUGINS="${pluginRepos[*]}"
IFS=$' \t\n' # Reset IFS to default
