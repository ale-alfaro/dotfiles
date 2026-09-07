---
name: unit-testing
description: Write or improve native_sim unit tests for this repo — ZTEST suite layout, faking dependencies with FFF instead of adding hooks to sources, running under ASAN/UBSAN/LSAN, and reading a gcovr coverage report for what it actually says. Use when adding a test suite, chasing uncovered code, making a dependency fail on demand, or when a test needs something to misbehave that the real thing never would.
---

# Unit testing in sh_sdk

For shell-driven samples and console harnesses (piping commands into a
native_sim exe, `--uart_stdinout`, the shell-log-backend flush trap), see the
`native-sim-shell` skill; this one is ZTEST/FFF unit suites.

Host-side suites on `native_sim`, driven by twister. The library under test should
need no disk, no flash simulator and no hardware — if it does, that is usually a
design smell in the library rather than a fact about the test.

## The rule that outranks everything here

**Never change a source file for testing purposes only.** It is in `CLAUDE.md`
because it has to fire while you are editing the library, not while you are
writing tests. If a test needs a dependency to fail, fake the dependency.

A seam a *product* uses is not a testing seam. `shrd_stream` takes a backend of
function pointers because the medium is genuinely the caller's choice; that it
is also fakeable is a consequence. The test to apply: **would this exist if
there were no tests?** If no, it does not go in.

## Layout

```
tests/<subsys>/<thing>/
├── CMakeLists.txt      # find_package(Zephyr); target_sources(app PRIVATE src/main.c)
├── prj.conf            # CONFIG_ZTEST=y + only what the thing under test needs
├── testcase.yaml       # harness: ztest, platform_allow: [native_sim]
└── src/main.c
```

Keep `prj.conf` minimal. Every option you add is a dependency the suite now has;
`tests/shrd/stream` needs no `DISK_ACCESS`, no `FLASH`, no FTL, and that is the
point. Note `CONFIG_SYS_CLOCK_TICKS_PER_SEC=8192` is required by anything pulling
in `lib/shrd/shrd_time.c` (there is a `BUILD_ASSERT` for it).

Several `ZTEST_SUITE`s per file is fine and preferable to one giant suite — group
by the thing being characterised (`_init`, `_record`, `_flush`, `_resume`), and
give them a shared `before` that resets all global state.

## Faking with FFF

`#include <zephyr/fff.h>`, one `DEFINE_FFF_GLOBALS;` per binary.

The pattern that works well here: **`custom_fake` is the pass-through, and a test
overrides it only to misbehave.**

```c
DEFINE_FFF_GLOBALS;
FAKE_VALUE_FUNC(int, fake_page_read, void *, uint32_t, void *, size_t);

static int real_page_read(void *user, uint32_t page, void *buf, size_t len)
{
	memcpy(buf, media[page], len);   /* the honest behaviour */
	return 0;
}

static void suite_before(void *f)
{
	RESET_FAKE(fake_page_read);
	FFF_RESET_HISTORY();
	fake_page_read_fake.custom_fake = real_page_read;
}
```

Then a test says what it wants to go wrong, and nothing else has to know:

```c
fake_page_read_fake.custom_fake = NULL;      /* drop the pass-through */
fake_page_read_fake.return_val  = -EIO;      /* and fail from here on */
```

`fake_page_read_fake.call_count` doubles as an assertion (`"init must touch no
media"`) and as a threshold for "the medium goes bad partway through".

### Traps

- **`SET_CUSTOM_FAKE_SEQ` / `SET_RETURN_SEQ` repeat their LAST entry once
  exhausted.** A fixed-length array shorter than the run under test therefore
  never reaches the failing entry, and the test passes for the wrong reason.
  Prefer a call-count threshold inside one `custom_fake` when you do not know
  how many calls there will be.
- **Do not tune a threshold from a previous run's total call count.** If the
  clean run makes N calls and you fail after N, nothing fails. Pick a point you
  can reason about — "everything after the first read" — not a measured one.
- `custom_fake` takes precedence over `return_val`, so set it to `NULL` when you
  want the return value to win.

## Sanitizers

Not optional for anything that copies buffers. The SHRD stream takes
`(const void *, count)` and C carries no length with a pointer, so a caller that
overstates a count reads off the end of its own array and **nothing in any build
can detect it**. A plain run of the suite passed exactly that bug; ASAN failed it
on the first try.

```
mise -E test run test:sim --san tests/<subsys>/<thing>
```

The flags live in `twister-sanitize.args` (twister's `fromfile_prefix_chars` is
`+`, so one bare argument per line and **no comments**). A bare
`west twister +twister-sanitize.args ...` works too.

## Coverage

```
west test.sim -C --coverage-tool gcovr --coverage-formats html,txt \
  --coverage-basedir . -T tests/<subsys>/<thing>
```

Reports land in `twister-out/coverage/`. `--coverage-basedir .` keeps the report
about this repo instead of the whole Zephyr tree. Do not run coverage and the
sanitizers together — separate concerns, and gcov plus ASAN is slow.

**Read the distribution, not the percentage.** The TOTAL line is meaningless —
it is diluted by Zephyr. Look at the per-file rows for the code you wrote, then
look at *which* lines are missing. A library at 87% whose entire uncovered
remainder is failure paths is worse tested than the number suggests, because the
happy path is the part least likely to be wrong.

Uncovered lines are worth triaging into three piles:

1. **Design claims with no test.** A comment saying "an unreadable block is
   treated as WRITTEN, and that choice is the whole safety argument" on a line
   that never executes is a wish. These are the ones to chase.
2. **Mechanical guards.** NULL-argument checks, alignment checks. Covering them
   moves the percentage without moving the risk. Leave them.
3. **Dead or speculative API.** A function uncovered because *nothing calls it*
   is a design signal, not a test gap — decide whether it should exist. Two
   functions in `shrd_stream` were deleted or given a real caller on exactly
   this evidence.

## Asserting

Assert on the **artefact**, not the context. These suites read the faked medium
back and check block types, CRCs and counts, because the context struct is the
thing the tests are trying to catch lying.

Give `zassert_*` a message that states the rule, not the values —
`"the cursor must never claim media the backend refused"` tells the next reader
why the line exists; `"expected 2"` does not.
