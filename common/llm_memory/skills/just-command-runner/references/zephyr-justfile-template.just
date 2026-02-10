set shell := ['zsh', '-uc']
set unstable := true
# Required variables to be available for any action
west := require('west')
app := env('APP_DIR', source_dir())
board := shell('west config build.board') || 'anne_chest/nrf52840'

# Default recipe used for listing the recipes.
@_:
    just --list-heading '{{ BOLD + RED }}{{ "\n" + file_stem(app) + ":\n" }}{{ NORMAL }}' --list

####################################
# Configuration through west recipes
# ###################################

# To create deterministic builds the best method to keep unchanging or rarely changed variables in the .west/config at the top of the west workspace
# They can be set manually but preferred method is through the west CLI with west config.

# The following 3 variables are supported by west build. They set the default board, build_dir format and set the build pristine flag value
# For more info  and other build configs supported by Zephyr look at https://docs.zephyrproject.org/latest/develop/west/build-flash-debug.html#configuration-options
[group('config')]
configure:
    west config build.board {{ board }}
    west config build.dir-fmt build/{board}
    west config build.pristine always
    # west config build.my_custom_var val - You can set your own custom ones too

# This variables can then be fetched later but always be mindful of them not existing!
build_dir_fmt :=shell('west config build.dir_fmt') || 'build/{board}'

####################################
# Build recipes
# ###################################

# Variables for building that can be hardcoded or left blank.
# They can be set to other values when running the recipe by specifying KEY=VALUE pairs before the recipe name (example below)
clean := ''
target := ''
target_flag := target && f'-t {{target}}'
snippet := ''
snippet_flag := snippet && f'-S {{snippet}}'
board_flag := board && f'-b {{board}}'
base_build_dir := app  / 'build' / board
build_dir := if shell('west config build.sysbuild') == 'true' { build_dir / file_stem(source_dir()) } else { build_dir}
build_dir_flag := build_dir && f'-d {{build_dir}}'

[group('build')]
clean:
    {{ if clean && path_exists(build_dir) == 'true' { f'rm -r {{build_dir}}' } else { "echo 'Build dir doesnt exist'" } }}

[group('build')]
build *extra_args: clean
    {{ west }} build {{ f'{{board_flag}} {{build_dir_flag}}  {{snippet_flag}} {{target_flag}}' }} {{ extra_args }}

# Example of setting a recipe variables to specific values within another recipe. This can be done through the CLI as well
[group('build')]
build_clean *extra_args:
  just --justfile {{ source_file() }} clean=1 build {{ extra_args }}

####################################
# Running on target recipes
# ###################################

[group('run')]
flash *extra_args: build
    {{ west }} flash -d {{ build_dir }} {{ extra_args }}

####################################
# Tooling recipes
# ###################################


# dtsh is shell-like interface for Devicetree
dtsh := which('dtsh')

_dtsh *args:
    {{ if dtsh == '' { error('dtsh not found in path. Please install it with uv tool install dtsh')} else { '' } }}
    {{ if path_exists(build_dir / 'zephyr' / 'zephyr.dts') != 'true' { error(f'Build dir {{build_dir}} does not exist') } else { '' } }}
    {{ dtsh  }} '{{ args }}' {{ f'{{build_dir / "zephyr" / "zephyr.dts"}}' }}

# dtsh can be non-interactively with targetted commands to get information on the devicetree fast and quick
# Either a high-level overview using the tree command or ls:
# Print tree with NYKC (Node name, bus info, labels/aliases, bindings compat str)
[group('tools')]
dts_tree : (_dtsh build_dir "tree --format NYKC --pager")

[group('tools')]
dts_ls: (_dtsh build_dir "ls -l NYKC")


# Or can targetted on certain nodes of the devicetree with cat and find
[group('tools')]
dts_cat bnode fmt='--format Bd --pager': (_dtsh build_dir f"cat &{{node}} {{fmt}}")

[group('tools')]
dtsh_out_html node: (_dtsh " -c 'cat &{{node}} -A > {{node}}.html'")

[group('tools')]
dts_find dts-ord_num: (_dtsh build_dir f'find --with-dts-ord {{dts-ord_num}} --format psTd')



