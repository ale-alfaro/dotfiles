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

import sys
from functools import partial
from pathlib import Path
from typing import overload

import attrs
import cattrs
from rich.pretty import pprint

EXAMPLE_TOML = """

[common]
board = "nice_nano_v2"
app_dir = "zmk/app"
cmake_args = ["-DCONFIG_ZMK_STUDIO=y" ,"-DCONFIG_ZMK_STUDIO_LOCKING=n" , '-DBOARD_ROOT=/home/alealfaro/dotfiles/common/zmk-config/zmk/app' ,'-DZMK_CONFIG=/home/alealfaro/dotfiles/common/zmk-config/config']
snippets = "studio-rpc-usb-uart"

[[apps]]
id = "corne_left"
cmake_args = [ '-DSHIELD=corne_left' ]

[[apps]]
id = "corne_right"
cmake_args = [ '-DSHIELD=corne_right' ]

"""
import io
import logging
import os
import shlex
from collections import defaultdict
from functools import cached_property
from subprocess import CalledProcessError
from typing import Annotated, Any, Self, cast, override

import anyio
import attr
import cyclopts
from attr import AttrsInstance
from cattrs.preconf.tomlkit import TomlkitConverter
from dotenv import load_dotenv
from rich.console import Console
from rich.panel import Panel
from rich.progress import (
    Progress,
    SpinnerColumn,
    TaskID,
    TextColumn,
)

print_console = Console()
error_console = Console(stderr=True, style="bold red")
FORMAT = "%(message)s"
logger = logging.getLogger(__name__)
# logger = logging.getLogger("rich")
# log_handler = RichHandler()


BuildSpecDefaultDict = defaultdict[str, str | Path | list[str]]
DEFAULT_WEST_BUILD_CMD = ["build", "--pristine=always"]
DEFAULT_TWISTER_FLAGS = ["--clobber-output", "-W", "-i"]
flags_for_field_map: dict[str, str] = {
    "board": "-b",
    "app_dir": "-s",
    "build_dir": "-d",
    "conf_file": "--extra-conf",
    "dtc_overlay": "--extra-dtc-overlay",
    "snippets": "--snippet",
    "shield": "--shield",
    "cmake_args": "--",
}


@attrs.define
class CommonCfg:
    board: str | None = None
    app_dir: Path | None = None
    conf_file: str | None = None
    dtc_overlay: str | None = None
    snippets: str | None = None
    shield: str | None = None
    cmake_args: list[str] | None = None


@attrs.define
class AppCfg(CommonCfg):
    id: str | None = None


@attrs.define
class FileSpec:
    common: CommonCfg = attrs.field(factory=CommonCfg)
    apps: list[AppCfg] = attrs.field(factory=list)


@attrs.define
class ZephyrAppBuildArgs:
    id: str
    cwd: Path
    app_dir: Path
    board: str
    conf_file: str | None = None
    dtc_overlay: str | None = None
    snippets: str | None = None
    shield: str | None = None
    cmake_args: list[str] | None = None

    @classmethod
    def from_cfg(cls, cfg: AppCfg, cwd: Path) -> Self:
        if cfg.app_dir is None:
            raise ValueError("app_dir is required (set in [common] or each [[apps]])")
        if cfg.board is None:
            raise ValueError("board is required (set in [common] or each [[apps]])")

        app_id = cfg.id or f"{cfg.board[:5]}_{cfg.app_dir.name}"
        return cls(
            id=app_id,
            cwd=cwd,
            app_dir=cfg.app_dir,
            board=cfg.board,
            conf_file=cfg.conf_file,
            dtc_overlay=cfg.dtc_overlay,
            snippets=cfg.snippets,
            shield=cfg.shield,
            cmake_args=cfg.cmake_args,
        )

    @property
    def build_dir(self) -> Path:
        return self.app_dir / f"build_{self.id}"

    @property
    def west_command(self) -> list[str]:
        west_args: list[str] = list(DEFAULT_WEST_BUILD_CMD)
        west_args.extend(["-d", str(self.build_dir.absolute())])
        west_args.extend(["-s", str(self.app_dir.absolute())])

        for field in ("board", "conf_file", "dtc_overlay", "snippets", "shield"):
            if value := getattr(self, field):
                west_args.extend([flags_for_field_map[field], value])

        if self.cmake_args:
            west_args.extend(["--", *self.cmake_args])
        return west_args


def _make_file_spec(text: str, spec_dir: Path) -> FileSpec:
    converter = TomlkitConverter()

    @converter.register_structure_hook
    def resolve_path(val, _) -> Path:
        # Accept tomlkit nodes, strings, or Paths and make them absolute against spec_dir.
        p = val if isinstance(val, Path) else Path(str(val))
        return p if p.is_absolute() else (spec_dir / p).resolve()

    file_spec = converter.loads(text, FileSpec)

    return file_spec


@overload
def load_spec(
    *,
    file: Path,
    text: None = ...,
    spec_dir: None = ...,
) -> tuple[list[ZephyrAppBuildArgs], Path]: ...


@overload
def load_spec(
    *,
    file: None = ...,
    text: str,
    spec_dir: Path,
) -> tuple[list[ZephyrAppBuildArgs], Path]: ...


def load_spec(
    *,
    file: Path | None = None,
    text: str | None = None,
    spec_dir: Path | None = None,
) -> tuple[list[ZephyrAppBuildArgs], Path]:
    if text and spec_dir:
        logger.info(f"Got text{text} and spec_dir{spec_dir}")  # noqa: G004
    elif file:
        spec_dir = file.parent
        text = file.read_text()
    else:
        raise ValueError

    file_spec = _make_file_spec(text, spec_dir)
    cmake_args: list[str] = file_spec.common.cmake_args or []
    common_dict = attrs.asdict(
        file_spec.common,
        recurse=False,
        filter=attrs.filters.exclude(list),
    )
    merged_apps: list[ZephyrAppBuildArgs] = []

    def app_dict_serializer(inst: type, field: attr.Attribute, value: Any) -> Any:
        match value:
            case [*args] if cmake_args:
                return [*cmake_args, *args]
            case Path() as path if field.name == "app_dir":
                return spec_dir / path
            case None if val := common_dict.get(field.name):
                return val
            case _:
                return value

    for raw_app in file_spec.apps:
        merged = attrs.asdict(
            raw_app,
            value_serializer=app_dict_serializer,
        )
        # breakpoint()

        merged_cfg = cattrs.global_converter.structure_attrs_fromdict(merged, AppCfg)
        merged_apps.append(ZephyrAppBuildArgs.from_cfg(merged_cfg, spec_dir))

    return merged_apps, spec_dir


@attrs.define
class WestSpec:
    apps: list[ZephyrAppBuildArgs]
    cwd: Path


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


app = cyclopts.App()


@attrs.frozen(kw_only=True)
class OptionalPathValidator(cyclopts.validators.Path):
    @override
    def __call__(self, type_: Any, path: Any) -> Any:
        if isinstance(type_, Path | None):
            if path is None:
                return None

            return super().__call__(Path, cast("Path", path))

        return super().__call__(type_, path)


def complicated(
    value: int | str | None,
    self: AttrsInstance,
) -> ZephyrAppBuildArgs | None:
    build = cast("Common", self)
    spec = build.spec
    app: ZephyrAppBuildArgs | None = None
    match value:
        case int(x) if len(spec.apps) > x:
            app = spec.apps[x]
        case str(app_name):
            app = next((app for app in spec.apps if app.id == app_name), None)
            if not app:
                app = next(
                    (app for app in spec.apps if app.id.startswith(app_name)),
                    None,
                )
        case _:
            return None

    if not app:
        return None

    return app


@cyclopts.Parameter(name="*")
@attrs.define
class Common:
    spec_file: Annotated[
        Path,
        cyclopts.Parameter(validator=cyclopts.validators.Path(exists=True)),
    ]
    """Specification file for running west commands"""
    verbose: Annotated[bool, cyclopts.Parameter(negative="")] = attrs.field(
        kw_only=True,
        default=False,
    )
    """Enable verbose logging"""
    test: Annotated[bool, cyclopts.Parameter(negative="")] = attrs.field(
        kw_only=True,
        default=False,
    )
    """Enable test mode"""
    cwd: Annotated[
        Path | None,
        cyclopts.Parameter(validator=OptionalPathValidator(exists=True)),
    ] = None
    """Current working directory to run the west commands on"""
    zephyr_base: Annotated[
        Path | None,
        cyclopts.Parameter(validator=OptionalPathValidator(exists=True)),
    ] = None
    """ Zephyr Base environment variable pointing to the zephyr project in use"""
    dotenv: Annotated[
        Path | None,
        cyclopts.Parameter(validator=OptionalPathValidator(exists=True)),
    ] = None
    """.env file to load environment variables"""
    single_app: ZephyrAppBuildArgs | None = attrs.field(
        kw_only=True,
        converter=attrs.Converter(
            complicated,
            takes_self=True,
        ),
        default=None,
    )
    """Single app to complete the action on."""

    @cached_property
    def spec(self) -> WestSpec:
        if not self.spec_file.exists():
            raise cyclopts.ValidationError("Spec file path doesnt exist")
        return WestSpec(*load_spec(file=self.spec_file))

    def __attrs_post_init__(self):
        if dotenv := self.dotenv:
            if dotenv.exists():
                load_dotenv(dotenv)
            else:
                msg = f".env file not found at {dotenv}"
                raise FileNotFoundError(msg)

        log_level = logging.DEBUG if self.verbose else logging.INFO
        logging.basicConfig(
            level=log_level,
            format=FORMAT,
            datefmt="[%X]",
            # handlers=[log_handler],
        )


async def run_build(
    app: ZephyrAppBuildArgs,
    west_extra_args: list[str],
    cwd: Path,
    zephyr_base: Path | None = None,
) -> None:
    west_args = app.west_command
    if west_extra_args:
        west_args.extend(west_extra_args)
    await run_west_cmd(west_args, cwd, zephyr_base)


async def run_test(
    app: ZephyrAppBuildArgs,
    twister_extra_args: list[str],
    cwd: Path,
    zephyr_base: Path | None = None,
) -> None:
    west_args = [
        "twister",
        "-T",
        str(app.app_dir),
        "-p",
        app.board,
        *DEFAULT_TWISTER_FLAGS,
    ]
    if twister_extra_args:
        west_args.extend(twister_extra_args)

    await run_west_cmd(west_args, cwd, zephyr_base)


@app.command
async def build(common: Common, target: str | None = None) -> None:
    west_extra_args = []

    if common.test:
        west_extra_args.append("--dry-run")
    if target:
        west_extra_args.extend(["-t", target])
    cwd: Path = common.cwd or common.spec.cwd
    if app := common.single_app:
        await run_build(app, west_extra_args, cwd, common.zephyr_base)
    else:
        for app in common.spec.apps:
            await run_build(app, west_extra_args, cwd, common.zephyr_base)
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


@app.command
async def test(common: Common) -> None:
    """Run twister for each app in the spec (or a single app if selected)."""
    twister_extra_args: list[str] = []
    if common.verbose:
        twister_extra_args.append("-v")

    cwd: Path = common.cwd or common.spec.cwd
    if app := common.single_app:
        await run_test(app, twister_extra_args, cwd, common.zephyr_base)
    else:
        for app in common.spec.apps:
            await run_test(app, twister_extra_args, cwd, common.zephyr_base)


@app.command
async def flash(
    common: Common,
    *,
    clean: Annotated[bool, cyclopts.Parameter(negative="")] = False,
) -> None:
    spec = common.spec
    app = spec.apps[0]
    if single_app := common.single_app:
        app = single_app

    if not app.build_dir.exists() or clean:
        build_cmd = app.west_command
        await run_west_cmd(build_cmd, spec.cwd, common.zephyr_base)
        if not app.build_dir.exists():
            msg = f"{app.build_dir} not found. app build dir couldn't be found after executing the build. "
            raise cyclopts.ValidationError(msg)

    await run_west_cmd(
        ["flash", "-d", str(app.build_dir)],
        spec.cwd,
        common.zephyr_base,
    )


@app.command
def demo():
    """Print resolved west build commands using the embedded EXAMPLE_TOML."""
    apps, _spec_dir = load_spec(text=EXAMPLE_TOML, spec_dir=Path.cwd())
    for _app in apps:
        pprint(_app)


@app.command
def help():
    """Display the help screen."""
    app.help_print()


async def main_loop():
    await app.run_async()


if __name__ == "__main__":
    anyio.run(partial(main_loop), backend="asyncio")
