---
name: zephyr-out-of-tree-contributions
description: Working in a zephyr workspace but not on the zephyr project itself. When the active manifest is not Zephyr's. 
---

## Commits

- Every commit must carry a `Signed-off-by:` line from the human responsible for the work; it
  is required, not optional. Never add, edit or copy one yourself: only a human can certify the
  DCO, and the submitter adds their own (`git commit -s`). 
- Never add `Co-authored-by:`. Do not put "Generated with ...", session links or 
  any other mention of AI tools in commit messages,
  PR bodies, issues or comments. The `Assisted-by:` trailer below is the only place AI
  involvement is recorded.
- Add exactly one `Assisted-by: <Agent>:<model-version> [tool ...]` trailer, for example
  `Assisted-by: Claude:claude-opus-4.6 coccinelle`, naming the tool actually used. Replace it
  rather than stacking when a different model amends the commit. `checkpatch.pl` validates the
  format; basic tools (git, gcc, cmake, editors) are not listed.
- State what you did not do (not built, not run, not run on hardware, no reproducer) instead of implying it was done.
- Commit messages, code comments, Kconfig help texts and docs describe the tree as it is: no
  references to prompts, plans, sessions, "the rework" or "as requested". Write tersely and
  concretely;  
- reject verbose, hedging or self-congratulatory prose. No emoji.


### Commit message stylw

    area: subarea: imperative summary (75 columns max, no trailing period)

    Body wrapped at 75 columns: what the change does, why this approach,
    which assumptions were made and how it was tested. Never empty.

    Fixes #12345

    Assisted-by: Claude:claude-opus-4.6
    Signed-off-by: Full Name <email@example.com>

- `area:` is the prefix the file's recent history uses: `git log --format=%s -20 -- <path>`.
  Examples: `Bluetooth: Host:`, `drivers: i2c: nrfx:`, `dts: arm: st:`, `boards: nordic:`,
  `kernel:`, `doc:`, `.github:`. Never `subsys:` or `treewide:`, never `WIP`.
- Trailers (`Assisted-by`, `Signed-off-by`, `Link:`, `(cherry picked from commit ...)`) form one
  block as the last paragraph. `Fixes #N` goes in its own paragraph directly before that
  block. Reference other commits as `commit <12-char sha> ("subject")`.
- One `Signed-off-by:` line must match the commit `Author:` name and e-mail; never remove an
  existing sign-off. Verify with `git log -1 --format='%an <%ae>%n%b'`.
- One logical change per commit: a fix, its tests and its docs may be separate commits, but one
  commit never mixes unrelated changes. No fixup, squash or merge commits in a PR: fold review
  fixes into the commit that owns the lines. Without an interactive terminal:
  `git commit --fixup=<sha>`, then
  `GIT_SEQUENCE_EDITOR=true GIT_EDITOR=true git rebase -i --autosquash <base>`.
- Update a branch with `git rebase upstream/main`, never by merging `main` into it.
- Stage explicit paths (`git add <file>`); never `git add -A`, `git add .` or `commit -a`, which
  pick up build directories, notes and reports. Before pushing, review
  `git show --stat upstream/main..HEAD`.



## Checks

Ensure pre-commit checks are installed and ran through `hk`. If not setup, help the user setup
the checks mentioned below. Aside from the regular formatters and linters that are common to 
many C/C++ projects (clang-{format,tidy}, gersemi or other CMake formatter), Zephyr has its
own in-tree suite of compliance checks. Not all are good  checks or are better than a simple `hk` step
as a lot are tailored to running in the Zephyr tree and not outside projects. The checks that are 
OK to port/run for every commit are:
- checkpatch:
    - on staged changes: `git format-patch -1 --stdout <sha> | ./scripts/checkpatch.pl -`.
    - on one commit: `git format-patch -1 --stdout <sha> | ./scripts/checkpatch.pl -`.
- check-compliance.py
    - Prefix all commands with `uv run --isolated -r $ZEPHYR_BASE/scripts/requirements-compliance.txt`
    - Script location: `$ZEPHYR_BASE/scripts/ci/check_compliance.py `. Always run it using the prefix and inspect if failing
    - `-l` lists the checks. `-m <Check>` runs one.
    - Running: `$ZEPHYR_BASE/scripts/ci/check_compliance.py --parallel -c upstream/main..HEAD` 
    - Available valid checks:
        - Checkpatch
        - Gitlint
        - KconfigBasic
        - CMakeStyle 
        - SphinxLint
        - KeepSorted
