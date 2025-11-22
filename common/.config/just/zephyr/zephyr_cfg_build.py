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
# ]
# ///
import logging
import pathlib
from functools import partial
from typing import Self

import anyio
import attrs
import tomlkit
import yaml
from cattrs.preconf.pyyaml import make_converter as pyyaml_make_converter
from cattrs.preconf.tomlkit import make_converter as tomlkit_make_converter

logger = logging.getLogger(__name__)


@attrs.define
class ZephyrAppBuildArgs:
    app_dir: pathlib.Path | None = None
    board: str | None = None
    artifact: str | None = None
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


async def run_cmd(
    bin_exe: list[str],
    cwd: pathlib.Path,
    build_args: ZephyrBuildArgs,
) -> None:

    common_build_args = attrs.asdict(build_args.common)

    logger.debug("%s", common_build_args)
    for app in build_args.apps:
        cmake_args: list[str] = []
        west_args: list[str] = ["--pristine=always"]
        field_dict: dict[str, str | pathlib.Path | list[str]] = attrs.asdict(app)
        logger.info("%s", field_dict)
        for field, value in field_dict.items():
            # Check for None or empty list
            common_val = common_build_args.get(field)
            resolved_val: str | pathlib.Path | list[str] = value or common_val
            if flag := flags_for_field_map.get(field):
                match resolved_val:
                    case list() as args_list if len(args_list) > 0:
                        for arg in args_list:
                            cmake_args.append(f"-D{arg}")
                    case pathlib.Path() as path_val:
                        west_arg_val: str = path_val.absolute().as_posix()
                        west_args.extend([flag, west_arg_val])
                    case str() as str_val:
                        west_arg_val = str_val
                        west_args.extend([flag, west_arg_val])

        build_cmd: list[str] = [*bin_exe, "west", "build", *west_args]
        if cmake_args:
            build_cmd.extend(["--", *cmake_args])

        logger.info(f"Running {build_cmd} in  {cwd}")  # noqa: G004
        try:
            res = await anyio.run_process(build_cmd, check=True, cwd=cwd)
            logger.info("Success! ")
            logger.debug(res.stdout.decode())
        except anyio.CalledProcessError as exc:
            logger.exception(f"""
                    Process Failed!
                        cmd: {exc.cmd}
                        retcode: {exc.returncode}
                        stderr: {exc.stderr.rstrip().decode()}
                        stdout: {exc.output.rstrip().decode()}
                    """)  # noqa: G004


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
    logging.basicConfig(level=log_level)
    anyio.run(
        partial(
            run_cmd,
            bin_exe=["echo"] if args.test else ["uv", "run"],
            cwd=cwd.absolute(),
            build_args=ZephyrBuildArgs.from_file(file),
        ),
    )
