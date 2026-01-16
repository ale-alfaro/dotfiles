---
name: just-recipe-authoring
description: Create build,test,run recipes and integrate shell and python scripts with Just. Use when automating any set of shell commands, trigerring a software development lifecycle activity and general scripting of short but deterministic command recipes.
---

# Just Recipe Authoring

Expert guidance for Just, a command runner with syntax inspired by make. Use this skill for creating justfiles, writing recipes, configuring settings, and implementing task automation workflows.

**Key capabilities:**

- Create and organize justfiles with proper structure
- Write recipes with attributes, dependencies, and parameters
- Configure settings for shell, modules, and imports
- Use built-in constants for terminal formatting
- Implement check/write patterns for code quality tools

# Workflows

## 1) Boilerplate, variables and default recipe at the top

- Add `set shell := ['zsh', '-uc']` and `set unstable := true` always. Other settings that are accepted are:

| Name                 | Value              | Default                     | Description                                                                                                          |
| -------------------- | ------------------ | --------------------------- | -------------------------------------------------------------------------------------------------------------------- |
| `dotenv-load`        | boolean            | `false`                     | Load a `.env` file, if present.                                                                                      |
| `dotenv-path`        | string             | -                           | Load a `.env` file from a custom path and error if not present. Overrides `dotenv-filename`.                         |
| `quiet`              | boolean            | `false`                     | Disable echoing recipe lines before executing.                                                                       |
| `script-interpreter` | `[COMMAND, ARGS…]` | `['uv', 'run', '--script']` | Set command used to invoke recipes with empty `[script]` attribute. Use uv unless instructed                         |
| `working-directory`  | string             | -                           | Set the working directory for recipes and backticks, relative to the default working directory. **USE WITH CAUTION** |

- Any executable used in the recipes should be referenced with `require('west')` to enforce tool availability. If the recipe is optional you can use which
- Declare all paths up-fron using `source_dir()` to get the Justfile directory absolute path and using `home_dir()` or other Just provided path functions for user directories and other common paths.
- Keep variables at the top; expose knobs via env/vars, not long argument lists.
- Add a default listing recipe:

```just
@_:
    just --list
```

## 2) Recipe groups and attributes

- Define the recipe groups by themes or the stages of the workflow to automate. Use a word or two words max hyphonated for the name of the recipe group
- Section out the recipe group with a simple page break `--- RECIPE_GROUP ---`
- If a relative order exist, put the recipe groups that should be run first or are dependencies of the ones below first
- Attributes that are useful to use not only to group recipe but to add specialized behavior to a recipe. All accepted attributes are listed below:

| Name                                         | Type           | Description                                                                                                                                 |
| -------------------------------------------- | -------------- | ------------------------------------------------------------------------------------------------------------------------------------------- |
| `[confirm]`<sup>1.17.0</sup>                 | recipe         | Require confirmation prior to executing recipe.                                                                                             |
| `[confirm(PROMPT)]`<sup>1.23.0</sup>         | recipe         | Require confirmation prior to executing recipe with a custom prompt.                                                                        |
| `[doc(DOC)]`<sup>1.27.0</sup>                | module, recipe | Set recipe or module's [documentation comment](#documentation-comments) to `DOC`.                                                           |
| `[extension(EXT)]`<sup>1.32.0</sup>          | recipe         | Set shebang recipe script's file extension to `EXT`. `EXT` should include a period if one is desired.                                       |
| `[group(NAME)]`<sup>1.27.0</sup>             | module, recipe | Put recipe or module in in [group](#groups) `NAME`.                                                                                         |
| `[linux]`<sup>1.8.0</sup>                    | recipe         | Enable recipe on Linux.                                                                                                                     |
| `[macos]`<sup>1.8.0</sup>                    | recipe         | Enable recipe on MacOS.                                                                                                                     |
| `[no-cd]`<sup>1.9.0</sup>                    | recipe         | Don't change directory before executing recipe.                                                                                             |
| `[parallel]`<sup>1.42.0</sup>                | recipe         | Run this recipe's dependencies in parallel.                                                                                                 |
| `[script]`<sup>1.33.0</sup>                  | recipe         | Execute recipe as script. See [script recipes](#script-recipes) for more details.                                                           |
| `[script(COMMAND)]`<sup>1.32.0</sup>         | recipe         | Execute recipe as a script interpreted by `COMMAND`. See [script recipes](#script-recipes) for more details.                                |
| `[working-directory(PATH)]`<sup>1.38.0</sup> | recipe         | Set recipe working directory. `PATH` may be relative or absolute. If relative, it is interpreted relative to the default working directory. |

## 3) Recipe creation

- Add private helpers recipes prefixed with `_` first and any private variables that aren't meant to be set by the user. No doc string required for this
- Add the main recipes with a doc string using the attribute `[doc('...')]` and distinguish clearly the arguments that are required vs optional and if a '*extra' or '*args' catch all requirement is used and why
- Follow the rules, tips and encouraged usage patterns below

### Rules

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

### Tips

1. Use `@` prefix to suppress command echo: `@echo "quiet"`
2. Use `+` for variadic parameters: `test +args`
3. Use `*` for optional variadic: `build *flags`
4. Quote glob patterns in variables: `GLOBS := "\"**/*.json\""`
5. Use `[no-cd]` in monorepos to stay in current directory
6. Private recipes start with `_` or use `[private]`
7. For cross-platform linewise recipes, set both `set shell := [...]` and `set windows-shell := [...]` so Windows uses a Windows-appropriate shell while other OSes use the default shell.

### Encouraged Advanced Patterns

#### Recipe Argument Flags (v1.46.0+)

The `[arg()]` attribute configures parameters as CLI-style options:

```just
# Long option (--target)
[arg("target", long)]
build target:
    cargo build --target {{ target }}

# Short option (-v)
[arg("verbose", short="v")]
run verbose="false":
    echo "Verbose: {{ verbose }}"

# Combined long + short
[arg("output", long, short="o")]
compile output:
    gcc main.c -o {{ output }}

# Flag without value (presence sets to "true")
[arg("release", long, value="true")]
build release="false":
    cargo build {{ if release == "true" { "--release" } else { "" } }}

# Help string (shown in `just --usage`)
[arg("target", long, help="Build target architecture")]
build target:
    cargo build --target {{ target }}
```

**Usage examples:**

```bash
just build --target x86_64
just build --target=x86_64
just compile -o main
just build --release
just --usage build    # Show recipe argument help
```

Multiple attributes can be combined:

```just
[no-cd, private]
[group("checks")]
recipe:
    echo "hello"
```

#### Modules

Load recipes from other files using submodule (requires `set unstable`):

```just
mod foo                   # Loads foo.just or foo/justfile
mod bar "path/to/bar"     # Custom path
mod? optional             # Optional module

# Call module recipes
just foo::build
```

## 4) Validate Justfile formatting

- Always run `just --fmt --check --unstable --justfile path/to/Justfile` after edits. This will return 0 if all is good or return 1 if there's any errors and additionally a diff with the suggested changes in another file with the name Justfile.fmt or {FILENAME}.fmt if not called Justfile

# Full References

- `references/just-quick-reference.md` — concise just patterns
- `references/just-manual.md` — baseline manual details
- `references/zephyr-justfile-template.just` — Zephyr app template
