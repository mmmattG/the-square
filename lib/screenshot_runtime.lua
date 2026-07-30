local base_screenshot = require("lib.base_screenshot")
local defs = require("lib.runtime_defs")
local planet_instance = require("lib.planet_instance")

local screenshot_runtime = {}

local function build_screenshot_path(planet_name, square_size)
  return string.format(
    "%s/%s-base-%dx%d-tick-%d.png",
    defs.BASE_SCREENSHOT_DIRECTORY,
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
  local planet = viewed_surface and planet_instance.for_surface(viewed_surface.name)

  if not planet then
    player.print({"message.the-square-screenshot-unsupported-surface"})
    return false
  end

  local square_size = planet:get_square_size()
  local surface = game.surfaces[planet:get_surface_name()]

  if not surface then
    player.print({"message.the-square-screenshot-unsupported-surface"})
    return false
  end

  local capture = base_screenshot.build_capture_spec(
    square_size,
    defs.BASE_SCREENSHOT_MARGIN_TILES,
    defs.get_screenshot_pixels_per_tile(),
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
    show_entity_info = defs.is_screenshot_alt_mode_enabled(),
    show_cursor_building_preview = false,
    force_render = true
  })

  player.print({
    "message.the-square-screenshot-saved",
    path,
    square_size,
    defs.BASE_SCREENSHOT_MARGIN_TILES,
    defs.get_screenshot_pixels_per_tile()
  })

  return true
end

return screenshot_runtime
