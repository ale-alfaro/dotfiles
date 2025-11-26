#!/usr/bin/env -S uv run --script
#
# /// script
# requires-python = ">=3.13"
# dependencies = [
#   "requests<3",
#   "psutil",
# ]
# ///

"""UF2 runner (flash only) for UF2 compatible bootloaders."""

import argparse
import logging
import shutil
import sys
from pathlib import Path

logger = logging.getLogger(__name__)


import psutil


def get_uf2_info_path(part) -> Path:
    return Path(part.mountpoint) / "INFO_UF2.TXT"


def is_uf2_partition(part):
    try:
        return (part.fstype in {"vfat", "FAT", "msdos"}) and get_uf2_info_path(
            part,
        ).is_file()
    except PermissionError:
        return False


def get_uf2_info(part):
    lines = get_uf2_info_path(part).read_text().splitlines()

    lines = lines[1:]  # Skip the first summary line

    def split_uf2_info(line: str):
        k, _, val = line.partition(":")
        return k.strip(), val.strip()

    return {k: v for k, v in (split_uf2_info(line) for line in lines) if k and v}


def match_board_id(part, board_id):
    info = get_uf2_info(part)

    return info.get("Board-ID") == board_id


def get_uf2_partitions(board_id=None):
    parts = [part for part in psutil.disk_partitions() if is_uf2_partition(part)]

    if (board_id is not None) and parts:
        parts = [part for part in parts if match_board_id(part, board_id)]
        if not parts:
            logger.warning(
                "Discovered UF2 partitions don't match Board-ID '%s'",
                board_id,
            )

    return parts


def copy_uf2_to_partition(uf2_file, part):
    try:
        shutil.copy(uf2_file, part.mountpoint)
    except OSError as e:
        if e.errno == PermissionError:
            logger.info("Flash successful (device disconnected as expected).")
        else:
            raise


def list_devices(board_id=None):
    partitions = get_uf2_partitions(board_id)
    if not partitions:
        logger.info("No matching UF2 partitions found")
        return

    logger.info("Found %d matching UF2 partitions:", len(partitions))
    for part in partitions:
        info = get_uf2_info(part)
        logger.info("  - Mountpoint: %s", part.mountpoint)
        logger.info("    Board-ID: %s", info.get("Board-ID", "N/A"))


def main():
    parser = argparse.ArgumentParser(
        description="Flash a UF2 file to a device or list available devices.",
    )
    parser.add_argument("uf2_file", type=Path, nargs="?", help="The UF2 file to flash.")
    parser.add_argument(
        "--board-id",
        dest="board_id",
        help="Board-ID value to match from INFO_UF2.TXT",
    )
    parser.add_argument(
        "--list-devices",
        action="store_true",
        help="List available UF2 devices and exit.",
    )
    args = parser.parse_args()

    logging.basicConfig(level=logging.INFO, format="%(message)s")

    if args.list_devices:
        list_devices(args.board_id)
        sys.exit(0)

    if not args.uf2_file:
        parser.error("the following arguments are required: uf2_file")

    if not args.uf2_file.is_file():
        raise RuntimeError("UF2 file not found")

    partitions = get_uf2_partitions(args.board_id)
    if not partitions or args.board_id is None:
        raise RuntimeError("No UF2 partitions found. Please specify a --board-id.")

    if len(partitions) > 1:
        if args.board_id is None:
            logger.error(
                "More than one UF2 partition found. Please specify a --board-id",
            )
            list_devices()
            sys.exit(1)
        else:
            raise RuntimeError("More than one matching UF2 partitions found")

    part = partitions[0]
    logger.info("Copying UF2 file to '%s'", part.mountpoint)
    copy_uf2_to_partition(args.uf2_file, part)


if __name__ == "__main__":
    main()
