# Aria firmware GDB Python helper: flash both nRF5340 cores from one build dir.
#
# Registers a single command that replays the canonical dual-core flash
# sequence against the J-Link gdbserver, deriving both hex paths from the
# build directory passed as the only argument:
#
#   (gdb) aria-flash build_debug
#
# Net core (CPUNET) is flashed first, then the app core (CPUAPP) — the same
# load-bearing order enforced by `mise run debug:flash` and the .jlink scripts
# (flashing only CPUAPP can leave the HCI/IPC ABI mismatched with a stale
# CPUNET image; see the project_ble_conn_param_hang bug).
#
# Source it from a GDB pane (or auto-source via mise-tasks/debug_session):
#   (gdb) source scripts/gdb/aria_flash.py

import typing
from pathlib import Path

import gdb

# Hex paths relative to the build directory, in flash order.
# _NET_HEX = os.path.join("hci_ipc", "zephyr", "merged_CPUNET.hex")
# _APP_HEX = os.path.join("zephyr", "merged.hex")


class AriaFlash(gdb.Command):
    """
    Flash both nRF5340 cores from a single build directory and continue.

    Usage: aria-flash <build-dir>

    Replays the canonical sequence: reset, select CPUNET, load
    <build-dir>/hci_ipc/zephyr/merged_CPUNET.hex, release it, select CPUAPP,
    load <build-dir>/zephyr/merged.hex, reset, continue. Both hex files are
    checked to exist before any monitor command runs, so a wrong build dir
    fails fast instead of half-flashing the device.
    """

    def __init__(self):
        super().__init__("aria-flash", gdb.COMMAND_USER)

    @typing.override
    def invoke(self, arg, from_tty):
        argv = gdb.string_to_argv(arg)
        if len(argv) != 1:
            raise gdb.GdbError("usage: aria-flash <build-dir>")

        build_dir = argv[0]
        net_hex = Path(build_dir, "merged_aria_nrf5340_cpunet.hex")
        app_hex = Path(build_dir, "merged_aria_nrf5340_cpuapp.hex")

        # Fail fast: verify both images exist before touching the device, so a
        # typo'd build dir can't leave one core flashed and the other stale.
        missing = [p for p in (net_hex, app_hex) if not p.is_file()]
        if missing:
            msg = f"hex file(s) not found under {build_dir}"
            raise gdb.GdbError(
                msg
            )

        steps = [
            "monitor reset",
            "monitor device nrf5340_xxaa_net",
            "monitor reset",
            f"load {net_hex}",
            "monitor reset",
            "monitor go",
            "monitor device nrf5340_xxaa_app",
            "monitor reset",
            f"load {app_hex}",
            "monitor reset",
            "continue",
        ]

        print(f"[aria-flash] net: {net_hex}")
        print(f"[aria-flash] app: {app_hex}")
        for cmd in steps:
            print(f"[aria-flash] {cmd}")
            gdb.execute(cmd)


AriaFlash()
