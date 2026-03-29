#!/bin/sh

set -eu

repo_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
build_dir="$repo_root/build"

mod_name=$(
  python3 -c 'import json, pathlib; print(json.loads(pathlib.Path("info.json").read_text())["name"])' \
    < /dev/null
)
mod_version=$(
  python3 -c 'import json, pathlib; print(json.loads(pathlib.Path("info.json").read_text())["version"])' \
    < /dev/null
)

artifact_base="${mod_name}_${mod_version}"
artifact_path="$build_dir/${artifact_base}.zip"
stage_dir=$(mktemp -d "${TMPDIR:-/tmp}/the-square-build.XXXXXX")
package_root="$stage_dir/$artifact_base"

cleanup() {
  rm -rf "$stage_dir"
}

trap cleanup EXIT INT TERM

mkdir -p "$build_dir" "$package_root"

copy_if_exists() {
  path="$1"

  if [ -e "$repo_root/$path" ]; then
    cp -R "$repo_root/$path" "$package_root/$path"
  fi
}

copy_if_exists "info.json"
copy_if_exists "control.lua"
copy_if_exists "settings.lua"
copy_if_exists "settings-updates.lua"
copy_if_exists "settings-final-fixes.lua"
copy_if_exists "data.lua"
copy_if_exists "data-updates.lua"
copy_if_exists "data-final-fixes.lua"
copy_if_exists "changelog.txt"
copy_if_exists "thumbnail.png"
copy_if_exists "locale"
copy_if_exists "graphics"
copy_if_exists "prototypes"
copy_if_exists "migrations"
copy_if_exists "scenarios"
copy_if_exists "campaigns"
copy_if_exists "tutorials"
copy_if_exists "sound"
copy_if_exists "styles"
copy_if_exists "lib"

rm -f "$artifact_path"

(
  cd "$stage_dir"
  zip -qr "$artifact_path" "$artifact_base"
)

printf '%s\n' "$artifact_path"
