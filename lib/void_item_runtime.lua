local defs = require("lib.runtime_defs")
local planet_instance = require("lib.planet_instance")

local void_item_runtime = {}

local function get_event_entity(event)
  return event and (event.entity or event.created_entity)
end

function void_item_runtime.should_destroy_entity(entity)
  if not (entity and entity.valid and entity.surface and entity.position) then
    return false
  end

  if entity.type ~= "item-entity" then
    return false
  end

  local planet = planet_instance.for_surface(entity.surface.name)

  if not planet then
    return false
  end

  local tile_position = defs.snap_entity_position_to_tile(entity.position)
  local square_bounds = defs.get_square_bounds(planet:get_square_size())

  if defs.is_inside_bounds(square_bounds, tile_position) then
    return false
  end

  local tile = entity.surface.get_tile and entity.surface.get_tile(tile_position)

  return tile and tile.name == defs.VOID_TILE_NAME
end

function void_item_runtime.destroy_if_void_item(event)
  local entity = get_event_entity(event)

  if void_item_runtime.should_destroy_entity(entity) then
    entity.destroy()
    return true
  end

  return false
end

return void_item_runtime
