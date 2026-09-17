West's built-in commands allow you to work with _projects_ (Git repositories) under a common _workspace_ directory.

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

### Common workflows

- Get the topdir of the workspace and confirm you are in one that is valid

```sh
west topdir
```

- List the configuration keys active locally and globally

```sh
west config -l
```

- Get the path of the active manifest in the workspace

```sh
west manifest --path
```

```sh
west config -l
```

- List name and absolute paths of all active projects:

```sh
❯ west list -f '{name:20} {posixpath}'
```

- List name and hash of projects with filtering for project names:

```sh
❯ west list -f '{name}: {revision}' | rg  "^(sh_sdk|segno)"
```

- Look at the short summary of the git status of all active projects

```sh
west status -s
```

- Look at the diff for a project

```sh
west diff manifest
```

- Search build system files (CMake, Kconfig, Devicetree) in all active projects:

```sh
❯ west grep -tdts -tcmake -tkconfig -e -detect 2>/dev/null
```

- Search C source files only inside the manifest and segno project:

```sh
❯ west grep --project=manifest --project=segno -tc man
```

---

### Example workspace

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

- topdir
  Above, `zephyrproject` is the name of the workspace's top level
  directory, or _topdir_. (The name :file:`zephyrproject` is just an example
  -- it could be anything, like `z`, `my-zephyr-workspace`, etc.)

- .west directory
  The topdir contains the `.west` directory. When west needs to find
  the topdir, it searches for `.west`, and uses its parent directory.

- configuration file
  The file `.west/config` is the workspace's _local_ configuration files.

- manifest repository
  Every west workspace contains exactly one _manifest repository_, which is a
  Git repository containing a _manifest file_. The location of the manifest
  repository is given by the `manifest.path` configuration option in the local configuration file.

- manifest file
  The manifest file is a YAML file that defines _projects_, which are the
  additional Git repositories in the workspace managed by west. The manifest
  file is named **west.yml** by default; this can be overridden using the
  `manifest.file` local configuration option.

  You use the `west update` command to update the
  workspace's projects based on the contents of the manifest file.

- projects
  Projects are Git repositories managed by west. Projects are defined in the
  manifest file and can be located anywhere inside the workspace. In the above
  example workspace, `zcbor` and `net-tools` are projects.

  By default, the Zephyr build system uses west to get
  the locations of all the projects in the workspace, so any code they contain
  can be used as _modules_.

> [!Note] However modules and projects are conceptually different and have different contracts in the build system
