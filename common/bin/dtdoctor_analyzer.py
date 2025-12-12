#!/usr/bin/env -S uv run --script
#
# /// script
# requires-python = ">=3.13"
# dependencies = [
#     "python-dotenv",
#    "rich",
#    "PyYAML",
# ]
# ///

r"""
A script to help diagnose build errors related to Devicetree.

To use this script as a standalone tool, provide the path to an edt.pickle file
(e.g ./build/zephyr/edt.pickle) and a symbol that appeared in the build error
message (e.g. __device_dts_ord_123).

Example usage:

./scripts/dts/dtdoctor_analyzer.py \\
    --edt-pickle ./build/zephyr/edt.pickle \\
    --symbol __device_dts_ord_123

"""

import argparse
import importlib.util
import os
import pickle
import re
import sys
from pathlib import Path
from types import ModuleType

from rich.pretty import pprint

if (zephyr_base := os.environ.get("ZEPHYR_BASE", "")) and Path(zephyr_base).is_dir():
    sys.path.insert(
        0,
        str(Path(zephyr_base) / "scripts" / "dts" / "python-devicetree" / "src"),
    )
    sys.path.insert(0, str(Path(zephyr_base) / "scripts" / "kconfig"))
    pprint("Loaded mods from ZEPHYR_BASE")
else:
    from dotenv import load_dotenv

    if (dotenv := Path().cwd() / ".direnv" / ".env") and dotenv.is_file():
        load_dotenv(dotenv)
        zephyr_base = os.environ.get("ZEPHYR_BASE")
        pprint("Loaded mods from dotenv")
    else:
        raise ImportError
# For illustrative purposes.
mod_names = ["devicetree", "kconfiglib"]
mods = []
# from devicetree import edtlib
devicetree: ModuleType | None = None
kconfiglib: ModuleType | None = None
for name in mod_names:
    if name in sys.modules:
        pprint(f"{name!r} already in sys.modules")
    elif (spec := importlib.util.find_spec(name)) and spec.loader:
        # If you chose to perform the actual import ...
        module = importlib.util.module_from_spec(spec)
        pprint(f"importing {module!r} ")
        sys.modules[name] = module
        mods.append(module)
        spec.loader.exec_module(module)
        pprint(f"{name!r} has been imported")
    else:
        pprint(f"can't find the {name!r} module")

match mods:
    case [devicetree, kconfiglib] if zephyr_base and Path(zephyr_base).is_dir():
        pprint("Loaded zephyr mods")
    case _:
        raise ImportError("Couldn't load zephyr mods")


import kconfiglib
from devicetree import edtlib


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
        allow_abbrev=False,
    )
    parser.add_argument(
        "--edt-pickle",
        required=True,
        help="path to edt.pickle file corresponding to the build to analyze",
    )
    parser.add_argument(
        "--symbol",
        required=True,
        help="symbol for which to obtain troubleshooting information",
    )
    return parser.parse_args()


def load_edt(path: str) -> edtlib.EDT:
    with Path(path).open("rb") as f:
        return pickle.load(f)


def setup_kconfig() -> kconfiglib.Kconfig:
    kconf = kconfiglib.Kconfig(
        Path(zephyr_base) / "Kconfig",
        warn=False,
    )
    return kconf


def format_node(node: edtlib.Node) -> str:
    return f"{node.labels[0]}: {node.path}" if node.labels else node.path


def find_kconfig_deps(kconf: kconfiglib.Kconfig, dt_has_symbol: str) -> set[str]:
    """Find all Kconfig symbols that depend on the provided DT_HAS symbol."""
    prefix = os.environ.get("CONFIG_", "CONFIG_")
    target = f"{prefix}{dt_has_symbol}"
    deps = set()

    def collect_syms(expr):
        # Recursively collect all symbol names in the expression tree except the target
        for item in kconfiglib.expr_items(expr):
            if not isinstance(item, kconfiglib.Symbol):
                continue
            sym_name = f"{prefix}{item.name}"
            if sym_name != target:
                deps.add(sym_name)

    for sym in getattr(kconf, "unique_defined_syms", []):
        for node in sym.nodes:
            # Check dependencies
            if node.dep is None:
                continue
            dep_str = kconfiglib.expr_str(
                node.dep,
                lambda sc: f"{prefix}{sc.name}"
                if hasattr(sc, "name") and sc.name
                else str(sc),
            )
            if target in dep_str:
                collect_syms(node.dep)

            # Check selects/implies
            for attr in ["orig_selects", "orig_implies"]:
                for value, _ in getattr(node, attr, []) or []:
                    value_str = kconfiglib.expr_str(value, str)
                    if target in value_str:
                        collect_syms(value)

    return deps


def handle_enabled_node(node: edtlib.Node) -> list[str]:
    """
    Handle diagnosis for an enabled DT node (linker error, one or more Kconfigs might be gating
    the device driver).
    """
    lines = [
        f"'{format_node(node)}' is enabled but no driver appears to be available for it.\n",
    ]

    compats = list(getattr(node, "compats", []))
    if compats:
        kconf = setup_kconfig()
        deps = set()
        for compat in compats:
            dt_has = f"DT_HAS_{edtlib.str_as_token(compat.upper())}_ENABLED"
            deps.update(find_kconfig_deps(kconf, dt_has))

        if deps:
            lines.append("Try enabling these Kconfig options:\n")
            lines.extend(f" - {dep}=y" for dep in sorted(deps))
    else:
        lines.append("Could not determine compatible; check driver Kconfig manually.")

    return lines


def handle_disabled_node(node: edtlib.Node) -> list[str]:
    """Handle diagnosis for a disabled DT node."""
    edt = node.edt
    status_prop = node._node.props.get("status")
    lines = [
        f"'{format_node(node)}' is disabled in {status_prop.filename}:{status_prop.lineno}",
    ]

    # Show dependency
    users = getattr(node, "required_by", [])
    if users:
        lines.append("The following nodes depend on it:")
        lines.extend(f" - {u.path}" for u in users)

    # Show chosen/alias references
    chosen_refs = [
        name
        for name, n in (
            getattr(edt, "chosen_nodes", {}) or getattr(edt, "chosen", {})
        ).items()
        if n is node
    ]
    alias_refs = [name for name, n in getattr(edt, "aliases", {}).items() if n is node]

    if chosen_refs or alias_refs:
        lines.append("")

    if chosen_refs:
        lines.append(
            'It is referenced as a "chosen" in '
            f"""{", ".join([f"'{ref}'" for ref in sorted(chosen_refs)])}""",
        )
    if alias_refs:
        lines.append(
            "It is referenced by the following aliases: "
            f"""{", ".join([f"'{ref}'" for ref in sorted(alias_refs)])}""",
        )

    lines.append("\nTry enabling the node by setting its 'status' property to 'okay'.")

    return lines


def main() -> int:
    args = parse_args()

    m = re.search(r"__device_dts_ord_(\d+)", args.symbol)
    if not m:
        return 1

    # Find node by ordinal amongst all nodes
    edt = load_edt(args.edt_pickle)
    node = next((n for n in edt.nodes if n.dep_ordinal == int(m.group(1))), None)
    if not node:
        return 1

    if node.status == "okay":
        handle_enabled_node(node)
    else:
        handle_disabled_node(node)

    return 0


if __name__ == "__main__":
    sys.exit(main())
