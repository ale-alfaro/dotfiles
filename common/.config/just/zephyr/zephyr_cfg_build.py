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
#     "rich"
# ]
# ///
import logging
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


def copy_artifacts(build_dir: pathlib.Path, dest: pathlib.Path) -> None:

    dest.mkdir(parents=True, exist_ok=True)
    artifact_path = build_dir / "zephyr"
    if artifacts := artifact_path.glob(pattern="zmk.{hex,uf2,elf}"):
        for file_path in artifacts:
            # shutil.copy2 copies file data and metadata (like modification times)
            shutil.copy2(file_path, dest)


async def run_cmd(
    bin_exe: list[str],
    cwd: pathlib.Path,
    build_args: ZephyrBuildArgs,
) -> None:

    common_build_args = attrs.asdict(build_args.common)
    logger.debug("%s", common_build_args)
    for app in build_args.apps:
        cmake_args: list[str] = []
        build_dir = cwd / f"build_{app.artifact}"
        west_args: list[str] = [
            "--pristine=always",
            "-d",
            build_dir.absolute().as_posix(),
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
                case ("--", list() as cmake_args) if len(cmake_args) > 0:
                    if common_cmake_args := common_build_args.get("cmake_args"):
                        cmake_args.extend(common_cmake_args)
                    west_args.extend(["--", *cmake_args])
                case ("-s", pathlib.Path() as path_val):
                    app_dir = cwd / path_val
                    west_args.extend([flag, app_dir.absolute().as_posix()])

                case (_, str() as str_val):
                    west_arg_val = str_val
                    west_args.extend([flag, west_arg_val])

        build_cmd: list[str] = [*bin_exe, "west", "build", *west_args]

        logger.info(f"Running {build_cmd} in  {cwd}")  # noqa: G004
        try:
            res = await anyio.run_process(build_cmd, check=True, cwd=cwd)
            logger.info("Success! ")
            logger.debug(res.stdout.decode())
            # Ensure the destination directory exists
        except CalledProcessError as exc:
            logger.exception(f"""
                    Process Failed!
                        cmd: {exc.cmd}
                        retcode: {exc.returncode}
                        stderr: {exc.stderr.rstrip().decode()}
                        """)  # noqa: G004
            logger.exception(f"stdout: {exc.stdout.rstrip().decode()}")  # noqa: G004

        except OSError:
            logger.exception("Failed to copy artifacts")


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument(
        "file",
        help="YAML or TOML file to convert to spec",
        type=pathlib.Path,
    )
    parser.add_argument(
        "--cwd",
        help="Working directory where cmd will be run at. If left blank the cwd will be the parent directory of the file",
        type=pathlib.Path,
    )
    parser.add_argument("--test", action="store_true", help="Test mode")
    args = parser.parse_args()
    file: pathlib.Path = args.file
    cwd: pathlib.Path = args.cwd or file.parent

    log_level = logging.DEBUG if args.test else logging.INFO
    logging.basicConfig(
        level=log_level,
        format=FORMAT,
        datefmt="[%X]",
        handlers=[RichHandler()],
    )
    anyio.run(
        partial(
            run_cmd,
            bin_exe=["echo"] if args.test else ["uv", "run", "--active"],
            cwd=cwd.absolute(),
            build_args=ZephyrBuildArgs.from_file(file),
        ),
    )
