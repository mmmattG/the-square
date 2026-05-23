#!/bin/sh

set -eu

repo_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
mod_name=$(python3 -c 'import json, pathlib; print(json.loads(pathlib.Path("info.json").read_text())["name"])' < /dev/null)

find_factorio() {
  if [ "${FACTORIO:-}" ]; then printf '%s\n' "$FACTORIO"; return 0; fi
  if command -v factorio >/dev/null 2>&1; then command -v factorio; return 0; fi
  for candidate in \
    "/Applications/Factorio.app/Contents/MacOS/factorio" \
    "$HOME/Library/Application Support/Steam/steamapps/common/Factorio/factorio.app/Contents/MacOS/factorio"; do
    if [ -x "$candidate" ]; then printf '%s\n' "$candidate"; return 0; fi
  done
  return 1
}

factorio_bin=$(find_factorio) || {
  echo "error: Factorio binary not found. Set FACTORIO=/path/to/factorio." >&2
  exit 127
}

artifact_path=$("$repo_root/scripts/build-mod.sh")
work_dir=$(mktemp -d "${TMPDIR:-/tmp}/the-square-e2e-load.XXXXXX")

cleanup() {
  if [ "${KEEP_E2E_ARTIFACTS:-}" ]; then
    echo "Kept e2e artifacts in $work_dir" >&2
  else
    rm -rf "$work_dir"
  fi
}
trap cleanup EXIT INT TERM

mod_dir="$work_dir/mods"
write_data_dir="$work_dir/write-data"
config_path="$work_dir/config.ini"
save_path="$work_dir/load-smoke.zip"
log_path="$work_dir/factorio-load.log"
mkdir -p "$mod_dir" "$write_data_dir"
cp "$artifact_path" "$mod_dir/"
cat > "$config_path" <<EOF
[path]
read-data=__PATH__system-read-data__
write-data=$write_data_dir
EOF

cat > "$mod_dir/mod-list.json" <<EOF
{"mods":[{"name":"base","enabled":true},{"name":"elevated-rails","enabled":false},{"name":"quality","enabled":false},{"name":"space-age","enabled":false},{"name":"$mod_name","enabled":true}]}
EOF

"$factorio_bin" --create "$save_path" --config "$config_path" --mod-directory "$mod_dir" --disable-audio > "$log_path" 2>&1 || {
  echo "FAIL Factorio failed to load The Square and create a smoke-test save" >&2
  tail -200 "$log_path" >&2 || true
  KEEP_E2E_ARTIFACTS=1
  exit 1
}

if grep -E "Failed to load mods|Error while loading entity prototype|Error while loading recipe prototype|Error while loading item prototype|Error while running event|non-recoverable error|stack traceback" "$log_path" >/dev/null 2>&1; then
  echo "FAIL Factorio log contains a load/runtime error" >&2
  grep -E "Failed to load mods|Error while loading .* prototype|Error while running event|non-recoverable error|stack traceback" "$log_path" >&2 || true
  KEEP_E2E_ARTIFACTS=1
  exit 1
fi

printf 'PASS Factorio loaded The Square and created a smoke-test save\n'
