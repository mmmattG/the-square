local base_screenshot = require("lib.base_screenshot")
local defs = require("lib.runtime_defs")

local screenshot_runtime = {}

local function build_screenshot_path(square_size)
  return string.format(
    "%s/base-%dx%d-tick-%d.png",
    defs.BASE_SCREENSHOT_DIRECTORY,
    square_size,
    square_size,
    game.tick
  )
end

function screenshot_runtime.take_base_screenshot(player)
  if not (player and player.valid and storage.bootstrap) then
    return
  end

  local bootstrap = storage.bootstrap
  local surface = game.surfaces[bootstrap.surface_name]

  if not surface then
    return
  end

  local capture = base_screenshot.build_capture_spec(
    bootstrap.square_size,
    defs.BASE_SCREENSHOT_MARGIN_TILES
  )
  local path = build_screenshot_path(bootstrap.square_size)

  game.take_screenshot({
    by_player = player,
    surface = surface,
    position = capture.position,
    resolution = capture.resolution,
    zoom = capture.zoom,
    path = path,
    show_gui = false,
    show_entity_info = false,
    show_cursor_building_preview = false,
    force_render = true
  })

  player.print({
    "message.fes-screenshot-saved",
    path,
    bootstrap.square_size,
    defs.BASE_SCREENSHOT_MARGIN_TILES
  })
end

return screenshot_runtime
