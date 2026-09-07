
---

## Architecture & module design

Build applications as small modules with explicit responsibilities: orchestration,
hardware access, BLE/transport, state management, UI/shell, fault handling. **Do
not put everything in `main.c`.**

**Prefer**
- Event-driven modules communicating through **zbus** channels — no direct
  cross-module function calls for state changes.
- Explicit **state machines (SMF)** for non-trivial connection/provisioning flow.
- Clear ownership of threads, work items, and shared state.
- Each module can define its own thread via `K_THREAD_DEFINE`, eliminating a
  monolithic `main()`.

### zbus as the module backbone

zbus is the preferred inter-module mechanism in modern NCS: pub/sub over typed
channels, decoupled producers and consumers. Observer choice in brief (full
decision + execution-context reasoning is in the [[zephyr-zbus]] skill):

- **Listener** — synchronous callback in the *publisher's* context, channel
  already locked. Lightweight reactions only (LED toggle, flag set). Do **not**
  call `zbus_chan_read()` inside a listener; use `zbus_chan_const_msg()`.
- **Subscriber** — thread-based, receives a channel *reference* via msgq; must
  `zbus_chan_read()` after notification. Use when the observer may conditionally read.
- **Message subscriber** — thread-based, receives a *copy* via FIFO. Use when the
  observer always needs the data and wants its own context.

**Rules**
- Define channel messages as plain C structs.
- Keep channel definitions and message types in a shared `common/` directory.
- Prefer message subscribers when the observer always needs the data; subscribers
  when it may conditionally read.
- Do not publish from ISR context unless the design explicitly accounts for VDED
  execution at ISR priority. (BLE callbacks run in the RX thread, not an ISR — see
  BLE section — but the same "don't do heavy work synchronously" caution applies.)

### Module interface rules
- Keep interfaces typed and explicit; small headers exposing public API only.
- Hide private state in `.c` files. Use enums/structs, not loosely related globals.
- One place for fatal-error policy. Separate board adaptation from app behavior — a
  well-structured module should build for both `nrf52840dk/nrf52840` and
  `nrf5340dk/nrf5340/cpuapp` with only overlay/Kconfig differences.

### Project structure

Recommended out-of-tree starting point: the `ncs-example-application` template
(West T2 topology, custom boards/bindings, out-of-tree drivers, CI).

Typical layout:

```
application/
├── CMakeLists.txt
├── prj.conf
├── Kconfig
├── west.yml
├── sample.yaml
├── boards/
│   ├── nrf52840dk_nrf52840.overlay
│   └── nrf5340dk_nrf5340_cpuapp.overlay
├── dts/
│   └── bindings/
├── src/
│   ├── main.c
│   └── modules/
├── sysbuild.conf          (or Kconfig.sysbuild)
└── sysbuild/              (MCUboot / nRF5340 net-core image config)
```

**CMake rules**
- Add sources with `target_sources(app PRIVATE ...)`; use `zephyr_library_sources(...)`
  for a reusable library.
- Do not hard-code toolchain paths or board names in `CMakeLists.txt`.
- Guard conditionally-needed sources with `CONFIG_*` in CMake.

**Sysbuild** — on the nRF5340 (and for MCUboot on either part), the build is
multi-image. Sysbuild manages child images — the MCUboot bootloader and, on the
nRF5340, the **network-core BLE image** — via `sysbuild.conf` / `Kconfig.sysbuild`
and `sysbuild/` overlays. See the dual-core section below.

---

## Build and Test


### CMake rules

- Use `target_sources(app PRIVATE ...)` to add source files.
- Use `zephyr_library_sources(...)` when building a reusable library.
- Do not hardcode toolchain paths or board names in CMakeLists.txt.
- Use `CONFIG_*` guards in CMake when source files are conditionally needed.

### Sysbuild

For multi-image builds (MCUboot, and on nRF5340 the network core), use sysbuild. Sysbuild manages child images and their configuration through `sysbuild.conf` and `sysbuild/` overlays.

### Testing And Sample Metadata

#### Rules

- Treat `sample.yaml` or equivalent test metadata as part of the codebase.
- Keep supported boards and build variants explicit.
- Validate representative configuration combinations. A configuration that is documented as supported (`=n` as well as `=y`) must actually compile.
- Separate demo configuration from release configuration.
- Make insecure test overlays visibly named and easy to exclude.

---

## Configuration model (detail)


| Put in **devicetree** | Put in **Kconfig** |
| --- | --- |
| Peripherals, buses (I2C/SPI/UART), IRQ lines | Feature / subsystem enablement (incl. `CONFIG_BT*`) |
| GPIOs, PWMs, pinctrl | BLE roles, buffer counts, GATT sizing |
| Aliases (`led0`, `sw0`) and chosen nodes | Stack sizes, logging levels, retry intervals/timeouts |
| Board-specific enablement, boot-time HW settings | Optional software behavior |
| Driver configuration | — |
| Storage / MCUboot partitions | — |


Deeper rules:

**devicetree rules**
- Keep board-specific changes in overlays, board files, bindings.
- Validate each device with `device_is_ready()` (or the subsystem equivalent)
  before first use. Fail early on missing mandatory hardware; degrade gracefully
  on absent optional hardware.

**Kconfig rules**
- Only add prompts for values users should intentionally change.
- Prefer `depends on` over `select` for non-helper symbols. Use hidden helper
  symbols for derived config. Keep Kconfig hierarchical.
- Put units in symbol names/prompts for time/size/rate. Keep explicit defaults for
  `int`/`hex`.

Prefer: 
- `DEVICE_DT_GET(...)` / `DEVICE_DT_GET_OR_NULL(...)`: obtain device pointers
- `DT_ALIAS(...)` / `DT_NODELABEL(...)` / `DT_CHOSEN(...)`: node references
- `DT_PROP(...)`: read a property value from a node instead of using a Kconfig
- `DT_FOREACH_STATUS_OKAY(...)`: iterate over all enabled nodes of a compatible
- `DT_INST_*` macros: for device driver instance iteration

#### Rules

- Validate each device with `device_is_ready()` or the subsystem equivalent before first use.
- `__ASSERT` early when mandatory hardware is missing.
---

## Runtime behavior

### Concurrency model

Default policy: ISR for minimum urgent work → workqueue for deferred short work →
dedicated thread for long-lived/blocking flows → msgq/zbus/sem/mutex/event/condvar
chosen by communication pattern.

**Primitive selection**
- `k_work` / `k_work_delayable` — deferred short work, timers, retry/backoff/debounce/coalescing.
- dedicated thread — protocol loops, blocking I/O, independent subsystem flow.
- `k_msgq` / zbus — producer-consumer and module decoupling.
- `k_sem` — simple event signaling. `k_mutex` — ownership of shared state in thread context.
- atomics — small shared flags and counters.

**Rules**
- ISR: acknowledge, sample minimal state, signal, exit. Defer parsing, logging,
  allocation, retries, I/O.
- Use dedicated workqueues only when the system workqueue is a poor fit. Don't
  block workqueue handlers unless the design tolerates queue starvation.
- **Do not** inspect `k_work_busy_get()` / `k_work_is_pending()` to drive
  correctness logic — that's a race. Use the return value of `k_work_submit()` /
  `k_work_schedule()` to detect already-pending work.
- Synchronize shared state explicitly. Prefer zbus over ad hoc shared globals or
  raw msgqs for inter-module communication.

**Thread stack sizing**
- `K_THREAD_STACK_DEFINE` for threads that may run in user mode;
  `K_KERNEL_STACK_DEFINE` for kernel-only threads (saves memory).
- Enable `CONFIG_THREAD_ANALYZER` to right-size stacks before shipping.
- Size `CONFIG_ISR_STACK_SIZE` for nested interrupts and ISR-context work.
- Both parts have an ARM MPU: supervisor-mode stack overflow is non-recoverable —
  treat as fatal. (Stack protection config is under Security & hardening.)

### ISR guidance

An ISR must finish quickly; avoid blocking, heavy logging, large stack use, and
complex parsing/policy. It should only clear/ack the source, snapshot minimum
data, and submit work / signal a thread.

**Review check:** loops, formatting, allocation, sleeps, or protocol processing in
an ISR is almost certainly wrong.

### State management (SMF)

Use an explicit state machine when behavior depends on connection / provisioning /
session / recovery state — the common shape for a BLE peripheral or central. Enable
`CONFIG_SMF` (and `CONFIG_SMF_ANCESTOR_SUPPORT` for hierarchical machines).

The state object must have `struct smf_ctx` as its **first member**:

```c
struct my_conn_obj {
    struct smf_ctx ctx;
    /* module-specific data */
};

enum conn_state { STATE_ADVERTISING, STATE_CONNECTED, STATE_DISCONNECTED };

static const struct smf_state states[] = {
    [STATE_ADVERTISING]  = SMF_CREATE_STATE(adv_entry, adv_run, adv_exit, NULL, NULL),
    [STATE_CONNECTED]    = SMF_CREATE_STATE(conn_entry, conn_run, conn_exit, NULL, NULL),
    [STATE_DISCONNECTED] = SMF_CREATE_STATE(disc_entry, disc_run, NULL, NULL, NULL),
};

smf_set_initial(SMF_CTX(&obj), &states[STATE_ADVERTISING]);
while (1) {
    /* wait for event (e.g. zbus notification from a bt_conn callback) */
    if (smf_run_state(SMF_CTX(&obj))) {
        break; /* terminal error */
    }
}
```

**Rules**
- SMF is **run-to-completion**: a message and its transitions complete before the next.
- Run functions return `SMF_EVENT_HANDLED` (consumed) or `SMF_EVENT_PROPAGATE`
  (pass to parent — hierarchical only).
- Call `smf_set_state()` only from entry or run functions, **never** from exit.
- For hierarchical machines, define initial transitions for parent states when
  `CONFIG_SMF_INITIAL_TRANSITION` is enabled. Ancestor entry runs before child
  entry; ancestor exit runs after child exit.
- Model states as enums/SMF states; separate entry/run/exit; centralize transitions;
  reject impossible transitions explicitly; log state changes once, not per poll.
- Keep BLE callbacks (RX thread) out of the state logic itself — have them *post an
  event* (zbus / semaphore / msgq) that the SMF thread consumes.

---

## Reliability And Safety

### Error handling & recovery

**Rules**
- Check and handle every fallible call. Return rich error codes upward until one
  layer owns policy.
- Distinguish transient from fatal failure. Make retry policy explicit and bounded.
- Clean up partial initialization on failure. Fail fast on impossible states.
- Log enough context to debug the failure once. Use assertions for programmer
  errors, not expected runtime conditions.

**Prefer:** leaf functions return error codes; the module boundary decides
retry/fallback/reset/fatal; top-level fault policy is centralized.

**Avoid:** ignoring return values; "log and continue" without understanding the
remaining state; returning success after failed init; hiding fatal conditions in
`printk()`.

### Logging & observability

**Rules**
- `LOG_MODULE_REGISTER(...)` per source file/module; make level configurable via
  Kconfig where useful.
- `LOG_ERR` for failures, `LOG_WRN` for degraded-but-survivable, `LOG_INF` for
  major transitions, `LOG_DBG` for detailed traces.
- Log state changes, retries, and configuration decisions. Keep logs actionable
  and compact. Never leak secrets/bonding keys/production identifiers.

**Avoid:** `printk()` in production modules, repeated logs in hot loops, vague
messages like "failed". On the nRF5340, remember the network-core image has its own
logging path — application logs come from the app core.

### Initialization & startup

Phased order: (1) validate mandatory devices, (2) initialize module state,
(3) register callbacks, (4) start queues/threads, (5) load settings if needed
(`settings_load()` — required before `bt_enable()`-dependent bond restore),
(6) enable BLE / external interfaces (`bt_enable()`, start advertising).

**Rules:** verify readiness before first use; keep init order obvious; use
`SYS_INIT` only for work that truly belongs before `main()`; keep side effects out
of global initializers; make startup idempotent where practical.

### Memory & data ownership

**Rules:** prefer static storage, fixed-capacity queues, bounded buffers; treat
heap as an exception needing justification; never allocate in ISR; avoid allocation
in steady-state real-time paths; make ownership clear for buffers passed between
threads; check sizes before formatting strings; bound every copy/serialization
(including every GATT write payload).

**Review check:** any path that can run forever, under load, or after fault
recovery (e.g. reconnect loops) must not grow memory over time.

### Persistent storage

Both the nRF52840 and nRF5340 have classical **flash** — use NVS-backed storage.

**Backend selection**
- **NVS** (`CONFIG_NVS`) — the storage backend for flash parts (nRF52840, nRF5340).
  FIFO circular buffer, 16-bit IDs, ~8 bytes metadata/entry.
- **Settings** (`CONFIG_SETTINGS`) — preferred abstraction over raw NVS: string
  keys, handler-based loading, and it is the standard store for **BLE bonding data**.
- **FCB** (`CONFIG_FCB`) — only for FIFO-mode append-only logging.
- (ZMS, `CONFIG_ZMS`, targets RRAM/MRAM parts such as the nRF54 series and is out of
  scope here — do not use it on nRF52840/nRF5340 flash.)

**Rules**
- Use Settings for app config and BLE bonds; raw NVS only when Settings is
  insufficient. Only write when data actually changes (NVS checks first).
- Define storage partitions in devicetree, not C. Load settings during init
  (`settings_load()`) before enabling features that depend on them; commit atomically.
- Compute flash-wear lifetime before shipping:
  `lifetime_min = SECTOR_COUNT * SECTOR_SIZE * PAGE_ERASES / (writes_per_min * (data_size + 8))`.
  Increase `SECTOR_COUNT`/`SECTOR_SIZE` if too short. Minimum 2 NVS sectors (one
  kept empty for GC).
- Required for NVS: `CONFIG_NVS=y`, `CONFIG_FLASH=y`, `CONFIG_FLASH_MAP=y`.

**Avoid:** high-frequency writes without wear analysis; large frequently-changing
blobs; assuming NVS sector sizes match flash page sizes.

### Power management

**Rules:** make power policy explicit; bring interfaces up only when needed and
down when not; express latency constraints intentionally; don't assume idle code
is power-efficient; avoid polling when event-driven is possible; prefer blocking
waits over busy loops. For BLE peripherals, connection/advertising interval choice
is the dominant power lever — pick it intentionally, don't leave it at a demo default.

### Portability & board agnosticism

**Rules:** application logic depends on DT aliases, chosen nodes, compatible
bindings, and public Zephyr APIs. Board specifics live in board files / overlays /
bindings. Keep subsystems disabled by default at board level unless required for
basic operation. Adapt across the nRF52840 and nRF5340 via build-time config, not
source edits.

**Prefer** overlays over `#ifdef CONFIG_BOARD_*` when hardware selection is the
real issue; common aliases (`led0`, `sw0`) and chosen nodes for generic code.
**Allow** `CONFIG_BOARD_*` only for true board-specific software policy DT can't
express cleanly (e.g. the nRF5340-only net-core image selection, which lives in
sysbuild config, not app logic).

---

## API Design

### Rules

- Prefer functions over function-like macros unless a macro is required.
- Keep APIs small and typed.
- Use `const` aggressively.
- Minimize variable scope.
- Mark internal functions `static`.
- Use explicit units in names: `_ms`, `_us`, `_bytes`, `_hz`.
- Document threading assumptions at module boundaries.

