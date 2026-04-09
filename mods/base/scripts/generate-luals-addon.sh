#!/bin/sh

set -eu

repo_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
factorio_docs_version="${FACTORIO_DOCS_VERSION:-latest}"
addon_dir="${LUALS_ADDON_DIR:-$repo_root/.cache/fmtk/luals-addon}"

mkdir -p "$addon_dir"
exec "$repo_root/scripts/fmtk.sh" luals-addon -o "$factorio_docs_version" "$addon_dir"
