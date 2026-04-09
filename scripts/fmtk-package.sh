#!/bin/sh

set -eu

repo_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
output_dir="${FMTK_PACKAGE_OUTDIR:-$repo_root/build/fmtk}"

mkdir -p "$output_dir"
exec "$repo_root/scripts/fmtk.sh" package --outdir "$output_dir"
