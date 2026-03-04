#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.13"
# dependencies = [
#     "psutil",
# ]
# ///


"""UF2 runner (flash only) for UF2 compatible bootloaders."""

import argparse
import logging
import sys
from pathlib import Path
from shutil import copy

from psutil import sdiskpart
from psutil._common import sdiskpart

try:
    import psutil
except ImportError:
    sys.exit(1)


def get_uf2_info_path(part) -> Path:
    return Path(part.mountpoint) / "INFO_UF2.TXT"


def is_uf2_partition(part: sdiskpart) -> bool:
    try:
        return (part.fstype in {"vfat", "FAT", "msdos"}) and get_uf2_info_path(
            part,
        ).is_file()
    except PermissionError:
        return False


def get_uf2_info(part: sdiskpart) -> dict[str, str]:
    lines = get_uf2_info_path(part).read_text().splitlines()

    lines = lines[1:]  # Skip the first summary line

    def split_uf2_info(line: str) -> tuple[str, str]:
        k, _, val = line.partition(":")
        return k.strip(), val.strip()

    return {k: v for k, v in (split_uf2_info(line) for line in lines) if k and v}


def match_board_id(part: sdiskpart, board_id) -> bool:
    info = get_uf2_info(part)

    return info.get("Board-ID") == board_id


def get_uf2_partitions(board_id=None) -> list[sdiskpart]:
    parts = [part for part in psutil.disk_partitions() if is_uf2_partition(part)]

    if (board_id is not None) and parts:
        parts = [part for part in parts if match_board_id(part, board_id)]
        if not parts:
            logging.warning(
                "Discovered UF2 partitions don't match Board-ID '%s'",
                board_id,
            )

    return parts


def copy_uf2_to_partition(uf2_file, part: sdiskpart) -> None:
    try:
        copy(uf2_file, part.mountpoint)
    except OSError as e:
        if isinstance(e, PermissionError):
            logging.info("Flash successful (device disconnected as expected).")
        else:
            raise


def list_devices(board_id=None) -> None:
    partitions = get_uf2_partitions(board_id)
    if not partitions:
        logging.info("No matching UF2 partitions found")
        return

    logging.info("Found %d matching UF2 partitions:", len(partitions))
    for part in partitions:
        info = get_uf2_info(part)
        logging.info("  - Mountpoint: %s", part.mountpoint)
        logging.info("    Board-ID: %s", info.get("Board-ID", "N/A"))


def main() -> None:
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
        msg = f"UF2 file not found: {args.uf2_file}"
        raise RuntimeError(msg)

    partitions = get_uf2_partitions(args.board_id)
    if not partitions:
        if args.board_id is None:
            raise RuntimeError("No UF2 partitions found. Please specify a --board-id.")
        raise RuntimeError("No matching UF2 partitions found")

    if len(partitions) > 1:
        if args.board_id is None:
            logging.error(
                "More than one UF2 partition found. Please specify a --board-id.",
            )
            list_devices()
            sys.exit(1)
        else:
            raise RuntimeError("More than one matching UF2 partitions found")

    part = partitions[0]
    logging.info("Copying UF2 file to '%s'", part.mountpoint)
    copy_uf2_to_partition(args.uf2_file, part)


if __name__ == "__main__":
    main()
