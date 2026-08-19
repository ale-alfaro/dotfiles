"""
Cortex-M debug helpers: cortex-fault, cortex-irq, cortex-mpu.

Design rules these commands follow, because the previous version broke them:

  * Never present a guess as a reading. If the core is not in an exception,
    there is no exception frame to decode - say so instead of formatting
    whatever bytes happen to sit under SP.
  * Distinguish "fault happened" from "fault reporting is configured" and
    from "debugger halted the core". SHCSR enable bits and DFSR.HALTED are
    not faults.
  * Decode registers for the architecture actually present. The ARMv8-M MPU
    is RBAR/RLAR/MAIR; it is not ARMv7-M's RBAR/RASR with TEX/S/C/B/SRD.

References: ARMv7-M ARM (DDI 0403), ARMv8-M ARM (DDI 0553).
"""

import contextlib
from struct import pack, unpack
from typing import override

import gdb

# =============================================================================
# Register addresses
# =============================================================================

# --- SCB (System Control Block) ---
SCB_CPUID = 0xE000ED00
SCB_ICSR = 0xE000ED04
SCB_VTOR = 0xE000ED08
SCB_AIRCR = 0xE000ED0C
SCB_CCR = 0xE000ED14
SCB_SHPR1 = 0xE000ED18  # byte n-4 holds priority of exception n (4..15)
SCB_SHCSR = 0xE000ED24
SCB_CFSR = 0xE000ED28
SCB_HFSR = 0xE000ED2C
SCB_DFSR = 0xE000ED30
SCB_MMFAR = 0xE000ED34
SCB_BFAR = 0xE000ED38

# Priority byte for system exception n (4 <= n <= 15) lives at SHPR_BYTE_BASE+n.
SHPR_BYTE_BASE = SCB_SHPR1 - 4

# --- NVIC ---
NVIC_ICTR = 0xE000E004
NVIC_ISER_BASE = 0xE000E100  # read-back gives enable state
NVIC_ISPR_BASE = 0xE000E200  # read-back gives pending state
NVIC_IABR_BASE = 0xE000E300  # active state
NVIC_IPR_BASE = 0xE000E400  # one priority byte per IRQ

# --- MPU (ARMv7-M and ARMv8-M share TYPE/CTRL/RNR/RBAR addresses) ---
MPU_TYPE = 0xE000ED90
MPU_CTRL = 0xE000ED94
MPU_RNR = 0xE000ED98
MPU_RBAR = 0xE000ED9C
MPU_RASR = 0xE000EDA0  # ARMv7-M only
MPU_RLAR = 0xE000EDA0  # ARMv8-M: same address, entirely different register
MPU_MAIR0 = 0xE000EDC0  # ARMv8-M only
MPU_MAIR1 = 0xE000EDC4

# --- SysTick ---
SYST_CSR = 0xE000E010
SYST_RVR = 0xE000E014
SYST_CVR = 0xE000E018

# =============================================================================
# Decode tables
# =============================================================================

MMFSR_BITS = {
    0: ("IACCVIOL", "instruction fetch from a region that forbids execution"),
    1: ("DACCVIOL", "data access violated region permissions"),
    3: ("MUNSTKERR", "fault unstacking on exception return"),
    4: ("MSTKERR", "fault stacking on exception entry (stack overflow?)"),
    5: ("MLSPERR", "fault during FP lazy state preservation"),
    7: ("MMARVALID", "MMFAR holds the faulting address"),
}

BFSR_BITS = {
    0: ("IBUSERR", "bus error on instruction fetch"),
    1: ("PRECISERR", "precise data bus error - BFAR is exact"),
    2: ("IMPRECISERR", "imprecise data bus error - PC and BFAR are NOT reliable"),
    3: ("UNSTKERR", "bus error unstacking on exception return"),
    4: ("STKERR", "bus error stacking on exception entry (stack overflow?)"),
    5: ("LSPERR", "bus error during FP lazy state preservation"),
    7: ("BFARVALID", "BFAR holds the faulting address"),
}

UFSR_BITS = {
    0: ("UNDEFINSTR", "undefined instruction - corrupt PC or wrong instruction set"),
    1: ("INVSTATE", "invalid EPSR state - branched to an address with Thumb bit clear"),
    2: ("INVPC", "illegal EXC_RETURN - corrupt stacked LR"),
    3: ("NOCP", "coprocessor access with FPU/CP disabled"),
    4: ("STKOF", "stack overflow detected by stack limit registers (ARMv8-M)"),
    8: ("UNALIGNED", "unaligned access with CCR.UNALIGN_TRP set"),
    9: ("DIVBYZERO", "integer divide by zero with CCR.DIV_0_TRP set"),
}

HFSR_BITS = {
    1: ("VECTTBL", "bus error reading the vector table - check VTOR"),
    30: ("FORCED", "escalated from a configurable fault - see CFSR below"),
    31: ("DEBUGEVT", "debug event while debug monitor was disabled"),
}

SHCSR_ACT_BITS = {
    0: "MemManage",
    1: "BusFault",
    2: "HardFault",  # ARMv8-M only
    3: "UsageFault",
    5: "NMI",  # ARMv8-M only
    7: "SVCall",
    8: "DebugMonitor",
    10: "PendSV",
    11: "SysTick",
}

SHCSR_PEND_BITS = {
    12: "UsageFault",
    13: "MemManage",
    14: "BusFault",
    15: "SVCall",
    20: "SecureFault",  # ARMv8-M
    21: "HardFault",  # ARMv8-M
}

CPUID_PARTS = {
    0xC20: ("Cortex-M0", 6),
    0xC21: ("Cortex-M1", 6),
    0xC23: ("Cortex-M3", 7),
    0xC24: ("Cortex-M4", 7),
    0xC27: ("Cortex-M7", 7),
    0xC60: ("Cortex-M0+", 6),
    0xD20: ("Cortex-M23", 8),
    0xD21: ("Cortex-M33", 8),
    0xD22: ("Cortex-M55", 8),
    0xD23: ("Cortex-M85", 8),
}

SYSTEM_EXCEPTIONS = {
    0: "Initial SP",
    1: "Reset",
    2: "NMI",
    3: "HardFault",
    4: "MemManage",
    5: "BusFault",
    6: "UsageFault",
    7: "SecureFault",
    11: "SVCall",
    12: "DebugMonitor",
    14: "PendSV",
    15: "SysTick",
}

# Exceptions that mean "we are handling a fault right now".
FAULT_EXCEPTIONS = {3, 4, 5, 6, 7}

# --- ARMv7-M MPU RASR decode ---
V7_MPU_AP = {
    0b000: "no access",
    0b001: "RW priv-only",
    0b010: "RW priv / RO unpriv",
    0b011: "RW any",
    0b101: "RO priv-only",
    0b110: "RO any",
    0b111: "RO any",
}

V7_MPU_MEM_TYPES = {
    (0b000, 0, 0): "Strongly-ordered",
    (0b000, 0, 1): "Device, shareable",
    (0b000, 1, 0): "Normal, write-through",
    (0b000, 1, 1): "Normal, write-back, no write-allocate",
    (0b001, 0, 0): "Normal, non-cacheable",
    (0b001, 1, 1): "Normal, write-back, write-allocate",
    (0b010, 0, 0): "Device, non-shareable",
}

# --- ARMv8-M MPU RBAR decode ---
V8_MPU_AP = {
    0b00: "RW priv-only",
    0b01: "RW any",
    0b10: "RO priv-only",
    0b11: "RO any",
}

V8_MPU_SH = {0b00: "non-shareable", 0b01: "?reserved", 0b10: "outer-shareable", 0b11: "inner-shareable"}

V8_DEVICE_ATTRS = {0b00: "Device-nGnRnE", 0b01: "Device-nGnRE", 0b10: "Device-nGRE", 0b11: "Device-GRE"}

# Magic-number thresholds pulled out so lint stays quiet and intent is clear.
KB = 1024
ARCH_V8 = 8
ARCH_V6 = 6
EXC_RETURN_TAG = 0xFF000000
V7_MIN_SIZE_EXP = 4
MAX_IRQS = 496


# =============================================================================
# Low-level access
# =============================================================================


def _read_reg32(addr):
    data = gdb.selected_inferior().read_memory(addr, 4)
    return unpack("<I", bytes(data))[0]


def _write_reg32(addr, val):
    gdb.selected_inferior().write_memory(addr, pack("<I", val & 0xFFFFFFFF))


def _read_words(addr, count):
    """Read `count` consecutive 32-bit words in one transaction."""
    data = bytes(gdb.selected_inferior().read_memory(addr, count * 4))
    return list(unpack(f"<{count}I", data))


def _cpu_reg(name):
    """Read a CPU register by GDB name. Returns None if unavailable."""
    try:
        return int(gdb.parse_and_eval(f"${name}")) & 0xFFFFFFFF
    except (gdb.error, ValueError):
        return None


def _fmt_size(nbytes):
    if nbytes >= KB * KB:
        return f"{nbytes / (KB * KB):.10g} MB"
    if nbytes >= KB:
        return f"{nbytes / KB:.10g} KB"
    return f"{nbytes} B"


def _header(title):
    print(f"\n── {title} " + "─" * max(0, 58 - len(title)))


def _symbolize(addr, *, thumb=False):
    """
    Return " <symbol at file:line>" for an address, or "" if unresolvable.

    Returning "" rather than the hex string keeps the caller from printing
    the same number twice, which is what made the old output look broken.
    """
    if thumb:
        addr &= ~1
    name = ""
    with contextlib.suppress(gdb.error):
        out = gdb.execute(f"info symbol 0x{addr:08X}", to_string=True).strip()
        if out and "No symbol" not in out:
            name = out.split(" in section")[0]

    where = ""
    with contextlib.suppress(gdb.error):
        sal = gdb.find_pc_line(addr)
        if sal.symtab is not None and sal.line:
            where = f" at {sal.symtab.filename}:{sal.line}"

    if not name and not where:
        return ""
    return f"  <{name}{where}>"


def _cpu_info():
    """Return (raw_cpuid, part_name, arch_major, revision_string)."""
    cpuid = _read_reg32(SCB_CPUID)
    partno = (cpuid >> 4) & 0xFFF
    part, arch = CPUID_PARTS.get(partno, (f"unknown part 0x{partno:03X}", 7))
    rev = f"r{(cpuid >> 20) & 0xF}p{cpuid & 0xF}"
    return cpuid, part, arch, rev


def _exception_name(num):
    if num == 0:
        return "Thread mode"
    if num in SYSTEM_EXCEPTIONS:
        return SYSTEM_EXCEPTIONS[num]
    return f"IRQ{num - 16}"


def _current_exception():
    """Return the IPSR exception number, or None if xPSR is unreadable."""
    xpsr = _cpu_reg("xpsr")
    return None if xpsr is None else xpsr & 0x1FF


# =============================================================================
# cortex-fault
# =============================================================================


def _find_exc_return():
    """
    Locate a live EXC_RETURN value by walking frames outward from the newest.

    LR only holds EXC_RETURN at handler entry; once the handler pushes LR and
    calls out, it does not. Rather than assume, search the unwound frames for
    an LR tagged 0xFFxxxxxx. Returns (exc_return, frame_description) or
    (None, None).
    """
    try:
        frame = gdb.newest_frame()
    except gdb.error:
        return None, None

    depth = 0
    max_depth = 32
    while frame is not None and depth < max_depth:
        try:
            lr = int(frame.read_register("lr")) & 0xFFFFFFFF
        except (gdb.error, ValueError):
            lr = 0
        if lr & EXC_RETURN_TAG == EXC_RETURN_TAG:
            return lr, frame.name() or f"frame #{depth}"
        try:
            frame = frame.older()
        except gdb.error:
            return None, None
        depth += 1
    return None, None


def _decode_exc_return(exc_return, arch):
    """Return (stack_name, is_extended_frame, notes)."""
    use_psp = bool(exc_return & (1 << 2))
    to_thread = bool(exc_return & (1 << 3))
    standard = bool(exc_return & (1 << 4))  # FType: 1 = basic frame

    notes = [f"returns to {'Thread' if to_thread else 'Handler'} mode"]
    if arch >= ARCH_V8:
        notes.append(f"S={int(bool(exc_return & (1 << 6)))}")
        notes.append(f"ES={int(bool(exc_return & 1))}")
    return ("PSP" if use_psp else "MSP"), (not standard), notes


def _print_frame(sp, *, extended, arch):
    """Print an exception stack frame. Returns the pre-exception SP."""
    basic = ["R0", "R1", "R2", "R3", "R12", "LR", "PC", "xPSR"]
    words = _read_words(sp, 8)
    for name, val in zip(basic, words, strict=True):
        extra = ""
        if name == "LR":
            extra = _symbolize(val, thumb=True) or ""
            extra = f"{extra}   (return address)" if extra else "   (return address)"
        elif name == "PC":
            extra = _symbolize(val)
        elif name == "xPSR":
            interrupted = val & 0x1FF
            thumb_bit = "T" if val & (1 << 24) else "!T"
            extra = f"   [{_exception_name(interrupted)}, {thumb_bit}]"
        print(f"    {name:>4s}  0x{val:08X}{extra}")

    frame_words = 8
    if extended:
        frame_words = 26  # 8 basic + S0-S15 + FPSCR + reserved
        fpu = _read_words(sp + 32, 18)
        print("    --- FPU extended frame (EXC_RETURN.FType=0) ---")
        for i in range(16):
            print(f"      S{i:<3d} 0x{fpu[i]:08X}")
        print(f"    FPSCR  0x{fpu[16]:08X}")

    stacked_xpsr = words[7]
    realigned = bool(stacked_xpsr & (1 << 9))
    pre_sp = sp + frame_words * 4 + (4 if realigned else 0)
    align_note = " (+4 SPREALIGN padding)" if realigned else ""
    print(f"\n    Pre-exception SP = 0x{pre_sp:08X}{align_note}")
    if arch >= ARCH_V8 and extended:
        print("    Note: a secure->non-secure transition adds additional state; "
              "frame size may be larger than assumed.")
    return pre_sp


def _decode_cfsr(cfsr):
    """Print CFSR sub-register decode. Returns True if anything was set."""
    mmfsr = cfsr & 0xFF
    bfsr = (cfsr >> 8) & 0xFF
    ufsr = (cfsr >> 16) & 0xFFFF

    for label, value, table, far_bit, far_addr, far_name in (
        ("MemManage (MMFSR)", mmfsr, MMFSR_BITS, 7, SCB_MMFAR, "MMFAR"),
        ("BusFault (BFSR)", bfsr, BFSR_BITS, 7, SCB_BFAR, "BFAR"),
        ("UsageFault (UFSR)", ufsr, UFSR_BITS, None, None, None),
    ):
        if not value:
            continue
        print(f"  {label} = 0x{value:02X}")
        for bit, (name, desc) in sorted(table.items()):
            if value & (1 << bit):
                print(f"    {name:<12s} {desc}")
        if far_bit is not None and value & (1 << far_bit):
            far = _read_reg32(far_addr)
            print(f"    {far_name:<12s} 0x{far:08X}{_symbolize(far)}")
        elif far_name is not None:
            print(f"    {far_name:<12s} not valid - faulting address unknown")

    return bool(cfsr)


class CortexMFault(gdb.Command):
    """
    Triage a Cortex-M fault: verdict first, then evidence.

    Usage:
      cortex-fault           decode fault state and, if in a fault handler,
                             the exception frame
      cortex-fault <sp>      decode a frame at an explicit stack pointer
                             (for post-mortem dumps or a saved ESF)
      cortex-fault clear     clear the sticky CFSR/HFSR bits

    Reports "no fault" when there is no fault. Refuses to decode an
    exception frame unless a real EXC_RETURN (0xFFxxxxxx) is found or you
    supply the stack pointer yourself.
    """

    def __init__(self):
        super().__init__("cortex-fault", gdb.COMMAND_USER)

    @override
    def invoke(self, argument, from_tty):
        args = gdb.string_to_argv(argument)

        try:
            cpuid, part, arch, rev = _cpu_info()
        except gdb.MemoryError:
            print("cortex-fault: cannot read CPUID - is a target connected and halted?")
            return

        if args and args[0] == "clear":
            self._clear(arch)
            return

        has_cfsr = arch >= 7  # ARMv6-M has no configurable faults
        cfsr = _read_reg32(SCB_CFSR) if has_cfsr else 0
        hfsr = _read_reg32(SCB_HFSR)
        dfsr = _read_reg32(SCB_DFSR)
        shcsr = _read_reg32(SCB_SHCSR)
        ipsr = _current_exception()

        self._verdict(part, rev, ipsr, cfsr, hfsr, shcsr, has_cfsr=has_cfsr)

        if cfsr or hfsr:
            _header("Fault status")
            if hfsr:
                print(f"  HFSR = 0x{hfsr:08X}")
                for bit, (name, desc) in sorted(HFSR_BITS.items()):
                    if hfsr & (1 << bit):
                        print(f"    {name:<12s} {desc}")
            if has_cfsr and cfsr:
                _decode_cfsr(cfsr)
            print("\n  (CFSR/HFSR are sticky, write-1-to-clear: "
                  "'cortex-fault clear' to reset)")

        self._frame_section(args, arch, ipsr, dfsr)

    @staticmethod
    def _verdict(part, rev, ipsr, cfsr, hfsr, shcsr, *, has_cfsr):
        """Print the one-thing-you-need-to-know line."""
        pending = [
            name for bit, name in SHCSR_PEND_BITS.items() if shcsr & (1 << bit)
        ]

        if ipsr in FAULT_EXCEPTIONS:
            state = f"IN {_exception_name(ipsr)} HANDLER"
        elif cfsr or hfsr:
            state = "no active fault, but sticky fault bits are set from an earlier fault"
        elif pending:
            state = f"fault pending (not yet taken): {', '.join(pending)}"
        else:
            state = "NO FAULT"

        mode = "unknown mode" if ipsr is None else _exception_name(ipsr)
        print(f"\n{state}")
        print(f"  {part} {rev}, currently in {mode}")
        if not has_cfsr:
            print("  ARMv6-M: no CFSR/MMFAR/BFAR on this core")
        if not (cfsr or hfsr) and ipsr not in FAULT_EXCEPTIONS:
            print(f"  CFSR = 0x{cfsr:08X}, HFSR = 0x{hfsr:08X}")

    def _frame_section(self, args, arch, ipsr, dfsr):
        """Decode an exception frame only when one demonstrably exists."""
        explicit_sp = None
        if args and args[0] != "clear":
            try:
                explicit_sp = int(gdb.parse_and_eval(args[0])) & 0xFFFFFFFF
            except gdb.error as exc:
                print(f"cortex-fault: cannot evaluate '{args[0]}': {exc}")
                return

        if explicit_sp is not None:
            _header(f"Frame at 0x{explicit_sp:08X} (as given)")
            self._safe_frame(explicit_sp, extended=False, arch=arch)
            print("    Assumed a basic 8-word frame; if the FPU frame was stacked, "
                  "S0-S15/FPSCR follow at +0x20.")
            return

        exc_return, where = _find_exc_return()
        if exc_return is None:
            _header("Exception frame")
            if ipsr == 0:
                print("  Core is in Thread mode - no exception frame is stacked.")
            else:
                print("  No EXC_RETURN found in the unwound frames.")
            if dfsr & 1:
                print("  (DFSR.HALTED is set simply because the debugger halted the "
                      "core - it is not a fault.)")
            print("  Pass a stack pointer explicitly if you have one: "
                  "cortex-fault $psp")
            return

        stack, extended, notes = _decode_exc_return(exc_return, arch)
        sp = _cpu_reg("psp" if stack == "PSP" else "msp")
        _header("Exception frame")
        print(f"  EXC_RETURN = 0x{exc_return:08X} (from {where}) - "
              f"{', '.join(notes)}")
        if sp is None:
            print(f"  Frame is on {stack}, but GDB will not give me ${stack.lower()}.")
            return
        print(f"  Frame is on {stack} = 0x{sp:08X}\n")
        self._safe_frame(sp, extended=extended, arch=arch)

    @staticmethod
    def _safe_frame(sp, *, extended, arch):
        try:
            _print_frame(sp, extended=extended, arch=arch)
        except gdb.MemoryError:
            print(f"    cannot read the frame at 0x{sp:08X} - "
                  "address is not mapped or the stack pointer is corrupt")

    @staticmethod
    def _clear(arch):
        try:
            if arch >= 7:
                _write_reg32(SCB_CFSR, 0xFFFFFFFF)
            _write_reg32(SCB_HFSR, 0xFFFFFFFF)
        except gdb.MemoryError:
            print("cortex-fault: write failed")
            return
        print("Cleared CFSR and HFSR.")


# =============================================================================
# cortex-irq
# =============================================================================


def _probe_prio_bits():
    """
    Determine how many priority bits the implementation provides.

    Writes 0xFF to the SVCall priority byte, reads back the implemented bits,
    then restores. Safe while halted: no exception can be taken. Returns None
    if the probe is inconclusive.
    """
    addr = SHPR_BYTE_BASE + 8  # SHPR2 word; SVCall is its top byte
    try:
        orig = _read_reg32(addr)
        _write_reg32(addr, orig | 0xFF000000)
        readback = (_read_reg32(addr) >> 24) & 0xFF
        _write_reg32(addr, orig)
    except gdb.MemoryError:
        return None
    if readback == 0:
        return None
    return bin(readback).count("1")


def _prigroup_split(prigroup, prio_bits):
    """Return (group_levels, sub_levels) implied by AIRCR.PRIGROUP."""
    if prio_bits is None:
        return None, None
    lowest_implemented = 8 - prio_bits
    group_bits = 8 - max(prigroup + 1, lowest_implemented)
    group_bits = max(0, min(group_bits, prio_bits))
    return 1 << group_bits, 1 << (prio_bits - group_bits)


class CortexMIrq(gdb.Command):
    """
    Show interrupt and exception state: what is masked, pending, and active.

    Usage:
      cortex-irq          system exceptions plus every external IRQ that is
                          enabled, pending, or active
      cortex-irq --all    every implemented external IRQ

    Covers the questions the old commands could not answer: am I masked
    (PRIMASK/FAULTMASK/BASEPRI), which exception am I in, what is pending,
    and which handler does each IRQ actually vector to.
    """

    def __init__(self):
        super().__init__("cortex-irq", gdb.COMMAND_USER)

    @override
    def invoke(self, argument, from_tty):
        show_all = "--all" in argument

        try:
            cpuid, part, arch, rev = _cpu_info()
            vtor = _read_reg32(SCB_VTOR)
            icsr = _read_reg32(SCB_ICSR)
            aircr = _read_reg32(SCB_AIRCR)
            shcsr = _read_reg32(SCB_SHCSR)
        except gdb.MemoryError:
            print("cortex-irq: cannot read SCB - is a target connected and halted?")
            return

        self._print_context(part, rev, vtor, icsr, aircr, arch)
        self._print_masks()
        self._print_system_exceptions(shcsr, icsr, vtor, arch)
        self._print_nvic(vtor, show_all=show_all)
        self._print_systick()

    @staticmethod
    def _print_context(part, rev, vtor, icsr, aircr, arch):
        ipsr = _current_exception()
        control = _cpu_reg("control")

        stack = "?"
        privilege = "?"
        if control is not None:
            stack = "PSP" if control & (1 << 1) else "MSP"
            privilege = "unprivileged" if control & 1 else "privileged"

        print(f"\n{part} {rev} - {_exception_name(ipsr) if ipsr is not None else '?'}"
              f", {stack} active, {privilege}")
        print(f"  VTOR  = 0x{vtor:08X}")

        prio_bits = _probe_prio_bits()
        prigroup = (aircr >> 8) & 0x7
        groups, subs = _prigroup_split(prigroup, prio_bits)
        bits_txt = f"{prio_bits} implemented priority bits" if prio_bits else "priority bit count unknown"
        split_txt = (
            f" -> {groups} preemption levels x {subs} sub-priorities"
            if groups is not None
            else ""
        )
        print(f"  AIRCR = 0x{aircr:08X}  PRIGROUP={prigroup}, {bits_txt}{split_txt}")

        vectactive = icsr & 0x1FF
        vectpending = (icsr >> 12) & 0x1FF
        flags = []
        if icsr & (1 << 22):
            flags.append("ISRPENDING")
        if icsr & (1 << 26):
            flags.append("SysTick pending")
        if icsr & (1 << 28):
            flags.append("PendSV pending")
        if icsr & (1 << 31):
            flags.append("NMI pending")
        print(f"  ICSR  = 0x{icsr:08X}  active={_exception_name(vectactive)}, "
              f"pending={_exception_name(vectpending)}"
              + (f", {', '.join(flags)}" if flags else ""))

    @staticmethod
    def _print_masks():
        primask = _cpu_reg("primask")
        faultmask = _cpu_reg("faultmask")
        basepri = _cpu_reg("basepri")

        parts = []
        blocked = []
        if primask is not None:
            parts.append(f"PRIMASK={primask & 1}")
            if primask & 1:
                blocked.append("PRIMASK blocks all exceptions except NMI and HardFault")
        if faultmask is not None:
            parts.append(f"FAULTMASK={faultmask & 1}")
            if faultmask & 1:
                blocked.append("FAULTMASK blocks everything except NMI")
        if basepri is not None:
            parts.append(f"BASEPRI=0x{basepri & 0xFF:02X}")
            if basepri & 0xFF:
                blocked.append(
                    f"BASEPRI blocks priorities numerically >= 0x{basepri & 0xFF:02X}"
                )

        if not parts:
            return
        print(f"  Masks: {', '.join(parts)}")
        for line in blocked:
            print(f"         ! {line}")
        if not blocked:
            print("         no masking in effect")

    @staticmethod
    def _vector_handler(vtor, exc_num):
        try:
            handler = _read_reg32(vtor + exc_num * 4)
        except gdb.MemoryError:
            return ""
        return _symbolize(handler, thumb=True)

    @staticmethod
    def _print_system_exceptions(shcsr, icsr, vtor, arch):
        _header("System exceptions")
        try:
            shpr = _read_words(SCB_SHPR1, 3)
        except gdb.MemoryError:
            shpr = None

        active_bits = {
            bit: name
            for bit, name in SHCSR_ACT_BITS.items()
            if arch >= ARCH_V8 or bit not in {2, 5}
        }
        active = {name for bit, name in active_bits.items() if shcsr & (1 << bit)}
        pending = {
            name for bit, name in SHCSR_PEND_BITS.items() if shcsr & (1 << bit)
        }
        if icsr & (1 << 26):
            pending.add("SysTick")
        if icsr & (1 << 28):
            pending.add("PendSV")
        if icsr & (1 << 31):
            pending.add("NMI")

        enables = {
            "MemManage": shcsr & (1 << 16),
            "BusFault": shcsr & (1 << 17),
            "UsageFault": shcsr & (1 << 18),
            "SecureFault": shcsr & (1 << 19),
        }

        print(f"  SHCSR = 0x{shcsr:08X}")
        print(f"  {'Exc':>3s}  {'Name':<13s} {'Pri':>5s}  State      Handler")
        for num in sorted(SYSTEM_EXCEPTIONS):
            if num < 2 or (num == 7 and arch < ARCH_V8):  # noqa: PLR2004
                continue
            name = SYSTEM_EXCEPTIONS[num]
            if num in {2, 3}:
                prio = "-14" if num == 2 else "-13"  # noqa: PLR2004
            elif shpr is None:
                prio = "?"
            else:
                byte = (shpr[(num - 4) // 4] >> (8 * ((num - 4) % 4))) & 0xFF
                prio = f"0x{byte:02X}"

            state = []
            if name in active:
                state.append("ACTIVE")
            if name in pending:
                state.append("PENDING")
            if name in enables and not enables[name]:
                state.append("disabled")
            state_txt = ",".join(state) if state else "-"

            print(f"  {num:3d}  {name:<13s} {prio:>5s}  {state_txt:<10s}"
                  f"{CortexMIrq._vector_handler(vtor, num)}")

    @staticmethod
    def _print_nvic(vtor, *, show_all):
        try:
            ictr = _read_reg32(NVIC_ICTR)
        except gdb.MemoryError:
            print("  (NVIC unreadable)")
            return

        num_irqs = min((ictr + 1) * 32, MAX_IRQS)
        nwords = (num_irqs + 31) // 32

        try:
            enable = _read_words(NVIC_ISER_BASE, nwords)
            pend = _read_words(NVIC_ISPR_BASE, nwords)
            active = _read_words(NVIC_IABR_BASE, nwords)
            prio = _read_words(NVIC_IPR_BASE, num_irqs // 4)
        except gdb.MemoryError:
            print("  (NVIC register read failed)")
            return

        _header(f"External IRQs (ICTR implies up to {num_irqs} lines)")
        print(f"  {'IRQ':>4s}  En Pnd Act   {'Pri':>5s}  Handler")

        shown = 0
        for irq in range(num_irqs):
            word, bit = divmod(irq, 32)
            en = (enable[word] >> bit) & 1
            pn = (pend[word] >> bit) & 1
            ac = (active[word] >> bit) & 1
            if not (show_all or en or pn or ac):
                continue
            pri = (prio[irq // 4] >> (8 * (irq % 4))) & 0xFF
            marks = f"{'*' if en else '.'}   {'*' if pn else '.'}   {'*' if ac else '.'}"
            print(f"  {irq:4d}  {marks}   0x{pri:02X}"
                  f"{CortexMIrq._vector_handler(vtor, irq + 16)}")
            shown += 1

        if not shown:
            print("  (no IRQ enabled, pending, or active - use --all)")

    @staticmethod
    def _print_systick():
        try:
            csr = _read_reg32(SYST_CSR)
            rvr = _read_reg32(SYST_RVR)
            cvr = _read_reg32(SYST_CVR)
        except gdb.MemoryError:
            return
        state = "on" if csr & 1 else "OFF"
        tickint = "IRQ on" if csr & (1 << 1) else "IRQ off"
        src = "core clock" if csr & (1 << 2) else "external ref"
        print(f"\n  SysTick: {state}, {tickint}, {src}, "
              f"reload={rvr} current={cvr}")


# =============================================================================
# cortex-mpu
# =============================================================================


def _v8_decode_mair(mair0, mair1, index):
    """Decode one ARMv8-M MAIR attribute byte into a description."""
    word = mair0 if index < 4 else mair1  # noqa: PLR2004
    attr = (word >> (8 * (index % 4))) & 0xFF
    outer = (attr >> 4) & 0xF
    inner = attr & 0xF

    if outer == 0:
        return V8_DEVICE_ATTRS.get(inner >> 2, f"Device?({attr:#04x})")

    def cache(field):
        if field == 0b0100:
            return "non-cacheable"
        policy = "WT" if not (field & 0b1000) else "WB"
        alloc = ""
        if field & 0b0010:
            alloc += "R"
        if field & 0b0001:
            alloc += "W"
        return f"{policy}{'-' + alloc + 'A' if alloc else '-noA'}"

    return f"Normal, outer {cache(outer)}, inner {cache(inner)}"


def _v8_region(index):
    """Read one ARMv8-M MPU region. Returns a dict or None on read error."""
    try:
        _write_reg32(MPU_RNR, index)
        rbar = _read_reg32(MPU_RBAR)
        rlar = _read_reg32(MPU_RLAR)
    except gdb.MemoryError:
        return None
    return {
        "index": index,
        "enabled": bool(rlar & 1),
        "base": rbar & 0xFFFFFFE0,
        "limit": (rlar & 0xFFFFFFE0) | 0x1F,
        "xn": bool(rbar & 1),
        "ap": (rbar >> 1) & 0x3,
        "sh": (rbar >> 3) & 0x3,
        "attrindx": (rlar >> 1) & 0x7,
        "pxn": bool(rlar & (1 << 4)),
        "raw": (rbar, rlar),
    }


def _v7_region(index):
    """Read one ARMv7-M MPU region. Returns a dict or None on read error."""
    try:
        _write_reg32(MPU_RNR, index)
        rbar = _read_reg32(MPU_RBAR)
        rasr = _read_reg32(MPU_RASR)
    except gdb.MemoryError:
        return None
    size_exp = (rasr >> 1) & 0x1F
    size = 1 << (size_exp + 1) if size_exp >= V7_MIN_SIZE_EXP else 0
    base = rbar & 0xFFFFFFE0
    return {
        "index": index,
        "enabled": bool(rasr & 1),
        "base": base,
        "limit": base + size - 1 if size else base,
        "size": size,
        "xn": bool(rasr & (1 << 28)),
        "ap": (rasr >> 24) & 0x7,
        "tex": (rasr >> 19) & 0x7,
        "s": bool(rasr & (1 << 18)),
        "c": (rasr >> 17) & 1,
        "b": (rasr >> 16) & 1,
        "srd": (rasr >> 8) & 0xFF,
        "raw": (rbar, rasr),
    }


class CortexMMpu(gdb.Command):
    """
    Decode MPU regions using the architecture actually present.

    Usage:
      cortex-mpu            list every region
      cortex-mpu <address>  report which region covers an address and the
                            permissions that apply - what you want after a
                            MemManage fault, using MMFAR

    ARMv8-M cores (M23/M33/M55/M85) use RBAR/RLAR with MAIR attributes and
    base/limit addressing. ARMv7-M cores use RBAR/RASR with TEX/S/C/B and
    power-of-two sizes plus sub-region disable. The two are not
    interchangeable.
    """

    def __init__(self):
        super().__init__("cortex-mpu", gdb.COMMAND_USER)

    @override
    def invoke(self, argument, from_tty):
        args = gdb.string_to_argv(argument)

        try:
            cpuid, part, arch, rev = _cpu_info()
            mpu_type = _read_reg32(MPU_TYPE)
            ctrl = _read_reg32(MPU_CTRL)
        except gdb.MemoryError:
            print("cortex-mpu: cannot read MPU - is a target connected and halted?")
            return

        nregions = (mpu_type >> 8) & 0xFF
        if nregions == 0:
            print(f"{part}: no MPU implemented (MPU_TYPE.DREGION = 0)")
            return

        query = None
        if args:
            try:
                query = int(gdb.parse_and_eval(args[0])) & 0xFFFFFFFF
            except gdb.error as exc:
                print(f"cortex-mpu: cannot evaluate '{args[0]}': {exc}")
                return

        v8 = arch >= ARCH_V8
        enabled = bool(ctrl & 1)
        mair = None
        if v8:
            try:
                mair = (_read_reg32(MPU_MAIR0), _read_reg32(MPU_MAIR1))
            except gdb.MemoryError:
                mair = None

        _header(f"MPU - {part} ({'ARMv8-M' if v8 else 'ARMv7-M'}), "
                f"{nregions} regions, {'ENABLED' if enabled else 'DISABLED'}")
        print(f"  MPU_CTRL = 0x{ctrl:08X}  "
              f"PRIVDEFENA={'on' if ctrl & (1 << 2) else 'off'}, "
              f"HFNMIENA={'on' if ctrl & (1 << 1) else 'off'}")
        if not enabled:
            print("  ! MPU is off: no region below is being enforced.")

        # MPU_RNR is part of the target's state - restore whatever the
        # firmware left there.
        saved_rnr = None
        with contextlib.suppress(gdb.MemoryError):
            saved_rnr = _read_reg32(MPU_RNR)

        try:
            regions = [
                (_v8_region(i) if v8 else _v7_region(i)) for i in range(nregions)
            ]
        finally:
            if saved_rnr is not None:
                with contextlib.suppress(gdb.MemoryError):
                    _write_reg32(MPU_RNR, saved_rnr)

        if query is None:
            self._list(regions, mair, v8=v8)
        else:
            self._lookup(query, regions, mair, ctrl, v8=v8, enabled=enabled)

    @staticmethod
    def _describe(region, mair, *, v8):
        if v8:
            attrs = (
                _v8_decode_mair(mair[0], mair[1], region["attrindx"])
                if mair
                else f"AttrIndx={region['attrindx']}"
            )
            perms = V8_MPU_AP[region["ap"]]
            extra = f"{V8_MPU_SH[region['sh']]}"
            if region["pxn"]:
                extra += ", PXN"
        else:
            attrs = V7_MPU_MEM_TYPES.get(
                (region["tex"], region["c"], region["b"]),
                f"TEX={region['tex']} C={region['c']} B={region['b']}",
            )
            perms = V7_MPU_AP.get(region["ap"], f"AP={region['ap']}")
            extra = "shareable" if region["s"] else "non-shareable"
        return perms, attrs, extra

    @classmethod
    def _list(cls, regions, mair, *, v8):
        print()
        for region in regions:
            if region is None:
                print("  [?] <read error>")
                continue
            if not region["enabled"]:
                print(f"  [{region['index']}] off")
                continue
            perms, attrs, extra = cls._describe(region, mair, v8=v8)
            size = region["limit"] - region["base"] + 1
            xn = "XN" if region["xn"] else "  "
            print(f"  [{region['index']}] 0x{region['base']:08X}-0x{region['limit']:08X}"
                  f"  {_fmt_size(size):>9s}  {perms:<14s} {xn}  {attrs}, {extra}")
            if not v8 and region["srd"]:
                disabled = [str(i) for i in range(8) if region["srd"] & (1 << i)]
                print(f"        SRD=0b{region['srd']:08b} "
                      f"(sub-regions disabled: {', '.join(disabled)})")

    @classmethod
    def _lookup(cls, addr, regions, mair, ctrl, *, v8, enabled):
        print(f"\n  Looking up 0x{addr:08X}{_symbolize(addr)}")

        matches = []
        for region in regions:
            if region is None or not region["enabled"]:
                continue
            if not (region["base"] <= addr <= region["limit"]):
                continue
            if not v8 and region["srd"]:
                # Sub-regions only exist for regions of 256 bytes or more.
                size = region["limit"] - region["base"] + 1
                if size >= 256:  # noqa: PLR2004
                    sub = (addr - region["base"]) * 8 // size
                    if region["srd"] & (1 << sub):
                        print(f"  [{region['index']}] covers it but sub-region "
                              f"{sub} is disabled - region does not apply")
                        continue
            matches.append(region)

        if not matches:
            print("  No enabled region covers this address.")
            if ctrl & (1 << 2):
                print("  PRIVDEFENA is on: privileged accesses fall back to the "
                      "default memory map; unprivileged accesses fault.")
            else:
                print("  PRIVDEFENA is off: any access faults (MemManage).")
            return

        for region in matches:
            perms, attrs, extra = cls._describe(region, mair, v8=v8)
            print(f"  [{region['index']}] 0x{region['base']:08X}-0x{region['limit']:08X}"
                  f"  {perms}, {'no execute' if region['xn'] else 'executable'}, "
                  f"{attrs}, {extra}")

        if len(matches) > 1:
            if v8:
                print("  ! Overlapping enabled regions are UNPREDICTABLE on ARMv8-M.")
            else:
                print(f"  Highest-numbered region wins on ARMv7-M: "
                      f"region {matches[-1]['index']} applies.")
        if not enabled:
            print("  ! MPU_CTRL.ENABLE is 0, so none of this is enforced right now.")


# =============================================================================
# Registration
# =============================================================================

CortexMFault()
CortexMIrq()
CortexMMpu()

print("Cortex-M helpers: cortex-fault, cortex-irq, cortex-mpu ('help <cmd>' for usage)")
