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
work_dir=$(mktemp -d "${TMPDIR:-/tmp}/the-square-e2e.XXXXXX")

cleanup() {
  if [ "${KEEP_E2E_ARTIFACTS:-}" ]; then
    echo "Kept e2e artifacts in $work_dir" >&2
  else
    rm -rf "$work_dir"
  fi
}
trap cleanup EXIT INT TERM

write_validator_mod() {
  mod_dir="$1"
  validator_dir="$mod_dir/the-square-e2e-validator_0.1.0"
  mkdir -p "$validator_dir"
  cat > "$validator_dir/info.json" <<EOF
{"name":"the-square-e2e-validator","version":"0.1.0","title":"The Square E2E Validator","author":"The Square tests","factorio_version":"2.0","dependencies":["base","$mod_name"]}
EOF
  cat > "$validator_dir/control.lua" <<'EOF'
local checks = {
  {label = "inside center", position = {x = 0, y = 0}, expected = "grass-1"},
  {label = "inside north-west corner", position = {x = -3, y = -3}, expected = "grass-1"},
  {label = "inside south-east corner", position = {x = 3, y = 3}, expected = "grass-1"},
  {label = "border north", position = {x = 0, y = -4}, expected = "out-of-map"},
  {label = "border south", position = {x = 0, y = 4}, expected = "out-of-map"},
  {label = "border west", position = {x = -4, y = 0}, expected = "out-of-map"},
  {label = "border east", position = {x = 4, y = 0}, expected = "out-of-map"},
  {label = "near outside diagonal", position = {x = 4, y = 4}, expected = "out-of-map"},
  {label = "well outside positive", position = {x = 64, y = 64}, expected = "out-of-map"},
  {label = "well outside negative", position = {x = -64, y = -64}, expected = "out-of-map"},
  {label = "far generated chunk", position = {x = 128, y = 128}, expected = "out-of-map"}
}

local function chunk_center_for(position)
  return {x = position.x, y = position.y}
end

local function generate_chunks_for_checks(surface)
  for _, check in ipairs(checks) do
    surface.request_to_generate_chunks(chunk_center_for(check.position), 0)
  end
  surface.request_to_generate_chunks({x = 0, y = 0}, 3)
  surface.force_generate_chunk_requests()
end

local function tile_name_at(surface, position)
  local tile = surface.get_tile(position.x, position.y)
  if tile then
    return tile.name
  end
  return "<missing>"
end

local function validate_tiles(surface)
  local failures = {}
  log("[the-square-e2e-validator] tile check results after forced chunk generation:")
  for _, check in ipairs(checks) do
    local actual = tile_name_at(surface, check.position)
    local line = string.format(
      "[the-square-e2e-validator] %s at (%d,%d): expected=%s actual=%s",
      check.label,
      check.position.x,
      check.position.y,
      check.expected,
      actual
    )
    log(line)

    if actual ~= check.expected then
      failures[#failures + 1] = line
    end
  end

  if #failures > 0 then
    error("[the-square-e2e-validator] tile assertions failed:\n" .. table.concat(failures, "\n"))
  end
end

local function ensure_chunks_requested()
  local surface = game.surfaces.nauvis
  if not surface then
    error("[the-square-e2e-validator] missing Nauvis surface")
  end

  generate_chunks_for_checks(surface)
  storage.the_square_e2e_chunks_requested_tick = game.tick
end

script.on_init(function()
  ensure_chunks_requested()
end)

script.on_nth_tick(30, function()
  local surface = game.surfaces.nauvis
  if not surface then
    error("[the-square-e2e-validator] missing Nauvis surface")
  end

  if not storage.the_square_e2e_chunks_requested_tick then
    ensure_chunks_requested()
    return
  end

  -- Let other mods receive on_chunk_generated and repaint newly generated chunks
  -- before this validator reads tile names.
  if game.tick <= storage.the_square_e2e_chunks_requested_tick then
    return
  end

  validate_tiles(surface)
end)
EOF
}

write_mod_list() {
  mod_dir="$1"
  cat > "$mod_dir/mod-list.json" <<EOF
{"mods":[{"name":"base","enabled":true},{"name":"elevated-rails","enabled":false},{"name":"quality","enabled":false},{"name":"space-age","enabled":false},{"name":"$mod_name","enabled":true},{"name":"the-square-e2e-validator","enabled":true}]}
EOF
}

case_dir="$work_dir/tile-checks"
mod_dir="$case_dir/mods"
save_path="$case_dir/default-world.zip"
log_path="$case_dir/factorio-create.log"
bench_log_path="$case_dir/factorio-benchmark.log"
mkdir -p "$mod_dir"
cp "$artifact_path" "$mod_dir/"
write_validator_mod "$mod_dir"
write_mod_list "$mod_dir"

"$factorio_bin" --create "$save_path" --mod-directory "$mod_dir" --disable-audio > "$log_path" 2>&1 || {
  echo "FAIL Factorio save creation failed" >&2
  tail -200 "$log_path" >&2 || true
  KEEP_E2E_ARTIFACTS=1
  exit 1
}

set +e
"$factorio_bin" --benchmark "$save_path" --benchmark-ticks 90 --mod-directory "$mod_dir" --disable-audio > "$bench_log_path" 2>&1
benchmark_status=$?
set -e

if [ "$benchmark_status" -ne 0 ]; then
  echo "FAIL Factorio benchmark validation failed" >&2
  echo "--- benchmark log tile results ---" >&2
  grep "\[the-square-e2e-validator\]" "$bench_log_path" >&2 || true
  tail -80 "$bench_log_path" >&2 || true
  KEEP_E2E_ARTIFACTS=1
  exit "$benchmark_status"
fi

if grep -E "Error while running event|non-recoverable error|stack traceback|attempt to .* nil|\[the-square-e2e-validator\] tile assertions failed" "$log_path" "$bench_log_path" >/dev/null 2>&1; then
  echo "FAIL Factorio tile validation failed" >&2
  echo "--- create log tile results ---" >&2
  grep "\[the-square-e2e-validator\]" "$log_path" >&2 || true
  echo "--- benchmark log tile results ---" >&2
  grep "\[the-square-e2e-validator\]" "$bench_log_path" >&2 || true
  KEEP_E2E_ARTIFACTS=1
  exit 1
fi

echo "--- create log tile results ---"
grep "\[the-square-e2e-validator\]" "$log_path" || true
echo "--- benchmark log tile results ---"
grep "\[the-square-e2e-validator\]" "$bench_log_path" || true
printf 'PASS Factorio created a world, force-generated chunks, and all checked tiles matched expected names\n'
