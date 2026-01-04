set unstable := true

board := ''
snippet := ''
extra_conf := ''
overlay := ''
app_dir := env('CWAPP_DIR', 'app')
build_dir_fmt := ''
build_dir := ''
clean := '0'
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
cfg_set +settings:
    just {{ settings }} _cfg_set

[group('config')]
cfg_get:
    {{ west }} config -l

[group('build')]
build *args:
    {{ if app_dir && path_exists(app_dir) == "true" { f'west bd {{args}}' } else { error("App dir doesn't exist") } }}

[group('build')]
build_clean dir=join(app_dir, 'build') *args: && (build args)
    {{ if dir && path_exists(dir) == 'true' { f'rm -r {{dir}}' } else { error(f"Build dir {{dir}} doesn't exist") } }}

img := file_stem(app_dir)
img_build_dir := build_dir / img

[arg('img', pattern='app|mcuboot')]
[group('utils')]
[working-directory(x"${CWAPP_DIR}")]
config img="app": (cfg_set 'target=menuconfig')
    {{ west }} tgt '/{{ img }}'
