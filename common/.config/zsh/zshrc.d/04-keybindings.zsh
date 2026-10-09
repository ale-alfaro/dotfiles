#!/usr/bin/env zsh
# +---------+
# | Keybindings |
# +---------+
#
bindkey -v
export KEYTIMEOUT=5
#
#     key_backspace              kbs       kb  backspace key
#     key_catab                  ktbc      ka  clear-all-tabs key
#     key_clear                  kclr      kC  clear-screen or erase key
#     key_ctab                   kctab     kt  clear-tab key
#     key_dc                     kdch1     kD  delete-character key
#     key_dl                     kdl1      kL  delete-line key
#     key_eol                    kel       kE  clear-to-end-of-line key
#     key_eos                    ked       kS  clear-to-end-of-screen key
#     key_f0                     kf0       k0  F0 function key
#     key_f1                     kf1       k1  F1 function key
#     key_f10                    kf10      k;  F10 function key
#     key_f2                     kf2       k2  F2 function key
#     key_f3                     kf3       k3  F3 function key
#     key_f4                     kf4       k4  F4 function key
#     key_f5                     kf5       k5  F5 function key
#     key_f6                     kf6       k6  F6 function key
#     key_f7                     kf7       k7  F7 function key
#     key_f8                     kf8       k8  F8 function key
#     key_f9                     kf9       k9  F9 function key
#     key_home                   khome     kh  home key
#     key_ic                     kich1     kI  insert-character key
#     key_il                     kil1      kA  insert-line key
#     key_ll                     kll       kH  lower-left key (home down)
#     key_npage                  knp       kN  next-page key
#     key_ppage                  kpp       kP  previous-page key
#     key_sf                     kind      kF  scroll-forward key
#     key_sr                     kri       kR  scroll-backward key
#     key_right                  kcuf1     kr  right-arrow key
#     key_stab                   khts      kT  set-tab key
#     key_left                   kcub1     kl  left-arrow key
#     key_up                     kcuu1     ku  up-arrow key
#     key_down                   kcud1     kd  down-arrow key
 
# create a zkbd compatible hash;
# to add other keys to this hash, see: man 5 terminfo
typeset -g -A key

key[Home]="${terminfo[khome]}"
key[End]="${terminfo[kend]}"
key[Insert]="${terminfo[kich1]}"
key[Backspace]="${terminfo[kbs]}"
key[Delete]="${terminfo[kdch1]}"
key[Up]="${terminfo[kcuu1]}"
key[Down]="${terminfo[kcud1]}"
key[Left]="${terminfo[kcub1]}"
key[Right]="${terminfo[kcuf1]}"
key[PageUp]="${terminfo[kpp]}"
key[PageDown]="${terminfo[knp]}"
key[Shift-Tab]="${terminfo[kcbt]}"
key[Control-Left]="${terminfo[kLFT5]}"
key[Control-Right]="${terminfo[kRIT5]}"

# setup key accordingly
[[ -n "${key[Backspace]}" ]] && bindkey -- "${key[Backspace]}"  backward-delete-char
[[ -n "${key[Delete]}"    ]] && bindkey -- "${key[Delete]}"     delete-char
[[ -n "${key[Left]}"      ]] && bindkey -- "${key[Left]}"       backward-char
[[ -n "${key[Right]}"     ]] && bindkey -- "${key[Right]}"      forward-char
[[ -n "${key[PageUp]}"    ]] && bindkey -- "${key[PageUp]}"     beginning-of-buffer-or-history
[[ -n "${key[PageDown]}"  ]] && bindkey -- "${key[PageDown]}"   end-of-buffer-or-history
[[ -n "${key[Shift-Tab]}" ]] && bindkey -- "${key[Shift-Tab]}"  reverse-menu-complete

# Finally, make sure the terminal is in application mode, when zle is
# active. Only then are the values from $terminfo valid.
if (( ${+terminfo[smkx]} && ${+terminfo[rmkx]} )); then
    autoload -Uz add-zle-hook-widget
    function zle_application_mode_start { echoti smkx }
    function zle_application_mode_stop { echoti rmkx }
    add-zle-hook-widget -Uz zle-line-init zle_application_mode_start
    add-zle-hook-widget -Uz zle-line-finish zle_application_mode_stop
fi

autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search

[[ -n "${key[Up]}"   ]] && bindkey -- "${key[Up]}"   up-line-or-beginning-search
[[ -n "${key[Down]}" ]] && bindkey -- "${key[Down]}" down-line-or-beginning-search

