set unstable := true

concise := env('PYTHON_DIAG_CONCISE', '')
ruff_args := f"--fix --unsafe-fixes --exit-zero {{concise && '--output-format concise'}}"
ty_args := "--exit-zero {{concise && '--output-format concise'}}"
basedpyright_args := "--level error"
pyrefly_args := concise && "--output-format min-text"
commands := "ruff ty basedpyright pyrefly"

# Run linters
[group('qa')]
[no-cd]
ruff-check:
    uvx ruff check {{ ruff_args }}
    uvx ruff format

[group('qa')]
[no-cd]
basedpyright-check:
    uvx basedpyright  {{ basedpyright_args }}

[group('qa')]
[no-cd]
pyrefly-check:
    uvx pyrefly check {{ pyrefly_args }}

[group('qa')]
[no-cd]
ty-check:
    uvx ty check {{ ty_args }}

# [group('qa')]
# [no-cd]
# check-all pattern *extra:
#     for cmd in {{ commands }}; do \
#         if [[ "$cmd" =~ {{ pattern }} ]]; then \
#           just python::$cmd; else just python::noop $cmd; \
#         fi; \
#     done
#     {{ extra }}

# Update dependencies
[group('lifecycle')]
[no-cd]
pyproject-update:
    uv sync --upgrade 

[group('lifecycle')]
[no-cd]
pyproject-install python_semver="3.13":
    uv venv "--python={{ python_semver }}"
    uv sync 
    @echo "Installing pre-commit hook"
    @uv run prek install

# Remove temporary files
[group('lifecycle')]
[no-cd]
pyproject-clean:
    rm -rf .venv .pytest_cache .mypy_cache .ruff_cache
    find . -type d -name "__pycache__" -exec rm -r {} +

# Recreate project virtualenv from nothing
[group('lifecycle')]
[no-cd]
pyproject-fresh *python_semver: pyproject-clean (pyproject-install python_semver)

log_lvl := "INFO"
pytest_opts := f" --strict-markers --strict-config -ra -v -s --log-cli-level={{log_lvl}}"

pytest_run:
    uv run -m pytest {{ pytest_opts }}
