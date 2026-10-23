-- Top-bar buttons (base screenshot, cliff explosives, dev Expand) and the dev mode
-- status panel. The Move Square window lives in square_move_gui.
local debug_platform_runtime = require("lib.debug_platform_runtime")
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
local DEV_ORBIT_BUTTON_PREFIX = "the_square_dev_orbit_teleport__"
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

  if debug_platform_runtime.is_space_age_active() then
    frame.add({type = "label", caption = {"gui.the-square-dev-orbit-teleport-title"}})

    for _, planet_name in ipairs(planet_catalog.SUPPORTED_PLANETS) do
      frame.add({
        type = "button",
        name = DEV_ORBIT_BUTTON_PREFIX .. planet_name,
        caption = {"gui.the-square-dev-orbit-teleport-button", planet_catalog.get(planet_name).label}
      })
    end
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

  local orbit_planet_name = string.match(name, "^" .. DEV_ORBIT_BUTTON_PREFIX .. "(.+)$")

  if orbit_planet_name then
    if gui_runtime.is_dev_mode_enabled(player) and debug_platform_runtime.is_space_age_active() then
      local result = debug_platform_runtime.teleport_player_to_planet_platform(player, orbit_planet_name)

      if not result.ok then
        player.print(result.error)
      end
    end

    return true
  end

  return false
end

return gui_runtime
