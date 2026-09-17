# Mise Tasks — reference

Distilled from the official mise docs (mise.jdx.dev/tasks). Kept here so the
agent can answer task-config questions without a web fetch.

Sources:
- https://mise.jdx.dev/tasks/
- https://mise.jdx.dev/tasks/toml-tasks.html

---

## Overview

Tasks let mise run project commands (build, test, lint, deploy, dev servers,
etc.) with the mise environment — tools and env vars from `mise.toml` — applied
automatically. Two definition styles:

- **In `mise.toml`** (`[tasks.<name>]` blocks) — what this skill uses.
- **As standalone scripts** in `mise-tasks/` with a `#MISE description="..."`
  header. Useful when the script wants real bash with shebang + linter
  support.

Either kind is invoked as `mise run <name>` (or `mise <name>` if there's no
built-in collision).

### Killer features

- Dependencies run in parallel by default — no config.
- `sources` + `outputs` lets mise skip a task if inputs haven't changed
  (Make-style up-to-date check).
- `mise watch <task>` re-runs on file change.

### Env vars passed into a task

| Variable | Meaning |
|---|---|
| `MISE_ORIGINAL_CWD` | Where the user invoked `mise run` from |
| `MISE_CONFIG_ROOT` | Dir holding the `mise.toml` that defines the task |
| `MISE_PROJECT_ROOT` | Project root (stable across invocation cwd) |
| `MISE_MONOREPO_ROOT` | Monorepo root, if `experimental_monorepo_root = true` |
| `MISE_TASK_NAME` | The name of the running task |
| `MISE_TASK_DIR` / `MISE_TASK_FILE` | Task script location |

---

## Trivial form

```toml
[tasks]
build = "cargo build"
test = "cargo test"
lint = "cargo clippy"
```

## Detailed form

```toml
[tasks.cleancache]
run = "rm -rf .cache"
hide = true                  # hide from `mise tasks ls`

[tasks.clean]
depends = ["cleancache"]     # runs before this task
run = "cargo clean"

[tasks.build]
description = "Build the CLI"
run = "cargo build"
alias = "b"                  # `mise run b` works too

[tasks.test]
description = "Run automated tests"
run = ["cargo test", "./scripts/test-e2e.sh"]   # series; stops on failure
dir = "{{cwd}}"              # default: project base dir

[tasks.lint]
env = { RUST_BACKTRACE = "1" }
run = '''
#!/usr/bin/env bash
cargo clippy
'''

[tasks.ci]                   # dependency-only task
description = "Run CI tasks"
depends = ["build", "lint", "test"]

[tasks.release]
confirm = "Are you sure you want to cut a new release?"
file = "scripts/release.sh"  # external script
```

### `vars` vs `env`

```toml
[env]
VERBOSE_ARGS = "--verbose"        # exported into the script's environment

[vars]
e2e_args = "--headless"           # accessible via `{{vars.e2e_args}}`,
                                  # NOT exported as an env var

[tasks.test]
run = './scripts/test-e2e.sh {{vars.e2e_args}} $VERBOSE_ARGS'
```

## Common options (most-used)

### `run`

Single string or array (run in series; stop on first failure).

```toml
[tasks.test]
run = "cargo test"
# or
run = ["cargo test", "./scripts/test-e2e.sh"]
```

Windows variant:

```toml
[tasks.test]
run = "cargo test"
run_windows = "cargo test --features windows"
```

### `dir`

Working directory for the task. Defaults to project base. `dir = "{{cwd}}"`
runs in the user's invocation cwd instead.

### `description`, `alias`

Shown in `mise tasks ls` and `mise run` (no-arg picker). Alias is a short
synonym usable on the command line.

### `depends`

Tasks to run *before* this one (in parallel with each other). See also
`wait_for` and `depends_post` in the full task-configuration docs.

```toml
[tasks.build]
run = "cargo build"

[tasks.test]
depends = ["build"]
```

### `env`

Per-task environment variables.

### `sources` + `outputs` (up-to-date check)

Skip the task if `sources` haven't changed since `outputs` were produced.

```toml
[tasks.build]
run = "cargo build"
sources = ["Cargo.toml", "src/**/*.rs"]
outputs = ["target/debug/mycli"]
```

`sources` alone is enough to drive `mise watch`. Inside templates,
`task_source_files()` gives the resolved list.

### `confirm`

Prompts before running. Good for destructive/release tasks.

### `hide`

`true` to hide from `mise tasks ls` — useful for helpers other tasks `depends`
on but humans shouldn't pick directly.

## Choosing a shell / interpreter

Tasks run with `set -e` by default when shell is `sh`/`bash`/`zsh`. Override
with `set +e` inside the script if needed.

Explicit shell:

```toml
[tasks.lint]
shell = "bash -c"
run = "cargo clippy"
```

Shebang form (any interpreter mise can install via `[tools]`):

```toml
[tools]
python = "latest"

[tasks.python_task]
run = '''
#!/usr/bin/env python
for i in range(10):
    print(i)
'''
```

`#!/usr/bin/env -S <cmd> <args>` lets you pass flags through env (e.g.
`#!/usr/bin/env -S python -u` for unbuffered Python). Mise mimics GNU
coreutils `env` semantics.

## File / remote scripts

```toml
[tasks.release]
file = "scripts/release.sh"
```

Remote sources also work; fetched once, cached in `MISE_CACHE_DIR` (clear with
`mise cache clear`, or bypass via `MISE_TASK_REMOTE_NO_CACHE=1`):

```toml
[tasks.build]
file = "https://example.com/build.sh"
# or
file = "git::https://github.com/myorg/example.git//myfile?ref=v1.0.0"
```

Trust the source — these get downloaded and executed.

## Arguments

By default, extra positional args go to the **last** command in the `run`
array.

```toml
[tasks.test]
run = ["cargo test", "./scripts/test-e2e.sh"]
```

`mise run test foo bar` → passes `foo bar` to `./scripts/test-e2e.sh` only.

### Recommended: `usage` field

```toml
[tasks.test]
usage = '''
arg "<file>" help="Test file to run" default="all"
flag "--format <format>" help="Output format" default="text"
flag "-v --verbose" help="Enable verbose output"
'''
run = 'cargo test ${usage_file?} --format ${usage_format?}'
```

Args/flags defined in `usage` are exposed to the script as `usage_*` env vars.
Full spec syntax: see the dedicated Task Arguments page.

### Tera template `arg()` / `option()` / `flag()` — DEPRECATED

Removed in mise **2026.11.0**. Migrate to `usage`. Old shape kept here only so
the agent recognizes legacy recipes:

```toml
[tasks.test]
run = [
    'cargo test {{arg(name="cargo_test_args", var=true)}}',
    './scripts/test-e2e.sh {{option(name="e2e_args")}}',
]
```

`arg()` = positional, `option()` = named (`--name value`), `flag()` = boolean
switch (`--name`, evaluates to `true`/`false`).

---

## Adding tasks via CLI

```sh
mise tasks add pre-commit --depends "test" --depends "render" -- echo pre-commit
```

writes:

```toml
[tasks.pre-commit]
depends = ["test", "render"]
run = "echo pre-commit"
```

Often easier to just edit `mise.toml` directly.

---

## Cross-references

For the full option list (including `wait_for`, `depends_post`, `quiet`,
`tools`, environment scopes, etc.) see:
https://mise.jdx.dev/tasks/task-configuration.html
