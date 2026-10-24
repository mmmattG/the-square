-- Top-bar buttons (base screenshot, cliff explosives, dev Expand) and the dev mode
-- status panel. The Move Square window lives in square_move_gui.
local dev_travel_runtime = require("lib.dev_travel_runtime")
local expansion_research = require("lib.expansion_research")
local mod_settings = require("lib.mod_settings")
local planet_catalog = require("lib.planet_catalog")
local planet_runtime = require("lib.planet_runtime")
local planet_state = require("lib.planet_state")
local screenshot_runtime = require("lib.screenshot_runtime")

local gui_runtime = {}

local SCREENSHOT_BUTTON_NAME = "the_square_screenshot_button"
local CLIFF_EXPLOSIVE_BUTTON_NAME = "the_square_cliff_explosive_button"
local DEV_EXPAND_BUTTON_NAME = "the_square_dev_expand_button"
local DEV_UNLOCK_BUTTON_PREFIX = "the_square_dev_unlock_planet__"
local DEV_ORBIT_BUTTON_PREFIX = "the_square_dev_orbit_teleport__"
local DEV_LAND_BUTTON_PREFIX = "the_square_dev_land__"
local DEBUG_FRAME_NAME = "the_square_debug_frame"

-- The playtest launcher (scripts/playtest-world.sh) turns dev mode on for everyone.
function gui_runtime.is_dev_mode_enabled(player)
  return storage.the_square_playtest_debug_enabled or mod_settings.is_dev_mode_enabled(player)
end

local function set_button(parent, name, shown, button)
  local existing = parent[name]

  if shown and not existing then
    button.type = "button"
    button.name = name
    parent.add(button)
  elseif not shown and existing then
    existing.destroy()
  end
end

local function build_status_lines()
  local planet = planet_state.get("nauvis")
  local square_size = planet:get_square_size()
  local completed_levels = planet:get_completed_square_expansion_levels()
  local next_level = completed_levels + 1
  local next_ring_tiles = (square_size + 2) * (square_size + 2) - square_size * square_size

  return {
    "Square: " .. square_size .. "x" .. square_size .. " (" .. square_size * square_size .. " tiles)",
    "Background tile: " .. mod_settings.get_background_tile(),
    "Expansion research: " .. completed_levels .. " levels completed",
    "Next expansion: level " .. next_level .. " using " .. expansion_research.get_band(next_level).label,
    "Next expansion unlocks " .. next_ring_tiles .. " tiles"
  }
end

-- One row per Planet: Unlock (research its discovery), Orbit and Land.
local function add_travel_table(frame, force)
  frame.add({type = "label", caption = {"gui.the-square-dev-travel-title"}})

  local travel = frame.add({type = "table", column_count = 4})

  for _, planet_name in ipairs(planet_catalog.SUPPORTED_PLANETS) do
    local label = planet_catalog.get(planet_name).label
    local discovery = dev_travel_runtime.get_discovery_technology(force, planet_name)

    travel.add({type = "label", caption = label})

    if discovery then
      travel.add({
        type = "button",
        name = DEV_UNLOCK_BUTTON_PREFIX .. planet_name,
        caption = {discovery.researched and "gui.the-square-dev-unlocked-button" or "gui.the-square-dev-unlock-button"},
        tooltip = {"gui.the-square-dev-unlock-button-tooltip", label},
        enabled = not discovery.researched
      })
    else
      travel.add({type = "empty-widget"})
    end

    travel.add({
      type = "button",
      name = DEV_ORBIT_BUTTON_PREFIX .. planet_name,
      caption = {"gui.the-square-dev-orbit-button"},
      tooltip = {"gui.the-square-dev-orbit-button-tooltip", label}
    })
    travel.add({
      type = "button",
      name = DEV_LAND_BUTTON_PREFIX .. planet_name,
      caption = {"gui.the-square-dev-land-button"},
      tooltip = {"gui.the-square-dev-land-button-tooltip", label}
    })
  end
end

-- Rebuilds the dev mode status panel, if the player has it open.
function gui_runtime.refresh_debug_panel(player)
  local frame = player.gui.left[DEBUG_FRAME_NAME]

  if not frame then
    return
  end

  frame.clear()

  for _, line in ipairs(build_status_lines()) do
    frame.add({type = "label", caption = line})
  end

  if dev_travel_runtime.is_space_age_active() then
    add_travel_table(frame, player.force)
  end
end

function gui_runtime.refresh_all_debug_panels()
  for _, player in pairs(game.players) do
    gui_runtime.refresh_debug_panel(player)
  end
end

-- Shows or hides each of the player's buttons to match their settings.
function gui_runtime.sync(player)
  local dev_mode = gui_runtime.is_dev_mode_enabled(player)

  set_button(player.gui.top, SCREENSHOT_BUTTON_NAME, true, {
    caption = {"gui.the-square-screenshot-button"},
    tooltip = {"gui.the-square-screenshot-button-tooltip", screenshot_runtime.DIRECTORY}
  })
  set_button(player.gui.top, CLIFF_EXPLOSIVE_BUTTON_NAME, mod_settings.is_cliff_explosive_button_enabled(player), {
    caption = {"gui.the-square-cliff-explosive-button"}
  })
  set_button(player.gui.top, DEV_EXPAND_BUTTON_NAME, dev_mode, {
    caption = {"gui.the-square-dev-expand-button"}
  })

  local frame = player.gui.left[DEBUG_FRAME_NAME]

  if dev_mode and not frame then
    player.gui.left.add({
      type = "frame",
      name = DEBUG_FRAME_NAME,
      direction = "vertical",
      caption = {"gui.the-square-debug-title"}
    })
  elseif not dev_mode and frame then
    frame.destroy()
  end

  gui_runtime.refresh_debug_panel(player)
end

function gui_runtime.sync_all()
  for _, player in pairs(game.players) do
    gui_runtime.sync(player)
  end
end

local function print_failure(player, result)
  if not result.ok then
    player.print(result.error)
  end
end

local TRAVEL_BUTTONS = {
  [DEV_UNLOCK_BUTTON_PREFIX] = function(player, planet_name)
    dev_travel_runtime.unlock_planet(player.force, planet_name)
    gui_runtime.refresh_all_debug_panels()
  end,
  [DEV_ORBIT_BUTTON_PREFIX] = function(player, planet_name)
    print_failure(player, dev_travel_runtime.go_to_orbit(player, planet_name))
  end,
  [DEV_LAND_BUTTON_PREFIX] = function(player, planet_name)
    print_failure(player, dev_travel_runtime.land(player, planet_name))
  end
}

-- Returns true when the click belonged to one of these buttons.
function gui_runtime.handle_click(player, element)
  local name = element.name

  if name == SCREENSHOT_BUTTON_NAME then
    screenshot_runtime.take_base_screenshot(player)
    return true
  end

  if name == CLIFF_EXPLOSIVE_BUTTON_NAME then
    if mod_settings.is_cliff_explosive_button_enabled(player) then
      player.insert({name = "cliff-explosives", count = 1})
    end

    return true
  end

  if name == DEV_EXPAND_BUTTON_NAME then
    if gui_runtime.is_dev_mode_enabled(player) then
      planet_runtime.expand_from_dev_button(player)
      gui_runtime.refresh_all_debug_panels()
    end

    return true
  end

  for prefix, travel in pairs(TRAVEL_BUTTONS) do
    local planet_name = string.match(name, "^" .. prefix .. "(.+)$")

    if planet_name then
      if gui_runtime.is_dev_mode_enabled(player)
        and dev_travel_runtime.is_space_age_active()
        and planet_catalog.is_supported(planet_name)
      then
        travel(player, planet_name)
      end

      return true
    end
  end

  return false
end

return gui_runtime
