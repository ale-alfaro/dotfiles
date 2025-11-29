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
from functools import partial
from subprocess import CalledProcessError
from typing import Self

import anyio
import attrs
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


@attrs.define
class ZephyrAppBuildArgs:
    artifact: str = "build"
    app_dir: pathlib.Path | None = None
    board: str | None = None
    conf_file: str | None = None
    dtc_overlay: str | None = None
    snippets: str | None = None
    shield: str | None = None
    cmake_args: list[str] = attrs.field(factory=list)


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
class ZephyrBuildArgs:
    common: ZephyrAppBuildArgs
    apps: list[ZephyrAppBuildArgs] = attrs.field(factory=list)

    @classmethod
    def from_file(
        cls,
        file: pathlib.Path,
    ) -> Self:
        if file.suffix == ".yaml":
            converter = pyyaml_make_converter()
            load_fn = yaml.safe_load
        elif file.suffix == ".toml":
            converter = tomlkit_make_converter()
            load_fn = tomlkit.load
        else:
            msg = f"wrong file type {file}. Ext: {file.suffix}"
            raise ValueError(msg)
        with file.open(encoding="utf-8") as f:
            return converter.structure(load_fn(f), ZephyrBuildArgs)


@attrs.define
class ZephyrBuildSpec:
    build_args: ZephyrBuildArgs
    cwd: pathlib.Path

    @classmethod
    def from_arg(cls, arg: str) -> Self:
        file = pathlib.Path(arg)
        if not file.exists():
            msg = f"File argument: {arg!r}  doesn't exist"
            raise argparse.ArgumentError(msg)
        try:
            return cls(ZephyrBuildArgs.from_file(file), file)
        except ValueError as e:
            msg = f"File argument invalid. {e}"
            raise argparse.ArgumentError(msg) from e


def copy_artifacts(build_dir: pathlib.Path, dest: pathlib.Path) -> None:
    dest.mkdir(parents=True, exist_ok=True)
    artifact_path = build_dir / "zephyr"
    if artifacts := artifact_path.glob(pattern="zmk.{hex,uf2,elf}"):
        for file_path in artifacts:
            # shutil.copy2 copies file data and metadata (like modification times)
            shutil.copy2(file_path, dest)


DEFAULT_WEST_BUILD_CMD = ["build", "--pristine=always"]


def create_west_build_cmd_from_spec(
    spec: ZephyrBuildSpec,
    *,
    cwd_arg: pathlib.Path | None = None,
    test_mode: bool = False,
) -> list[list[str]]:
    build_args: ZephyrBuildArgs = spec.build_args
    cwd: pathlib.Path = cwd_arg or spec.cwd.parent
    common_build_args = attrs.asdict(build_args.common)
    logger.debug("%s", common_build_args)
    build_cmds: list[list[str]] = []
    for app in build_args.apps:
        build_dir = cwd.absolute() / f"build_{app.artifact}"
        west_args: list[str] = [
            *DEFAULT_WEST_BUILD_CMD,
            "-d",
            str(build_dir),
        ]
        field_dict: dict[str, str | pathlib.Path | list[str]] = common_build_args | {
            k: v for k, v in attrs.asdict(app).items() if v
        }
        logger.info("%s", field_dict)
        flag_val = {
            flag: val
            for flag, val in {
                flags_for_field_map.get(field): value
                for field, value in field_dict.items()
            }.items()
            if flag
        }
        for flag, value in flag_val.items():
            match flag, value:
                case ("-s", pathlib.Path() as path_val):
                    app_dir = cwd / path_val
                    west_args.extend([flag, str(app_dir)])

                case (_, str() as str_val):
                    west_arg_val = str_val
                    west_args.extend([flag, west_arg_val])

        if test_mode:
            west_args.append("--dry-run")
        if cmake_args := field_dict.get("cmake_args"):
            west_args.extend([flag, *cmake_args])

        build_cmds.append(west_args)
    return build_cmds


async def build_west_spec(
    build_cmds: list[list[str]],
    cwd: pathlib.Path,
    zephyr_base: pathlib.Path,
) -> None:
    for cmd in build_cmds:
        await run_west_cmd(cmd, cwd, zephyr_base)


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
        type=ZephyrBuildSpec.from_arg,
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
    parser.add_argument("--test", action="store_true", help="Test mode")
    args = parser.parse_args()
    if args.dotenv:
        dotenv = pathlib.Path(args.dotenv)
        if dotenv.exists():
            load_dotenv(dotenv)
        else:
            msg = f".env file not found at {dotenv}"
            raise FileNotFoundError(msg)

    if zephyr_base := args.zephyr_base:
        config = io.StringIO("ZEPHYR_BASE=" + zephyr_base)
        load_dotenv(stream=config)
    else:
        zephyr_base: pathlib.Path = pathlib.Path(
            os.environ.get("ZEPHYR_BASE"),
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

    if spec_file := args.spec_file:
        build_cmds = create_west_build_cmd_from_spec(
            spec_file,
            test_mode=args.test,
        )
        anyio.run(
            partial(
                build_west_spec,
                build_cmds,
                cwd=args.cwd,
                zephyr_base=zephyr_base,
            ),
        )
    else:
        anyio.run(
            partial(
                run_west_cmd,
                ["topdir"],
                cwd=args.cwd or pathlib.Path.cwd(),
                zephyr_base=zephyr_base,
            ),
        )
