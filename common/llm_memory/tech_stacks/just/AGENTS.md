## Justfile quick reference (agent-focused)
- Default recipe: mark with `[default]`; otherwise first recipe runs. Handy default: `default:\n  @just --list`.
- Listing: `--list` / `--summary`, add `--unsorted`, `--list-heading`, `--list-prefix`; `--choose` uses `fzf` by default.
- Working dir: recipes run from justfile dir; `[no-cd]` keeps caller CWD; per-file `set working-directory := 'path'`; per-recipe `[working-directory: 'path']`.
- Invocation: multiple recipes allowed; `--one` enforces single. Aliases via `alias short := recipe` (cross-module OK).
- Settings to remember: `shell`/`windows-shell`, `script-interpreter`, `dotenv-*`, `export`, `quiet`, `positional-arguments`, `allow-duplicate-*`, `fallback`, `tempdir`, `unstable`. Boolean can be `set name`.
- Docs: comments before recipe show in `--list`; override/silence with `[doc('text')]` or `[doc]`.
- Expressions: `+` concat, `/` join paths, stringy `&& ||` (unstable), escape `{{` with `{{{{`. Strings support triple/indented; `x'~/$VAR'` expands at compile time.
- Functions (high value): `env(key[, default])`, `justfile()`, `justfile_directory()`, `source_file()`, `invocation_directory()`, `shell(cmd, args…)`, `require/which`, `path_exists`, `read`, hashing (`sha256/blake3`), `datetime*`, string/regex replace, case converters.
- Attributes to reach for: `[confirm [("Prompt")]]`, `[parallel]`, `[private]`, `[positional-arguments]`, `[no-exit-message]`, `[no-quiet]`, platform gates `[linux|macos|unix|windows|openbsd]`, `[group(name)]`, `[script[(cmd)]]`, `[extension(ext)]`, `[metadata(x)]`, `[working-directory(path)]`.
- Params: defaults allowed; variadic `+ARGS` (1+) or `*ARGS` (0+); pass args to deps with `(dep arg)`. Export param with `$param`. Quote interpolations when values may have spaces.
- Env + CLI: assign with `:=`; override via `NAME=val` or `--set`. `export` keyword/setting exports vars; `unexport NAME` removes from env. Dotenv via `set dotenv-load` or `dotenv-filename/path/required/override`.
- Positional mode: `set positional-arguments` (or recipe attribute) to use `$0,$1…,"$@"` for safe quoting.
- Dependencies: prereqs after `:` run first; `&&` adds post-run deps. `[parallel]` runs deps concurrently. Each recipe+arg pair runs once per invocation.
- Scripts & shebangs: shebang body saved to temp and executed; `[script(cmd)]` or `[script]` uses `script-interpreter` (default `sh -eu`) and avoids noexec/cygpath quirks.
- Error/control: prefix command with `-` to continue on failure; conditionals `if … {…} else {…}` with `== != =~`; `error("msg")` halts.
- Output: recipe name with `@` inverts per-line echo; `set quiet` silences globally, `[no-quiet]` opt-out; `[no-exit-message]` hides failure summary; `--timestamp[(-format)]` prefixes times.
- Imports/modules: `import 'path'` (or `import?`); `mod name` for submodules invoked as `name recipe` or `name::recipe`. Modules use their own settings; env load only in root. Optional modules with `mod?`.
- Private/groups: leading `_` or `[private]` hides from lists. Group recipes with `[group('name')]`; show via `--groups`.
- Shell precedence: CLI `--shell` > `windows-shell` > `windows-powershell` (deprecated) > `shell`. Common choices: `["bash","-uc"]`, `["zsh","-uc"]`, `["nu","-c"]`.
- Gotchas: each recipe line is a fresh shell (use `cd … &&` or shebang for state); multi-line constructs need `\` or shebang; avoid arg splitting by quoting, positional args, or exported args.

## Personal exemplars (copy patterns)
- `~/.config/just/python.just`  
  - QA-first: `ruff`, `ty`, `basedpyright`, `pyrefly` driven by one `concise` flag; grouped `qa` / `lifecycle`.  
  - Env-first knobs (`UV_RUN_FLAGS`, `UV_SYNC_FLAGS`); defaults make most commands zero-arg.  
  - `check-all` loops command list and respects dependency context via `is_dependency()`.  
  - Lifecycle: `update`, `install` (pins Python), `fresh`, `clean`.
- `~/.config/just/zephyr/justfile`  
  - Self-executable shebang `#!/usr/bin/env just --justfile --working-directory \`pwd\`` so you can call the file directly.  
  - Central vars: `zephyr_base`, `requirements_txt`, `west` wrapper with `uvx --with-requirements` and pinned Python.  
  - Imports keep surface small (`build/justfile`, `test/justfile`). Env-first defaults; minimal args.
- `~/.config/just/zephyr/build/justfile`  
  - `build_full` wraps west pristine builds with optional snippet; `_setup_clangd` symlink helper; `_copy_artifacts` gathers standard Zephyr outputs; `flash` picks runner from `BOARD` heuristic.
- `~/.config/just/zephyr/test/justfile`  
  - Twister runners: isolated vs non-isolated chosen by `TWISTER_NO_ISOLATION`. Report/output paths derive from test root.  
  - Shorthands for HW/sim/serial; pytest wrappers prefer `uv tool run pytest` unless `PYTEST_NO_ISOLATION=1`. Defaults for board/serial from env; grouped by `twister` / `pytest`.

## Script recipe pattern (uv)
- For complex logic, move to a script with inline metadata and call from just:  
  - Shebang: `#!/usr/bin/env -S uv run --script`  
  - Inline metadata:  
    ```
    # /// script
    # requires-python = ">=3.13"
    # dependencies = ["cattrs","attrs","PyYAML","tomlkit","anyio","rich","cyclopts","python-dotenv"]
    # ///
    ```  
  - Example: `bin/west-toml-build.py` parses TOML/YAML build specs, assembles west commands, and copies artifacts. Use `[script]` or a normal recipe that shells to `uv run --script bin/west-toml-build.py ...`.

## Patterns to reuse
- Favor tiny argument lists; expose env vars for knobs.  
- Hoist shared commands/paths to top-level vars.  
- Group recipes by workflow stage (`qa`, `lifecycle`, `manifest`, `twister`, `pytest`).  
- Default recipe lists commands for discoverability.  
- Use `[script]` or external uv scripts when logic branches or loops would clutter the justfile.
