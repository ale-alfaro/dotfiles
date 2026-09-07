
### Review Heuristics For LLMs

Flag code for review if any of these are true:

- `main()` mixes board wiring, business logic, protocol handling, and retries
- GPIO pins, buses, or peripheral names appear in Kconfig
- a value that devicetree already carries is duplicated into Kconfig, where the two can disagree
- board-specific constants are hard-coded in C instead of DT
- ISR does more than acknowledge and defer
- a zbus listener does more than latch a value, or calls `zbus_chan_read()` instead of `zbus_chan_const_msg()`
- `printk()` is used throughout a non-demo module
- return values are ignored
- `k_work_busy_get()` or `k_work_is_pending()` drives correctness logic
- dynamic allocation appears in real-time or long-lived paths
- an arena or custom allocator hands out unaligned blocks
- repeated polling replaces event-driven waits
- device readiness is not checked
- init failure returns success
- boot-time work scales with how much data is already on the medium
- logs contain secrets or are too vague to diagnose
- a failure path is silent, or reports a plausible-but-wrong value instead of an error
- retry loops have no backoff, no bound, or no cancel path
- a loop that walks external or on-media data has no bound and no proof of termination
- shared state is modified from multiple contexts without synchronization
- two related values are latched separately where a torn read matters
- C99-style `//` comments used instead of C89 `/* */`
- GATT read/write callback performs blocking work or heavy computation
- BLE notification sent without checking CCCD state
- external input (BLE writes, UART, data read back from media) not bounds-checked before use
- a documented-as-supported Kconfig combination does not compile
- `CONFIG_HW_STACK_PROTECTION` not enabled
- `CONFIG_FPU_SHARING=n` with more than one thread touching float
- a stack size is asserted to be "measured" without the measurement being reproducible
- default MCUboot signing keys used in shipping configuration
- NVS writes at high frequency without flash wear analysis
- Kconfig prompts start with "Enable" (NCS CI rejects these)
- `smf_set_state()` called from an exit function
- nRF5340 build missing its network-core image

### Review Heuristics For New Code

Approve directionally when most of these are true:

- hardware is described in DT and adapted via overlays
- features and sizing are configured in Kconfig
- modules have single responsibilities
- faults propagate to one clear policy point
- concurrency model is explicit
- long work is outside ISR context
- logs are structured and useful
- power transitions are intentional
- memory use is bounded
- test/build metadata covers intended variants
- C coding style matches Zephyr conventions (snake_case, C89 comments, braces)
- external inputs are validated before use
- BLE callbacks are non-blocking with proper CCCD checks
- persistent storage uses Settings/NVS with wear analysis
- stack protection is enabled
- DFU signing uses project-specific keys

### Production Shortcuts To Avoid

- demo-style `printk()` instead of logging
- return `0` after fatal setup failure
- busy loops for simplicity
- insecure test configuration copied into shipping code
- heuristic fixed delays where readiness events should exist
- heap allocation without a bounded-lifetime argument
- default MCUboot signing keys in production firmware
- `BT_GATT_PERM_READ` / `BT_GATT_PERM_WRITE` without encryption on sensitive characteristics
- NVS writes on every sensor reading without wear calculation
- `CONFIG_HW_STACK_PROTECTION` disabled to save a few bytes
- hard-coded connection parameters without application-specific justification
- a magic number in a config file justified only as "measured", with no way to re-measure it

### Representative In-Tree References

Use these as strong examples, not as templates to copy blindly:

- modular zbus + SMF architecture: `nrf/samples/net/mqtt/doc/architecture.rst`
- modular transport state machine: `nrf/samples/net/mqtt/src/modules/transport/transport.c`
- shared zbus channel definitions: `nrf/samples/net/mqtt/src/common/channel.h`
- hierarchical Kconfig: `nrf/samples/net/mqtt/Kconfig`
- CI/build variant metadata: `nrf/samples/net/mqtt/sample.yaml`
- DT-first button handling: `zephyr/samples/basic/button/src/main.c`
- PM policy and latency constraints: `zephyr/samples/subsys/pm/latency/src/main.c`
- explicit PM state hooks: `zephyr/samples/subsys/pm/latency/src/pm.c`
- BLE GATT service pattern (LBS): `nrf/subsys/bluetooth/services/lbs.c`
- BLE peripheral with HR service: `zephyr/samples/bluetooth/peripheral_hr/`
- BLE power profiling / phased init: `nrf/samples/bluetooth/peripheral_power_profiling/src/main.c`
- nRF5340 network-core BLE controller image: `nrf/samples/bluetooth/hci_ipc/`
- zbus observer patterns: `zephyr/samples/subsys/zbus/work_queue/src/main.c`
- SMF flat and hierarchical examples: `zephyr/samples/subsys/smf/`
- NVS persistent storage: `zephyr/samples/subsys/nvs/`
- Settings subsystem: `zephyr/samples/subsys/settings/`
- MCUboot + SMP server: `nrf/samples/zephyr/smp_svr_mini_boot/`
- production-grade template: `ncs-example-application` (GitHub)

Note: the `nrf/samples/net/mqtt` references are kept purely as the canonical NCS zbus + SMF architecture exemplar. Take the module structure from it, not its transport.

### Final Rule

Write code so that:

- hardware can change without rewriting application logic
- timing behavior is explainable
- failures are visible and recoverable
- each module can be reviewed in isolation
- an LLM can infer intent from structure, naming, and configuration layout

Important note:

- samples are valuable for patterns, structure, and API usage
- some samples are pedagogical and intentionally simplify logging, failure handling, debouncing, security, or power behavior
- prefer strong architectural patterns from samples, not every shortcut used in sample code
