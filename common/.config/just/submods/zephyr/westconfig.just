set unstable := true

board := ''
snippet := ''
extra_conf := ''
overlay := ''
app_dir := ''
build_dir_fmt := ''
build_dir := ''
pristine := ''
target := ''
west := require('west')

@_:
    just --list

_cfg_set *args:
    {{ west }} config build.board {{ if board != '' { board } else { `west config build.boards` || 'anne_chest' } }}
    {{ west }} config alias.bd 'build {{ app_dir && f"-s {{app_dir}}" }} {{ app_dir && f"-d {{app_dir}}/{{build_dir || 'build'}}" }}'
    {{ west }} config alias.tgt 'build {{ target && f"--pristine=never -t {{target}} " + build_dir && f"-d {{build_dir}}" }}'
    CMAKE_ARGS='{{ snippet && f"-DSNIPPET={{snippet}}" }} {{ overlay && f"-DDTC_OVERLAY_FILE={{overlay}}" }} {{ extra_conf && f"-DEXTRA_CONF_FILE={{extra_conf}}" }}'; if [[ "$CMAKE_ARGS" =~ '\w+'  ]]; then {{ west }} config build.cmake-args "$CMAKE_ARGS"; fi

    {{ pristine && f'{{west}} config build.pristine {{pristine}}' }}
    {{ build_dir_fmt && f'{{west}} config build.dir-fmt {{build_dir_fmt}}' }}

[group('config')]
set +settings:
    just {{ settings }} _cfg_set

[group('config')]
get:
    {{ west }} config -l
