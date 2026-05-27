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
case_dir="$repo_root/build/playtest"
mod_dir="$case_dir/mods"
write_data_dir="$case_dir/write-data"
config_path="$case_dir/config.ini"
save_path="$case_dir/the-square-playtest.zip"
log_path="$case_dir/factorio-create.log"

rm -rf "$case_dir"
mkdir -p "$mod_dir" "$write_data_dir"
cp "$artifact_path" "$mod_dir/"

cat > "$config_path" <<EOF
[path]
read-data=__PATH__system-read-data__
write-data=$write_data_dir
EOF

cat > "$mod_dir/mod-list.json" <<EOF
{"mods":[{"name":"base","enabled":true},{"name":"elevated-rails","enabled":false},{"name":"quality","enabled":false},{"name":"space-age","enabled":false},{"name":"$mod_name","enabled":true},{"name":"the-square-playtest-tools","enabled":true}]}
EOF

playtest_mod_dir="$mod_dir/the-square-playtest-tools_0.1.0"
mkdir -p "$playtest_mod_dir"

cat > "$playtest_mod_dir/info.json" <<EOF
{"name":"the-square-playtest-tools","version":"0.1.0","title":"The Square Playtest Tools","author":"The Square tests","factorio_version":"2.0","dependencies":["base","$mod_name"]}
EOF

cat > "$playtest_mod_dir/control.lua" <<'EOF'
local frame_name = "the_square_playtest_frame"
local toggle_button_name = "the_square_playtest_toggle"
local chest_position = {x = 0, y = 2}

local managed_line_item_roots = {
  "the-square-item-ingress-anchor",
  "the-square-item-egress-anchor",
  "the-square-fluid-ingress-anchor",
  "the-square-fluid-egress-anchor"
}

local managed_line_tier_suffixes = {
  "",
  "-red",
  "-blue",
  "-turbo"
}

local research_buttons = {
  {
    name = "the_square_playtest_unlock_oil",
    caption = "Unlock oil",
    technologies = {"oil-gathering", "oil-processing"}
  },
  {
    name = "the_square_playtest_unlock_uranium",
    caption = "Unlock uranium mining",
    technologies = {"uranium-mining"}
  },
  {
    name = "the_square_playtest_unlock_ingress_dual",
    caption = "Unlock dual-lane lines",
    technologies = {"the-square-ingress-dual-lane"}
  },
  {
    name = "the_square_playtest_unlock_ingress_red",
    caption = "Unlock red lines",
    technologies = {"the-square-ingress-red"}
  },
  {
    name = "the_square_playtest_unlock_ingress_blue",
    caption = "Unlock blue lines",
    technologies = {"the-square-ingress-blue"}
  },
  {
    name = "the_square_playtest_unlock_ingress_turbo",
    caption = "Unlock turbo lines",
    technologies = {"the-square-egress-turbo"}
  }
}

local function get_force()
  return game.forces.player
end

local function sync_the_square(force)
  if remote.interfaces["the-square"] and remote.interfaces["the-square"].sync_research_runtime_state then
    remote.call("the-square", "sync_research_runtime_state", force and force.name or "player")
  elseif force and force.reset_technology_effects then
    force.reset_technology_effects()
  end
end

local function enable_the_square_debug_ui()
  if remote.interfaces["the-square"] and remote.interfaces["the-square"].set_playtest_debug_enabled then
    remote.call("the-square", "set_playtest_debug_enabled", true)
  end
end

local function unlock_prerequisites(technology, seen)
  if not (technology and technology.valid ~= false) then
    return
  end

  seen = seen or {}
  if seen[technology.name] then
    return
  end
  seen[technology.name] = true

  for _, prerequisite in pairs(technology.prerequisites or {}) do
    unlock_prerequisites(prerequisite, seen)
  end

  technology.researched = true
end

local function unlock_technologies(force, technology_names)
  if not (force and force.technologies) then
    return 0
  end

  local unlocked = 0
  for _, technology_name in ipairs(technology_names) do
    local technology = force.technologies[technology_name]
    if technology then
      local was_researched = technology.researched
      unlock_prerequisites(technology)
      if not was_researched and technology.researched then
        unlocked = unlocked + 1
      end
    end
  end

  sync_the_square(force)
  return unlocked
end

local function reset_research(force)
  if not (force and force.technologies) then
    return
  end

  pcall(function()
    force.current_research = nil
  end)
  for _, technology in pairs(force.technologies) do
    if technology.valid ~= false then
      pcall(function()
        technology.researched = false
      end)
    end
  end
  force.reset_technology_effects()
  sync_the_square(force)
end

local function get_existing_managed_line_item_names()
  local names = {}

  for _, root in ipairs(managed_line_item_roots) do
    for _, suffix in ipairs(managed_line_tier_suffixes) do
      local item_name = root .. suffix
      if prototypes and prototypes.item and prototypes.item[item_name] then
        names[#names + 1] = item_name
      end
    end
  end

  return names
end

local function entity_prototype_exists(entity_name)
  return prototypes and prototypes.entity and prototypes.entity[entity_name] ~= nil
end

local function find_or_create_bonus_chest(surface)
  local chest = surface.find_entities_filtered({
    name = {"steel-chest", "iron-chest", "wooden-chest"},
    position = chest_position,
    radius = 0.5
  })[1]

  if chest and chest.valid then
    return chest
  end

  if entity_prototype_exists("steel-chest") then
    return surface.create_entity({name = "steel-chest", position = chest_position, force = get_force()})
  end

  if entity_prototype_exists("iron-chest") then
    return surface.create_entity({name = "iron-chest", position = chest_position, force = get_force()})
  end

  return surface.create_entity({name = "wooden-chest", position = chest_position, force = get_force()})
end

local function fill_bonus_chest(surface)
  local chest = find_or_create_bonus_chest(surface)
  local inventory = chest and chest.get_inventory(defines.inventory.chest)
  if not inventory then
    return nil
  end

  inventory.clear()
  for _, item_name in ipairs(get_existing_managed_line_item_names()) do
    inventory.insert({name = item_name, count = 50})
  end

  return chest
end

local function enable_debug_options(player)
  if not (player and player.valid) then
    return
  end

  player.cheat_mode = true
  player.force.manual_crafting_speed_modifier = math.max(player.force.manual_crafting_speed_modifier or 0, 1)
  player.force.manual_mining_speed_modifier = math.max(player.force.manual_mining_speed_modifier or 0, 1)

  local surface = player.surface
  if surface then
    surface.always_day = true
    player.force.chart(surface, {{x = -64, y = -64}, {x = 64, y = 64}})
    fill_bonus_chest(surface)
  end
end

local function ensure_playtest_button(player)
  if not (player and player.valid and player.gui and player.gui.top) then
    return
  end

  if not player.gui.top[toggle_button_name] then
    player.gui.top.add({
      type = "button",
      name = toggle_button_name,
      caption = "Playtest"
    })
  end
end

local function refresh_playtest_frame(player)
  if not (player and player.valid and player.gui and player.gui.left) then
    return
  end

  local frame = player.gui.left[frame_name]
  if not frame then
    frame = player.gui.left.add({
      type = "frame",
      name = frame_name,
      direction = "vertical",
      caption = "The Square playtest"
    })
  end

  frame.clear()
  frame.add({type = "label", caption = "Cheat mode, always day, and bonus Managed Line chest are enabled."})
  frame.add({type = "button", name = "the_square_playtest_refill_chest", caption = "Refill Managed Line chest"})

  for _, button in ipairs(research_buttons) do
    local technology = get_force().technologies[button.technologies[#button.technologies]]
    if technology then
      frame.add({type = "button", name = button.name, caption = button.caption})
    end
  end

  frame.add({type = "button", name = "the_square_playtest_reset_research", caption = "Reset research"})
end

local function setup_player(player)
  enable_the_square_debug_ui()
  enable_debug_options(player)
  ensure_playtest_button(player)
  refresh_playtest_frame(player)
end

local function setup_all_players()
  for _, player in pairs(game.players) do
    setup_player(player)
  end
end

script.on_init(function()
  storage.the_square_playtest = {initialized = true}
end)

script.on_event(defines.events.on_player_created, function(event)
  setup_player(game.get_player(event.player_index))
end)

script.on_event(defines.events.on_player_joined_game, function(event)
  setup_player(game.get_player(event.player_index))
end)

script.on_event(defines.events.on_gui_click, function(event)
  if not (event.element and event.element.valid) then
    return
  end

  local player = game.get_player(event.player_index)
  if not player then
    return
  end

  if event.element.name == toggle_button_name then
    local frame = player.gui.left[frame_name]
    if frame then
      frame.destroy()
    else
      refresh_playtest_frame(player)
    end
    return
  end

  if event.element.name == "the_square_playtest_refill_chest" then
    local chest = fill_bonus_chest(player.surface)
    if chest then
      player.print("Refilled Managed Line chest at (" .. chest.position.x .. ", " .. chest.position.y .. ").")
    end
    return
  end

  if event.element.name == "the_square_playtest_reset_research" then
    reset_research(player.force)
    player.print("Reset player force research.")
    refresh_playtest_frame(player)
    return
  end

  for _, button in ipairs(research_buttons) do
    if event.element.name == button.name then
      unlock_technologies(player.force, button.technologies)
      player.print(button.caption .. " complete, including prerequisites.")
      refresh_playtest_frame(player)
      return
    end
  end
end)

script.on_nth_tick(60, function()
  if not storage.the_square_playtest_setup_done then
    setup_all_players()
    storage.the_square_playtest_setup_done = true
  end
end)
EOF

"$factorio_bin" --create "$save_path" --config "$config_path" --mod-directory "$mod_dir" --disable-audio > "$log_path" 2>&1 || {
  echo "FAIL Factorio playtest save creation failed" >&2
  tail -200 "$log_path" >&2 || true
  exit 1
}

if grep -E "Failed to load mods|Error while loading .* prototype|Error while running event|non-recoverable error|stack traceback" "$log_path" >/dev/null 2>&1; then
  echo "FAIL Factorio log contains a load/runtime error" >&2
  grep -E "Failed to load mods|Error while loading .* prototype|Error while running event|non-recoverable error|stack traceback" "$log_path" >&2 || true
  exit 1
fi

echo "Created playtest save: $save_path"
echo "Playtest data directory: $case_dir"

if [ "${PLAYTEST_NO_LAUNCH:-}" ]; then
  exit 0
fi

exec "$factorio_bin" --load-game "$save_path" --config "$config_path" --mod-directory "$mod_dir"
