## Task Arguments (Usage Spec)

- Preferred method: usage spec via `#USAGE` lines in file tasks or `usage = '''...'''` in `mise.toml`.
- Values are exposed as `usage_` env vars (e.g., `usage_verbose`, `usage_target`).
- In Tera templates (TOML tasks), use `{{ usage.name }}` or `{{ usage["dry-run"] }}`.
- Positional args with `arg "<name>"` (required) or `arg "[name]"` (optional).
- Variadic args: `var=#true` plus `var_min`/`var_max`.
- Flags with `flag "-v --verbose"` etc., can set defaults or env backing.
- Use `--` to separate mise args from task args when invoking.
