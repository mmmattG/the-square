#!/bin/sh

set -eu

repo_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)

detect_mods_dir() {
  if [ "${FACTORIO_MODS_DIR:-}" ]; then
    printf '%s\n' "$FACTORIO_MODS_DIR"
    return
  fi

  if [ -d "$HOME/Library/Application Support/factorio/mods" ]; then
    printf '%s\n' "$HOME/Library/Application Support/factorio/mods"
    return
  fi

  if [ -d "$HOME/.factorio/mods" ]; then
    printf '%s\n' "$HOME/.factorio/mods"
    return
  fi

  printf '%s\n' "Could not detect a Factorio mods directory. Set FACTORIO_MODS_DIR." >&2
  exit 1
}

mod_name=$(
  python3 -c 'import json, pathlib; print(json.loads(pathlib.Path("info.json").read_text())["name"])' \
    < /dev/null
)

mods_dir=$(detect_mods_dir)
artifact_path=$("$repo_root/scripts/build-mod.sh")

mkdir -p "$mods_dir"

find "$mods_dir" -maxdepth 1 \( -name "${mod_name}" -o -name "${mod_name}_*.zip" \) -exec rm -rf {} +
cp "$artifact_path" "$mods_dir/"

printf 'Installed %s to %s\n' "$(basename "$artifact_path")" "$mods_dir"
