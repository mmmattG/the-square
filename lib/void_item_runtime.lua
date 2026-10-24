-- Items dropped into the Void are destroyed instead of piling up out of reach.
local planet_state = require("lib.planet_state")
local square_layout = require("lib.square_layout")
local square_runtime = require("lib.square_runtime")

local void_item_runtime = {}

local function should_destroy(entity)
  if not (entity.valid and entity.type == "item-entity") then
    return false
  end

  local planet = planet_state.for_surface(entity.surface)

  if not planet then
    return false
  end

  local tile_position = square_layout.snap_to_tile(entity.position)
  local square_bounds = square_layout.get_square_bounds(
    planet:get_square_size(),
    planet:get_square_position()
  )

  if square_layout.is_inside_bounds(square_bounds, tile_position) then
    return false
  end

  return entity.surface.get_tile(tile_position).name == square_runtime.VOID_TILE_NAME
end

function void_item_runtime.destroy_if_in_void(entity)
  if should_destroy(entity) then
    entity.destroy()
  end
end

return void_item_runtime
