#!/usr/bin/env zsh
# Install the Lua Hyprland config next to the hyprlang one.
#
# Hyprland prefers hyprland.lua over hyprland.conf when it exists, so the entry
# point lands as hyprland.lua.off and nothing changes until you --enable.
# hyprland.conf and hyprland/ are never touched.

set -euo pipefail

source_dir="${0:A:h}/hypr-lua"
target_dir="$HOME/.config/hypr"
entry="$target_dir/hyprland.lua"

usage() {
    print "usage: ${0:t} [install|enable|disable|status|probe]"
    print
    print "  install   copy lua/ and hyprland.lua.off into $target_dir (default)"
    print "  enable    hyprland.lua.off -> hyprland.lua, then reload"
    print "  disable   hyprland.lua -> hyprland.lua.off, then reload"
    print "  status    show which config Hyprland will read"
    print "  probe     enable the API dump and reload; writes ~/.cache/hypr-lua-api.txt"
}

reload() {
    hyprctl reload >/dev/null && print "reloaded"
}

case "${1:-install}" in
install)
    [[ -d $source_dir ]] || { print -u2 "ERROR: $source_dir missing"; exit 1 }

    mkdir -p "$target_dir/lua"
    # --no-clobber so re-running never overwrites edits you made in place.
    cp --no-clobber --verbose "$source_dir"/lua/*.lua "$target_dir/lua/"
    cp --no-clobber --verbose "$source_dir/hyprland.lua" "$entry.off"
    cp --no-clobber --verbose "$source_dir/.luarc.json" "$target_dir/.luarc.json"

    print
    print "installed, still inactive. 'hyprland.conf' is what Hyprland reads."
    print "run '${0:t} enable' to switch, '${0:t} disable' to switch back."
    ;;
enable)
    [[ -f $entry.off ]] || { print -u2 "ERROR: $entry.off not found; run install first"; exit 1 }
    mv --verbose "$entry.off" "$entry"
    reload
    ;;
disable)
    [[ -f $entry ]] || { print -u2 "ERROR: $entry not found; nothing to disable"; exit 1 }
    mv --verbose "$entry" "$entry.off"
    reload
    ;;
status)
    if [[ -f $entry ]]; then
        print "lua      $entry"
    else
        print "hyprlang $target_dir/hyprland.conf   (lua staged at $entry.off)"
    fi
    ;;
probe)
    [[ -f $entry ]] || { print -u2 "ERROR: enable the lua config first"; exit 1 }
    hyprctl keyword env HYPR_LUA_PROBE,1 >/dev/null
    reload
    print "wrote $HOME/.cache/hypr-lua-api.txt"
    ;;
*)
    usage
    exit 1
    ;;
esac
