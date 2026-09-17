---
name: zephyr-west-runner
description: Zephyr RTOS meta-tool West command runner. Use when working inside a west workspace
---

## Common Commands

### Build

```bash
# Make sure this variables are set
printenv
ZEPHYR_BASE=$PWD/zephyr
ZEPHYR_SDK_INSTALL_DIR=...
ZEPHYR_TOOLCHAIN_VARIANT=zephyr

# Build hello_world for a native sim board (best choice as first target board)
west build -p -b native_sim samples/hello_world

# Incremental build by specifying the build directory
west build -p=auto -d build
# Run on sample on native_sim
west build -p=never -b native_sim -t run <args>
#  Or...
./build/zephyr/zephyr.exe <args>
```

### VCS, search, list, etc

Look at [West Builtins](./west_builtins.md) for more

```bash
# Initialize workspace from manifest

# Show workspace state
west list
west status -s # Run git status on all active projects with git status -s flag
west diff manifest # Diff the manifest containing project
west grep --project=manifest --project=segno -tc man # Search in projects using ripgrep
# Run a command across all projects
west forall manifest -c "git log --oneline -5" # Run git log in manifest project root anywhere within the workspace
```

### Extracting information from a build

```bash
west build -p=never -d build/app -t dashboard  # HTML auto-generated dashboard menu
west build -p=never -d build/app -t traceconfig  # Generate a table of all config options
```

### Debugging

West debugserver launches the appriopiate gdbserver automatically

```bash
west debugserver --no-rebuild -d build/app  &
```

Then attach Zephyr SDK's gdb client with python support enabled. Batch cmds supported

```bash
arm-zephyr-eabi-gdb-py --se=build/app/zephyr/zephyr.elf -ex 'target remote :2331' -ex 'monitor halt' -ex 'info threads' -ex 'threads apply all bt'
```
