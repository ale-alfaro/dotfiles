---
name: mise-task-configuration
description: Use when defining and configuring Mise tasks in mise.toml. Covers task definitions, dependencies, file tasks, and parallel execution.
---

# Mise - Task Configuration

Defining and managing tasks in Mise for build automation, testing, and development workflows.

### Running Tasks

```bash
# Run a task
mise run build
mise build  # Shorthand if no command conflicts

# Run multiple tasks
mise run build test lint

# List available tasks
mise tasks ls

# Show task details
mise tasks info build
```
---
## TOML Tasks 


```toml
[tasks.build]
description = "Build with pre/post hooks"
depends = ["pre-build"]
run = "west build -p -b "

[tasks.pre-build]
description = "Run before build"
run = "echo 'Preparing build...'"

[tasks.post-build]
description = "Run after build"
run = "echo 'Build complete!'"

[tasks."build:full"]
description = "Build with all hooks"
depends = ["pre-build", "build", "post-build"]
run = "echo 'Full build pipeline complete'"
```

---

## File Tasks


```bash
# Create task directory
mkdir -p .mise-tasks

# Create executable task file
cat > .mise-tasks/deploy <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
#MISE description="Short task description"
#USAGE arg "<arg>" help="arg"

echo "Deploying... ${usage_arg?}"
EOF

chmod +x .mise-tasks/deploy

mise tasks --local

```

- Configure tasks with `#MISE` headers (description, alias, sources, outputs, env, depends, tools, etc.).
- Usage spec can be embedded with `#USAGE` lines to provide args/flags/auto-complete.
- Environment variables passed to file tasks:
  - `MISE_ORIGINAL_CWD`
  - `MISE_CONFIG_ROOT`
  - `MISE_PROJECT_ROOT`
  - `MISE_TASK_NAME`
  - `MISE_TASK_DIR`
  - `MISE_TASK_FILE`

>[!NOTE] Gotchas
>
> - Task files must be executable.
> - `#MISE` is intentionally parsed; `# MISE` is ignored.
> - Shebang controls the interpreter.

> [!SUCCESS] Must do's
> - Group tasks via subdirectories to create `group:task` names.
> - Default location: `mise-tasks/<task_name>`

---

## Task Arguments (Usage Spec)

- Preferred method: usage spec via `#USAGE` lines in file tasks or `usage = '''...'''` in `mise.toml`.
- Values are exposed as `usage_` env vars (e.g., `usage_verbose`, `usage_target`).
- In Tera templates (TOML tasks), use `{{ usage.name }}` or `{{ usage["dry-run"] }}`.
- Positional args with `arg "<name>"` (required) or `arg "[name]"` (optional).
- Variadic args: `var=#true` plus `var_min`/`var_max`.
- Flags with `flag "-v --verbose"` etc., can set defaults or env backing.
- Use `--` to separate mise args from task args when invoking.

---

## Templates (Tera)

- Templates are supported in `mise.toml` values (not in the file itself).
- Delimiters: `{{ }}` expressions, `{% %}` statements, `{# #}` comments.
- Useful variables: `env`, `cwd`, `config_root`, `xdg_cache_home`, `xdg_config_home`, `xdg_data_home`.
- Task scripts with usage spec expose `usage` map (e.g., `{{ usage.verbose }}`).
- Built-in functions: `exec`, `arch`, `os`, `os_family`, `num_cpus`, `read_file`.


---

### Environment Variables in Tasks

```toml
[tasks.build]
description = "Build with specific configuration"
env = { RUST_ENV = "production", OPTIMIZATION = "3" }
run = "cargo build --release"

[tasks.dev]
description = "Start development server"
env = { NODE_ENV = "development", PORT = "3000" }
run = "npm run dev"
```

---

## File Watching

### Watch Mode Tasks

```toml
[tasks.watch]
description = "Watch and rebuild on changes"
run = "cargo watch -x build"

[tasks."test:watch"]
description = "Watch and run tests"
run = "cargo watch -x test"
```

```bash
# Built-in watch with mise
mise watch --task build
```

---

## Task Validation


```bash
# Validate all tasks
mise tasks validate

# Check specific task
mise tasks info build
```

---

## Best Practices

### Use namespaces with ':' and Organize Tasks by Workflow

```toml
# Build tasks
[tasks."build:debug"]
description = "Build debug binary"
run = "cargo build"

# Test Tasks
[tasks."test:unit"]
description = "Run unit tests only"
run = "cargo test --lib"

[tasks."test:integration"]
description = "Run integration tests"
run = "cargo test --test '*'"

# Workflow task
[tasks.run]
description = "Build and run debug binary tests"
run = ["build:debug", "test:unit"]

```

### Conditional Execution

```toml
[tasks.deploy]
description = "Deploy only if tests pass"
run = '''
if mise run test; then
  mise run deploy
else
  echo "Tests failed, deployment cancelled"
  exit 1
fi
'''
```

### Leverage Dependencies

```toml
# Good: Explicit dependencies
[tasks.deploy]
description = "Deploy to production"
depends = ["lint", "test", "build"]
run = "./scripts/deploy.sh"

# Avoid: Manual sequencing in run command
[tasks.deploy]
description = "Deploy to production"
run = '''
cargo clippy
cargo test
cargo build --release
./scripts/deploy.sh
'''
```

### Use Environment Variables

```toml
# Access mise environment variables
[tasks.info]
description = "Show task info"
run = '''
echo "Task: $MISE_TASK_NAME"
echo "Project root: $MISE_PROJECT_ROOT"
echo "Config root: $MISE_CONFIG_ROOT"
'''
```


---


## Anti-Patterns

### Don't Hardcode Paths

```toml
# Bad: Hardcoded absolute paths
[tasks.build]
description = "Build"
run = "cd /Users/me/project && cargo build"

# Good: Use relative paths and environment variables
[tasks.build]
description = "Build"
run = "cd $MISE_PROJECT_ROOT && cargo build"
```

### Don't Duplicate Logic

```toml
# Bad: Duplicated test logic
[tasks."test:unit"]
run = "cargo test --lib"

[tasks."test:integration"]
run = "cargo test --test '*'"

[tasks."test:all"]
run = "cargo test --lib && cargo test --test '*'"

# Good: Use dependencies
[tasks."test:all"]
depends = ["test:unit", "test:integration"]
run = "echo 'All tests complete'"
```

