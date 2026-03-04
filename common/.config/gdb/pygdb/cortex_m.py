"""
ARM Cortex-M debug toolkit for GDB.

Provides commands for fault analysis, exception frame inspection, NVIC state,
MPU configuration, vector table display, and more.

Load into GDB:
    (gdb) source ~/.config/gdb/pygdb/cortex_m.py

All commands are prefixed 'cortex-'. Tab-complete 'cortex-' to see the full list.
"""

import contextlib
from struct import pack, unpack
from typing import override

import gdb

# =============================================================================
# Register addresses - ARMv7-M Architecture Reference Manual
# =============================================================================

# --- SCB (System Control Block) 0xE000ED00-0xE000ED3C ---
SCB_CPUID = 0xE000ED00
SCB_ICSR = 0xE000ED04
SCB_VTOR = 0xE000ED08
SCB_AIRCR = 0xE000ED0C
SCB_SCR = 0xE000ED10
SCB_CCR = 0xE000ED14
SCB_SHCSR = 0xE000ED24
SCB_CFSR = 0xE000ED28
SCB_HFSR = 0xE000ED2C
SCB_DFSR = 0xE000ED30
SCB_MMFAR = 0xE000ED34
SCB_BFAR = 0xE000ED38

# --- NVIC (Nested Vectored Interrupt Controller) ---
NVIC_ICTR = 0xE000E004
NVIC_ISER_BASE = 0xE000E100  # Interrupt Set-Enable   (32 IRQs per register)
NVIC_ICER_BASE = 0xE000E180  # Interrupt Clear-Enable
NVIC_ISPR_BASE = 0xE000E200  # Interrupt Set-Pending
NVIC_ICPR_BASE = 0xE000E280  # Interrupt Clear-Pending
NVIC_IABR_BASE = 0xE000E300  # Interrupt Active Bit
NVIC_IPR_BASE = 0xE000E400   # Interrupt Priority (8-bit per IRQ)

# --- MPU (Memory Protection Unit) ---
MPU_TYPE = 0xE000ED90
MPU_CTRL = 0xE000ED94
MPU_RNR = 0xE000ED98
MPU_RBAR = 0xE000ED9C
MPU_RASR = 0xE000EDA0

# --- SysTick ---
SYST_CSR = 0xE000E010
SYST_RVR = 0xE000E014
SYST_CVR = 0xE000E018
SYST_CALIB = 0xE000E01C

# =============================================================================
# Bitfield decode tables
# =============================================================================

# CFSR sub-registers --------------------------------------------------------
MMFSR_BITS = {
    0: ("IACCVIOL", "Instruction access violation"),
    1: ("DACCVIOL", "Data access violation"),
    3: ("MUNSTKERR", "MemManage fault on unstacking for return from exception"),
    4: ("MSTKERR", "MemManage fault on stacking for exception entry"),
    5: ("MLSPERR", "MemManage fault during FP lazy state preservation"),
    7: ("MMARVALID", "MMFAR holds a valid address"),
}

BFSR_BITS = {
    0: ("IBUSERR", "Instruction bus error"),
    1: ("PRECISERR", "Precise data bus error"),
    2: ("IMPRECISERR", "Imprecise data bus error"),
    3: ("UNSTKERR", "BusFault on unstacking for return from exception"),
    4: ("STKERR", "BusFault on stacking for exception entry"),
    5: ("LSPERR", "BusFault during FP lazy state preservation"),
    7: ("BFARVALID", "BFAR holds a valid address"),
}

UFSR_BITS = {
    0: ("UNDEFINSTR", "Undefined instruction"),
    1: ("INVSTATE", "Invalid state (e.g. Thumb bit)"),
    2: ("INVPC", "Invalid PC load (illegal EXC_RETURN)"),
    3: ("NOCP", "No coprocessor (FPU/CP access when disabled)"),
    4: ("STKOF", "Stack overflow (ARMv8-M)"),
    8: ("UNALIGNED", "Unaligned memory access"),
    9: ("DIVBYZERO", "Divide by zero"),
}

HFSR_BITS = {
    1: ("VECTTBL", "Vector table hard fault (bus fault on vector read)"),
    30: ("FORCED", "Forced hard fault (escalated configurable fault)"),
    31: ("DEBUGEVT", "Debug event hard fault"),
}

DFSR_BITS = {
    0: ("HALTED", "Halt requested"),
    1: ("BKPT", "Breakpoint"),
    2: ("DWTTRAP", "DWT match"),
    3: ("VCATCH", "Vector catch"),
    4: ("EXTERNAL", "External debug request"),
}

SHCSR_BITS = {
    0: ("MEMFAULTACT", "MemManage exception active"),
    1: ("BUSFAULTACT", "BusFault exception active"),
    3: ("USGFAULTACT", "UsageFault exception active"),
    7: ("SVCALLACT", "SVCall active"),
    8: ("MONITORACT", "Debug Monitor active"),
    10: ("PENDSVACT", "PendSV active"),
    11: ("SYSTICKACT", "SysTick active"),
    12: ("USGFAULTPENDED", "UsageFault pending"),
    13: ("MEMFAULTPENDED", "MemManage pending"),
    14: ("BUSFAULTPENDED", "BusFault pending"),
    15: ("SVCALLPENDED", "SVCall pending"),
    16: ("MEMFAULTENA", "MemManage enabled"),
    17: ("BUSFAULTENA", "BusFault enabled"),
    18: ("USGFAULTENA", "UsageFault enabled"),
}

CCR_BITS = {
    0: ("NONBASETHRDENA", "Non-base thread enable"),
    1: ("USERSETMPEND", "User set-pending enable"),
    3: ("UNALIGN_TRP", "Unaligned access trap"),
    4: ("DIV_0_TRP", "Divide-by-zero trap"),
    8: ("BFHFNMIGN", "Bus fault handler ignores precise bus faults during priority -1/-2 handlers"),
    9: ("STKALIGN", "8-byte stack alignment on exception entry"),
    16: ("DC", "Data cache enable (M7)"),
    17: ("IC", "Instruction cache enable (M7)"),
    18: ("BP", "Branch prediction enable (M7)"),
}

# CPUID part number table ---------------------------------------------------
CPUID_PARTS = {
    0xC20: "Cortex-M0",
    0xC21: "Cortex-M1",
    0xC23: "Cortex-M3",
    0xC24: "Cortex-M4",
    0xC27: "Cortex-M7",
    0xC60: "Cortex-M0+",
    0xD20: "Cortex-M23",
    0xD21: "Cortex-M33",
    0xD22: "Cortex-M55",
    0xD23: "Cortex-M85",
}

# ARMv6-M cores (no CFSR, no BusFault/UsageFault/MemManage)
ARMV6M_PARTS = {0xC20, 0xC60}

# MPU Access Permission table -----------------------------------------------
MPU_AP = {
    0b000: "No access",
    0b001: "Priv RW",
    0b010: "Priv RW / Unpriv RO",
    0b011: "Full access",
    0b101: "Priv RO",
    0b110: "Priv RO / Unpriv RO",
    0b111: "RO",
}

# MPU TEX/S/C/B memory type table ------------------------------------------
MPU_MEM_TYPES = {
    # (TEX, C, B) -> description
    (0b000, 0, 0): "Strongly-ordered",
    (0b000, 0, 1): "Device, shared",
    (0b000, 1, 0): "Write-through, no write-allocate",
    (0b000, 1, 1): "Write-back, no write-allocate",
    (0b001, 0, 0): "Non-cacheable",
    (0b001, 1, 0): "Write-back, write/read-allocate",
    (0b001, 1, 1): "Write-back, write/read-allocate",
    (0b010, 0, 0): "Device, non-shared",
}

# System exception names (vector table index 0-15) -------------------------
SYSTEM_EXCEPTIONS = {
    0: "Initial SP",
    1: "Reset",
    2: "NMI",
    3: "HardFault",
    4: "MemManage",
    5: "BusFault",
    6: "UsageFault",
    7: "Reserved",
    8: "Reserved",
    9: "Reserved",
    10: "Reserved",
    11: "SVCall",
    12: "Debug Monitor",
    13: "Reserved",
    14: "PendSV",
    15: "SysTick",
}

# =============================================================================
# Utility functions
# =============================================================================


def _read_reg32(addr):
    """Read a 32-bit memory-mapped register. Returns int."""
    data = gdb.selected_inferior().read_memory(addr, 4)
    return unpack("<I", bytes(data))[0]


def _write_reg32(addr, val):
    """Write a 32-bit memory-mapped register."""
    gdb.selected_inferior().write_memory(addr, pack("<I", val))


def _read_bulk(addr, size):
    """Read a block of memory. Returns bytes."""
    return bytes(gdb.selected_inferior().read_memory(addr, size))


def _decode_bits(value, bit_defs):
    """
    Decode set bits using a {bit: (name, description)} table.

    Returns list of formatted strings for bits that are set.
    """
    lines = []
    for bit, (name, desc) in sorted(bit_defs.items()):
        if value & (1 << bit):
            lines.append(f"  [{bit:2d}] {name}: {desc}")
    return lines


def _section_header(title):
    """Print a visual separator."""
    ruler = "\u2500" * 60
    print(f"\n{ruler}")
    print(f"  {title}")
    print(ruler)


def _resolve_symbol(addr):
    """Resolve an address to a symbol name, or return hex string."""
    try:
        result = gdb.execute(f"info symbol 0x{addr:08X}", to_string=True)
        if "No symbol" not in result:
            return result.strip()
    except gdb.error:
        pass
    return f"0x{addr:08X}"


def _get_cpuid_partno():
    """Read CPUID and return the part number field."""
    cpuid = _read_reg32(SCB_CPUID)
    return (cpuid >> 4) & 0xFFF


def _is_armv6m():
    """Detect ARMv6-M core (no CFSR, limited fault registers)."""
    try:
        return _get_cpuid_partno() in ARMV6M_PARTS
    except gdb.MemoryError:
        return False


def _dump_exception_frame(sp, exc_return=None):
    """Dump the exception stack frame at the given address."""
    basic_regs = ["R0", "R1", "R2", "R3", "R12", "LR", "PC", "xPSR"]
    for i, name in enumerate(basic_regs):
        val = _read_reg32(sp + i * 4)
        extra = ""
        if name in {"LR", "PC"}:
            extra = f"  ({_resolve_symbol(val)})"
        print(f"  {name:>4s}:  0x{val:08X}{extra}")

    # Extended frame with FP registers (EXC_RETURN bit 4 == 0)
    if exc_return is not None and (exc_return & (1 << 4)) == 0:
        print("  --- FPU extended frame ---")
        fp_names = [f"S{i}" for i in range(16)] + ["FPSCR", "Reserved"]
        for i, name in enumerate(fp_names):
            val = _read_reg32(sp + (8 + i) * 4)
            print(f"  {name:>8s}:  0x{val:08X}")


# =============================================================================
# GDB Commands
# =============================================================================


def _dump_cfsr():
    """Decode and print CFSR sub-registers (MMFSR, BFSR, UFSR)."""
    try:
        cfsr = _read_reg32(SCB_CFSR)
    except gdb.MemoryError:
        print("  CFSR: <read failed>")
        return

    print(f"\n  CFSR:   0x{cfsr:08X}")
    mmfsr = cfsr & 0xFF
    bfsr = (cfsr >> 8) & 0xFF
    ufsr = (cfsr >> 16) & 0xFFFF

    if mmfsr:
        print(f"    MMFSR: 0x{mmfsr:02X}")
        for line in _decode_bits(mmfsr, MMFSR_BITS):
            print(f"  {line}")
        if mmfsr & (1 << 7):  # MMARVALID
            mmfar = _read_reg32(SCB_MMFAR)
            print(f"    MMFAR: 0x{mmfar:08X}  ({_resolve_symbol(mmfar)})")

    if bfsr:
        print(f"    BFSR:  0x{bfsr:02X}")
        for line in _decode_bits(bfsr, BFSR_BITS):
            print(f"  {line}")
        if bfsr & (1 << 7):  # BFARVALID
            bfar = _read_reg32(SCB_BFAR)
            print(f"    BFAR:  0x{bfar:08X}  ({_resolve_symbol(bfar)})")

    if ufsr:
        print(f"    UFSR:  0x{ufsr:04X}")
        for line in _decode_bits(ufsr, UFSR_BITS):
            print(f"  {line}")


def _dump_fault_exception_frame():
    """Read EXC_RETURN, detect stack, dump frame and source listing."""
    try:
        exc_return = int(gdb.parse_and_eval("$lr"))
        if exc_return & (1 << 2):
            sp_name, sp = "PSP", int(gdb.parse_and_eval("$psp"))
        else:
            sp_name, sp = "MSP", int(gdb.parse_and_eval("$msp"))

        print(f"  Stack: {sp_name} = 0x{sp:08X}")
        _dump_exception_frame(sp, exc_return)

        # Source listing at faulting PC
        pc = _read_reg32(sp + 24)
        print(f"\nSource at PC (0x{pc:08X}):")
        try:
            gdb.execute(f"list *0x{pc:08X}")
        except gdb.error:
            print(f"  {_resolve_symbol(pc)}")
    except gdb.error:
        print("  (could not read LR/SP - not in exception context?)")


class CortexMFault(gdb.Command):
    """
    Decode Cortex-M fault status registers with per-bit analysis.

    Reads SHCSR, CFSR (MMFSR/BFSR/UFSR), HFSR, DFSR and decodes every set
    bit. Shows MMFAR/BFAR when valid. Dumps the exception frame and lists
    source at the faulting PC. Detects ARMv6-M (no CFSR).
    """

    def __init__(self):
        super().__init__("cortex-fault", gdb.COMMAND_USER)

    @override
    def invoke(self, argument, from_tty):
        try:
            shcsr = _read_reg32(SCB_SHCSR)
            hfsr = _read_reg32(SCB_HFSR)
            dfsr = _read_reg32(SCB_DFSR)
        except gdb.MemoryError:
            print("Error: cannot read fault registers (no target connected?)")
            return

        _section_header("Fault Status Registers")

        print(f"  SHCSR:  0x{shcsr:08X}")
        for line in _decode_bits(shcsr, SHCSR_BITS):
            print(line)

        if not _is_armv6m():
            _dump_cfsr()
        else:
            print("  (ARMv6-M: CFSR not available)")

        print(f"\n  HFSR:   0x{hfsr:08X}")
        for line in _decode_bits(hfsr, HFSR_BITS):
            print(line)

        print(f"\n  DFSR:   0x{dfsr:08X}")
        for line in _decode_bits(dfsr, DFSR_BITS):
            print(line)

        _section_header("Exception Frame")
        _dump_fault_exception_frame()


class CortexMFrame(gdb.Command):
    """
    Pretty-print a Cortex-M exception stack frame.

    Usage: cortex-frame [address]

    Without an address, auto-detects MSP/PSP from EXC_RETURN in LR.
    Handles basic (8-word) and extended (26-word FPU) frames via
    EXC_RETURN bit 4.
    """

    def __init__(self):
        super().__init__("cortex-frame", gdb.COMMAND_USER)

    @override
    def invoke(self, argument, from_tty):
        args = gdb.string_to_argv(argument)
        exc_return = None

        try:
            if args:
                sp = int(gdb.parse_and_eval(args[0]))
                with contextlib.suppress(gdb.error):
                    exc_return = int(gdb.parse_and_eval("$lr"))
            else:
                exc_return = int(gdb.parse_and_eval("$lr"))
                if exc_return & (1 << 2):
                    sp = int(gdb.parse_and_eval("$psp"))
                    print(f"Auto-detected PSP = 0x{sp:08X}")
                else:
                    sp = int(gdb.parse_and_eval("$msp"))
                    print(f"Auto-detected MSP = 0x{sp:08X}")
        except gdb.error:
            print("Error: cannot read SP/LR (no target connected?)")
            return

        try:
            _dump_exception_frame(sp, exc_return)
        except gdb.MemoryError:
            print(f"Error: cannot read memory at 0x{sp:08X}")


class CortexMStack(gdb.Command):
    """
    Analyze stack usage via fill-pattern watermark.

    Usage: cortex-stack <base> <size> [pattern]

    Scans from base upward for the fill pattern to find peak usage.
    Default pattern: 0xDEADBEEF
    Common alternatives: 0xAAAAAAAA (Zephyr), 0xA5A5A5A5 (FreeRTOS)
    """

    def __init__(self):
        super().__init__("cortex-stack", gdb.COMMAND_USER)

    @override
    def invoke(self, argument, from_tty):
        args = gdb.string_to_argv(argument)
        if len(args) < 2:  # noqa: PLR2004
            print("Usage: cortex-stack <base> <size> [pattern]")
            print("  base:    stack base address (lowest address)")
            print("  size:    stack size in bytes")
            print("  pattern: fill pattern (default 0xDEADBEEF)")
            return

        try:
            base = int(gdb.parse_and_eval(args[0]))
            size = int(gdb.parse_and_eval(args[1]))
            pattern = int(gdb.parse_and_eval(args[2])) if len(args) > 2 else 0xDEADBEEF  # noqa: PLR2004
        except gdb.error as e:
            print(f"Error: {e}")
            return

        try:
            data = _read_bulk(base, size)
        except gdb.MemoryError:
            print(f"Error: cannot read {size} bytes at 0x{base:08X}")
            return

        pat_bytes = pattern.to_bytes(4, "little")
        unused = 0
        for i in range(0, size - 3, 4):
            if data[i : i + 4] == pat_bytes:
                unused += 4
            else:
                break

        used = size - unused
        pct = (used / size) * 100 if size else 0

        _section_header("Stack Watermark Analysis")
        print(f"  Base:     0x{base:08X}")
        print(f"  Top:      0x{base + size:08X}")
        print(f"  Size:     {size} bytes ({size // 1024} KB)")
        print(f"  Pattern:  0x{pattern:08X}")
        print(f"  Used:     {used} bytes ({pct:.1f}%)")
        print(f"  Free:     {unused} bytes ({100 - pct:.1f}%)")


class CortexMCpuid(gdb.Command):
    """
    Decode the Cortex-M CPUID register.

    Shows implementer, variant, architecture, part name, and revision
    in the standard rNpM format.
    """

    def __init__(self):
        super().__init__("cortex-cpuid", gdb.COMMAND_USER)

    @override
    def invoke(self, argument, from_tty):
        try:
            cpuid = _read_reg32(SCB_CPUID)
        except gdb.MemoryError:
            print("Error: cannot read CPUID (no target connected?)")
            return

        implementer = (cpuid >> 24) & 0xFF
        variant = (cpuid >> 20) & 0xF
        arch = (cpuid >> 16) & 0xF
        partno = (cpuid >> 4) & 0xFFF
        revision = cpuid & 0xF

        impl_name = {0x41: "ARM"}.get(implementer, f"0x{implementer:02X}")
        arch_name = {0xC: "ARMv6-M", 0xF: "ARMv7-M/ARMv8-M"}.get(arch, f"0x{arch:X}")
        part_name = CPUID_PARTS.get(partno, f"Unknown (0x{partno:03X})")

        _section_header("CPUID")
        print(f"  Raw:           0x{cpuid:08X}")
        print(f"  Implementer:   {impl_name}")
        print(f"  Architecture:  {arch_name}")
        print(f"  Part:          {part_name}")
        print(f"  Revision:      r{variant}p{revision}")


class CortexMNvic(gdb.Command):
    """
    Display NVIC interrupt state: enabled, pending, active, priority.

    Usage: cortex-nvic [--all]

    Default: shows only IRQs with at least one flag set.
    --all:   shows all implemented IRQs.
    """

    def __init__(self):
        super().__init__("cortex-nvic", gdb.COMMAND_USER)

    @override
    def invoke(self, argument, from_tty):
        show_all = "--all" in argument

        try:
            ictr = _read_reg32(NVIC_ICTR)
        except gdb.MemoryError:
            print("Error: cannot read NVIC (no target connected?)")
            return

        num_irqs = min((ictr + 1) * 32, 496)

        _section_header(f"NVIC - {num_irqs} external IRQs")
        print(f"  {'IRQ':>5s}  {'Ena':>3s}  {'Pnd':>3s}  {'Act':>3s}  {'Pri':>5s}")
        print(f"  {'\u2500' * 5}  {'\u2500' * 3}  {'\u2500' * 3}  {'\u2500' * 3}  {'\u2500' * 5}")

        try:
            displayed = 0
            for irq in range(num_irqs):
                reg_idx = irq // 32
                bit = irq % 32

                enabled = (_read_reg32(NVIC_ISER_BASE + reg_idx * 4) >> bit) & 1
                pending = (_read_reg32(NVIC_ISPR_BASE + reg_idx * 4) >> bit) & 1
                active = (_read_reg32(NVIC_IABR_BASE + reg_idx * 4) >> bit) & 1
                priority = _read_reg32(NVIC_IPR_BASE + (irq & ~3)) >> (8 * (irq & 3)) & 0xFF

                if show_all or enabled or pending or active:
                    e = "*" if enabled else "."
                    p = "*" if pending else "."
                    a = "*" if active else "."
                    print(f"  {irq:5d}    {e}    {p}    {a}  0x{priority:02X}")
                    displayed += 1

            if not displayed:
                print("  (no IRQs with flags set - use --all to see all)")
        except gdb.MemoryError:
            print("  Error: failed reading NVIC registers")


def _format_region_size(size_exp):
    """Format an MPU region size exponent into a human-readable string."""
    kb = 1024
    region_size = 1 << (size_exp + 1) if size_exp >= 4 else 0  # noqa: PLR2004
    if region_size >= kb * kb:
        return f"{region_size // (kb * kb)} MB"
    if region_size >= kb:
        return f"{region_size // kb} KB"
    return f"{region_size} B"


def _decode_mem_type(rasr):
    """Decode MPU RASR TEX/C/B fields into a memory type string."""
    tex = (rasr >> 19) & 0x7
    c_bit = (rasr >> 17) & 1
    b_bit = (rasr >> 16) & 1
    return MPU_MEM_TYPES.get((tex, c_bit, b_bit), f"TEX={tex} C={c_bit} B={b_bit}")


class CortexMMpu(gdb.Command):
    """
    Display MPU region configuration.

    Shows base address, size, access permissions, XN, memory type,
    and sub-region disable for each configured region.
    """

    def __init__(self):
        super().__init__("cortex-mpu", gdb.COMMAND_USER)

    @override
    def invoke(self, argument, from_tty):
        try:
            mpu_type = _read_reg32(MPU_TYPE)
        except gdb.MemoryError:
            print("Error: cannot read MPU (no target connected?)")
            return

        num_regions = (mpu_type >> 8) & 0xFF
        if num_regions == 0:
            print("MPU not present on this core (MPU_TYPE.DREGION = 0)")
            return

        try:
            mpu_ctrl = _read_reg32(MPU_CTRL)
        except gdb.MemoryError:
            mpu_ctrl = 0

        enabled = "enabled" if mpu_ctrl & 1 else "disabled"
        privdefena = "yes" if mpu_ctrl & (1 << 2) else "no"
        hfnmiena = "yes" if mpu_ctrl & (1 << 1) else "no"

        _section_header(f"MPU - {num_regions} regions, {enabled}")
        print(f"  PRIVDEFENA: {privdefena}  |  HFNMIENA: {hfnmiena}")
        print()

        for i in range(num_regions):
            self._dump_region(i)

    @staticmethod
    def _dump_region(i):
        """Dump a single MPU region."""
        try:
            _write_reg32(MPU_RNR, i)
            rbar = _read_reg32(MPU_RBAR)
            rasr = _read_reg32(MPU_RASR)
        except gdb.MemoryError:
            print(f"  Region {i}: <read error>")
            return

        region_ena = "ON " if rasr & 1 else "OFF"
        base_addr = rbar & 0xFFFFFFE0
        xn = "XN" if rasr & (1 << 28) else "  "
        ap_str = MPU_AP.get((rasr >> 24) & 0x7, f"AP={(rasr >> 24) & 0x7}")
        shared = "S" if (rasr >> 18) & 1 else " "
        srd = (rasr >> 8) & 0xFF

        size_str = _format_region_size((rasr >> 1) & 0x1F)
        mem_type = _decode_mem_type(rasr)

        print(
            f"  [{i}] {region_ena}  0x{base_addr:08X}  {size_str:>8s}  "
            f"{ap_str:<22s}  {xn} {shared}  {mem_type}"
        )
        if srd:
            print(f"       SRD: 0b{srd:08b}")


class CortexMVtor(gdb.Command):
    """
    Display the vector table with symbol resolution.

    Usage: cortex-vtor [count]

    Shows the first 'count' vectors. Default: 16 (system exceptions only).
    Names the 16 standard system exceptions.
    """

    def __init__(self):
        super().__init__("cortex-vtor", gdb.COMMAND_USER)

    @override
    def invoke(self, argument, from_tty):
        args = gdb.string_to_argv(argument)
        count = 16
        if args:
            try:
                count = int(gdb.parse_and_eval(args[0]))
            except gdb.error:
                print("Usage: cortex-vtor [count]")
                return

        try:
            vtor = _read_reg32(SCB_VTOR)
        except gdb.MemoryError:
            print("Error: cannot read VTOR (no target connected?)")
            return

        _section_header(f"Vector Table at 0x{vtor:08X}")
        print(f"  {'#':>4s}  {'Address':>10s}  {'Handler':>10s}  Name / Symbol")
        print(f"  {'\u2500' * 4}  {'\u2500' * 10}  {'\u2500' * 10}  {'\u2500' * 30}")

        for i in range(count):
            try:
                entry_addr = vtor + i * 4
                handler = _read_reg32(entry_addr)
                exc_name = SYSTEM_EXCEPTIONS.get(i, f"IRQ{i - 16}")

                if i == 0:
                    print(f"  {i:4d}  0x{entry_addr:08X}  0x{handler:08X}  {exc_name}")
                else:
                    handler_addr = handler & ~1  # Clear thumb bit
                    sym = _resolve_symbol(handler_addr)
                    print(f"  {i:4d}  0x{entry_addr:08X}  0x{handler:08X}  {exc_name}: {sym}")
            except gdb.MemoryError:
                print(f"  {i:4d}  0x{vtor + i * 4:08X}  <read error>")


def _read_scb_reg(name, addr):
    """Read and print an SCB register, returning value or None on error."""
    try:
        val = _read_reg32(addr)
    except gdb.MemoryError:
        print(f"  {name}:    <read error>")
        return None
    else:
        return val


class CortexMScb(gdb.Command):
    """
    Display a System Control Block dashboard.

    Shows CPUID summary, ICSR, VTOR, AIRCR (PRIGROUP), CCR flags,
    SHCSR summary, and raw fault register values.
    """

    def __init__(self):
        super().__init__("cortex-scb", gdb.COMMAND_USER)

    @override
    def invoke(self, argument, from_tty):
        cpuid = _read_scb_reg("CPUID", SCB_CPUID)
        if cpuid is None:
            print("Error: cannot read SCB (no target connected?)")
            return

        partno = (cpuid >> 4) & 0xFFF
        variant = (cpuid >> 20) & 0xF
        revision = cpuid & 0xF
        part_name = CPUID_PARTS.get(partno, f"Unknown (0x{partno:03X})")

        _section_header("System Control Block")
        print(f"  CPUID:   0x{cpuid:08X}  ({part_name} r{variant}p{revision})")

        self._dump_icsr()
        self._dump_aircr()
        self._dump_ccr_shcsr()
        self._dump_fault_regs_raw()

    @staticmethod
    def _dump_icsr():
        """Print ICSR with active/pending exception decode."""
        vtor = _read_scb_reg("VTOR", SCB_VTOR)
        if vtor is not None:
            print(f"  VTOR:    0x{vtor:08X}")

        icsr = _read_scb_reg("ICSR", SCB_ICSR)
        if icsr is None:
            return
        active = icsr & 0x1FF
        pending = (icsr >> 12) & 0x1FF
        active_name = SYSTEM_EXCEPTIONS.get(active, f"IRQ{active - 16}") if active else "None"
        pending_name = (
            SYSTEM_EXCEPTIONS.get(pending, f"IRQ{pending - 16}") if pending else "None"
        )
        print(f"  ICSR:    0x{icsr:08X}  (active: {active_name}, pending: {pending_name})")

    @staticmethod
    def _dump_aircr():
        """Print AIRCR with PRIGROUP and endianness."""
        aircr = _read_scb_reg("AIRCR", SCB_AIRCR)
        if aircr is None:
            return
        prigroup = (aircr >> 8) & 0x7
        endian = "BE" if aircr & (1 << 15) else "LE"
        print(f"  AIRCR:   0x{aircr:08X}  (PRIGROUP={prigroup}, {endian})")

    @staticmethod
    def _dump_ccr_shcsr():
        """Print CCR and SHCSR with bitfield decode."""
        ccr = _read_scb_reg("CCR", SCB_CCR)
        if ccr is not None:
            print(f"  CCR:     0x{ccr:08X}")
            for line in _decode_bits(ccr, CCR_BITS):
                print(line)

        shcsr = _read_scb_reg("SHCSR", SCB_SHCSR)
        if shcsr is not None:
            print(f"  SHCSR:   0x{shcsr:08X}")
            for line in _decode_bits(shcsr, SHCSR_BITS):
                print(line)

    @staticmethod
    def _dump_fault_regs_raw():
        """Print raw fault register values."""
        if not _is_armv6m():
            for name, addr in [("CFSR", SCB_CFSR), ("HFSR", SCB_HFSR), ("DFSR", SCB_DFSR)]:
                val = _read_scb_reg(name, addr)
                if val is not None:
                    print(f"  {name}:    0x{val:08X}")
        else:
            hfsr = _read_scb_reg("HFSR", SCB_HFSR)
            if hfsr is not None:
                print(f"  HFSR:    0x{hfsr:08X}  (ARMv6-M: no CFSR)")


class CortexMSystick(gdb.Command):
    """
    Display SysTick timer state.

    Shows enable, tick interrupt, clock source, reload value,
    current value, and calibration info.
    """

    def __init__(self):
        super().__init__("cortex-systick", gdb.COMMAND_USER)

    @override
    def invoke(self, argument, from_tty):
        try:
            csr = _read_reg32(SYST_CSR)
        except gdb.MemoryError:
            print("Error: cannot read SysTick (no target connected?)")
            return

        try:
            rvr = _read_reg32(SYST_RVR)
            cvr = _read_reg32(SYST_CVR)
            calib = _read_reg32(SYST_CALIB)
        except gdb.MemoryError:
            rvr = cvr = calib = None

        _section_header("SysTick")

        enabled = "enabled" if csr & 1 else "disabled"
        tickint = "enabled" if csr & (1 << 1) else "disabled"
        clksrc = "processor clock" if csr & (1 << 2) else "external reference"
        countflag = "yes" if csr & (1 << 16) else "no"

        print(f"  CSR:      0x{csr:08X}")
        print(f"  Enable:   {enabled}")
        print(f"  TickInt:  {tickint}")
        print(f"  ClkSrc:   {clksrc}")
        print(f"  CountFlg: {countflag}")

        if rvr is not None:
            print(f"  Reload:   {rvr} (0x{rvr:08X})")
            print(f"  Current:  {cvr} (0x{cvr:08X})")
        if calib is not None:
            tenms = calib & 0x00FFFFFF
            skew = "inexact" if calib & (1 << 30) else "exact"
            noref = "no ref clock" if calib & (1 << 31) else "ref clock available"
            print(f"  Calib:    TENMS={tenms} ({skew}, {noref})")


# =============================================================================
# Module registration
# =============================================================================

CortexMFault()
CortexMFrame()
CortexMStack()
CortexMCpuid()
CortexMNvic()
CortexMMpu()
CortexMVtor()
CortexMScb()
CortexMSystick()

print("Cortex-M debug commands loaded. Type 'help cortex-' and tab-complete to see all.")
