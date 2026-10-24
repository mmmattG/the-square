-- Names of this mod's settings, and typed getters for them.
-- See settings.lua for defaults and locale/en for player-facing text.
local mod_settings = {}

mod_settings.EXPANSION_TILES_PER_RESEARCH = "the-square-expansion-tiles-per-research"
mod_settings.BACKGROUND_TILE = "the-square-background-tile"
mod_settings.SCREENSHOT_PIXELS_PER_TILE = "the-square-screenshot-pixels-per-tile"
mod_settings.SCREENSHOT_ALT_MODE = "the-square-screenshot-alt-mode"
mod_settings.DEV_MODE = "the-square-dev-mode"
mod_settings.CLIFF_EXPLOSIVE_BUTTON = "the-square-cliff-explosive-button"

-- A Background tile value that paints a two-tone lab checkerboard instead of one tile.
mod_settings.CHECKERBOARD_BACKGROUND = "checkerboard"

-- Startup: data and control stage.
function mod_settings.get_starting_square_size(planet_name)
  return settings.startup["the-square-" .. planet_name .. "-starting-square-size"].value
end

function mod_settings.get_expansion_tiles_per_research()
  return settings.startup[mod_settings.EXPANSION_TILES_PER_RESEARCH].value
end

-- Map settings.
function mod_settings.get_background_tile()
  return settings.global[mod_settings.BACKGROUND_TILE].value
end

function mod_settings.get_screenshot_pixels_per_tile()
  return settings.global[mod_settings.SCREENSHOT_PIXELS_PER_TILE].value
end

function mod_settings.is_screenshot_alt_mode_enabled()
  return settings.global[mod_settings.SCREENSHOT_ALT_MODE].value
end

-- Per-player settings.
function mod_settings.is_dev_mode_enabled(player)
  return settings.get_player_settings(player)[mod_settings.DEV_MODE].value
end

function mod_settings.is_cliff_explosive_button_enabled(player)
  return settings.get_player_settings(player)[mod_settings.CLIFF_EXPLOSIVE_BUTTON].value
end

return mod_settings
