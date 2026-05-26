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
work_dir=$(mktemp -d "${TMPDIR:-/tmp}/the-square-e2e-screenshot.XXXXXX")

cleanup() {
  if [ "${KEEP_E2E_ARTIFACTS:-}" ]; then
    echo "Kept e2e screenshot artifacts in $work_dir" >&2
  else
    rm -rf "$work_dir"
  fi
}
trap cleanup EXIT INT TERM

write_validator_mod() {
  mod_dir="$1"
  validator_dir="$mod_dir/the-square-e2e-screenshot-validator_0.1.0"
  mkdir -p "$validator_dir"
  cat > "$validator_dir/info.json" <<EOF
{"name":"the-square-e2e-screenshot-validator","version":"0.1.0","title":"The Square E2E Screenshot Validator","author":"The Square tests","factorio_version":"2.0","dependencies":["base","$mod_name"]}
EOF
  cat > "$validator_dir/control.lua" <<'EOF'
local prefix = "[the-square-e2e-screenshot]"
local screenshot_path = "the-square-e2e/world.png"

local checks = {
  {label = "inside center", position = {x = 0, y = 0}, expected = "grass-1"},
  {label = "inside north-west corner", position = {x = -3, y = -3}, expected = "grass-1"},
  {label = "inside south-east corner", position = {x = 3, y = 3}, expected = "grass-1"},
  {label = "border north", position = {x = 0, y = -4}, expected = "out-of-map"},
  {label = "border south", position = {x = 0, y = 4}, expected = "out-of-map"},
  {label = "border west", position = {x = -4, y = 0}, expected = "out-of-map"},
  {label = "border east", position = {x = 4, y = 0}, expected = "out-of-map"},
  {label = "near outside diagonal", position = {x = 4, y = 4}, expected = "out-of-map"}
}

local function generate_chunks_for_checks(surface)
  for _, check in ipairs(checks) do
    surface.request_to_generate_chunks({x = check.position.x, y = check.position.y}, 0)
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
  if storage.the_square_e2e_tiles_validated then
    return
  end

  local failures = {}
  log(prefix .. " tile check results after forced chunk generation:")
  for _, check in ipairs(checks) do
    local actual = tile_name_at(surface, check.position)
    local line = string.format(
      "%s %s at (%d,%d): expected=%s actual=%s",
      prefix,
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
    error(prefix .. " tile assertions failed:\n" .. table.concat(failures, "\n"))
  end

  storage.the_square_e2e_tiles_validated = true
  log(prefix .. " tile assertions passed")
end

local function ensure_chunks_requested()
  local surface = game.surfaces.nauvis
  if not surface then
    error(prefix .. " missing Nauvis surface")
  end

  generate_chunks_for_checks(surface)
  storage.the_square_e2e_chunks_requested_tick = game.tick
  log(prefix .. " requested chunks")
end

local function take_world_screenshot(surface)
  if storage.the_square_e2e_screenshot_requested then
    return
  end
  if not storage.the_square_e2e_tiles_validated then
    validate_tiles(surface)
  end

  game.take_screenshot({
    surface = surface,
    position = {x = 0, y = 0},
    resolution = {x = 512, y = 512},
    zoom = 1,
    path = screenshot_path,
    show_gui = false,
    show_entity_info = true,
    show_cursor_building_preview = false,
    force_render = true
  })

  storage.the_square_e2e_screenshot_requested = true
  log(prefix .. " requested screenshot path=" .. screenshot_path)
end

script.on_init(function()
  ensure_chunks_requested()
end)

script.on_nth_tick(30, function()
  local surface = game.surfaces.nauvis
  if not surface then
    error(prefix .. " missing Nauvis surface")
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

script.on_nth_tick(60, function()
  local surface = game.surfaces.nauvis
  if not surface then
    error(prefix .. " missing Nauvis surface")
  end

  if not storage.the_square_e2e_chunks_requested_tick then
    ensure_chunks_requested()
    return
  end

  take_world_screenshot(surface)
end)
EOF
}

write_mod_list() {
  mod_dir="$1"
  cat > "$mod_dir/mod-list.json" <<EOF
{"mods":[{"name":"base","enabled":true},{"name":"elevated-rails","enabled":false},{"name":"quality","enabled":false},{"name":"space-age","enabled":false},{"name":"$mod_name","enabled":true},{"name":"the-square-e2e-screenshot-validator","enabled":true}]}
EOF
}

case_dir="$work_dir/screenshot-check"
mod_dir="$case_dir/mods"
write_data_dir="$case_dir/write-data"
config_path="$case_dir/config.ini"
save_path="$case_dir/default-world.zip"
create_log_path="$case_dir/factorio-create.log"
run_log_path="$case_dir/factorio-graphics-run.log"
screenshot_path="$write_data_dir/script-output/the-square-e2e/world.png"
final_screenshot_path="${E2E_SCREENSHOT_PATH:-$repo_root/build/e2e-world.png}"
mkdir -p "$mod_dir" "$write_data_dir"
cp "$artifact_path" "$mod_dir/"
write_validator_mod "$mod_dir"
write_mod_list "$mod_dir"
cat > "$config_path" <<EOF
[path]
read-data=__PATH__system-read-data__
write-data=$write_data_dir
EOF

"$factorio_bin" --create "$save_path" --config "$config_path" --mod-directory "$mod_dir" --disable-audio > "$create_log_path" 2>&1 || {
  echo "FAIL Factorio save creation failed" >&2
  tail -200 "$create_log_path" >&2 || true
  KEEP_E2E_ARTIFACTS=1
  exit 1
}

# --benchmark is headless and does not render screenshots. Use the graphics benchmark
# path so game.take_screenshot captures the actual rendered gameplay view while still
# exiting deterministically after the requested ticks.
rm -f "$write_data_dir/.lock"
set +e
SteamAppId=427520 SteamGameId=427520 \
  "$factorio_bin" --benchmark-graphics "$save_path" --benchmark-ticks 180 --config "$config_path" --mod-directory "$mod_dir" --disable-audio --window-size 800x600 --force-graphics-preset low > "$run_log_path" 2>&1
run_status=$?
set -e

if [ "$run_status" -ne 0 ]; then
  echo "FAIL Factorio graphics benchmark screenshot run failed" >&2
  echo "--- screenshot validator log lines ---" >&2
  grep "\[the-square-e2e-screenshot\]" "$run_log_path" >&2 || true
  tail -120 "$run_log_path" >&2 || true
  KEEP_E2E_ARTIFACTS=1
  exit "$run_status"
fi

if grep -E "Failed to load mods|Error while loading .* prototype|Error while running event|non-recoverable error|stack traceback|attempt to .* nil|\[the-square-e2e-screenshot\] tile assertions failed" "$create_log_path" "$run_log_path" >/dev/null 2>&1; then
  echo "FAIL Factorio screenshot validation log contains an error" >&2
  echo "--- create log screenshot validator lines ---" >&2
  grep "\[the-square-e2e-screenshot\]" "$create_log_path" >&2 || true
  echo "--- run log screenshot validator lines ---" >&2
  grep "\[the-square-e2e-screenshot\]" "$run_log_path" >&2 || true
  KEEP_E2E_ARTIFACTS=1
  exit 1
fi

if [ ! -s "$screenshot_path" ]; then
  echo "FAIL screenshot was not written or is empty: $screenshot_path" >&2
  echo "--- run log screenshot validator lines ---" >&2
  grep "\[the-square-e2e-screenshot\]" "$run_log_path" >&2 || true
  echo "--- script-output files ---" >&2
  find "$write_data_dir/script-output" -type f -maxdepth 5 -print >&2 2>/dev/null || true
  KEEP_E2E_ARTIFACTS=1
  exit 1
fi

mkdir -p "$(dirname "$final_screenshot_path")"
cp "$screenshot_path" "$final_screenshot_path"

printf '%s\n' "--- create log screenshot validator lines ---"
grep "\[the-square-e2e-screenshot\]" "$create_log_path" || true
printf '%s\n' "--- run log screenshot validator lines ---"
grep "\[the-square-e2e-screenshot\]" "$run_log_path" || true
printf 'PASS Factorio created a world, validated tiles, and wrote gameplay screenshot: %s\n' "$final_screenshot_path"
