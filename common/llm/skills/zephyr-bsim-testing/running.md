# Running

## Verdicts: babblekit

`babblekit/testcase.h` — `TEST_START`, `TEST_PASS`, `TEST_PASS_AND_EXIT`,
`TEST_FAIL`, `TEST_ASSERT(expr, fmt, ...)`, `TEST_PRINT`. `TEST_FAIL` goes
through `bs_trace_error_time_line()` and **terminates the process**, so
`TEST_ASSERT` is fatal wherever it fires, including inside a GATT callback.

`babblekit/flags.h` — `DEFINE_FLAG_STATIC`, `SET_FLAG`, `UNSET_FLAG`,
`IS_FLAG_SET`, `WAIT_FOR_FLAG`, `WAIT_FOR_FLAG_UNSET`, `TAKE_FLAG`. `atomic_t`
underneath; the normal way a test thread waits on a callback thread.

`babblekit/sync.h` — `bk_sync_init/send/wait`, a backchannel between devices 0
and 1 only.

Use `TEST_PASS_AND_EXIT` to end a device early and save simulated time —
_except_ with backchannels, where exiting before the peer reads your message is
undefined; there use `TEST_PASS` and let the simulation run out.

A device that never reaches a verdict ends as **"in progress (not passed)"** and
the script exits non-zero, so a hung `WAIT_FOR_FLAG` does fail the test — at
`-sim_length` or `EXECUTE_TIMEOUT`. Keep both tight enough to find out quickly.

## Test scripts

`bsim.rst` is explicit: **no bespoke runners.** No python wrapper, no new shell
abstraction. Tree-wide maintenance depends on every script looking the same; if
you have a better idea, change all of them in one PR.

```bash
#!/usr/bin/env bash
set -eu
source "${ZEPHYR_BASE}/tests/bsim/sh_common.source"

simulation_id="my_test_${BOARD_TS}"   # unique, or parallel runs collide
verbosity_level=2

cd "${BSIM_OUT_PATH}/bin"
Execute "./bs_${BOARD_TS}_my_exe_name" -v=${verbosity_level} -s=${simulation_id} \
  -d=0 -rs=420 -testid=central
Execute "./bs_${BOARD_TS}_my_exe_name" -v=${verbosity_level} -s=${simulation_id} \
  -d=1 -rs=69  -testid=peripheral
Execute ./bs_2G4_phy_v1 -v=${verbosity_level} -s=${simulation_id} -D=2 \
  -sim_length=20e6 "$@"
wait_for_background_jobs
```

That is the shared-image form. With one application per role the script is the
same shape with a different exe per device — `-testid=` still selects the entry
point within each:

```bash
dut_exe="${BSIM_OUT_PATH}/bin/bs_${BOARD_TS}_${test_name}_dut_prj_conf"
tester_exe="${BSIM_OUT_PATH}/bin/bs_${BOARD_TS}_${test_name}_tester_prj_conf"

Execute "${dut_exe}"    -s=${simulation_id} -d=0 -rs=420 -testid=dut
Execute "${tester_exe}" -s=${simulation_id} -d=1 -rs=69  -testid=tester
```

- One test per script, in a `test_scripts/` (or `tests_scripts/`) subfolder.
- `-D=` **must** match the number of `Execute`d devices or the PHY waits forever.
- Put `${BOARD_TS}` in `simulation_id` so one test can run on two boards at once.
- Distinct `-rs=` per device. Omitting it pins one timing path forever; varying
  it is how timing-sensitive bugs surface.
- Forward `"$@"` to the PHY so the batch runner's options reach it.
- Scripts **never build**. They assume the exe is staged.
- Leave `EXECUTE_TIMEOUT` at the default unless measured runtime exceeds 5 s,
  then ~5× that. Never below the default.
- Keep output under ~100 lines; use `LOG_DBG` freely but do not ship `DBG` on.
- Write nothing outside `${BSIM_OUT_PATH}/results/<simulation_id>/` or `/tmp`.
- A leading `_` makes a script undiscoverable — use it for local debug helpers.

## Running a batch

`run_parallel.sh` is what CI should invoke: it discovers every `*.sh` under
`SEARCH_PATH`, skips `_`-prefixed helpers and `compile`/`ci.` scripts, runs them
in parallel and writes a JUnit report. New tests are then picked up with no
change to the CI recipe.

```bash
RESULTS_FILE=$PWD/bsim-results.xml \
SEARCH_PATH=$PWD/tests/bsim \
BOARD=nrf52_bsim/native \
  "${ZEPHYR_BASE}/tests/bsim/run_parallel.sh"
```

It uses GNU `parallel` when present and falls back to a serial loop when not.

## Debugging

- `-v=` 0..9 raises PHY verbosity; device output is prefixed `d_00:`, `d_01:`.
- Traces and results land in `${BSIM_OUT_PATH}/results/<simulation_id>/`.
- To debug one device: drop its `Execute` line, run the script, then start that
  device by hand under gdb with the same `-s=` / `-d=` / `-testid=`.
- `CONFIG_ARCH_POSIX_TRAP_ON_FATAL=y` plus a `test_delete_f` that `k_oops`es
  leaves a live process at the failure instead of a corpse.
- POSIX-arch binaries, so `tests/bsim/generate_coverage_report.sh` works.
