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

move_cursor_to_placement_preview() {
  python3 - <<'PY' >/dev/null 2>&1 &
import ctypes
import subprocess
import sys
import time

try:
    from AppKit import NSScreen

    screen = NSScreen.mainScreen().frame()
    screen_width = float(screen.size.width)
    screen_height = float(screen.size.height)
    window_width = 800.0
    window_height = 600.0
    window_left = (screen_width - window_width) / 2.0
    window_top = (screen_height - window_height) / 2.0

    try:
        bounds = subprocess.check_output(
            ["osascript"],
            input='''tell application "System Events"
  set matches to every process whose name contains "actorio"
  repeat with p in matches
    if exists window 1 of p then
      set pos to position of window 1 of p
      set sz to size of window 1 of p
      return ((item 1 of pos as integer) as string) & "," & ((item 2 of pos as integer) as string) & "," & ((item 1 of sz as integer) as string) & "," & ((item 2 of sz as integer) as string)
    end if
  end repeat
end tell
''',
            stderr=subprocess.DEVNULL,
            timeout=1,
            text=True,
        ).strip()
        if bounds:
            left, top, width, height = [float(part) for part in bounds.split(",")]
            if width > 1000.0:
                left = left / 2.0
                top = top / 2.0
                width = width / 2.0
                height = height / 2.0
            window_left = left
            window_top = top
            window_width = width
            window_height = height
    except Exception:
        pass

    # Move the real cursor to the top-middle of the gameplay viewport where the
    # north anchor slot is visible. This lets the real Factorio cursor-building
    # preview render instead of a scripted rendering substitute.
    target_x = window_left + (window_width / 2.0)
    target_y = window_top + 415.0

    core_graphics = ctypes.CDLL("/System/Library/Frameworks/CoreGraphics.framework/CoreGraphics")

    class CGPoint(ctypes.Structure):
        _fields_ = [("x", ctypes.c_double), ("y", ctypes.c_double)]

    core_graphics.CGWarpMouseCursorPosition.argtypes = [CGPoint]
    core_graphics.CGWarpMouseCursorPosition.restype = ctypes.c_int
    core_graphics.CGEventCreateMouseEvent.argtypes = [ctypes.c_void_p, ctypes.c_uint32, CGPoint, ctypes.c_uint32]
    core_graphics.CGEventCreateMouseEvent.restype = ctypes.c_void_p
    core_graphics.CGEventPost.argtypes = [ctypes.c_uint32, ctypes.c_void_p]
    core_graphics.CGEventPost.restype = None

    try:
        subprocess.run(
            ["osascript", "-e", 'tell application "Factorio" to activate'],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            timeout=0.5,
        )
    except Exception:
        pass

    for _ in range(100):
        point = CGPoint(target_x, target_y)
        core_graphics.CGWarpMouseCursorPosition(point)
        event = core_graphics.CGEventCreateMouseEvent(None, 5, point, 0)
        if event:
            core_graphics.CGEventPost(0, event)
        time.sleep(0.05)
except Exception:
    sys.exit(0)
PY
}

capture_factorio_window() {
  output_path="$1"
  region=$(osascript <<'APPLESCRIPT' 2>/dev/null || true
tell application "System Events"
  set matches to every process whose name contains "actorio"
  repeat with p in matches
    if exists window 1 of p then
      set pos to position of window 1 of p
      set sz to size of window 1 of p
      return ((item 1 of pos as integer) as string) & "," & ((item 2 of pos as integer) as string) & "," & ((item 1 of sz as integer) as string) & "," & ((item 2 of sz as integer) as string)
    end if
  end repeat
end tell
APPLESCRIPT
)
  if [ -z "$region" ]; then
    region=$(python3 - <<'PY'
from AppKit import NSScreen

screen = NSScreen.mainScreen().frame()
screen_width = float(screen.size.width)
screen_height = float(screen.size.height)
window_width = 800.0
window_height = 600.0
window_left = (screen_width - window_width) / 2.0
window_top = (screen_height - window_height) / 2.0
print("%d,%d,%d,%d" % (window_left, window_top, window_width, window_height))
PY
)
  fi
  region=$(printf '%s\n' "$region" | python3 -c 'import sys
left, top, width, height = [int(float(part)) for part in sys.stdin.read().strip().split(",")]
print(f"{left + 210},{top + 325},425,500")
')
  mkdir -p "$(dirname "$output_path")"
  screencapture -x -C -R"$region" "$output_path"
}

factorio_bin=$(find_factorio) || {
  echo "error: Factorio binary not found. Set FACTORIO=/path/to/factorio." >&2
  exit 127
}

artifact_path=$("$repo_root/scripts/build-mod.sh")
work_dir=$(mktemp -d "${TMPDIR:-/tmp}/the-square-e2e-placement-preview.XXXXXX")

cleanup() {
  if [ "${KEEP_E2E_ARTIFACTS:-}" ]; then
    echo "Kept e2e placement preview artifacts in $work_dir" >&2
  else
    rm -rf "$work_dir"
  fi
}
trap cleanup EXIT INT TERM

write_validator_mod() {
  mod_dir="$1"
  validator_dir="$mod_dir/the-square-e2e-placement-preview-validator_0.1.0"
  mkdir -p "$validator_dir"
  cat > "$validator_dir/info.json" <<EOF
{"name":"the-square-e2e-placement-preview-validator","version":"0.1.0","title":"The Square E2E Placement Preview Validator","author":"The Square tests","factorio_version":"2.0","dependencies":["base","$mod_name"]}
EOF
  cat > "$validator_dir/control.lua" <<'EOF'
local prefix = "[the-square-e2e-placement-preview]"
local screenshot_path = "the-square-e2e/placement-preview.png"
local preview_position = {x = 0, y = -4}
local ingress_item_name = "the-square-item-ingress-anchor"

local checks = {
  {label = "inside center", position = {x = 0, y = 0}, expected = "grass-1"},
  {label = "north middle anchor slot", position = preview_position, expected = "out-of-map"},
  {label = "north playable edge", position = {x = 0, y = -3}, expected = "grass-1"}
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
  if storage.the_square_e2e_placement_preview_tiles_validated then
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

  storage.the_square_e2e_placement_preview_tiles_validated = true
  log(prefix .. " tile assertions passed")
end

local function clear_existing_world_entities(surface)
  for _, entity in ipairs(surface.find_entities()) do
    if entity.valid and entity.type ~= "character" and entity.name ~= "the-square-anchor-slot-proxy" then
      entity.destroy({raise_destroy = false})
    end
  end
end

local function prepare_empty_world_with_cursor(surface)
  if storage.the_square_e2e_placement_preview_prepared then
    return
  end

  clear_existing_world_entities(surface)

  local player = game.get_player(1)
  if not player then
    error(prefix .. " missing player 1")
  end

  player.teleport({x = 0.5, y = 0.5}, surface)
  player.clear_cursor()
  player.cursor_stack.set_stack({name = ingress_item_name, count = 2})

  storage.the_square_e2e_placement_preview_prepared = true
  log(prefix .. " prepared empty world and cursor placement preview at (0,-4)")
end

local function ensure_chunks_requested()
  local surface = game.surfaces.nauvis
  if not surface then
    error(prefix .. " missing Nauvis surface")
  end

  generate_chunks_for_checks(surface)
  storage.the_square_e2e_placement_preview_chunks_requested_tick = game.tick
  log(prefix .. " requested chunks")
end

local function take_world_screenshot(surface)
  if storage.the_square_e2e_placement_preview_screenshot_requested then
    return
  end
  if not storage.the_square_e2e_placement_preview_tiles_validated then
    validate_tiles(surface)
  end

  prepare_empty_world_with_cursor(surface)
  clear_existing_world_entities(surface)

  local player = game.get_player(1)
  if not player then
    error(prefix .. " missing player 1")
  end

  game.take_screenshot({
    player = player,
    by_player = player,
    resolution = {x = 512, y = 512},
    zoom = 1.5,
    path = screenshot_path,
    show_gui = false,
    show_entity_info = true,
    show_cursor_building_preview = true,
    force_render = true
  })

  storage.the_square_e2e_placement_preview_screenshot_requested = true
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

  if not storage.the_square_e2e_placement_preview_chunks_requested_tick then
    ensure_chunks_requested()
    return
  end

  if game.tick <= storage.the_square_e2e_placement_preview_chunks_requested_tick then
    return
  end

  validate_tiles(surface)
  prepare_empty_world_with_cursor(surface)
end)

script.on_nth_tick(180, function()
  local surface = game.surfaces.nauvis
  if not surface then
    error(prefix .. " missing Nauvis surface")
  end

  if not storage.the_square_e2e_placement_preview_chunks_requested_tick then
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
{"mods":[{"name":"base","enabled":true},{"name":"elevated-rails","enabled":false},{"name":"quality","enabled":false},{"name":"space-age","enabled":false},{"name":"$mod_name","enabled":true},{"name":"the-square-e2e-placement-preview-validator","enabled":true}]}
EOF
}

case_dir="$work_dir/placement-preview-check"
mod_dir="$case_dir/mods"
write_data_dir="$case_dir/write-data"
config_path="$case_dir/config.ini"
save_path="$case_dir/default-world.zip"
create_log_path="$case_dir/factorio-create.log"
run_log_path="$case_dir/factorio-run.log"
screenshot_path="$write_data_dir/script-output/the-square-e2e/placement-preview.png"
window_screenshot_path="$case_dir/placement-preview-window.png"
final_screenshot_path="${E2E_PLACEMENT_PREVIEW_SCREENSHOT_PATH:-$repo_root/build/e2e-placement-preview.png}"
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

rm -f "$write_data_dir/.lock"
set +e
SteamAppId=427520 SteamGameId=427520 \
  "$factorio_bin" --load-game "$save_path" --config "$config_path" --mod-directory "$mod_dir" --disable-audio --window-size 800x600 --force-graphics-preset low > "$run_log_path" 2>&1 &
factorio_run_pid=$!
window_screenshot_status=1
if [ "$(uname -s)" = "Darwin" ] && command -v screencapture >/dev/null 2>&1; then
  screenshot_wait_attempts=0
  while [ "$screenshot_wait_attempts" -lt 400 ]; do
    if grep "\[the-square-e2e-placement-preview\] prepared empty world and cursor placement preview" "$run_log_path" >/dev/null 2>&1; then
      move_cursor_to_placement_preview
      sleep 3
      capture_factorio_window "$window_screenshot_path"
      window_screenshot_status=$?
      kill "$factorio_run_pid" >/dev/null 2>&1 || true
      break
    fi
    sleep 0.1
    screenshot_wait_attempts=$((screenshot_wait_attempts + 1))
  done
fi
wait "$factorio_run_pid"
run_status=$?
if [ "$run_status" -eq 143 ] || [ "$run_status" -eq 137 ] || [ "$run_status" -eq 130 ]; then
  run_status=0
fi
set -e

if [ "$run_status" -ne 0 ]; then
  echo "FAIL Factorio placement preview screenshot run failed" >&2
  echo "--- placement preview validator log lines ---" >&2
  grep "\[the-square-e2e-placement-preview\]" "$run_log_path" >&2 || true
  tail -120 "$run_log_path" >&2 || true
  KEEP_E2E_ARTIFACTS=1
  exit "$run_status"
fi

if grep -E "Failed to load mods|Error while loading .* prototype|Error while running event|non-recoverable error|stack traceback|attempt to .* nil|\[the-square-e2e-placement-preview\] tile assertions failed" "$create_log_path" "$run_log_path" >/dev/null 2>&1; then
  echo "FAIL Factorio placement preview screenshot validation log contains an error" >&2
  echo "--- create log placement preview validator lines ---" >&2
  grep "\[the-square-e2e-placement-preview\]" "$create_log_path" >&2 || true
  echo "--- run log placement preview validator lines ---" >&2
  grep "\[the-square-e2e-placement-preview\]" "$run_log_path" >&2 || true
  KEEP_E2E_ARTIFACTS=1
  exit 1
fi

if [ -s "$window_screenshot_path" ]; then
  screenshot_source_path="$window_screenshot_path"
else
  screenshot_source_path="$screenshot_path"
fi

if [ ! -s "$screenshot_source_path" ]; then
  echo "FAIL placement preview screenshot was not written or is empty: $screenshot_path" >&2
  if [ "$window_screenshot_status" -ne 0 ]; then
    echo "window screenshot capture status: $window_screenshot_status" >&2
  fi
  echo "--- run log placement preview validator lines ---" >&2
  grep "\[the-square-e2e-placement-preview\]" "$run_log_path" >&2 || true
  echo "--- script-output files ---" >&2
  find "$write_data_dir/script-output" -type f -maxdepth 5 -print >&2 2>/dev/null || true
  KEEP_E2E_ARTIFACTS=1
  exit 1
fi

mkdir -p "$(dirname "$final_screenshot_path")"
cp "$screenshot_source_path" "$final_screenshot_path"

printf '%s\n' "--- create log placement preview validator lines ---"
grep "\[the-square-e2e-placement-preview\]" "$create_log_path" || true
printf '%s\n' "--- run log placement preview validator lines ---"
grep "\[the-square-e2e-placement-preview\]" "$run_log_path" || true
printf 'PASS Factorio wrote placement preview gameplay screenshot: %s\n' "$final_screenshot_path"
