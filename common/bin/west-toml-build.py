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
#     "python-dotenv"
# ]
# ///
import io
import logging
import os
import pathlib
import shutil
from collections import defaultdict
from functools import partial
from subprocess import CalledProcessError
from typing import Self

import anyio
import attrs
import cattrs
import tomlkit
import yaml
from cattrs.preconf.pyyaml import make_converter as pyyaml_make_converter
from cattrs.preconf.tomlkit import make_converter as tomlkit_make_converter
from dotenv import load_dotenv
from rich.console import Console
from rich.logging import RichHandler

# logger = logging.getLogger(__name__)
error_console = Console(stderr=True, style="bold red")
FORMAT = "%(message)s"

logger = logging.getLogger("rich")


def optional_path(value: str | pathlib.Path | None) -> pathlib.Path | None:
    if value is None:
        return None
    return pathlib.Path(value)


def str_to_path(value: str | None) -> pathlib.Path | None:
    if not value:
        return None
    return pathlib.Path(value)


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
class ZephyrAppBuildArgs:
    app_dir: pathlib.Path
    board: str | None = None
    conf_file: str | None = None
    dtc_overlay: str | None = None
    snippets: str | None = None
    shield: str | None = None
    artifact: str = attrs.field(init=False)
    build_dir: pathlib.Path | None = attrs.field(init=False)
    cmake_args: list[str] = attrs.field(factory=list)

    def update_with_cwd(self, cwd: pathlib.Path) -> None:
        self.app_dir = cwd.absolute() / self.app_dir
        self.artifact = f"build_{self.app_dir.name}"
        self.build_dir = self.app_dir / self.artifact


BuildSpecDefaultDict = defaultdict[str, str | pathlib.Path | list[str]]
DEFAULT_WEST_BUILD_CMD = ["build", "--pristine=always"]


def copy_artifacts(build_dir: pathlib.Path, dest: pathlib.Path) -> None:
    dest.mkdir(parents=True, exist_ok=True)
    artifact_path = build_dir / "zephyr"
    if artifacts := artifact_path.glob(pattern="zmk.{hex,uf2,elf}"):
        for file_path in artifacts:
            # shutil.copy2 copies file data and metadata (like modification times)
            shutil.copy2(file_path, dest)


@attrs.define
class ZephyrBuildSpec:
    cwd: pathlib.Path
    apps: list[ZephyrAppBuildArgs] = attrs.field(factory=list)

    @classmethod
    def from_file(
        cls,
        file: pathlib.Path,
    ) -> Self:
        if file.suffix == ".yaml":
            pyyaml_make_converter()
            load_fn = yaml.safe_load
        elif file.suffix == ".toml":
            tomlkit_make_converter()
            load_fn = tomlkit.load
        else:
            msg = f"wrong file type {file}. Ext: {file.suffix}"
            raise ValueError(msg)

        with file.open(encoding="utf-8") as f:
            doc: tomlkit.TOMLDocument = load_fn(f)
            base = file.parent.absolute()
            logger.info(f"path: {base} spec_file: {doc}")  # noqa: G004
            if (_common := doc.get("common")) and (_apps := doc.get("apps")):

                def resolve_app(
                    raw: BuildSpecDefaultDict,
                ) -> ZephyrAppBuildArgs:
                    c = cattrs.Converter()
                    if app := c.structure(_common | raw, ZephyrAppBuildArgs):
                        app.update_with_cwd(base)
                        return app
                    raise ValueError("Couldn't resolve")

                return cls(base, [resolve_app(app) for app in _apps])
            msg = f"Mising fields in {file}. Ext: {file.suffix}"
            raise ValueError(msg)

    @classmethod
    def from_arg(cls, arg: str) -> Self:
        file = pathlib.Path(arg)
        if not file.exists():
            msg = f"File argument: {arg!r}  doesn't exist"
            raise argparse.ArgumentError(argument="spec_file", message=msg) from e
        try:
            return cls.from_file(file)
        except ValueError as e:
            msg = f"File argument invalid. {e}"
            raise argparse.ArgumentError(argument="spec_file", message=msg) from e


async def create_west_build_cmd_from_spec(
    spec: ZephyrBuildSpec,
    *,
    cwd_arg: pathlib.Path | None = None,
    zephyr_base: pathlib.Path,
    test_mode: bool = False,
    flash: bool = False,
) -> None:

    cwd = cwd_arg or spec.cwd
    build_dirs: list[pathlib.Path] = []

    for app in spec.apps:
        west_args: list[str] = list(DEFAULT_WEST_BUILD_CMD)
        if app.build_dir:
            build_dirs.append(app.build_dir)
            west_args.extend(["-d", str(app.build_dir.absolute())])
        if app.app_dir:
            west_args.extend(["-s", str(app.app_dir.absolute())])

        for field in ("board", "conf_file", "dtc_overlay", "snippets", "shield"):
            if value := getattr(app, field):
                west_args.extend([flags_for_field_map[field], value])

        if app.cmake_args:
            west_args.extend(["--", *app.cmake_args])

        if test_mode:
            west_args.append("--dry-run")
        await run_west_cmd(west_args, cwd, zephyr_base)
        if flash:
            await run_west_cmd(["flash", "-d", str(app.build_dir)], cwd, zephyr_base)


async def run_west_cmd(
    west_cmd: list[str],
    cwd: pathlib.Path,
    zephyr_base: pathlib.Path,
) -> None:
    requirements_txt_path = zephyr_base / "scripts" / "requirements-base.txt"
    if not requirements_txt_path.exists():
        msg = f"requirements.txt not found in {requirements_txt_path}"
        logger.error(msg)
        raise FileExistsError(msg)

    cmd = [
        "uv",
        "run",
        "--with-requirements",
        str(requirements_txt_path),
        "west",
        *west_cmd,
    ]

    logger.info(f"Running {cmd} in  {cwd}")  # noqa: G004
    try:
        res = await anyio.run_process(
            cmd,
            check=True,
            cwd=cwd,
        )
        logger.info("Success! ")
        logger.debug(res.stdout.decode())
        # Ensure the destination directory exists
    except CalledProcessError as exc:
        logger.exception(f"""
                    Process Failed!
                        cmd: {exc.cmd}
                        retcode: {exc.returncode}
                        stderr: {exc.stderr.rstrip().decode()}
                        BUILD_OUTPUT:
                        stdout: {exc.stdout.rstrip().decode()}
                        """)  # noqa: G004

    except OSError:
        logger.exception("Failed to copy artifacts")


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument(
        "spec_file",
        help="YAML or TOML file to convert to spec",
        type=pathlib.Path,
        nargs="?",
    )
    parser.add_argument(
        "--cwd",
        help="Working directory where cmd will be run at. If left blank the cwd will be the parent directory of the file",
        type=pathlib.Path,
    )
    parser.add_argument(
        "--dotenv",
        help=".env file to load before running west",
        type=pathlib.Path,
    )
    parser.add_argument(
        "-z",
        "--zephyr-base",
        help="Zephyr Base directory",
        type=pathlib.Path,
    )
    parser.add_argument(
        "--flash",
        help="Flash after building",
        action="store_true",
    )
    parser.add_argument("--test", action="store_true", help="Test mode")
    args = parser.parse_args()
    if args.dotenv:
        dotenv = pathlib.Path(args.dotenv)
        if dotenv.exists():
            load_dotenv(dotenv)
        else:
            msg = f".env file not found at {dotenv}"
            raise FileNotFoundError(msg)

    zephyr_base: pathlib.Path
    if arg := args.zephyr_base:
        zephyr_base = pathlib.Path(arg)
        config = io.StringIO("ZEPHYR_BASE=" + str(zephyr_base))
        load_dotenv(stream=config)
    elif env_var := os.environ.get("ZEPHYR_BASE"):
        zephyr_base = pathlib.Path(
            env_var,
        )
    else:
        parser.error(
            "ZEPHYR_BASE not defined; set the env var or pass -z/--zephyr-base",
        )

    log_level = logging.DEBUG if args.test else logging.INFO
    logging.basicConfig(
        level=log_level,
        format=FORMAT,
        datefmt="[%X]",
        handlers=[RichHandler()],
    )
    if not zephyr_base.exists():
        msg = f"ZEPHYR_BASE env variable must be set or added using -z and --zephyr-base. Current value is {zephyr_base}"
        logger.error(msg)
        raise NotADirectoryError(msg)

    if (spec_file := args.spec_file) and spec_file.exists():
        spec = ZephyrBuildSpec.from_file(spec_file)
        anyio.run(
            partial(
                create_west_build_cmd_from_spec,
                spec,
                cwd_arg=spec.cwd,
                zephyr_base=zephyr_base,
                flash=args.flash,
                test_mode=args.test,
            ),
        )
    else:
        cwd = args.cwd or pathlib.Path.cwd()
        anyio.run(
            partial(
                run_west_cmd,
                ["topdir"],
                cwd=cwd,
                zephyr_base=zephyr_base,
            ),
        )
