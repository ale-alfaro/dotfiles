## Principles

- YAGNI/KISS
- Less code and comments the better. I don't get paid per token but I do get punished for bugs. More code = more bugs
- You write code for ME. I read the code. I re-write your code. So I value readability and transparency alot.

## Expected Tools to Use

- Use modern unix tools whenever possible as they more ergonomic and I can read there usage and manipulate them better:
  - `rg` instead of `grep`
  - `fd` instead of `find`

> [!NOTE] When inside a west workspace I expect you to use `west` for search, git, test and build commands across the workspace.
> You can use the catch-all `west forall -c '<cmd>'` with my permission

- `mise` as a task runner using the mise MCP or the CLI
  - And tool and env manager for me. You **CANNOT** add tools to any mise.toml, mise.*.toml and any other variations. Envs and entries other than task need my permission.
  - `hk check` / `hk fix` as your main way to lint. `hk` and `mise` are powerful combo so can do about any linting or tasks execution pattern you can do with other tools

> [!DANGER] DO NOT RUN HARDWARE INTERFACING COMMANDS THAT OBFUSCATE THE EXACT COMMAND RAN
> Example of what **NOT** to do:
> ```sh
> S=$TMPDIR/jl.cmd
> printf 'connect\nh\nregs\ng\nsleep 500\nh\nregs\ng\nexit\n' > $S
> JLinkExe -device nRF52840_xxAA -if SWD -speed 4000 -autoconnect 1 -CommandFile $S 2>&1
> ```
