#!/bin/sh

set -eu

repo_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
venv_dir="${FACTORIO_TOOLS_VENV:-$repo_root/.venv/factorio-tools}"

if [ -x "$venv_dir/bin/python" ]; then
  exec "$venv_dir/bin/python" -m hornwitser.factorio_tools "$@"
fi

exec python3 -m hornwitser.factorio_tools "$@"
