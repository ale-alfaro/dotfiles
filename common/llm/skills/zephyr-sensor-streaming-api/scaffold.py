#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.9"
# dependencies = [
#   "jinja2>=3.1",
# ]
# ///
"""
Scaffold a Zephyr RTIO sensor driver.

Generates driver sources, Kconfig + CMake, devicetree binding, and (by default)
a sample app, matching the patterns documented in SKILL.md.

Usage:
  scaffold.py --vendor <vendor> --chip <chip> --bus {i2c,spi} \\
              --channels accel,gyro,q31:<label>:<SENSOR_CHAN_*> \\
              --out <path> [--no-stream] [--no-sample] [--dry-run] [--force]

The script is dispatched via `uv run --script` so the jinja2 dependency
is resolved transparently. No global install required.
"""
from __future__ import annotations

import argparse
import datetime
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

from jinja2 import Environment, FileSystemLoader, StrictUndefined


# ----------------------------------------------------------------------------
# Data model
# ----------------------------------------------------------------------------


TOKEN_RE = re.compile(r"^[a-z][a-z0-9_]*$")


@dataclass(frozen=True)
class Channel:
    """One sensor channel the generated decoder will handle."""

    token: str            # "accel" | "gyro" | "q31"
    label: str            # human-friendly tag used in sample printk's
    chan_macro: str       # SENSOR_CHAN_*
    data_struct: str      # output struct (e.g. sensor_three_axis_data)
    sample_data_struct: str  # per-frame struct (e.g. sensor_three_axis_sample_data)

    @property
    def is_three_axis(self) -> bool:
        return self.token in ("accel", "gyro")


def parse_channel(spec: str) -> Channel:
    """Parse one --channels token. Supported forms:

       accel
       gyro
       q31:<label>:<SENSOR_CHAN_*>
    """
    if spec == "accel":
        return Channel(
            token="accel",
            label="accel",
            chan_macro="SENSOR_CHAN_ACCEL_XYZ",
            data_struct="sensor_three_axis_data",
            sample_data_struct="sensor_three_axis_sample_data",
        )
    if spec == "gyro":
        return Channel(
            token="gyro",
            label="gyro",
            chan_macro="SENSOR_CHAN_GYRO_XYZ",
            data_struct="sensor_three_axis_data",
            sample_data_struct="sensor_three_axis_sample_data",
        )
    if spec.startswith("q31:"):
        parts = spec.split(":")
        if len(parts) != 3:
            raise ValueError(
                f"q31 channel must be 'q31:<label>:<SENSOR_CHAN_*>', got: {spec!r}"
            )
        _, label, chan_macro = parts
        if not label:
            raise ValueError(f"q31 channel label is empty in: {spec!r}")
        if not chan_macro.startswith("SENSOR_CHAN_"):
            raise ValueError(
                f"q31 channel macro must start with SENSOR_CHAN_, got: {chan_macro!r}"
            )
        return Channel(
            token="q31",
            label=label,
            chan_macro=chan_macro,
            data_struct="sensor_q31_data",
            sample_data_struct="sensor_q31_sample_data",
        )
    raise ValueError(f"Unknown channel spec: {spec!r}")


# ----------------------------------------------------------------------------
# CLI
# ----------------------------------------------------------------------------


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    p = argparse.ArgumentParser(
        description="Scaffold a Zephyr RTIO sensor driver. See SKILL.md.",
    )
    p.add_argument("--vendor", required=True, help="Lowercase vendor token (e.g. acme).")
    p.add_argument("--chip", required=True, help="Lowercase chip token (e.g. acme3).")
    p.add_argument("--bus", required=True, choices=("i2c", "spi"))
    p.add_argument(
        "--channels",
        required=True,
        help="Comma-separated channels: accel,gyro,q31:<label>:<SENSOR_CHAN_*>",
    )
    p.add_argument("--out", required=True, help="Workspace root to write under.")
    p.add_argument(
        "--no-stream",
        action="store_true",
        help="Skip stream/trigger sources, the streaming Kconfig, and int-gpios.",
    )
    p.add_argument(
        "--no-sample", action="store_true", help="Skip sample-app generation."
    )
    p.add_argument(
        "--dry-run",
        action="store_true",
        help="Print files that would be written, then exit.",
    )
    p.add_argument("--force", action="store_true", help="Overwrite existing files.")
    p.add_argument(
        "--only",
        default="",
        help=(
            "Comma-separated subset of targets to generate (e.g. "
            "'chip_decoder.c,binding.yaml'). Use --list-targets to enumerate."
        ),
    )
    p.add_argument(
        "--list-targets",
        action="store_true",
        help="Print the targets that would be generated with the given flags and exit.",
    )
    return p.parse_args(argv)


def validate_token(name: str, kind: str) -> None:
    if not TOKEN_RE.match(name):
        raise SystemExit(
            f"--{kind} must match [a-z][a-z0-9_]*, got: {name!r}"
        )


# ----------------------------------------------------------------------------
# Render context
# ----------------------------------------------------------------------------


def build_context(args: argparse.Namespace, channels: list[Channel]) -> dict:
    vendor = args.vendor
    chip = args.chip
    streaming = not args.no_stream

    bus = args.bus
    if bus == "i2c":
        bus_iodev_macro = "I2C_DT_IODEV_DEFINE"
        bus_dt_spec = "i2c_dt_spec"
        bus_spec_get = "I2C_DT_SPEC_INST_GET"
        bus_ready_check = "i2c_is_ready_dt"
    else:
        bus_iodev_macro = "SPI_DT_IODEV_DEFINE"
        bus_dt_spec = "spi_dt_spec"
        bus_spec_get = "SPI_DT_SPEC_INST_GET"
        bus_ready_check = "spi_is_ready_dt"

    return {
        "year": datetime.date.today().year,
        "vendor": vendor,
        "chip": chip,
        "vendor_upper": vendor.upper(),
        "chip_upper": chip.upper(),
        "compat_dash": f"{vendor},{chip}",
        "compat_under": f"{vendor}_{chip}",
        "bus": bus,
        "bus_upper": bus.upper(),
        "bus_iodev_macro": bus_iodev_macro,
        "bus_dt_spec": bus_dt_spec,
        "bus_spec_get": bus_spec_get,
        "bus_ready_check": bus_ready_check,
        "streaming": streaming,
        "channels": channels,
        # Convenience derived lists for templates that iterate by type
        "three_axis_channels": [c for c in channels if c.is_three_axis],
        "q31_channels": [c for c in channels if not c.is_three_axis],
        # SPDX flag toggles used in templates
        "is_i2c": bus == "i2c",
        "is_spi": bus == "spi",
    }


# ----------------------------------------------------------------------------
# File plan
# ----------------------------------------------------------------------------


@dataclass(frozen=True)
class Plan:
    template: str   # relative path under templates/ (e.g. "chip_decoder.c.j2")
    target: Path    # absolute output path

    @property
    def name(self) -> str:
        """Stable identifier used by --only / --list-targets.

        Equal to the template path minus the trailing '.j2' suffix.
        """
        assert self.template.endswith(".j2")
        return self.template[:-len(".j2")]


def make_plan(args: argparse.Namespace, ctx: dict) -> list[Plan]:
    out = Path(args.out)
    chip = ctx["chip"]
    vendor = ctx["vendor"]
    compat_dash = ctx["compat_dash"]
    streaming = ctx["streaming"]

    drv_dir = out / "drivers" / "sensor" / vendor / chip
    bind_dir = out / "dts" / "bindings" / "sensor"
    sample_dir = out / "samples" / "sensor" / chip

    plan: list[Plan] = [
        Plan("chip.c.j2",            drv_dir / f"{chip}.c"),
        Plan("chip.h.j2",            drv_dir / f"{chip}.h"),
        Plan("chip_rtio.c.j2",       drv_dir / f"{chip}_rtio.c"),
        Plan("chip_decoder.c.j2",    drv_dir / f"{chip}_decoder.c"),
        Plan("Kconfig.j2",           drv_dir / "Kconfig"),
        Plan("CMakeLists.txt.j2",    drv_dir / "CMakeLists.txt"),
        Plan("binding.yaml.j2",      bind_dir / f"{compat_dash}.yaml"),
    ]

    if streaming:
        plan.append(Plan("chip_stream.c.j2",  drv_dir / f"{chip}_stream.c"))
        plan.append(Plan("chip_trigger.c.j2", drv_dir / f"{chip}_trigger.c"))

    if not args.no_sample:
        plan.append(Plan("sample/main.c.j2",        sample_dir / "src" / "main.c"))
        plan.append(Plan("sample/prj.conf.j2",      sample_dir / "prj.conf"))
        plan.append(Plan("sample/sample.yaml.j2",   sample_dir / "sample.yaml"))
        plan.append(Plan("sample/CMakeLists.txt.j2", sample_dir / "CMakeLists.txt"))
        plan.append(Plan("sample/overlay.j2",       sample_dir / "boards" / f"{chip}.overlay"))

    return plan


def check_collisions(plan: Iterable[Plan], force: bool) -> None:
    existing = [p.target for p in plan if p.target.exists()]
    if existing and not force:
        msg = ["Target files already exist (use --force to overwrite):"]
        for path in existing:
            msg.append(f"  {path}")
        raise SystemExit("\n".join(msg))


# ----------------------------------------------------------------------------
# Rendering
# ----------------------------------------------------------------------------


def make_env(templates_dir: Path) -> Environment:
    return Environment(
        loader=FileSystemLoader(str(templates_dir)),
        undefined=StrictUndefined,
        keep_trailing_newline=True,
        trim_blocks=True,
        lstrip_blocks=True,
    )


def render_all(env: Environment, plan: Iterable[Plan], ctx: dict) -> None:
    for item in plan:
        tmpl = env.get_template(item.template)
        rendered = tmpl.render(**ctx)
        item.target.parent.mkdir(parents=True, exist_ok=True)
        item.target.write_text(rendered)


# ----------------------------------------------------------------------------
# main
# ----------------------------------------------------------------------------


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    validate_token(args.vendor, "vendor")
    validate_token(args.chip, "chip")

    try:
        channels = [parse_channel(s.strip()) for s in args.channels.split(",") if s.strip()]
    except ValueError as e:
        raise SystemExit(f"--channels: {e}") from None
    if not channels:
        raise SystemExit("--channels must list at least one channel.")

    ctx = build_context(args, channels)
    plan = make_plan(args, ctx)

    if args.list_targets:
        print("Available targets (use --only to select a subset):")
        for item in plan:
            print(f"  {item.name}")
        return 0

    if args.only:
        requested = {tok.strip() for tok in args.only.split(",") if tok.strip()}
        available = {item.name for item in plan}
        unknown = requested - available
        if unknown:
            raise SystemExit(
                "--only: unknown target(s): "
                + ", ".join(sorted(unknown))
                + "\n(Try --list-targets to see available names.)"
            )
        plan = [item for item in plan if item.name in requested]
        if not plan:
            raise SystemExit("--only filtered out every target; nothing to do.")

    if args.dry_run:
        print("Would write:")
        for item in plan:
            print(f"  {item.target}")
        return 0

    check_collisions(plan, args.force)

    templates_dir = Path(__file__).parent / "templates"
    if not templates_dir.is_dir():
        raise SystemExit(f"templates dir missing: {templates_dir}")

    env = make_env(templates_dir)
    render_all(env, plan, ctx)

    print("Wrote files:")
    for item in plan:
        print(f"  {item.target}")
    print()
    print("Next steps:")
    print("  1. Fill in the TODO markers (chip register addresses, scaling math,")
    print("     FIFO frame layout, attribute handling).")
    print("  2. Walk the completion checklist in SKILL.md before submitting.")
    print("  3. Wire the driver into your workspace build (west.yml, CMake glue).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
