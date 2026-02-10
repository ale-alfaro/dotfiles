---
name: zephyr-workspace-explorer
description: Use when an agent needs to explore or understand a Zephyr west workspace using local just recipes and west commands.
---

# Zephyr Workspace Explorer

## Background

This page introduces west's basic concepts and provides references to further
reading.

West's built-in commands allow you to work with :term:`projects <west project>`
(Git repositories) under a common :term:`workspace <west workspace>` directory.

West works in the following manner: the `west init` command creates the
:term:`west workspace`, and clones the :term:`manifest repo <west manifest
repository>`, while the `west update` command initially clones, and later updates, the
:term:`projects <west project>` listed in the manifest in the workspace.

### Example workspace

---

If you've followed the :ref:`getting_started`, your local
:term:`west workspace`, which in this case is the folder named
:file:`zephyrproject` as well as all its subfolders, looks like this:

```

   zephyrproject/                 # west topdir
   ├── .west/                     # marks the location of the topdir
   │   └── config                 # per-workspace local configuration file
   │
   │   # The manifest repository, never modified by west after creation:
   ├── zephyr/                    # .git/ repo
   │   ├── west.yml               # manifest file
   │   └── [... other files ...]
   │
   │   # Projects managed by west:
   ├── modules/
   │   └── lib/
   │       └── zcbor/             # .git/ project
   ├── tools/
   │   └── net-tools/             # .git/ project
   └── [ ... other projects ...]

```

### Workspace concepts

---

Here are the basic concepts you should understand about this structure.
Additional details are in :ref:`west-workspaces`.

- topdir
  Above, :file:`zephyrproject` is the name of the workspace's top level
  directory, or _topdir_. (The name :file:`zephyrproject` is just an example
  -- it could be anything, like `z`, `my-zephyr-workspace`, etc.)

  You'll typically create the topdir and a few other files and directories
  using :ref:`west init <west-init-basics>`.

- .west directory
  The topdir contains the :file:`.west` directory. When west needs to find
  the topdir, it searches for :file:`.west`, and uses its parent directory.
  The search starts from the current working directory (and starts again from
  the location in the :envvar:`ZEPHYR_BASE` environment variable as a
  fallback if that fails).

- configuration file
  The file :file:`.west/config` is the workspace's :ref:`local configuration
file <west-config>`.

- manifest repository
  Every west workspace contains exactly one _manifest repository_, which is a
  Git repository containing a _manifest file_. The location of the manifest
  repository is given by the :ref:`manifest.path configuration option
<west-config-index>` in the local configuration file.

  For upstream Zephyr, :file:`zephyr` is the manifest repository, but you can
  configure west to use any Git repository in the workspace as the manifest
  repository. The only requirement is that it contains a valid manifest file.
  See :ref:`west-topologies` for information on other options, and
  :ref:`west-manifests` for details on the manifest file format.

- manifest file
  The manifest file is a YAML file that defines _projects_, which are the
  additional Git repositories in the workspace managed by west. The manifest
  file is named :file:`west.yml` by default; this can be overridden using the
  `manifest.file` local configuration option.

  You use the :ref:`west update <west-update-basics>` command to update the
  workspace's projects based on the contents of the manifest file.

- projects
  Projects are Git repositories managed by west. Projects are defined in the
  manifest file and can be located anywhere inside the workspace. In the above
  example workspace, `zcbor` and `net-tools` are projects.

  By default, the Zephyr :ref:`build system <build_overview>` uses west to get
  the locations of all the projects in the workspace, so any code they contain
  can be used as :ref:`modules`. Note however that modules and projects
  :ref:`are conceptually different <modules-vs-projects>`.

## How to use West

### Built-in West Commands

West has a few commands for managing the projects in the workspace, which are summarized here. Run west <command> -h for detailed help.

- west compare: compare the state of the workspace against the manifest
- west diff: run git diff in local project repositories
- west forall: run an arbitrary command in local project repositories
- west grep: search for patterns in local project repositories
- west list: print a line of information about each project in the manifest, according to a format string
- west manifest: manage the manifest file. See Manifest Command.
- west status: run git status in local project repositories
- west config: get or set configuration options
- west topdir: print the top level directory of the west workspace
- west help: get help about a command, or print information about all commands in the workspace, including Extensions

## Zephyr Workspace Justfile

### Prerequisites

- `just` installed and available on PATH
- `west` installed and available on PATH
- `ZEPHYR_BASE` available as a environment variable
- Inside a west workspace. Check by running `west topdir` and checking if PWD is under it

### Overview

```sh
just --justfile skills/zephyr-workspace-explorer/Justfile
Available recipes:
    [boards]
    find_board name_pattern                        # Find boards with name pattern (can be regex)

    [grep]
    # Search the west workspace using ripgrep
    #  Required parameters:
    #  - keyword - word(s) or pattern to search for.
    #  - file_flags - type of file to search in. Glob pattern is applied to search
    #    Allowed flags:
    #    - blank: when left empty no filter is applied by file type
    #    - zbuild: **/dts/bindings/**/*, *.cmake, *.dts, *.dtsi, *.overlay, *.yaml, *.yml, CMakeLists.txt, Kconfig, Kconfig.*
    #    - zsrc: *.[ChH], *.[ChH].in, *.[chH], *.[chH].in, *.[ch]pp, *.[ch]pp.in, *.[ch]xx, *.[ch]xx.in, *.cats, *.cc, *.cc.in, *.hh, *.hh.in, *.inl, *.py, *.pyi
    #    - zdts: **/dts/bindings/**/*, *.dts, *.dtsi, *.overlay, *.yaml, *.yml
    #    - kconfig: Kconfig, Kconfig.*
    search keyword file_flags *extra_flags
    search_build keyword *flags                    # Shortcut: Search CMake files, Devicetree and Kconfig files
    search_src keyword *flags                      # Shortcut Search source files for keyword (C,C++,Python)
    search_summary keyword file_flags *extra_flags # Search and output number of matches per file instead of the lines with matches

    [projects]
    proj_list                                      # List projects
```

### How to use the justfile

- The just file is shebanged so you are able to call it as an executable `<SKILLS_ROOT>/skills/zephyr-workspace-explorer/Justfile`.
- Or through the just command by specificying the locatio with a flag: `just --justfile <SKILLS_ROOT>/skills/zephyr-workspace-explorer/Justfile`
- After calling the justfile without arguments once the following short alias will be installed for convenience:
  `alias justw='<SKILLS_ROOT>/skills/zephyr-workspace-explorer/Justfile'`
- Now you can the justfile directly from the workspace root:
  `justw <recipe> [args...]`
- Prefer the focused helpers before raw west commands.
- Keep searches narrow (project or file flags) to avoid long-running greps.
- When running from an app repo, ensure `ZEPHYR_BASE` and `WEST_TOPDIR` are set.

### Common workflows

- List projects:
  `justw proj_list`
- Find boards by name pattern (regex):
  `justw find_board nrf`
- Search build system files (CMake, Kconfig, Devicetree):
  `justw search_build DEVICE_TREE`
- Search source files (C/C++/Python):
  `justw search_src NRF_GPIO_PIN_MAP`
- Get per-file match counts:
  `justw search_summary NRF_GPIO_PIN_MAP zsrc`

### Notes on search flags

- `file_flags` selects a preset of file globs.
- Leave `file_flags` empty for a workspace-wide search.
- Extra flags are passed through to ripgrep (e.g., `-g '*.c'` or `--type-add`).
