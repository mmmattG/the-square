-- The Base screenshot button: saves a picture of the current Planet's Square to
-- script-output/the-square/.
local base_screenshot = require("lib.base_screenshot")
local mod_settings = require("lib.mod_settings")
local planet_state = require("lib.planet_state")

local screenshot_runtime = {}

screenshot_runtime.DIRECTORY = "the-square"

local MARGIN_TILES = 2

local function build_screenshot_path(planet_name, square_size)
  return string.format(
    "%s/%s-base-%dx%d-tick-%d.png",
    screenshot_runtime.DIRECTORY,
    planet_name,
    square_size,
    square_size,
    game.tick
  )
end

function screenshot_runtime.take_base_screenshot(player)
  if not (player and player.valid) then
    return false
  end

  local viewed_surface = player.surface
  local planet = viewed_surface and planet_state.for_surface(viewed_surface)

  if not planet then
    player.print({"message.the-square-screenshot-unsupported-surface"})
    return false
  end

  local square_size = planet:get_square_size()
  local surface = planet:get_surface()

  if not surface then
    player.print({"message.the-square-screenshot-unsupported-surface"})
    return false
  end

  local capture = base_screenshot.build_capture_spec(
    square_size,
    MARGIN_TILES,
    mod_settings.get_screenshot_pixels_per_tile(),
    planet:get_square_position()
  )
  local path = build_screenshot_path(viewed_surface.name, square_size)

  game.take_screenshot({
    by_player = player,
    surface = surface,
    position = capture.position,
    resolution = capture.resolution,
    zoom = capture.zoom,
    path = path,
    show_gui = false,
    show_entity_info = mod_settings.is_screenshot_alt_mode_enabled(),
    show_cursor_building_preview = false,
    force_render = true
  })

  player.print({
    "message.the-square-screenshot-saved",
    path,
    square_size,
    MARGIN_TILES,
    mod_settings.get_screenshot_pixels_per_tile()
  })

  return true
end

return screenshot_runtime
