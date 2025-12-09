#!/usr/bin/env bash
set -euo pipefail

uv run --no-project --isolated \
  --with-editable '.[test]' --with-editable ~/dev/datasette \
  python -m pytest "$@"

datasette_args=()
uv_with_args=()

# Parse CLI: take any --with X (or --with=X) for uv; everything else -> passed to datasette
while [ "$#" -gt 0 ]; do
  case "$1" in
    --with)
      if [ "$#" -lt 2 ]; then
        echo "tadd: missing value for --with" >&2
        exit 2
      fi
      uv_with_args+=(--with "$2")
      shift 2
      ;;
    --with=*)
      uv_with_args+=(--with "${1#--with=}")
      shift
      ;;
    --) # explicit separator: rest go to pytest_args verbatim
      shift
      # preserve original quoting/word boundaries
      datasette_args+=("$@")
      break
      ;;
    *)
      # anything else goes to pytest/datasette
      datasette_args+=("$1")
      shift
      ;;
  esac
done

# Run
exec uv run "${uv_with_args[@]}" --no-project --isolated \
  --with-editable '.[test]' --with-editable "$HOME/dev/datasette" \
  -- datasette "${datasette_args[@]}"
