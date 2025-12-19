concise := env('PYTHON_DIAG_CONCISE', '1')
uv_concise_flags := "--output-format concise"
ruff_args := "--fix --unsafe-fixes --exit-zero " + if concise == "1" { uv_concise_flags } else { "" }
ty_args := "--exit-zero " + if concise == "1" { uv_concise_flags } else { "" }
basedpyright_args := "--level error " + if concise == "1" { "" } else { "" }
pyrefly_args := " " + if concise == "1" { "--output-format min-text" } else { "" }
commands := "ruff ty basedpyright pyrefly"

@_:
    just --list

noop *args:
    @echo "No-op for {{ args }}"

# Run linters
[group('qa')]
[no-cd]
ruff:
    uvx ruff check {{ ruff_args }}
    uvx ruff format

[group('qa')]
[no-cd]
basedpyright:
    uvx basedpyright  {{ basedpyright_args }}

[group('qa')]
[no-cd]
pyrefly:
    uvx pyrefly check {{ pyrefly_args }}

[group('qa')]
[no-cd]
ty:
    uvx ty check {{ ty_args }}

uv_run_flags := env('UV_RUN_FLAGS', "--all-packages")
uv_sync_flags := env('UV_SYNC_FLAGS', "--dev --all-packages")

# Check types
[group('qa')]
[no-cd]
check-all pattern *extra:
    for cmd in {{ commands }}; do \
        if [[ "$cmd" =~ {{ pattern }} ]]; then \
          just python::$cmd; else just python::noop $cmd; \
        fi; \
    done
    {{ extra }}

# Update dependencies
[group('lifecycle')]
[no-cd]
update:
    uv sync --upgrade {{ uv_sync_flags }}

[group('lifecycle')]
[no-cd]
install python_semver="3.13":
    uv venv "--python={{ python_semver }}"
    uv sync {{ uv_sync_flags }}
    @echo "Installing pre-commit hook"
    @uv run prek install

# Remove temporary files
[group('lifecycle')]
[no-cd]
clean:
    rm -rf .venv .pytest_cache .mypy_cache .ruff_cache
    find . -type d -name "__pycache__" -exec rm -r {} +

# Recreate project virtualenv from nothing
[group('lifecycle')]
[no-cd]
fresh *python_semver: clean (install python_semver)

pytest_log_lvl := "INFO"
pytest_opts := f" --strict-markers --strict-config -ra -v -s --log-cli-level={{pytest_log_lvl}}"
pytest := f"uvx {{pytest_opts}} pytest"

pytest_run *args:
    {{ pytest }} {{ pytest_opts }} {{ args }}
