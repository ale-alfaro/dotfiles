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
import pathlib
import shlex
import shutil
import tomllib
from collections import defaultdict
from collections.abc import Mapping
from functools import cached_property
from subprocess import CalledProcessError
from typing import Annotated, Any, Self, cast, override

import anyio
import attrs
import cattrs
import cyclopts
import yaml
from attr import AttrsInstance
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


BuildSpecDefaultDict = defaultdict[str, str | pathlib.Path | list[str]]
DEFAULT_WEST_BUILD_CMD = ["build", "--pristine=always"]
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


def update_with_cwd(value: pathlib.Path, self) -> pathlib.Path:
    return self.cwd.absolute() / value


@attrs.define
class ZephyrAppBuildArgs:
    id: str
    cwd: pathlib.Path
    app_dir: pathlib.Path = attrs.field(
        converter=attrs.Converter(
            update_with_cwd,
            takes_self=True,
        ),
    )
    board: str
    conf_file: str | None = None
    dtc_overlay: str | None = None
    snippets: str | None = None
    shield: str | None = None
    cmake_args: list[str] = attrs.field(factory=list)

    @property
    def build_dir(self) -> pathlib.Path:
        return self.app_dir / f"build_{self.id}"

    @property
    def west_command(self) -> list[str]:
        west_args: list[str] = list(DEFAULT_WEST_BUILD_CMD)
        if self.build_dir:
            west_args.extend(["-d", str(self.build_dir.absolute())])
        if self.app_dir:
            west_args.extend(["-s", str(self.app_dir.absolute())])

        for field in ("board", "conf_file", "dtc_overlay", "snippets", "shield"):
            if value := getattr(self, field):
                west_args.extend([flags_for_field_map[field], value])

        if self.cmake_args:
            west_args.extend(["--", *self.cmake_args])
        return west_args


def copy_artifacts(build_dir: pathlib.Path, dest: pathlib.Path) -> None:
    dest.mkdir(parents=True, exist_ok=True)
    artifact_path = build_dir / "zephyr"
    if artifacts := artifact_path.glob(pattern="zmk.{hex,uf2,elf}"):
        for file_path in artifacts:
            # shutil.copy2 copies file data and metadata (like modification times)
            shutil.copy2(file_path, dest)


@attrs.define
class WestSpec:
    cwd: pathlib.Path
    apps: list[ZephyrAppBuildArgs] = attrs.field(factory=list)

    @classmethod
    def from_file(
        cls,
        file: pathlib.Path,
        cwd_arg: pathlib.Path | None = None,
    ) -> Self:
        if file.suffix == ".yaml":
            load_fn = yaml.safe_load
        elif file.suffix == ".toml":
            load_fn = tomllib.load
        else:
            msg = f"wrong file type {file}. Ext: {file.suffix}"
            raise ValueError(msg)

        with file.open("+rb") as f:
            doc = load_fn(f)
            cwd = cwd_arg or file.parent.absolute()
            logger.info(f"path: {cwd} spec_file: {doc}")  # noqa: G004

            try:
                if (_common := doc.get("common")) and (_apps := doc.get("apps")):

                    def resolve_app(
                        raw: Mapping[str, str],
                    ) -> ZephyrAppBuildArgs:
                        c = cattrs.Converter()
                        resolved_dict = _common | raw
                        app_dir = resolved_dict["app_dir"]
                        board: str = resolved_dict["board"]
                        if "id" not in resolved_dict:
                            resolved_dict["id"] = f"{board[:5]}_{app_dir}"
                        resolved_dict["cwd"] = cwd
                        app = c.structure(resolved_dict, ZephyrAppBuildArgs)
                        return app

                    return cls(cwd, [resolve_app(app) for app in _apps])
                raise ValueError

            except (KeyError, ValueError, TypeError) as e:
                msg = f"Mising fields in {file}. Ext: {file.suffix}"
                raise ValueError(msg) from e


async def run_west_cmd(
    west_cmd: list[str],
    cwd: pathlib.Path,
    zephyr_base: pathlib.Path | None = None,
) -> None:
    if zephyr_base:
        config = io.StringIO("ZEPHYR_BASE=" + str(zephyr_base))
        load_dotenv(stream=config)
    elif env_var := os.environ.get("ZEPHYR_BASE"):
        zephyr_base = pathlib.Path(
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
        "uv",
        "run",
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
        progress.console.print(
            Panel(
                f"""
Running:
    [bold]west {shlex.join(west_cmd)}[/bold]
                               """,
                title=f"{'Building' if west_cmd[0] == 'build' else 'Flashing'} app ",
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
            progress.console.print(
                Panel(
                    f"""
            [bold]{res.stdout.decode().rstrip()}[/bold]
                               """,
                    title=f"{'Build' if west_cmd[0] == 'build' else 'Flash'} Output ",
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

        except OSError:
            progress.update(task, description="Failed to copy artifacts!")
            error_console.print("Failed to copy artifacts")


app = cyclopts.App()


@attrs.frozen(kw_only=True)
class OptionalPathValidator(cyclopts.validators.Path):
    @override
    def __call__(self, type_: Any, path: Any) -> Any:
        if isinstance(type_, pathlib.Path | None):
            if path is None:
                return None

            return super().__call__(pathlib.Path, cast("pathlib.Path", path))

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
        pathlib.Path,
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
        pathlib.Path | None,
        cyclopts.Parameter(validator=OptionalPathValidator(exists=True)),
    ] = None
    """Current working directory to run the west commands on"""
    zephyr_base: Annotated[
        pathlib.Path | None,
        cyclopts.Parameter(validator=OptionalPathValidator(exists=True)),
    ] = None
    """ Zephyr Base environment variable pointing to the zephyr project in use"""
    dotenv: Annotated[
        pathlib.Path | None,
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
        return WestSpec.from_file(self.spec_file, self.cwd)

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

        if not self.spec_file.exists():
            raise cyclopts.ValidationError("Spec file path doesnt exist")
        self.spec = WestSpec.from_file(self.spec_file, self.cwd)


@app.command
async def build(common: Common, target: str | None = None) -> None:
    west_extra_args = []

    spec = common.spec

    if common.test:
        west_extra_args.append("--dry-run")
    if target:
        west_extra_args.extend(["-t", target])

    async def run_build(app: ZephyrAppBuildArgs) -> None:
        west_args = app.west_command
        if west_extra_args:
            west_args.extend(west_extra_args)
        await run_west_cmd(west_args, spec.cwd, common.zephyr_base)

    if app := common.single_app:
        await run_build(app)
    else:
        for app in spec.apps:
            await run_build(app)


@app.command
async def flash(
    common: Common,
    *,
    clean: Annotated[bool, cyclopts.Parameter(negative="")] = False,
) -> None:

    spec = common.spec
    if not (app := common.single_app):
        app = spec.apps[0]

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
def help():
    """Display the help screen."""
    app.help_print()


async def main_loop():
    await app.run_async()


if __name__ == "__main__":
    anyio.run(main_loop, backend="asyncio")
