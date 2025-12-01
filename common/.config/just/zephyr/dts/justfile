# Add custom bindings directory to dtsh
# custom_bindings_dir := join(app_dir, 'dts', 'bindings')
# shell-like interface with Devicetree
#
# user files:
#   -u, --user-files    initialize per-user configuration files and exit
#   --preferences FILE  load additional preferences file
#   --theme FILE        load additional styles file
#
# session control:
#   -c CMD              execute CMD at startup (may be repeated)
#   -f FILE             execute batch commands from FILE at startup
#   -i, --interactive   enter interactive loop after batch command

tree_cmd := 'tree --format NYKC --pager'
zephyr_bindings_dir := join(env('ZEPHYR_BASE', ''), "dts", "bindings")
zephyr_extra_bindings_dir := env('ZEPHYR_EXTRA_BINDINGS_DIR', '')

[group('tools')]
[no-cd]
dtsh build_dir *args:
    dtsh {{ args }} {{ if zephyr_extra_bindings_dir != '' { '-b ' + zephyr_bindings_dir + ' -b ' + zephyr_extra_bindings_dir } else { '' } }} {{ join(build_dir, "zephyr", "zephyr.dts") }}

[group('tools')]
[no-cd]
dtsh-cmd build_dir +cmds=tree_cmd: (dtsh build_dir replace("-c 'CMD' ", "CMD", cmds))

[group('tools')]
[no-cd]
dtsh-tree build_dir: (dtsh-cmd build_dir tree_cmd)

find_cmd := 'find --with-dts-ord NUM --format psTd'

[group('tools')]
[no-cd]
dtsh-find build_dir dts-ord_num: (dtsh-cmd build_dir replace(find_cmd, "NUM", dts-ord_num))

mem_dtsh_file := join(source_directory(), "partitions.dtsh")

[group('tools')]
[no-cd]
dtsh-mem build_dir: (dtsh build_dir append(mem_dtsh_file, "-f "))
