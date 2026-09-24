---
name: bsim-testing
description: Write, build, run and debug BabbleSim (bsim) multi-device tests in a Zephyr west workspace — two simulated radios talking over a simulated PHY, babblekit TEST_/FLAG macros, bst_test testid dispatch, choosing one shared image or one application per role, the twister-staged exe naming that upstream compile.sh does not use, and the traps that make a bsim test hang or silently pass. Use when adding or fixing a test under tests/bsim, driving a real BLE connection between two devices, or when a bsim run exits non-zero with "in progress (not passed)" or "cannot be found (did you forget to compile it?)".
metadata:
  type: reference
---

For single-image host suites use the `unit-testing` skill (ZTEST/FFF on
`native_sim`); for driving one image's shell use `native-sim-shell`. Reach here
only when the thing under test **needs a second device and a real radio** — a
GATT flow, a connection lifecycle, controller-level timing.

Canonical references in the Zephyr tree, worth opening once:
`doc/develop/test/bsim.rst`, `tests/bsim/sh_common.source`,
`tests/bsim/compile.source`, and the template at
`tests/bsim/bluetooth/host/misc/sample_test/`.

---

## Environment and tooling

Read [[setup.md|Setup]] for how to build the bsim executables and
set the environment for executing

---

## Building and creating a testsuite

The two build paths:

**A. Upstream `compile.sh`** (`tests/bsim/**` in the Zephyr tree). Calls
cmake/ninja directly through `compile.source`, deliberately avoiding west since
not every Zephyr user has it. Takes `sysbuild=1` for multi-image builds.

```bash
app=tests/bsim/bluetooth/host/foo compile       # inside a compile.sh
```

Produces `bs_${BOARD}_${app}_${conf_file}`, with `/`, `.` and `;` mangled to `_`.

**B. twister staging** (`harness: bsim`). twister builds; its `Bsim` harness
copies the exe into place. The suite must be `build_only: true` — twister cannot
run the simulation — and declare the name:

```yaml
tests:
  my.suite.bsim:
    build_only: true
    harness: bsim
    harness_config:
      bsim_exe_name: tests_bsim_services_prj_conf
    platform_allow: [nrf52_bsim/native]
```

Produces `$BSIM_OUT_PATH/bin/bs_<platform>_<bsim_exe_name>`, with `/`, `.` and
`@` replaced by `_`. `sh_common.source` exports `BOARD_TS` as `$BOARD` with
`/`→`_`, so a script refers to `bs_${BOARD_TS}_<bsim_exe_name>`.

> [!CAUTION] the harness **warns and skips** the copy when `BSIM_OUT_PATH` is unset rather than failing the build.
> the suite is invisible to a plain `twister -T tests` run on a non-bsim platform — so it is
> easy for it to never run anywhere. Check what CI actually invokes.

#### One image or one per role

Devices in a simulation are **separate processes**, so they need not be the same
executable. Two shapes, and the choice matters more than it looks:

**Shared image**, roles picked by `-testid=`. The template
(`host/misc/sample_test/`) does this, and it is right when the roles are close
and their Kconfig does not conflict.

```
tests/bsim/<group>/
├── CMakeLists.txt          # + add_subdirectory($ENV{ZEPHYR_BASE}/tests/bsim/babblekit babblekit)
├── prj.conf
├── testcase.yaml           # build_only + harness: bsim + bsim_exe_name
├── src/main.c              # test_installers[] — the roles
├── src/<role>_test.c       # one file per role
└── test_scripts/<name>.sh  # one test per script
```

**One application per role**, each with its own `testcase.yaml`, `prj.conf` and
`bsim_exe_name`; the script starts a different exe per device. Upstream does this
in `host/misc/hfc_multilink/{dut,tester}/`.

```
tests/bsim/<group>/
├── dut/                    # the thing under test
│   ├── prj.conf            # only what the DUT needs
│   └── testcase.yaml       # bsim_exe_name: ..._dut_prj_conf
├── tester/                 # the peer that drives it
│   ├── prj.conf            # scan/connect/GATT client, nothing else
│   └── testcase.yaml       # bsim_exe_name: ..._tester_prj_conf
└── test_scripts/<name>.sh
```

> [!IMPORTANT] Split the moment the roles disagree about configuration.
> A shared image gives **every** device every `SYS_INIT`, `BT_GATT_SERVICE_DEFINE`
> and `ZBUS_CHAN_ADD_OBS` in it. If an SDK layer owns `bt_enable()` and keeps a
> connectable advertiser up — normal for a product GAP layer — the tester
> inherits it and the failures do not look like configuration:
>
> - `bt_le_adv_start()` → `-ENOMEM`, the SDK already holds the only adv set;
> - `bt_conn_le_create()` → `-ENOMEM`, its connectable advertiser holds the only
>   conn slot at `BT_MAX_CONN=1`;
> - `bt_conn_le_create()` → `-EACCES`, HCI `0x2005` (LE Set Random Address)
>   `status 0x0c`: disallowed while an advertiser runs, and the non-privacy
>   originate path must set the random identity (`host/id.c`).
>
> Tolerating extra errnos or stopping the SDK's advertiser from inside the test
> fights a state machine built to keep it running. Give the tester its own image
> instead; its `prj.conf` then describes only the peer, and the DUT's only the DUT.

#### CMake

`CMakeLists.txt` needs babblekit and the bsim headers:

```cmake
add_subdirectory(${ZEPHYR_BASE}/tests/bsim/babblekit babblekit)
target_link_libraries(app PRIVATE babblekit)
zephyr_include_directories(
  ${BSIM_COMPONENTS_PATH}/libUtilv1/src/
  ${BSIM_COMPONENTS_PATH}/libPhyComv1/src/)
```

`tests/bluetooth/common/testlib` is worth linking too — `bt_testlib_scan_find_name`,
`bt_testlib_connect` and friends keep connection boilerplate out of the test.

### Board targets

All bsim boards are `ARCH_POSIX`. That has a Kconfig consequence: a `choice`
whose default arm is unavailable on POSIX silently falls through to whatever arm _is_ reachable.

#### Non-sysbuild

| Target                       | What you get                                             |
| ---------------------------- | -------------------------------------------------------- |
| `nrf52_bsim/native`          | fast default; host + controller in one POSIX image       |
| `nrf5340bsim/nrf5340/cpunet` | host + controller flat in one image. No sysbuild needed. |

#### Sysbuild

| Target                       | What you get                                         |
| ---------------------------- | ---------------------------------------------------- |
| `nrf5340bsim/nrf5340/cpuapp` | app core, and **an empty netcore** — no radio at all |

> [!NOTE] On nRF5340, `cpunet` and `cpuapp` are not interchangeable:
> A cpuapp build alone has no controller, so `bt_enable()` has nothing to talk to.
> Pair it with an `hci_ipc` netcore image via sysbuild. The upstream pattern is
> three files beside the test — copy them from `tests/bsim/bluetooth/host/misc/hfc/`:

```cmake
# sysbuild.cmake
ExternalZephyrProject_Add(APPLICATION hci_ipc
  SOURCE_DIR ${ZEPHYR_BASE}/samples/bluetooth/hci_ipc
  BOARD ${SB_CONFIG_NET_CORE_BOARD})
set(hci_ipc_CONF_FILE ${APP_DIR}/nrf5340_cpunet.conf CACHE INTERNAL "")
native_simulator_set_primary_mcu_index(${DEFAULT_IMAGE} hci_ipc)
native_simulator_set_child_images(${DEFAULT_IMAGE} hci_ipc)
native_simulator_set_final_executable(${DEFAULT_IMAGE})
```

`native_simulator_set_final_executable` copies the assembled exe to
`<build>/zephyr/zephyr.exe` — exactly where twister's bsim harness looks — so
`sysbuild: true` and `harness: bsim` do compose. `Kconfig.sysbuild` must set
`NATIVE_SIMULATOR_PRIMARY_MCU_INDEX` to the app core, or `-testid=` is delivered
to the netcore and no role runs.

> [!WARNING] **Before enabling sysbuild, check whether the repo ships its own sysbuild
> module** (`zephyr/module.yml` → `sysbuild-cmake`). A product SDK often hooks
> `<module>_pre_cmake` and merges an application baseline — DFU, MCUmgr, settings,
> a watchdog — into the default image of _every_ sysbuild build.

---
### Running

Rules worth restating because they are easy to miss:

- `-D=` **must** match the number of `Execute`d devices, or the PHY waits forever.
- Include `${BOARD_TS}` in `simulation_id` so the same test can run on both
  boards concurrently.
- Give each device a distinct `-rs=` seed. Omitting it means one fixed timing
  path forever; varying it is how timing-sensitive bugs surface.
- Forward `"$@"` to the PHY so `run_parallel.sh` options reach it.
- Scripts **never build**. They assume the exe is staged.
- Leave `EXECUTE_TIMEOUT` at the default unless the measured runtime exceeds 5 s;
  then set it to ~5× that. Never below the default.
- Keep output under ~100 lines. Use `LOG_DBG` freely, but do not ship `DBG` on.
- Scripts starting with `_` are not auto-discovered — use that for local
  debug helpers.

### Test scripts

Follow the existing scripts exactly. `bsim.rst` is explicit: **no bespoke
runners**, no python wrapper, no new shell abstraction — tree-wide updates
depend on every script looking the same.

```bash
#!/usr/bin/env bash
set -eu
source "${ZEPHYR_BASE}/tests/bsim/sh_common.source"

simulation_id="svc_dlog_${BOARD_TS}"   # unique, or parallel runs collide
verbosity_level=2

cd "${BSIM_OUT_PATH}/bin"
Execute "./bs_${BOARD_TS}_tests_bsim_services_prj_conf" \
  -v="${verbosity_level}" -s="${simulation_id}" -d=0 -rs=420 -testid=central
Execute "./bs_${BOARD_TS}_tests_bsim_services_prj_conf" \
  -v="${verbosity_level}" -s="${simulation_id}" -d=1 -rs=69 -testid=peripheral
Execute ./bs_2G4_phy_v1 -v="${verbosity_level}" -s="${simulation_id}" -D=2 \
  -sim_length=20e6 "$@"
wait_for_background_jobs
```

> [!NOTE] For more on how to [[running.md|debug and run]] read on the supplemental material
---

## Traps

- **"cannot be found (did you forget to compile it?)"** — the script's exe name
  and the staged name disagree, or twister ran without `BSIM_OUT_PATH` and
  silently skipped the copy. `ls $BSIM_OUT_PATH/bin` first.
- **PHY hangs** — `-D=` mismatch, or a device died before registering.
- **A role fights the image it shares.** `-ENOMEM` from `bt_le_adv_start()` or
  `bt_conn_le_create()`, or `-EACCES` with HCI `0x2005 status 0x0c`, means an SDK
  layer in the shared image is already advertising. Split the roles into two
  applications rather than tolerating the errno.
- **Passes having tested nothing** — no `TEST_START`, or a `WAIT_FOR_FLAG` whose
  flag was set by an unrelated earlier event. Prove a new test can fail: break
  the expected value once and watch it go red.
- **A latched state flag** ("I already sent a bad ack") read by a per-iteration
  assertion makes a one-iteration test pass and a two-iteration test fail
  spuriously. Clear it when the condition it names ends.
- **The suite runs nowhere.** `build_only: true` means a normal twister run
  builds it and stops; the scripts run only if something invokes them. Confirm
  CI does, and prefer a ZTEST whenever the coverage can live there instead.
