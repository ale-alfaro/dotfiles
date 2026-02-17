#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.13"
# dependencies = [
#     "rich",
#     "cyclopts",
#     "kconfiglib==14.1.1a4",
#     "west",
# ]
# ///

# Copyright (c) 2019 Nordic Semiconductor ASA
# SPDX-License-Identifier: Apache-2.0

"""

Linter for the Zephyr Kconfig files. Pass --help to see
available checks. By default, all checks are enabled.


Some of the checks rely on heuristics and can get tripped up
by things like preprocessor magic, so manual checking is
still needed. 'west grep' is handy.

Requires west, because the checks need to see Kconfig files
and source code from modules.
"""

from __future__ import annotations

import atexit
import os
import re
import shlex
import subprocess  # noqa: S404
import tempfile
from collections import namedtuple
from dataclasses import dataclass
from enum import Flag, auto
from pathlib import Path
from typing import TYPE_CHECKING, Annotated, Literal

import cyclopts
import kconfiglib
from rich.console import Console
from west.configuration import Configuration as WestConfig
from west.manifest import (
    Manifest,
    ManifestImportFailed,
    Project,
)

if TYPE_CHECKING:
    from collections.abc import Callable, Iterable, Sequence

console = Console()
error_console = Console(stderr=True, style="bold red")
app = cyclopts.App()


def warn(msg: str) -> None:
    error_console.print(f"{msg}")


def err(msg: str) -> None:
    error_console.print(f"{msg}")


def run_cmd(cmd: Sequence[str], *, cwd: Path, check: bool = True) -> str:
    cmd_s = " ".join(shlex.quote(word) for word in cmd)

    try:
        result = subprocess.run(  # noqa: S603
            cmd,
            cwd=cwd,
            check=check,
            capture_output=True,
            text=True,
        )
    except OSError as exc:
        stdout = result.stdout.encode("utf-8").decode("utf-8", errors="ignore")
        stderr = result.stderr

        err(
            f"""\
'{cmd_s}' exited with status {result.returncode}.

===stdout===
{stdout}
===stderr===
{stderr}"""
        )
        raise SystemExit(1) from exc

    if stderr := result.stderr:
        warn(f"'{cmd_s}' wrote to stderr:\n{stderr}")

    return result.stdout.encode("utf-8").decode("utf-8", errors="ignore")


def west_grep(
    args: Sequence[str],
    *,
    zephyr_base: Path,
    check: bool = True,
) -> str:
    cmd = [
        "west",
        "grep",
        "--tool",
        "ripgrep",
        "--color=never",
        *args,
    ]
    return run_cmd(cmd, cwd=zephyr_base, check=check)


class LintContext:
    def __init__(self, zephyr_base: Path) -> None:
        self.zephyr_base = zephyr_base
        self._modules_tempdir: tempfile.TemporaryDirectory[str] | None = None
        self.kconf = self._init_kconfig()

    def _init_kconfig(self) -> kconfiglib.Kconfig:
        self._configure_env()
        return kconfiglib.Kconfig(suppress_traceback=True)

    def _configure_env(self) -> None:
        modules_dir = self._modules_file_dir()
        os.environ.update(
            srctree=str(self.zephyr_base),
            CMAKE_BINARY_DIR=str(modules_dir),
            KCONFIG_DOC_MODE="1",
            ZEPHYR_BASE=str(self.zephyr_base),
            SOC_DIR="soc",
            ARCH_DIR="arch",
            KCONFIG_BOARD_DIR="boards/*/*",
            ARCH="*",
        )

    def _modules_file_dir(self) -> Path:
        self._modules_tempdir = tempfile.TemporaryDirectory()
        atexit.register(self._modules_tempdir.cleanup)

        out_dir = Path(self._modules_tempdir.name)
        cmd = [
            str(self.zephyr_base / "scripts" / "zephyr_module.py"),
            "--kconfig-out",
            str(out_dir / "Kconfig.modules"),
        ]
        run_cmd(cmd, cwd=self.zephyr_base)
        return out_dir


def has_prompt(sym: kconfiglib.Symbol) -> bool:
    return any(node.prompt for node in sym.nodes)


def is_selected_or_implied(
    sym: kconfiglib.Symbol, *, kconf: kconfiglib.Kconfig
) -> bool:
    return sym.rev_dep is not kconf.n or sym.weak_rev_dep is not kconf.n


def has_defaults(sym: kconfiglib.Symbol) -> bool:
    return bool(sym.defaults)


def is_selecting_or_implying(sym: kconfiglib.Symbol) -> bool:
    return sym.selects or sym.implies


def name_and_locs(sym: kconfiglib.Symbol) -> str:
    locations = ", ".join(f"{node.filename}:{node.linenr}" for node in sym.nodes)
    return f"{sym.name:40} {locations}"


def check_always_n(context: LintContext) -> None:
    print_header("Symbols that can't be anything but n/empty")
    for sym in context.kconf.unique_defined_syms:
        if (
            not has_prompt(sym)
            and not is_selected_or_implied(sym, kconf=context.kconf)
            and not has_defaults(sym)
        ):
            console.print(name_and_locs(sym))


def check_unused(context: LintContext) -> None:
    print_header("Symbols that look unused")
    referenced = referenced_sym_names(context)
    for sym in context.kconf.unique_defined_syms:
        if (
            not is_selecting_or_implying(sym)
            and not sym.choice
            and sym.name not in referenced
        ):
            console.print(name_and_locs(sym))


def check_pointless_menuconfigs(context: LintContext) -> None:
    print_header("menuconfig symbols with empty menus")
    for node in context.kconf.node_iter():
        if (
            node.is_menuconfig
            and not node.list
            and isinstance(node.item, kconfiglib.Symbol)
        ):
            console.print(f"{node.item.name:40} {node.filename}:{node.linenr}")


def check_defconfig_only_definition(context: LintContext) -> None:
    print_header("Symbols only defined in Kconfig.defconfig files")
    for sym in context.kconf.unique_defined_syms:
        if all("defconfig" in node.filename for node in sym.nodes):
            console.print(name_and_locs(sym))


def check_missing_config_prefix(context: LintContext) -> None:
    print_header("Symbol references that might be missing a CONFIG_ prefix")

    defined: set[str] = set()
    regex = r"#\s*define\s+([A-Z0-9_]+)\b"
    defines = west_grep(
        ["--no-heading", "-n", regex],
        zephyr_base=context.zephyr_base,
        check=False,
    )
    defined.update(re.findall(regex, defines))

    syms = [sym for sym in context.kconf.unique_defined_syms if sym.name not in defined]

    for batch in split_list(syms, 200):
        regex = (
            r"(?:#\s*if(?:n?def)\s+|\bdefined\s*\(\s*|IS_ENABLED\(\s*)(?:"
            + "|".join(sym.name for sym in batch)
            + r")\b"
        )
        output = west_grep(
            ["--no-heading", "-n", "--pcre2", regex],
            zephyr_base=context.zephyr_base,
            check=False,
        )
        console.print(output, end="")


def split_list(items: Sequence[object], batch_size: int) -> Iterable[Sequence[object]]:
    for i in range(0, len(items), batch_size):
        yield items[i : i + batch_size]


def print_header(text: str) -> None:
    console.print(text + "\n" + len(text) * "=")


def referenced_sym_names(context: LintContext) -> set[str]:
    return referenced_in_kconfig(context.kconf) | referenced_outside_kconfig(
        context.zephyr_base
    )


def referenced_in_kconfig(kconf: kconfiglib.Kconfig) -> set[str]:
    return {
        ref.name
        for node in kconf.node_iter()
        for ref in node.referenced
        if isinstance(ref, kconfiglib.Symbol)
    }


def referenced_outside_kconfig(zephyr_base: Path) -> set[str]:
    regex = r"\bCONFIG_[A-Z0-9_]+\b"

    res: set[str] = set()

    output = west_grep(
        ["--no-heading", "-n", regex],
        zephyr_base=zephyr_base,
    )
    for line in output.splitlines():
        if re.match(r"[\s#]*CONFIG_[A-Z0-9_]+=.*", line):
            continue
        res.update(match[7:] for match in re.findall(regex, line))

    return res


@dataclass
class WestProjects:
    manifest_path: Path
    projects: list[Project]


def west_projects() -> WestProjects:

    manifest = Manifest.from_file()
    if not manifest:
        raise ManifestImportFailed

    if manifest_path := manifest.path:
        manifest_path = Path(manifest_path)
    else:
        cfg_key = Literal["manifest.path"]
        manifest_path_from_cfg: str | None = WestConfig.get(cfg_key, "")  # ty:ignore[invalid-argument-type]
        if not manifest_path_from_cfg:
            raise ManifestImportFailed
        manifest_path = Path(manifest_path_from_cfg)
    projects = [p for p in manifest.get_projects([]) if manifest.is_active(p)]
    return WestProjects(manifest_path, projects)


def parse_modules(zephyr_base, west_projs=None):

    west_projs = west_projs or west_projects()
    modules = [p.posixpath for p in west_projs.projects] if west_projs else []

    Module = namedtuple("Module", ["project", "meta", "depends"])

    all_modules_by_name = {}
    # dep_modules is a list of all modules that has an unresolved dependency
    dep_modules = []
    # start_modules is a list modules with no depends left (no incoming edge)
    start_modules = []
    # sorted_modules is a topological sorted list of the modules
    sorted_modules = []

    for project in modules:
        # Avoid including Zephyr base project as module.
        if project == zephyr_base:
            continue

        meta = process_module(project)
        if meta:
            depends = meta.get("build", {}).get("depends", [])
            all_modules_by_name[meta["name"]] = Module(project, meta, depends)

        elif project in extra_modules:
            err(
                f"{project}, given in ZEPHYR_EXTRA_MODULES, "
                "is not a valid zephyr module"
            )
            raise SystemExit(1)

    for module in all_modules_by_name.values():
        if not module.depends:
            start_modules.append(module)
        else:
            dep_modules.append(module)

    # This will do a topological sort to ensure the modules are ordered
    # according to dependency settings.
    while start_modules:
        node = start_modules.pop(0)
        sorted_modules.append(node)
        node_name = node.meta["name"]
        to_remove = []
        for module in dep_modules:
            if node_name in module.depends:
                module.depends.remove(node_name)
                if not module.depends:
                    start_modules.append(module)
                    to_remove.append(module)
        for module in to_remove:
            dep_modules.remove(module)

    if dep_modules:
        # If there are any modules with unresolved dependencies, then the
        # modules contains unmet or cyclic dependencies. Error out.
        error = "Unmet or cyclic dependencies in modules:\n"
        for module in dep_modules:
            error += f"{module.project} depends on: {module.depends}\n"
        err(error)
        raise SystemExit(1)

    return sorted_modules


@cyclopts.Parameter(name="*")
class KconfigLintChecks(Flag):
    ALWAYS_N = auto()
    UNUSED = auto()
    POINTLESS_MENUCONFIGS = auto()
    DEFCONFIG_ONLY_DEFINITION = auto()
    MISSING_CONFIG_PREFIX = auto()


def resolve_checks(
    checks: KconfigLintChecks,
) -> tuple[Callable[[LintContext], None], ...]:
    selected: list[Callable[[LintContext], None]] = []
    if checks & KconfigLintChecks.ALWAYS_N:
        selected.append(check_always_n)
    if checks & KconfigLintChecks.UNUSED:
        selected.append(check_unused)
    if checks & KconfigLintChecks.POINTLESS_MENUCONFIGS:
        selected.append(check_pointless_menuconfigs)
    if checks & KconfigLintChecks.DEFCONFIG_ONLY_DEFINITION:
        selected.append(check_defconfig_only_definition)
    if checks & KconfigLintChecks.MISSING_CONFIG_PREFIX:
        selected.append(check_missing_config_prefix)

    if selected:
        return tuple(selected)

    return (
        check_always_n,
        check_unused,
        check_pointless_menuconfigs,
        check_defconfig_only_definition,
        check_missing_config_prefix,
    )


@app.default
def main(
    checks: Annotated[
        KconfigLintChecks, cyclopts.Parameter(negative="")
    ] = KconfigLintChecks.ALWAYS_N,
    zephyr_base: Annotated[
        Path | None,
        cyclopts.Parameter(
            ["-b", "--zephyr-base"],
            help="Path to Zephyr base (defaults to ZEPHYR_BASE when omitted).",
        ),
    ] = None,
) -> None:
    """
    Run selected Kconfig checks (defaults to all when none are selected).

    Check descriptions:

    Always N
    List symbols that can never be anything but n/empty. These are detected as
    symbols with no prompt or defaults that aren't selected or implied.

    Unused
    List symbols that might be unused.

    Heuristic:
    - Isn't referenced in Kconfig
    - Isn't referenced as CONFIG_<NAME> outside Kconfig
        (besides possibly as CONFIG_<NAME>=<VALUE>)
    - Isn't selecting/implying other symbols
    - Isn't a choice symbol

    C preprocessor magic can trip up this check.

    Pointless Menuconfigs
    List symbols defined with 'menuconfig' where the menu is empty due to the
    symbol not being followed by stuff that depends on it.

    Defconfig-only Definition
    List symbols that are only defined in Kconfig.defconfig files. A common base
    definition should probably be added somewhere for such symbols, and the type
    declaration ('int', 'hex', etc.) removed from Kconfig.defconfig.

    Missing CONFIG_ Prefix
    Look for references like

        #if MACRO
        #if(n)def MACRO
        defined(MACRO)
        IS_ENABLED(MACRO)

    where MACRO is the name of a defined Kconfig symbol but doesn't have a
    CONFIG_ prefix. Could be a typo.

    Macros that are #define'd somewhere are not flagged.
    """
    if not zephyr_base:
        if env_base := os.environ.get("ZEPHYR_BASE"):
            zephyr_base = Path(env_base).expanduser().resolve()
    else:
        zephyr_base = zephyr_base.expanduser().resolve()
    if not zephyr_base.is_dir():
        err("Couldn't find Zephyr Base (use --zephyr-base or set ZEPHYR_BASE)")
        raise SystemExit(1)
    context = LintContext(zephyr_base)
    check_fns = resolve_checks(checks)

    first = True
    for check in check_fns:
        if not first:
            console.print()
        first = False
        check(context)


if __name__ == "__main__":
    app()
