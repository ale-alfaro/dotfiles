---
name: ncs-embedded-code-review 
description: Reviewing code in a NCS/Zephyr project. Use when doing code review inside a NCS-flavored west workspace.
---

## How To Use This Document

Use the sections in this order:

1. Use `Core Rules` as the canonical and idiomatic baseline. Example pointers below each point
2. Start with `Quick Reference Checklist` for easy to spot footguns or improvements
3. Use the grouped sections in [Domain Specific Guidance](domain-specific-guidance.md) with grep to find relevant guidance on specific topics
4. Use [Review Aids](review-aids.md) for llm-specific heuristics.

## Core Rules

1. keep code board-agnostic

    - Put hardware description in devicetree.
    - Put software feature selection and resource sizing in Kconfig.

1. keep behavior deterministic
    - Prefer static allocation and bounded memory use.
    - Keep ISRs short. Defer real work to threads or workqueues.
1. keep failure modes explicit
    - Check every return value that can fail.
    - Make power behavior explicit.
    - **DO NOT CONDITIONALLY QUEUE**. Example checking the return values of `k_work_busy_get()` or `k_work_is_pending()` to decide whether to queue or not. ALWAYS a bug... should be avoided to prevent race conditions
1. keep software components small and testable
    - Keep threaded modules thin (under ~1000 lines). Split into libraries and composable software components
1. keep configuration in the right abstraction layer: hardware and drivers settings in devicetree, software features in Kconfig
    - Drivers should depend on the `DT_HAS_<VENDOR>_<COMPAT_NAME>_ENABLED` auto-generated symbols to be enabled
    - `depends on` and `imply` are better tools than `select` to define features with wide dependencies. Use `select` for hidden (promptless) symbols within or for self-evident,low-impact dependencies such as `SERIAL` when enabling `UART_CONSOLE`


## Quick Reference Checklist

Use this as a fast pass before deeper review:

1. Hardware and drivers configuration are described in devicetree; software features and most sizing are configured in Kconfig, with documented exceptions.
2. No GPIO pins, peripheral instances, or board wiring are encoded in Kconfig or hard-coded in application logic.
3. Every DT-backed device is validated before first use.
4. `main()` is thin; real behavior lives in small modules with explicit ownership.
5. ISR code only acknowledges, snapshots minimal state, and defers work.
6. Concurrency is explicit: workqueue, thread, zbus, msgq, mutex, sem, or atomics are chosen intentionally.
7. Shared mutable state has clear synchronization and ownership.
8. Every fallible call is checked; retry, fallback, and fatal policies are explicit and bounded.
9. State-dependent behavior uses SMF or explicit state transitions.
10. Logging is structured, compact, and does not leak secrets.
11. External input is bounds-checked and validated before use.
12. Memory use is bounded; heap use is justified and avoided in ISR and steady-state real-time paths.
13. Persistent data uses Settings/NVS with partitioning and flash wear considered.
14. Power behavior is intentional; polling and busy loops are avoided where events suffice.
15. BLE GATT callbacks do not block, and notifications respect CCCD state.
16. `CONFIG_HW_STACK_PROTECTION` is enabled (both target parts have an MPU).
17. Security-sensitive material such as keys, certificates, and credentials is never hard-coded or logged.
18. DFU and bootloader settings are production-safe: signed images, non-default keys, and a tested upgrade path.
19. Code follows Zephyr coding style: `snake_case`, C89 comments (`/* */`), braces on all bodies, 100-column line limit.
20. Kconfig prompts do not start with "Enable", include units, and have help text where needed.
21. Initialization follows phased order; startup is idempotent where practical.
22. Public APIs are typed, `const`-correct, and document threading assumptions.
23. BLE connection reference counting (`bt_conn_ref()` / `bt_conn_unref()`) is correct across callbacks and disconnect paths.
24. Build and test metadata covers intended boards, images, and release-relevant variants.
25. On nRF5340, every build variant has the matching network-core image (`hci_ipc`) wired through sysbuild.


