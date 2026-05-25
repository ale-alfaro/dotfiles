## File Tasks

- File tasks can live in: `mise-tasks/`, `.mise-tasks/`, `mise/tasks/`, `.mise/tasks/`, or `.config/mise/tasks/`.
- Task files must be executable.
- Configure tasks with `#MISE` headers (description, alias, sources, outputs, env, depends, tools, etc.).
- `#MISE` is intentionally parsed; `# MISE` is ignored.
- Shebang controls the interpreter.
- `mise tasks edit <name>` can create/edit tasks quickly.
- Tasks can be grouped by subdirectories, producing names like `group:task`.
- Usage spec can be embedded with `#USAGE` lines to provide args/flags/auto-complete.
