#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.12"
# dependencies = [
#     "pylink-square",
# ]
# ///
# Copyright 2017 Square, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
#
# Example RTT terminal.
#
# This module creates an interactive terminal with the target using RTT.
#
# Usage: rtt target_device
# Author: Charles Nicholson
# Date: October 11, 2017
# Copyright: 2017 Square, Inc.

import argparse
import sys
import time

import pylink

try:
    import thread
except ImportError:
    import _thread as thread


def read_rtt(jlink):
    """
    Reads the JLink RTT buffer #0 at 10Hz and prints to stdout.

    This method is a polling loop against the connected JLink unit. If
    the JLink is disconnected, it will exit. Additionally, if any exceptions
    are raised, they will be caught and re-raised after interrupting the
    main thread.

    sys.stdout.write and sys.stdout.flush are used since target terminals
    are expected to transmit newlines, which may or may not line up with the
    arbitrarily-chosen 1024-byte buffer that this loop uses to read.

    Args:
      jlink (pylink.JLink): The JLink to read.

    Raises:
      Exception on error.

    """
    try:
        while jlink.connected():
            terminal_bytes = jlink.rtt_read(0, 1024)
            if terminal_bytes:
                sys.stdout.write("".join(map(chr, terminal_bytes)))
                sys.stdout.flush()
            time.sleep(0.1)
    except Exception:
        thread.interrupt_main()
        raise


def write_rtt(jlink):
    """
    Writes kayboard input to JLink RTT buffer #0.

    This method is a loop that blocks waiting on stdin. When enter is pressed,
    LF and NUL bytes are added to the input and transmitted as a byte list.
    If the JLink is disconnected, it will exit gracefully. If any other
    exceptions are raised, they will be caught and re-raised after interrupting
    the main thread.

    Args:
      jlink (pylink.JLink): The JLink to write to.

    Raises:
      Exception on error.

    """
    try:
        while jlink.connected():
            bytes = list(bytearray(input(), "utf-8") + b"\x0a\x00")
            jlink.rtt_write(0, bytes)
    except Exception:
        thread.interrupt_main()
        raise


def main(target_device, block_address=None):
    """
    Creates an interactive terminal to the target via RTT.

    The main loop opens a connection to the JLink, and then connects
    to the target device. RTT is started, the number of buffers is presented,
    and then two worker threads are spawned: one for read, and one for write.

    The main loops sleeps until the JLink is either disconnected or the
    user hits ctrl-c.

    Args:
      target_device (string): The target CPU to connect to.
      block_address (int): optional address pointing to start of RTT block.

    Returns:
      Always returns ``0`` or a JLinkException.

    Raises:
      JLinkException on error.

    """
    jlink = pylink.JLink()
    jlink.open()
    jlink.set_tif(pylink.enums.JLinkInterfaces.SWD)
    jlink.connect(target_device)
    jlink.rtt_start(block_address)

    while True:
        try:
            jlink.rtt_get_num_up_buffers()
            jlink.rtt_get_num_down_buffers()
            break
        except pylink.errors.JLinkRTTException:
            time.sleep(0.1)

    for buf_index in range(jlink.rtt_get_num_up_buffers()):
        jlink.rtt_get_buf_descriptor(buf_index, True)

    for buf_index in range(jlink.rtt_get_num_down_buffers()):
        jlink.rtt_get_buf_descriptor(buf_index, False)

    try:
        thread.start_new_thread(read_rtt, (jlink,))
        thread.start_new_thread(write_rtt, (jlink,))
        while jlink.connected():
            time.sleep(1)
    except KeyboardInterrupt:
        pass


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Open RTT console.")
    parser.add_argument(
        "target_cpu",
        help="Device Name (see https://www.segger.com/supported-devices/jlink/)",
    )
    parser.add_argument(
        "rtt_block_address",
        help="RTT block address in hex",
        type=lambda x: int(x, 16),
        nargs="?",
    )

    args = parser.parse_args()

    sys.exit(main(args.target_cpu, args.rtt_block_address))
