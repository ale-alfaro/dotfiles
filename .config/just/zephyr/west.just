
west-topdir := `west topdir`
zephyr_base:= ```
    topdir=$(west topdir)
    zephyr_base=$(realpath $topdir/$(west config zephyr.base))
    echo $zephyr_base
    ```
full_board_name_cmd := 'west boards --board-root ' + zmk_module_dir +  ' -f "{name}/{qualifiers}" ' + ' --name "$1"'

default:
    if { west-topdir == ''} { echo "Run this from the top of a west tree"; exit 1; }
    @just --list


zephyr_bindings_dir := join(zephyr_base, 'dts', 'bindings')

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

dtsh build-dir *args:
    dtsh {{args}} -b {{zephyr_bindings_dir}}  {{join( build_dir, "zephyr", "zephyr.dts" )}}

dtsh-cmd build_dir +cmds: (dtsh artifact_name replace("-c 'CMD' ", "CMD", cmds))

find_cmd := "find --with-dts-ord NUM --format psTd"

dtsh-find artifact_name dts-ord_num: (dtsh-cmd artifact_name replace(find_cmd, "NUM", dts-ord_num))

rom_mem_cmd :='find -E --also-known-as (image|storage).* --format NLrd'
ram_mem_cmd := 'find --also-known-as $1 -i --format NLrd'

# presentation.dtsh: DTSh sample script

# Start with the tree of buses and connected devices: speaker will
# press "q" when done
find --with-bus * --OR --on-bus * --format NYcd -T --pager

# Let's look at the Flash partitions.
#
# 1st, the controller: : speaker will press "q" when done
cat &flash_controller -A --pager
# Then partitions with addresses and sizes: speaker will press "q"
# when done
tree &flash_controller --format NrC --pager

# Lets talk about DTS labels: speaker will press "q" when done
find --with-label * -l --pager
