#!/usr/bin/env -S uv run --script
#
# /// script
# requires-python = ">=3.13"
# dependencies = [
#     "rich",
#     "cyclopts",
#     "PyYAML",
# ]
# ///
#
# SPDX-License-Identifier: Apache-2.0
#
# diffconfig - a tool to compare .config files.
#
# originally written in 2006 by Matt Mackall
#  (at least, this was in his bloatwatch source code)
# last worked on 2008 by Tim Bird
#

from __future__ import annotations

import os
import re
from contextlib import nullcontext
from dataclasses import dataclass
from pathlib import Path
from typing import TYPE_CHECKING, Annotated

import cyclopts
import yaml
from rich.console import Console
from rich.text import Text

if TYPE_CHECKING:
    from collections.abc import Mapping

ConfigMap = dict[str, str]

console = Console()
error_console = Console(stderr=True, style="bold red")
app = cyclopts.App()


def resolve_base_dir(kbuild_output: Path | None) -> Path:
    """Return the directory to use when defaults are requested."""
    if kbuild_output:
        return kbuild_output.expanduser()
    if env_output := os.environ.get("KBUILD_OUTPUT"):
        return Path(env_output).expanduser()
    return Path.cwd()


def resolve_from_domains(build_dir: Path) -> tuple[Path, Path]:
    """Use <build_dir>/domains.yaml to derive default config paths."""
    domains_file = build_dir.expanduser() / "domains.yaml"
    try:
        with domains_file.open(encoding="utf-8") as f:
            data = yaml.safe_load(f)
    except FileNotFoundError as exc:
        msg = f"domains.yaml not found at {domains_file}"
        raise cyclopts.ValidationError(msg) from exc
    except yaml.YAMLError as exc:
        msg = f"Failed to parse {domains_file}"
        raise cyclopts.ValidationError(msg) from exc

    if not isinstance(data, dict):
        msg = f"Unexpected domains.yaml format in {domains_file}"
        raise cyclopts.ValidationError(msg)

    default_domain = data.get("default")
    domains = data.get("domains")

    if not isinstance(default_domain, str) or not isinstance(domains, list):
        msg = f"domains.yaml missing required fields in {domains_file}"
        raise cyclopts.ValidationError(msg)

    root = build_dir.expanduser()
    yaml_root_raw = data.get("build_dir")
    if isinstance(yaml_root_raw, str):
        yaml_root = Path(yaml_root_raw)
        root = yaml_root if yaml_root.is_absolute() else (root / yaml_root).resolve()

    domain_entry = next(
        (d for d in domains if isinstance(d, dict) and d.get("name") == default_domain),
        None,
    )
    if not domain_entry or "build_dir" not in domain_entry:
        msg = f"Default domain '{default_domain}' not found in {domains_file}"
        raise cyclopts.ValidationError(msg)

    domain_build_dir = Path(domain_entry["build_dir"])
    if not domain_build_dir.is_absolute():
        domain_build_dir = (root / domain_build_dir).resolve()

    config_base = domain_build_dir / "zephyr"
    return config_base / ".config.old", config_base / ".config"


def resolve_paths(
    prev: Path | None,
    curr: Path | None,
    kbuild_output: Path | None,
    build_dir: Path | None,
) -> tuple[Path, Path]:
    """Determine which files to compare, honoring defaults and env vars."""
    if build_dir and (prev or curr):
        msg = "Provide explicit config paths or --build-dir, not both"
        raise cyclopts.ValidationError(msg)

    if build_dir:
        return resolve_from_domains(build_dir)

    if (prev is None) != (curr is None):
        msg = "Provide both config paths or omit both to use .config.old and .config"
        raise cyclopts.ValidationError(msg)

    if prev is None and curr is None:
        base_dir = resolve_base_dir(kbuild_output)
        return base_dir / ".config.old", base_dir / ".config"

    # At this point both are not None because the XOR check above passed.
    assert prev is not None
    assert curr is not None
    return prev.expanduser(), curr.expanduser()


def read_config(path: Path) -> ConfigMap:
    """Parse a .config file into a mapping of CONFIG_* names to values."""
    config: ConfigMap = {}
    with path.open(encoding="utf-8") as config_file:
        for raw_line in config_file:
            line = raw_line.strip()
            if not line:
                continue

            if line.startswith("CONFIG_") and "=" in line:
                name, value = line.split("=", 1)
                config[name.removeprefix("CONFIG_")] = value
            elif line.startswith("# CONFIG_") and line.endswith(" is not set"):
                name = line[len("# CONFIG_") : -len(" is not set")]
                config[name] = "n"

    return config


@dataclass(frozen=True, slots=True)
class DiffResult:
    removed: Mapping[str, str]
    changed: Mapping[str, tuple[str, str]]
    added: Mapping[str, str]


def diff_configs(prev: Mapping[str, str], curr: Mapping[str, str]) -> DiffResult:
    """Calculate differences between two config mappings."""
    prev_keys = set(prev)
    curr_keys = set(curr)

    removed = {name: prev[name] for name in sorted(prev_keys - curr_keys)}
    added = {name: curr[name] for name in sorted(curr_keys - prev_keys)}
    changed = {
        name: (prev[name], curr[name])
        for name in sorted(prev_keys & curr_keys)
        if prev[name] != curr[name]
    }

    return DiffResult(removed=removed, changed=changed, added=added)


def print_merge_line(name: str, value: str) -> None:
    """Render a line in merge style (new config contents)."""
    if value == "n":
        console.print(f"# CONFIG_{name} is not set")
    else:
        console.print(f"CONFIG_{name}={value}")


def print_diff(diff: DiffResult, *, merge: bool) -> None:
    """Print a diff using rich formatting."""
    for name, value in diff.removed.items():
        if merge:
            continue
        console.print(f"-{name} {value}", style="red")

    for name, (old, new) in diff.changed.items():
        if merge:
            print_merge_line(name, new)
            continue
        console.print(f" {name} {old} -> {new}", style="yellow")

    for name, value in diff.added.items():
        if merge:
            print_merge_line(name, value)
            continue
        console.print(f"+{name} {value}", style="green")


def load_config_text(path: Path) -> str:
    """Read config file contents as text."""
    return path.read_text(encoding="utf-8")


def render_config(
    path: Path,
    *,
    find: str | None,
    use_pager: bool = True,
    context: int = 0,
) -> None:
    """Render a config file with optional regex filtering/highlighting."""
    try:
        raw_text = load_config_text(path)
    except OSError as exc:
        error_console.print(f"Error opening config file: {exc}")
        raise SystemExit(1)

    lines = raw_text.splitlines()
    if find:
        try:
            pattern = re.compile(find)
        except re.error as exc:
            error_console.print(f"Invalid regex for --find: {exc}")
            raise SystemExit(1)

        match_rows = {
            idx
            for idx, line in enumerate(lines)
            if pattern.search(line)
        }
        if not match_rows:
            error_console.print(f"No matches for pattern: {find!r}")
            raise SystemExit(1)

        if context > 0:
            for idx in tuple(match_rows):
                start = max(0, idx - context)
                end = min(len(lines) - 1, idx + context)
                match_rows.update(range(start, end + 1))

        selection = [(idx, lines[idx]) for idx in sorted(match_rows)]
    else:
        selection = list(enumerate(lines))

    width = len(str(len(lines)))
    text = Text()
    for idx, line in selection:
        text.append(f"{idx + 1:>{width}} │ ", style="dim")
        text.append(line)
        text.append("\n")

    if find:
        text.highlight_regex(find, style="reverse bold yellow")

    with console.pager() if use_pager else nullcontext():
        console.print(text)


@app.command
def cmp(
    prev: Annotated[
        Path | None,
        cyclopts.Parameter(
            name="prev",
            help="Baseline .config file (defaults to .config.old when omitted)",
        ),
    ] = None,
    curr: Annotated[
        Path | None,
        cyclopts.Parameter(
            name="curr",
            help="Updated .config file (defaults to .config when omitted)",
        ),
    ] = None,
    *,
    merge: Annotated[
        bool,
        cyclopts.Parameter(
            ["-m", "--merge"],
            negative="",
            help="Emit output in merge style (only new config lines)",
        ),
    ] = False,
    kbuild_output: Annotated[
        Path | None,
        cyclopts.Parameter(
            ["-o", "--kbuild-output"],
            help="Directory to use when resolving default config paths",
        ),
    ] = None,
    build_dir: Annotated[
        Path | None,
        cyclopts.Parameter(
            ["-b", "--build-dir"],
            help="Build directory containing domains.yaml to derive config paths",
        ),
    ] = None,
) -> None:
    """Compare .config files and show sorted differences."""
    prev_path, curr_path = resolve_paths(prev, curr, kbuild_output, build_dir)

    missing = [path for path in (prev_path, curr_path) if not path.exists()]
    if missing:
        for path in missing:
            error_console.print(f"Config file not found: {path}")
        raise SystemExit(1)

    try:
        prev_config = read_config(prev_path)
        curr_config = read_config(curr_path)
    except OSError as exc:
        error_console.print(f"Error opening config files: {exc}")
        raise SystemExit(1)

    diff = diff_configs(prev_config, curr_config)
    print_diff(diff, merge=merge)


@app.command
def view(
    config: Annotated[
        Path,
        cyclopts.Parameter(
            name="config",
            help="Config file to display (defaults to .config if omitted)",
        ),
    ] = Path(".config"),
    *,
    find: Annotated[
        str | None,
        cyclopts.Parameter(
            ["-f", "--find"],
            help="Regex to highlight matching text",
        ),
    ] = None,
    no_pager: Annotated[
        bool,
        cyclopts.Parameter(
            "--no-pager",
            negative="",
            help="Disable pager output",
        ),
    ] = False,
    context: Annotated[
        int,
        cyclopts.Parameter(
            ["-C", "--context"],
            help="Include N surrounding lines for --find",
        ),
    ] = 0,
) -> None:
    """Render a single config file with optional regex highlighting."""
    if not config.exists():
        error_console.print(f"Config file not found: {config}")
        raise SystemExit(1)

    use_pager = False if find else not no_pager
    render_config(config, find=find, use_pager=use_pager, context=context)


if __name__ == "__main__":
    app()
