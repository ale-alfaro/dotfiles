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
  - And tool and env manager for me. You CANNOT update any mise.toml, mise.*.toml and any other variations EXCEPT FOR ADDING TASKS
  - `hk check` / `hk fix` as your main way to lint. `hk` and `mise` are powerful combo so can do about any linting or tasks execution pattern you can do with other tools
  - Special provision given for a `mise.ai.toml` per project.
    - Its active in your environment and not mine by default (your shell should have `MISE_ENV=ai`)
    - It is yours to write into and it persists across sessions;
    - It is gitignored globally and should only be for development use. Tasks can always be added to the git tracked mise.toml if proven to be useful

> [!DANGER] I do check your commands and I am above average in bash and good zsh
> So you better not hide anything for me... and also be proactive of setting permissions when none exist
