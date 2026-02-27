#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.13"
# dependencies = [
#     "rich",
#     "cyclopts",
# ]
# ///
"""

Installation instructions:
1. Install uv using one of the methods listed here https://docs.astral.sh/uv/getting-started/installation/#__tabbed_1_2.

    Example for Mac/Linux:
        curl -LsSf https://astral.sh/uv/install.sh | sh
    Example for Windows:
        powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
2. Once uv is installed and in your PATH install python through uv:
    uv python install --default
3. OPTIONAL. Make this script into an executable file by changing permissions:
    chmod +x diffconfig.py.
    With that you will be able to run the script as an executable. You can add it in your path or call it using './diffconfig.py .config .config.old'
Usage instructions:

Run with uv using:
    `uv run --script diffconfig.py .config .config.old`
    OR if you made it into an executable file:
    `./diffconfig.py .config .config.old`
If you want to output to a file insted of stdout use the -o flag:
    `uv run --script diffconfig.py .config .config.old -o out.diff`


"""

from __future__ import annotations

import os
from dataclasses import dataclass
from pathlib import Path
from typing import TYPE_CHECKING, Annotated

import cyclopts
from rich.console import Console
from rich.text import Text

if TYPE_CHECKING:
    from collections.abc import Mapping


ConfigMap = dict[str, str]

error_console = Console(stderr=True, style="bold red")
app = cyclopts.App()


def resolve_base_dir(kbuild_output: Path | None) -> Path:
    """Return the directory to use when defaults are requested."""
    if kbuild_output:
        return kbuild_output.expanduser()
    if env_output := os.environ.get("KBUILD_OUTPUT"):
        return Path(env_output).expanduser()
    return Path.cwd()


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


def create_merge_line(config_name: str, config_val: str) -> str:
    """Render a line in merge style (new config contents)."""
    return (
        f"# CONFIG_{config_name} is not set"
        if config_val == "n"
        else f"CONFIG_{config_name}={config_val}"
    )


def create_diff(diff: DiffResult, *, merge: bool) -> list[str]:
    """Print a diff using rich formatting."""
    diff_res: list[str] = []
    for name, value in diff.removed.items():
        if not merge:
            diff_res.append(Text(f"-{name} {value}", style="red"))

    for name, (old, new) in diff.changed.items():
        if merge:
            diff_res.append(create_merge_line(name, new))
        else:
            diff_res.append(Text(f" {name} {old} -> {new}", style="yellow"))

    for name, value in diff.added.items():
        if merge:
            diff_res.append(create_merge_line(name, value))
        else:
            diff_res.append(Text(f"+{name} {value}", style="green"))
    return diff_res


def load_config_text(path: Path) -> str:
    """Read config file contents as text."""
    return path.read_text(encoding="utf-8")


def render_diff(
    diff: DiffResult,
    *,
    merge: bool = False,
    output_to_file: Path | None = None,
) -> None:

    lines: list[str] = create_diff(diff, merge=merge)

    text = Text()
    if out := output_to_file:
        with out.open(mode="w", encoding="utf-8") as f:
            [text.append(f"{line}\n") for line in lines]
            console = Console(file=f)
            console.print(text)
    else:
        for idx, line in enumerate(lines):
            text.append(f"{idx + 1:>{len(str(len(lines)))}} │ ", style="dim")
            text.append(line)
            text.append("\n")
        console = Console()
        console.print(text)


@app.default
def cmp(
    prev: Annotated[
        Path,
        cyclopts.Parameter(
            "*",
            help="Baseline .config file (defaults to .config.old when omitted)",
        ),
    ] = ".config.old",
    curr: Annotated[
        Path,
        cyclopts.Parameter(
            "*",
            help="Baseline .config file (defaults to .config.old when omitted)",
        ),
    ] = ".config",
    *,
    output: Annotated[
        Path | None,
        cyclopts.Parameter(
            ["-o", "--output"],
            negative="",
            help="Output to file specified",
        ),
    ] = None,
    merge: Annotated[
        bool,
        cyclopts.Parameter(
            ["-m", "--merge"],
            negative="",
            help="Emit output in merge style (only new config lines)",
        ),
    ] = False,
) -> None:
    """Compare .config files and show sorted differences."""
    prev_config_map: dict[str, str] = read_config(prev)
    curr_config_map: dict[str, str] = read_config(curr)
    diff = diff_configs(prev_config_map, curr_config_map)
    render_diff(diff, merge=merge, output_to_file=output)


if __name__ == "__main__":
    app()
