#!/usr/bin/env -S uv run --script
#
# /// script
# requires-python = ">=3.13"
# dependencies = [
#     "cattrs",
#     "attrs",
#     "PyYAML",
#     "tomlkit",
#     "anyio",
#     "rich",
#     "cyclopts",
#     "python-dotenv"
# ]
# ///
import io
import logging
import os
import re
import shlex
import sys
import tomllib
from collections import defaultdict
from functools import partial
from pathlib import Path
from subprocess import CalledProcessError
from typing import (
    Annotated,
    Any,
    Callable,
    ClassVar,
    Literal,
    Mapping,
    Optional,
    Union,
)

import anyio
import attrs
import cattrs
import cyclopts
import tomlkit
from cattrs import override
from cattrs.gen import make_dict_structure_fn
from cattrs.preconf.tomlkit import TomlkitConverter, make_converter
from cyclopts.argument import ArgumentCollection
from dotenv import load_dotenv
from rich.console import Console
from rich.panel import Panel
from rich.pretty import pprint
from rich.progress import (
    Progress,
    SpinnerColumn,
    TaskID,
    TextColumn,
)

EXAMPLE_TOML = """

  [common]
  app_dir = "shell_module"

  [common.build_flags]
  pristine = "always"
  sysbuild = true
  dry_run = false
  build_opt = ["-j4", "-v"]

  [common.cmake_vars]
  EXTRA_CONF_FILE = ["foo.conf", "bar.conf"]
  FILE_SUFFIX = "dbg"

  [[apps]]
  id = "bt_nus"
  app_dir = "shell_bt_nus"
  conf_file = "bt_nus"

  [apps.build_flags]
  force = true

  [apps.cmake_vars]
  CONF_FILE = "rtt_uart.conf"

"""
print_console = Console()
error_console = Console(stderr=True, style="bold red")
FORMAT = "%(message)s"
logger = logging.getLogger(__name__)


# logger = logging.getLogger("rich")
# log_handler = RichHandler()
@attrs.frozen()
class WestFlagBuilder:
    flag: str
    long: bool = attrs.field(default=False)
    takes_value: bool = attrs.field(default=True)
    repeatable: bool = attrs.field(default=False)

    def render(self) -> str:
        return f"{'--' if self.long else '-'}{self.flag}"

    def __call__(self, raw_opt: Any) -> list[str]:
        if raw_opt is None:
            return []
        if not self.takes_value:
            if isinstance(raw_opt, bool) and not raw_opt:
                return []
            return [self.render()]
        if isinstance(raw_opt, list):
            if not self.repeatable:
                return [self.render(), " ".join(str(x) for x in raw_opt)]
            return [item for x in raw_opt for item in (self.render(), str(x))]
        return [self.render(), str(raw_opt)]


type CMakeVariableValueType = str | int | Path | list[str] | bool


@attrs.frozen()
class CMakeVariableBuilder:
    var: str
    valid_regex: ClassVar[re.Pattern] = re.compile(r"[yn\d+\w+]")

    def __call__(self, value: CMakeVariableValueType) -> str | None:
        if isinstance(value, bool):
            return f"-D{self.var}={'y' if value else 'n'}"
        elif isinstance(value, list):
            joined = ";".join(str(x) for x in value)
            return f"-D{self.var}={joined}"
        elif isinstance(value, (str, int)):
            return f"-D{self.var}={str(value)}"
        else:
            return None


class CMakeFlags:
    name: Literal[
        "FILE_SUFFIX",
        "SB_CONF_FILE",
        "CONF_FILE",
        "DTC_OVERLAY_FILE",
        "PM_STATIC_YML_FILE",
        "EXTRA_CONF_FILE",
        "EXTRA_DTC_OVERLAY_FILE",
        "SHIELD",
    ]


DEFAULT_WEST_BUILD_CMD = ["build"]
DEFAULT_TWISTER_FLAGS = ["--clobber-output", "-W", "-i"]
TARGET_BUILD_COMMANDS: set[str] = {
    "flash",
    "run",
    "menuconfig",
    "guiconfig",
    "pahole",
    "puncover",
    "ram_report",
    "rom_report",
    "footprint",
    "initlevels",
}

CMakeFlags = attrs.make_class(
    "CMakeFlags",
    {
        flag_name: attrs.field(
            default=None,
            type=Optional[str],
            converter=builder,
            kw_only=True,
        )
        for flag_name, builder in _CMakeFlags.items()
    },
)
_WestFlags: dict[str, WestFlagBuilder] = {
    "board": WestFlagBuilder("b"),
    "app_dir": WestFlagBuilder("s"),
    "build_dir": WestFlagBuilder("d"),
    "snippets": WestFlagBuilder("S"),
    "target": WestFlagBuilder("t"),
    "domain": WestFlagBuilder("domain", long=True),
    "extra_conf_file": WestFlagBuilder("extra-conf", long=True, repeatable=True),
    "extra_dtc_overlay": WestFlagBuilder(
        "extra-dtc-overlay", long=True, repeatable=True
    ),
    "shield": WestFlagBuilder("shield", long=True, repeatable=True),
    "pristine": WestFlagBuilder("pristine", long=True),
    "force": WestFlagBuilder("force", long=True, takes_value=False),
    "cmake": WestFlagBuilder("cmake", long=True, takes_value=False),
    "cmake_only": WestFlagBuilder("cmake-only", long=True, takes_value=False),
    "sysbuild": WestFlagBuilder("sysbuild", long=True, takes_value=False),
    "no_sysbuild": WestFlagBuilder("no-sysbuild", long=True, takes_value=False),
    "dry_run": WestFlagBuilder("dry-run", long=True, takes_value=False),
    "build_opt": WestFlagBuilder("build-opt", long=True, repeatable=True),
    "test_item": WestFlagBuilder("test-item", long=True),
}
WestFlags = attrs.make_class(
    "WestFlags",
    {
        flag_name: attrs.field(
            default=None, type=Optional[list[str]], converter=builder, kw_only=True
        )
        for flag_name, builder in _WestFlags.items()
    },
)


@attrs.frozen
class AppCfg:
    flags = attrs.field(type=WestFlags)
    cmake = attrs.field(type=CMakeFlags)
    cmake_vars: Mapping[str, CMakeVariableValueType] = attrs.field(factory=dict)

    @property
    def west_command(self) -> list[str]:
        west_cmd: list[str] = [
            "build",
            *self.flags.values(),
            *self.west_extra_args,
            "--",
            *self.cmake.values(),
        ]
        return west_cmd


# def from_toml(apps: dict[str, Any]) -> AppCfg:
#     return cattrs.structure_attrs_fromdict(


@attrs.frozen
class Config:
    base: AppCfg = attrs.field()
    apps: dict[str, AppCfg] = attrs.field(factory=dict)
    # zephyr_base: Path
    # cwd: Path


async def run_west_cmd(
    west_cmd: list[str],
    cwd: Path,
    zephyr_base: Path | None = None,
) -> None:
    if zephyr_base:
        config = io.StringIO("ZEPHYR_BASE=" + str(zephyr_base))
        load_dotenv(stream=config)
    elif env_var := os.environ.get("ZEPHYR_BASE"):
        zephyr_base = Path(
            env_var,
        )
    else:
        raise cyclopts.ValidationError(
            "ZEPHYR_BASE not defined; set the env var or pass -z/--zephyr-base",
        )
    if not zephyr_base.exists():
        msg = f"ZEPHYR_BASE env variable must be set or added using -z and --zephyr-base. Current value is {zephyr_base}"
        error_console.print(msg)
        raise cyclopts.ValidationError(msg)

    requirements_txt_path = zephyr_base / "scripts" / "requirements-base.txt"
    if not requirements_txt_path.exists():
        msg = f"requirements.txt not found in {requirements_txt_path}"
        error_console.print(msg)
        raise FileExistsError(msg)

    cmd = [
        "uvx",
        "--with-requirements",
        str(requirements_txt_path),
        "west",
        *west_cmd,
    ]

    with Progress(
        SpinnerColumn(),
        TextColumn("[progress.description]{task.description}", justify="right"),
        console=print_console,
        transient=True,
    ) as progress:
        match west_cmd[0]:
            case "build":
                action = "Building"
            case "flash":
                action = "Flashing"
            case "twister":
                action = "Testing"
            case _:
                action = "Running"
        progress.console.print(
            Panel(
                f"""
Running:
    [bold]west {shlex.join(west_cmd)}[/bold]
                               """,
                title=f"{action} app ",
            ),
            overflow="fold",
        )
        task: TaskID = progress.add_task(
            "Running...",
            total=None,
        )
        try:
            progress.start_task(task)
            res = await anyio.run_process(
                cmd,
                check=True,
                cwd=cwd,
            )
            if res.stdout:
                progress.console.print(
                    Panel(
                        f"""
            [bold]{res.stdout.decode().rstrip()}[/bold]
                               """,
                        title=f"{action} Output ",
                    ),
                    overflow="ellipsis",
                )

            progress.update(task, description="Success!")
        except CalledProcessError as exc:
            progress.update(task, description="Process Failed!")
            error_console.print(f"""
                        Process Failed!
                            cmd: {exc.cmd}
                            retcode: {exc.returncode}
                            stderr: {exc.stderr.rstrip().decode()}
                            BUILD_OUTPUT:
                            stdout: {exc.stdout.rstrip().decode()}
                            """)

            sys.exit(1)


# async def run_build(
#     app: AppCfg,
#     cwd: Path,
#     zephyr_base: Path | None = None,
#     target: str | None = None,
# ) -> None:
#     if target:
#         build_flags_override: dict[str, Any] = {"pristine": "never", "target": target}
#         sysbuild_setting = (app.flags or {}).get("sysbuild")
#         if sysbuild_setting is not False:
#             domain = (app.flags or {}).get("domain")
#             if not domain:
#                 domain = app.app_dir.name
#             build_flags_override["domain"] = domain
#     else:
#         west_args = app.west_command
#     await run_west_cmd(west_args, cwd, zephyr_base)
#
#
# async def run_test(
#     app: AppCfg,
#     twister_extra_args: list[str],
#     cwd: Path,
#     zephyr_base: Path | None = None,
# ) -> None:
#     west_args = [
#         "twister",
#         "-T",
#         str(app.app_dir),
#         "-p",
#         app.board,
#         *DEFAULT_TWISTER_FLAGS,
#     ]
#     if twister_extra_args:
#         west_args.extend(twister_extra_args)
#
#     await run_west_cmd(west_args, cwd, zephyr_base)


async def symlink_compdb(app: AppCfg) -> None:
    async for file in anyio.Path(app.build_dir / app.app_dir.stem).glob(
        "compile_commands.json",
    ):
        compile_commands = anyio.Path(
            app.app_dir / "compile_commands.json",
        )
        try:
            logger.info(
                "unlinking first in case compile_commands.json is present at %s",
                compile_commands,
            )
            await compile_commands.unlink(missing_ok=True)

            logger.info(
                "symlinking compile_commands.json, to %s from %s",
                compile_commands,
                file,
            )
            await compile_commands.symlink_to(file)

        except FileExistsError as e:
            logger.info("compile_commands.json alredy symlinked")
            raise StopAsyncIteration from e


def find_build_toml():

    p: Path | None = next(Path(Path.cwd()).glob("build.toml"))
    if not p:
        raise FileNotFoundError
    return p.read_text() if p else Path.cwd()


# SPEC_ENV_VAR = "WEST_BUILD_SPEC"
# SPEC_DEFAULT_NAME = "build.toml"
#
#
# @attrs.define
# class EnvVars
#     names: list[str] = attrs.field(factory=list)
#
#     def _prefix(self, commands: tuple[str, ...]) -> str:
#         prefix = self.prefix
#         if self.command and commands:
#             prefix += "_".join(x.upper() for x in commands) + "_"
#
#         return prefix
#
#     def __call__(
#         self,
#         app: cyclopts.App,
#         commands: tuple[str, ...],
#         arguments: ArgumentCollection,
#     ):
#         added_tokens = set()
#
#         candidate_env_keys = {
#             name: val for name, val in os.environ.items() if name in self.names
#         }
#         candidate_env_keys.sort()
#         delimiter = "_"
#         for candidate_env_key in candidate_env_keys:
#             try:
#                 argument, remaining_keys, _ = arguments.match(
#                     candidate_env_key,
#                     delimiter=delimiter,
#                 )
#             except ValueError:
#                 continue
#             if set(argument.tokens) - added_tokens:
#                 # Skip if there are any tokens from another source.
#                 continue
#
#             # There's inherently an ambiguity because we use "_" as the key-delimiter.
#             # However, we can somewhat resolve this ambiguity by checking if the argument
#             # accepts subkeys. If there are no children arguments, then just re-combine the
#             # remaining_keys.
#             if not argument.children and remaining_keys:
#                 remaining_keys = (delimiter.join(remaining_keys),)
#
#             remaining_keys = tuple(x.lower() for x in remaining_keys)
#             for i, value in enumerate(
#                 argument.env_var_split(os.environ[candidate_env_key])
#             ):
#                 token = cyclopts.Token(
#                     keyword=candidate_env_key,
#                     value=value,
#                     source=self.source,
#                     index=i,
#                     keys=remaining_keys,
#                 )
#                 argument.append(token)
#                 added_tokens.add(token)
#
#
app = cyclopts.App()
#     name="west-toml-build",
#     config=[
#         EnvVars(["ZEPHYR_BASE", "WEST_TOPDIR"]),
#         cyclopts.config.Toml(
#             "build.toml",  # Name of the TOML File
#             root_keys=[
#                 "apps",
#             ],  # The project's namespace in the TOML.
#             # If "pyproject.toml" is not found in the current directory,
#             # then iteratively search parenting directories until found.
#             search_parents=True,
#             use_commands_as_keys=False,
#         ),
#     ],
# )


@app.command
async def build(
    *,
    app: Annotated[AppCfg, cyclopts.Parameter(parse=False)],
    cwd: Annotated[Path | None, cyclopts.Parameter(parse=False)] = None,
    zephyr_base: Annotated[Path | None, cyclopts.Parameter(parse=False)] = None,
    target: Annotated[str, cyclopts.Parameter(parse=False)] = "",
    dry_run: bool = False,
) -> None:
    """Build apps from the spec or run a supported build target with -t.

    Supported targets: menuconfig, guiconfig, pahole, puncover, ram_report,
    rom_report, footprint, initlevels, flash, run.
    """
    if dry_run:
        app.west_extra_args.append("--dry-run")
    pprint(app.west_command)
    # await run_west_cmd(app.west_command, cwd, zephyr_base)
    # apps = [a for a in spec.apps if app_id == app.id] if app_id else spec.apps
    # for idx, app in enumerate(apps):
    # await run_build(app, cwd or Path.cwd(), zephyr_base, target=target)
    # Only symlink_compdb for the first app
    # if idx == 0:
    # await symlink_compdb(app)


#
# @app.command
# async def test(spec: BuildConfig) -> None:
#     """Run twister for each app in the spec (or a single app if selected)."""
#     twister_extra_args: list[str] = []
#     if common.verbose:
#         twister_extra_args.append("-v")
#
#     cwd: Path = common.cwd or common.spec.cwd
#     if app := common.single_app:
#         await run_test(app, twister_extra_args, cwd, common.zephyr_base)
#     else:
#         for app in common.spec.apps:
#             await run_test(app, twister_extra_args, cwd, common.zephyr_base)


# @app.command
# async def config(
#     spec: BuildConfig,
#     app_id: str,
#     *,
#     gui: Annotated[bool, cyclopts.Parameter(negative="")] = False,
# ) -> None:
#     """Run Kconfig UI. Defaults to menuconfig, or guiconfig with --gui."""
#     target = "guiconfig" if gui else "menuconfig"
#     app: AppCfg = next((a for a in spec.apps if app_id == a.id), None)
#     await run_build(
#         app,
#         [],
#         app.cwd,
#         app.zephyr_base,
#         target=target,
#         is_target_build=True,
#         ignore_spec_flags=True,
#     )


# @app.command
# async def analyze_mem(
#     spec: BuildConfig,
#     app_id: str,
#     *,
#     pahole: Annotated[bool, cyclopts.Parameter(negative="")] = False,
#     puncover: Annotated[bool, cyclopts.Parameter(negative="")] = False,
#     ram_report: Annotated[bool, cyclopts.Parameter(negative="")] = False,
#     rom_report: Annotated[bool, cyclopts.Parameter(negative="")] = False,
#     footprint: Annotated[bool, cyclopts.Parameter(negative="")] = False,
# ) -> None:
#     """Analyze memory usage. Defaults to footprint unless a flag is selected."""
#     selected = [
#         name
#         for name, enabled in (
#             ("pahole", pahole),
#             ("puncover", puncover),
#             ("ram_report", ram_report),
#             ("rom_report", rom_report),
#             ("footprint", footprint),
#         )
#         if enabled
#     ]
#     target = selected[0] if selected else "footprint"
#     app: AppCfg = next((a for a in spec.apps if app_id == a.id), None)
#     await run_build(
#         app,
#         [],
#         app.cwd,
#         app.zephyr_base,
#         target=target,
#         is_target_build=True,
#         ignore_spec_flags=True,
#     )
#
#
# @app.command
# async def analyze_init(spec: BuildConfig, app_id: str) -> None:
#     """Display initialization sequence (initlevels target)."""
#     app: AppCfg = next((a for a in spec.apps if app_id == a.id), None)
#     await run_build(
#         app,
#         [],
#         app.cwd,
#         app.zephyr_base,
#         target="initlevels",
#         is_target_build=True,
#         ignore_spec_flags=True,
#     )
#
#
# @app.command
# async def run(spec: BuildConfig, app_id: str) -> None:
#     """Run the app on the target hardware (currently uses flash)."""
#     app: AppCfg = next((a for a in spec.apps if app_id == a.id), None)
#     await run_build(
#         app,
#         [],
#         app.cwd,
#         app.zephyr_base,
#         target="flash",
#         is_target_build=True,
#         ignore_spec_flags=True,
# )


@app.command
def help():
    """Display the help screen."""
    app.help_print()


async def main_loop():
    await app.run_async()


@app.meta.default
def launcher(
    *tokens: Annotated[str, cyclopts.Parameter(show=False, allow_leading_hyphen=True)],
    verbose: bool = False,
):
    additional_kwargs = {}
    command, bound, _ = app.parse_args(tokens)
    # "ignored" is a dict mapping python-variable-name to it's type annotation for parameters with "parse=False".
    # toml: dict[str, Any] = cyclopts.config.Toml("build.toml")
    toml = find_build_toml()

    load_dotenv()

    log_level = logging.DEBUG if verbose else logging.INFO
    logging.basicConfig(
        level=log_level,
        format=FORMAT,
        datefmt="[%X]",
        # handlers=[log_handler],
    )
    logger.info(f"Toml: f{toml}")
    # if appflags := cattrs.structure_attrs_fromdict(tomllib.loads(toml), AppCfg):
    cfg_converter: TomlkitConverter = make_converter()

    # cfg_converter.register_structure_hook_factory(
    #     attrs.has,
    #     lambda cl: cattrs.gen.make_dict_structure_fn(
    #         cl, cfg_converter, _cattrs_forbid_extra_keys=True
    #     ),
    # )
    cfg_converter.register_structure_hook(
        AppCfg,
        make_dict_structure_fn(AppCfg, cfg_converter, cmake_vars=override(omit=True)),
    )
    cfg = cfg_converter.loads(toml, Config)
    logger.info(f"Running command: f{command}, {cfg}")

    def launch():
        # app.run_async(["build"], backend="asyncio")
        anyio.run(partial(build, app=cfg), backend="asyncio")

    return launch


if __name__ == "__main__":
    app.meta()
