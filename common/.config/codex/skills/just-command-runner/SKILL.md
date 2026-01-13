---
name:just-command-runner 
description: Use when working with Just for Zephyr development creating or extending project Justfiles, applying the user’s preferred patterns, wiring west builds/flash/run, and understanding just settings, recipes, and modules. Includes a Zephyr-focused Justfile template and a concise Just reference.
---

# Zephyr Justfile Usage

Use this skill to create or extend Justfiles for Zephyr applications, following the preferred patterns and conventions.

## 1) Start from the reference

- Use `references/just-quick-reference.md` as the default baseline.
- Pull missing details from `references/just-manual.md` only when needed.
- Use `references/zephyr-justfile-template.just` as the starting template for new apps.

## 2) Establish core settings

- Prefer `set shell := ['zsh', '-uc']` and `set unstable := true` to match the template.
- Use `require('west')` to enforce tool availability.
- Derive `app` from `source_dir()` and `board` from `west config build.board` with a fallback.
- Keep variables at the top; expose knobs via env/vars, not long argument lists.

## 3) Default + discoverability

- Use a default listing recipe that formats the app name.
- Prefer `just --list-heading` to keep a consistent UI.

## 4) Validate Justfile formatting (must)

- Always run `just --fmt --check --unstable --justfile path/to/Justfile` after edits. This will return 0 if all is good or return 1 if there's any errors and additionally a diff with the suggested changes in another file with the name Justfile.fmt or {FILENAME}.fmt if not called Justfile

## 5) Justfile lessons (must)

1. NEVER use "bash -lc '...'" or such commands in a justfile. It is redundant. If you really need to execute a bash script like recipe use a shebang recipe which is composed of a
   shebang on the first line of the recipe. Example:

   ```
   build:
   #!/usr/bin/env bash
       set -euxo pipefail
   ```

   - Also set the options `set -euxo pipefail` to add increased safety when running them.

2. Do not ever call a dependency by name INSIDE THE RECIPE. It has to be called outside the recipe in the same line where the recipe name is defined:

   ```
   build: clean
   ```

   - If the recipe has any arguments that are required you must enclose it in paranthesis. Additionally you can pass the recipe arguments to a dependency without the brackets:

   ```
   build app: (clean app)
   ```

   - If you want to call a recipe not as a dependency but as a command inside the recipe execution you can but must be careful to do it with the right just invocation:

   ```
   build:
   just --justfile {{source_file()}} my_recipe my_args
   ```

   - The safest way to call it is with the --justfile flag and with {{source_file()}} as the replacement string. You can use {{justfile()}} but there's edge cases where it might not work

3. Always define variables OUTSIDE and NOT INSIDE the recipe unless required. Define variables that will be re-used by multiple reciipes always outside the recipes and even if only one
   recipe uses variables always prefer to define them as just variables instead of shell variables:

   ```
   build_path := 'build'

   build:
   cd {{build_path}} && make
   ```

4. If a recipe has a lot of `\` for continuation to the next line below, STOP, reconsider the approach and decide whether the recipe can be:
   - Broken down to smaller recipes that can be chained together
   - Made into a shebang recipe
5. For advanced recipes you can use python instead of the shell for recipes. If so use uv as the shebang recipe runner:

```
    build:
    #!/usr/bin/env -S uv run --script
    # /// script
    # requires-python = ">=3.12"
    # dependencies = [
    #     "pylink-square",
    # ]
    ...
```

## 6) Zephyr build workflow

- Provide `configure` to set `west config` defaults (board, build dir format, pristine).
- Provide `build`, `build_clean`, and `clean` with `build_dir` derived from west config.
- Use `board`, `snippet`, `target`, and `clean` as overridable knobs.

## 7) Flash/run tooling

- Provide a `flash` recipe that depends on `build`.

## 8) Devicetree tooling (dtsh)

- Provide `_dtsh` guard + helpers: `dts_tree`, `dts_ls`, `dts_cat`, `dtsh_out_html`, `dts_find`.

## 9) Extend safely

- Group recipes by workflow stage: `config`, `build`, `run`, `tools`.
- Keep private helpers prefixed with `_`.
- Quote interpolations when values may include spaces.
- Use `--justfile {{ source_file() }}` for self-invocations.

## References

- `references/just-quick-reference.md` — concise just patterns
- `references/just-manual.md` — baseline manual details
- `references/zephyr-justfile-template.just` — Zephyr app template
