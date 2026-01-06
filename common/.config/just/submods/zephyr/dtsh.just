set unstable := true

# This variable pointing to the dtsh cmd can be overrided to use west if desired

dtsh := which('dtsh')

@_:
    just --list

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
#
#   * - a - unit address
#   * - A - node aliases
#   * - b - bus of appearance
#   * - B -supported bus protocols
#   * - c - compatible strings
#   * - C
# binding's compatible or headline
#   * - d
# binding's description
#   * - D
# node dependencies
#   * - i
# generated interrupts
#   * - K
# all labels and aliases
#   * - l
# device label
#   * - L
# DTS labels
#   * - N
# node name
#   * - n
# unit name
#   * - o
# dependency ordinal (aka ``dts_ord``)
#   * - p
# path name
#   * - r
# registers (base address and size)
#   * - R
# registers (address range)
#   * - s
# status string
#   * - T
# dependent nodes
#   * - v
# vendor name
#   * - X
# child-binding depth
#   * - Y
# bus information

[no-cd]
_cmd build_dir +cmds:
    {{ if path_exists(dtsh) != 'true' { error(dtsh) } else { '' } }}
    {{ dtsh }} -c '{{ cmds }}' {{ join(build_dir, "zephyr", "zephyr.dts") }}

[group('tools')]
[no-cd]
sh build_dir *args:
    {{ if path_exists(dtsh) != 'true' { error(dtsh) } else { '' } }}
    {{ dtsh }} {{ args }} {{ join(build_dir, "zephyr", "zephyr.dts") }}

# Print tree with NYKC (Node name, bus info, labels/aliases, bindings compat str)
[group('tools')]
tree build_dir: (_cmd build_dir "tree --format NYKC --pager")

# Print tree with NYKC (Node name, bus info, labels/aliases, bindings compat str)
[group('tools')]
cat build_dir node fmt='--format Bd --pager': (_cmd build_dir f"cat &{{node}} {{fmt}}")

[group('tools')]
ls build_dir: (_cmd build_dir "ls -l NYKC")

[group('tools')]
find build_dir dts-ord_num: (_cmd build_dir f'find --with-dts-ord {{dts-ord_num}} --format psTd')

partitions_batch := '''
  tree &flash_controller --format NLrd
  find --also-known-as ram -i --format NLrd
'''

find_by_label label:
    {{ dtsh }} -c 'find --with-label {{ label }} -l --pager'

partitions:
    {{ dtsh }} -f <{{ partitions_batch }}

flash_info_batch := '''
  find --with-bus * --OR --on-bus * --format NYcd -T --pager
  cat &flash_controller -A --pager
  tree &flash_controller --format NrC --pager
'''

flash_detailed:
    {{ dtsh }} -f <{{ flash_info_batch }}
