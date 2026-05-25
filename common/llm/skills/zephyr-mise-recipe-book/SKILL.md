---
name: zephyr-mise-recipe-book
description: Use when about to run `west build`, `west flash`, `west twister`, or a `mise x ... -- west ...` one-liner in a Zephyr/west workspace that has a `mise.ai.toml`. Symptoms: chaining `cd <subdir> && mise ...`, passing multiple `-D<CONFIG>=y` flags inline, copying a long west invocation between turns, or switching to absolute paths because cwd "doesn't persist".
---

# Zephyr workspace: mise recipe book

## Overview

If the workspace has a `mise.ai.toml` (or equivalent project-owned task runner gated by an env), **do not invent ad-hoc `west`/`mise x` one-liners**. Add a task to the recipe file, then call it via `mise -E ai run <task>`.

The recipe file is owned by the user. It encodes their conventions — board, build dir, sysbuild on/off, toolchain pin, source-dir layout. Reinventing the invocation throws all of that away.

## When NOT to use

- No recipe file exists. Ask the user where recipes should live before creating one.
- One-shot exploratory query nobody repeats (`west list`, `west config -l`). Inline is fine.
- Recipe already exists and works — just run it.

## The rule

1. **Look first.** Grep `mise.ai.toml` for a task that matches. If yes, `mise -E ai run <task>`.
2. **If none matches, add one.** Edit `mise.ai.toml`. Paths relative to `config_root`. No `cd`, no absolute paths. The `[tools]` block pins workspace-scoped toolchain (e.g. `vfox-zephyr:arm`).
3. **Then call it.**

## Quick reference

| Situation | Wrong | Right |
|-----------|-------|-------|
| First build of a test/sample | `mise x ... -- west build -b BOARD ...` ad-hoc | New `[tasks."<group>:<verb>"]` in `mise.ai.toml`, then `mise -E ai run ...` |
| Selecting a testcase | 8× `-D<CONFIG>=y` inline | `-T <testcase_name>` (configs come from `testcase.yaml`) |
| Sysbuild dragging in netcore | `--no-sysbuild` on every call | `west config build.sysbuild false` once |
| Source tree path | `/abs/path/to/sh_sdk/...` | `../sh_sdk/...` (relative to recipe file) |
| Different cwd needed | `cd subdir && mise ...` | Just use relative paths in the task `run` — mise resolves from `config_root` |

## Adding a new recipe

Two starting points live in this skill's directory — pick by intent:

- **`template.mise.ai.toml`** — agent-gated recipes for `mise.ai.toml`. Concrete tasks meant to be **run** as-is (`mise -E ai run ftl:test:aria:build`). Copy this when the workspace has no recipes yet and you need to record what you just figured out.
- **`template.bible.mise.toml`** — generic `west:*` **task templates** for the project-level `mise.toml`. Not meant to be run directly — `[tasks.*]` blocks `extends = "west:build"` them and override `vars.*`. **Templates and their consumers MUST live in the same mise file** — mise does not resolve templates across files (no global pool, no monorepo cross-inheritance). Symptom of getting this wrong: `template '<name>' was not found. Available templates: (none)` at task-run time. Also requires `experimental = true` in `[settings]`, and collisions with existing `[task_templates."west:build"]` / `["west:flash"]` need a rename, not a silent overwrite.

For mise task syntax beyond what the templates demonstrate (`sources`/`outputs` up-to-date checks, `usage` args, `confirm`, `hide`, alternate shells/interpreters, remote `file =` sources, the templates merge table, etc.) see **`mise-tasks-reference.md`** in this skill's directory.

Minimal shape:

```toml
[tasks."<group>:<artifact>:<board>:<verb>"]
description = "One line; future you reads this back."
run = '''
west build --no-sysbuild -p=always -b <board> \
    -d build_<short_name> \
    -T <testcase_or_sample_name> \
    ../<path_to_source>
'''
```

Naming: `<group>:<artifact>:<board>:<verb>` — e.g. `ftl:test:aria:build`, `ftl:sample:aria:flash`. Chain with `depends = ["other:task"]`.

## Common rationalizations (closed loopholes)

| Excuse | Reality |
|--------|---------|
| "I know which `-D` flags I need." | They belong in `testcase.yaml`/`sample.yaml`. `-T` selects them reproducibly. |
| "Each Bash call is fresh — I need `cd` or absolute paths." | mise resolves `config_root` from `mise.toml`. Relative paths in `run = '''...'''` work. |
| "`--no-sysbuild` per call is faster than fixing west config." | It's how the netcore kept getting dragged in. One line of west config fixes it permanently. |
| "It's a one-off." | The first reinvention is always a "one-off." Add it now. |

## Red flags — STOP

- About to write `cd <dir> && mise ...`
- About to pass more than one `-D<…>=y` to `west build`
- Copy-pasting a long `mise x ... -- west ...` from earlier in the conversation
- Switching to absolute paths because relative "didn't work"
- Adding `--no-sysbuild` for the second time

All mean: open `mise.ai.toml`, add the recipe, run it from there.
