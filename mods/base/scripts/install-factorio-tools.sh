#!/bin/sh

set -eu

repo_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
venv_dir="${FACTORIO_TOOLS_VENV:-$repo_root/.venv/factorio-tools}"

python3 -m venv "$venv_dir"
"$venv_dir/bin/pip" install --upgrade pip
"$venv_dir/bin/pip" install -r "$repo_root/requirements/factorio-tools.txt"
