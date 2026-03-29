local bootstrap_layout = require("lib.bootstrap_layout")

local base_screenshot = {}

local PIXELS_PER_TILE = 32

function base_screenshot.build_capture_spec(square_size, margin_tiles)
  local bounds = bootstrap_layout.get_square_bounds(square_size + (margin_tiles * 2))
  local tile_span = square_size + (margin_tiles * 2)

  return {
    position = {
      x = (bounds.left_top.x + bounds.right_bottom.x) / 2,
      y = (bounds.left_top.y + bounds.right_bottom.y) / 2
    },
    resolution = {
      x = tile_span * PIXELS_PER_TILE,
      y = tile_span * PIXELS_PER_TILE
    },
    tile_span = tile_span,
    zoom = 1
  }
end

return base_screenshot
