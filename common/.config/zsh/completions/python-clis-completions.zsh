python_clis=("pytest" "ruff" "pylint" "mypy")

for cli in "${python_clis[@]}"; do
  eval "$(register-python-argcomplete "$cli")"
done
