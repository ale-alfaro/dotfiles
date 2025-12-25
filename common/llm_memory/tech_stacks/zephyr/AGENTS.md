# Zephyr RTOS

The Zephyr Project is a scalable real-time operating system (RTOS) supporting
multiple hardware architectures, optimized for resource constrained devices,
and built with security in mind.

The Zephyr OS is based on a small-footprint kernel designed for use on
resource-constrained systems: from simple embedded environmental sensors and
LED wearables to sophisticated smart watches and IoT wireless gateways.

## Overview - Project Structure & Module Organization

- Core kernel and scheduler: `kernel/` and `arch/`
- Device drivers: `drivers/` (per-subsystem subfolders), SoC/board data in `soc/` and `boards/`
- Public headers and APIs: `include/`
- Samples and reference apps: `samples/`
- Automated tests: `tests/` (Twister suites) and scenario-specific assets in `snippets/`
- Build and tooling scripts: `scripts/`, CMake glue in `cmake/`, docs in `doc/`

# Embedded C

## Embedded C - Software Coding Style & Naming Conventions

- C code follows Zephyr’s Linux-aligned style: tabs for indent (8), braces on new lines for functions, `snake_case` for functions/vars, `UPPER_SNAKE_CASE` for macros and Kconfig symbols.
- Keep public APIs in `include/` with `zephyr/`-prefixed headers; internal headers stay near implementation.
- Use `const` pointers over macros where possible; prefer `ARRAY_SIZE()` and `BIT()` helpers.
  - Place the `*` or `&` next to the type (e.g., `int* number`).
- **Preprocessor Macros:**
  - Use macros only when they significantly improve the code.
  - Standalone statement macros must require a semicolon.
  - function should be used in preference to a function-like macro where they are interchangeable
- **Unsigned Integers:** Permitted, but be careful when mixing with signed
  integers.
- **C and C++ Standard Libraries:**
  - A limited subset of the C++ Standard Library is permitted. Dynamic memory
    allocation, streams, and exceptions are disallowed.
  - Use Zephyr's own libraries (`<zephyr/sys/util.h>` for low-level utilities like bit shifts, `<zephyr/kernel.h>` for synchronization primitives, etc)
- **Comments:**
  - Sections of code should not be “commented out”
  - Code in comments should be indented with two additional spaces.
- **Control Statements:**
  - Always use braces for loops and conditionals.
  - Prefer early exits with `return` and `continue`.
  - Do not use `else` after a `return` or `continue`.
- **Header Files and Include Guards:**
  - Use C header guards unless the header is clearly using C++ (i.e has `hpp` `hh` suffix), int that case use `#pragma once`.
  - Precautions shall be taken in order to prevent the contents of a header file being included more than once
- **Logging:**
  - Use the `<zephyr/logging/log.h>` module for logging. A file should always register a new logging module using `LOG_MODULE_REGISTER(<NAME>, <LOG_LEVEL>);`
  - Log errors as soon as they are unambiguously determined to be errors.
  - Log at the appropriate level (`LOG_DBG`, `LOG_INF`, `LOG_WRN`,
    `LOG_ERR`).
- **Memory Allocation:** No dynamic memory allocation in driver or any low level code.
- **C++ Standard:** All C++ code must compile with `-std=c++17`. C++20 features
  can be used if the code remains C++17 compatible.
- **Formatting:** Code is automatically formatted with `clang-format`.

## Embedded C - Testing Guidelines

- Prefer `native_posix` for fast unit/regression runs before hardware.
- Add new tests under `tests/<area>/<feature>/`; name cases with `test_<feature>_<behavior>()`.
- Ensure Twister metadata (`testcase.yaml`) defines `platform_allow`/`filter` and sensible `timeout`.
- Aim to keep PRs Twister-clean on at least `native_posix` and the target board family.

# Build System and Tooling

## West: Zephyr Meta Tool

- Used for most if not all tasks and workflows done in Zephyr. Most importantly it does:
  - Configure & build: `west build --board <board>  -s <app_dir>` (out in `build/`)
  - Run test suites: `west twister --platform native_posix --test-root tests/kernel` (select port and tree)

## Build System Topology (High-Level)

```
west -> CMake (cmake/ + zephyr_cmake_package) -> Kconfig -> Devicetree (dts/)
     \                                                                |
      \-> Python helpers (scripts/pylib, twister, dts/) --------------+
              |
              +-> Twister orchestrates: testcases (tests/*) + platforms (boards/soc) -> runners/flash
              |
              +-> Sysbuild (doc/build/sysbuild/) aggregates multi-image builds
```

Use `west build` to drive the CMake/Kconfig/DTS pipeline; Python layers in `scripts/` provide glue for board metadata, test discovery (Twister), and flashing/debug workflows.

The main build products will be in `build/zephyr`; `build/zephyr/zephyr.elf` is the application binary in ELF
format. Other binary formats, disassembly, and map files may be present depending on your board.

### Build System - Details

1. `west build`: resolves workspace, fetches modules, and seeds CMake with board/toolchain; wrappers live in `west_commands/`.
2. CMake phase (`cmake/`, `zephyr_cmake_package.rst`): configures app + Zephyr as a package, generates `zephyr/.config` and build graph.
3. Kconfig (`doc/build/kconfig/`): text-based options that toggle kernel/drivers/features; choices stored in `.config`, turned into generated headers (`autoconf.h`) and CMake cache entries.
4. Devicetree (`doc/build/dts/`): hardware description (nodes, compatibles, properties) merged from board DTS + overlays; Python helpers in `scripts/dts/` validate bindings YAML and emit `devicetree_generated.h` for compile-time access.
5. Codegen and compilation: generated headers + board data feed `ninja` targets under `build/`.
6. Sysbuild (`doc/build/sysbuild/`): optional multi-image aggregator (e.g., MCUboot + app); orchestrated from `sysbuild/` and driven by west target selection.
7. Testing: Twister (`scripts/twister/`) enumerates `tests/*/testcase.yaml`, matches platforms from `boards/`, and dispatches runners/flash backends.
8. Signing/flashing (`doc/build/signing/`, `doc/build/flashing/`): post-build steps integrated via west targets; Python helpers wrap board-specific tools.

### Build System - Key Technologies & Stack

- Build orchestration: `west` (Python) with extensions in `scripts/west_commands/`.
- Meta-build: CMake toolchain files under `cmake/`; Ninja as the default generator.
- Configuration: Kconfig option tree → `.config` + `autoconf.h`; edited via `menuconfig`/`guiconfig` or direct `prj.conf`.
- Hardware description: Devicetree sources (`*.dts`, overlays) + bindings YAML defining schema and enum defaults; compiled with `dtc`, processed by Python in `scripts/dts/`.
- Multi-image: Sysbuild for combined images (bootloader + app).
- Testing: Twister (Python) with runners for QEMU/native_posix/hardware; test specs in `tests/*/testcase.yaml`.
- Toolchains: Zephyr SDK, cross GCC/Clang as configured by board/toolchain files.
- Packaging: `zephyr_cmake_package` for external CMake consumers.
- Signing/flash: west targets wrap imgtool, bossac, openocd, nrfjprog, pyocd, dfu-util depending on board support.

## Tooling in Python - Overview

- Python tooling base is `scripts/`; key subdirs: `pylib/` (shared helpers), `twister/` (test runner), `dts/` (Devicetree utilities), `ci/` (automation), `west_commands/` (west plugins), `github_helpers.py` (maintainer tools).
- Build assets live outside: sources in `kernel/`, `arch/`, `drivers/`; board/SoC data in `boards/` and `soc/`; Kconfig in `Kconfig` tree; DTS bindings under `dts/` top-level.
- Requirements files (`requirements*.txt`) define pinned envs for CI, build, and testing; prefer the narrowest file that matches your task.
- Docs for the build flow start at `doc/build/index.rst` with deep dives under `doc/build/cmake/`, `doc/build/dts/`, `doc/build/kconfig/`, and `doc/build/sysbuild/`.

# Tips

- DTS overlays belong in `boards/<board>/` or local `app.overlay`; reuse established `compatible` strings to stay tooling-friendly.
- When extending Python tooling, prefer existing hooks in `pylib/` and `west_commands/` to keep build/test UX consistent.

## Run a Sample Application natively (Linux)

You can compile some samples to run as host programs
on Linux. See :zephyr:board:`native_sim` for more information. On 64-bit host operating systems, you
need to install a 32-bit C library, or build targeting :ref:`native_sim/native/64<native_sim32_64>`.

```sh
west build -t run
# or just run zephyr.exe directly:
./build/zephyr/zephyr.exe
```

You can run `./build/zephyr/zephyr.exe --help` to get a list of available
options.

This executable can be instrumented using standard tools, such as gdb or
valgrind.
