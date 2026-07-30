local defs = require("lib.runtime_defs")
local planet_instance = require("lib.planet_instance")
local planet_square = require("lib.planet_square")

local square_move_runtime = {}

local OPPOSITE_SIDE = {
  north = "south",
  east = "west",
  south = "north",
  west = "east"
}

local VALID_DIRECTIONS = {
  north = true,
  east = true,
  south = true,
  west = true
}

local function copy_position(position)
  return {x = position.x, y = position.y}
end

local function get_entity_tile_position(entity)
  return defs.snap_entity_position_to_tile(entity.position)
end

local function is_bounding_box_inside(bounds, bounding_box)
  return bounding_box.left_top.x >= bounds.left_top.x
    and bounding_box.left_top.y >= bounds.left_top.y
    and bounding_box.right_bottom.x <= bounds.right_bottom.x
    and bounding_box.right_bottom.y <= bounds.right_bottom.y
end

local function is_entity_inside_bounds(entity, bounds)
  if entity.bounding_box then
    return is_bounding_box_inside(bounds, entity.bounding_box)
  end

  return defs.is_inside_bounds(bounds, get_entity_tile_position(entity))
end

local function build_permitted_connections(managed_lines, departing_side)
  local permitted = {}

  if not (managed_lines and managed_lines.anchors) then
    return permitted
  end

  for _, anchor in ipairs(managed_lines.anchors) do
    if anchor.resource
      and anchor.position
      and anchor.side == departing_side
    then
      local connection_position = defs.move_position(anchor.position, anchor.side, -1)
      permitted[defs.get_position_key(connection_position)] = {
        kind = anchor.kind,
        direction = anchor.direction
          or defs.get_anchor_direction_for_side(anchor.flow, anchor.kind, anchor.side)
      }
    end
  end

  return permitted
end

local function is_permitted_departing_connection(entity, permitted_connections)
  local connection = permitted_connections[defs.get_position_key(get_entity_tile_position(entity))]

  if not connection then
    return false
  end

  if connection.kind == "fluid" then
    return entity.type == "pipe"
  end

  return entity.type == "transport-belt" and entity.direction == connection.direction
end

local function get_departing_area(square_size, square_position, direction)
  local bounds = defs.get_square_bounds(square_size, square_position)

  if direction == "north" then
    return {
      left_top = {x = bounds.left_top.x, y = bounds.right_bottom.y - 1},
      right_bottom = copy_position(bounds.right_bottom)
    }
  end

  if direction == "east" then
    return {
      left_top = copy_position(bounds.left_top),
      right_bottom = {x = bounds.left_top.x + 1, y = bounds.right_bottom.y}
    }
  end

  if direction == "south" then
    return {
      left_top = copy_position(bounds.left_top),
      right_bottom = {x = bounds.right_bottom.x, y = bounds.left_top.y + 1}
    }
  end

  return {
    left_top = {x = bounds.right_bottom.x - 1, y = bounds.left_top.y},
    right_bottom = copy_position(bounds.right_bottom)
  }
end

local function get_square_tile_updates(planet, target_position)
  local square_size = planet:get_square_size()
  local surface_size = planet:get_surface_size()
  local floor_tile_name = planet:get_floor_tile_name()
  local previous_position = planet:get_square_position()
  local previous_bounds = defs.get_square_bounds(surface_size, previous_position)
  local next_bounds = defs.get_square_bounds(surface_size, target_position)
  local min_x = math.min(previous_bounds.left_top.x, next_bounds.left_top.x)
  local min_y = math.min(previous_bounds.left_top.y, next_bounds.left_top.y)
  local max_x = math.max(previous_bounds.right_bottom.x, next_bounds.right_bottom.x) - 1
  local max_y = math.max(previous_bounds.right_bottom.y, next_bounds.right_bottom.y) - 1
  local updates = {}

  for y = min_y, max_y do
    for x = min_x, max_x do
      local position = {x = x, y = y}
      local previous_name = defs.get_managed_tile_name(
        square_size,
        surface_size,
        position,
        floor_tile_name,
        previous_position
      )
      local next_name = defs.get_managed_tile_name(
        square_size,
        surface_size,
        position,
        floor_tile_name,
        target_position
      )

      if previous_name ~= next_name then
        updates[#updates + 1] = {
          name = next_name or defs.VOID_TILE_NAME,
          position = position
        }
      end
    end
  end

  return updates
end

local function ensure_surface_dimensions(surface, surface_size, target_position)
  local map_gen_settings = surface.map_gen_settings
  local target_width = surface_size + (math.abs(target_position.x) * 2)
  local target_height = surface_size + (math.abs(target_position.y) * 2)

  if map_gen_settings.width < target_width or map_gen_settings.height < target_height then
    map_gen_settings.width = math.max(map_gen_settings.width, target_width)
    map_gen_settings.height = math.max(map_gen_settings.height, target_height)
    surface.map_gen_settings = map_gen_settings
  end

  local chunk_radius = math.max(defs.CHART_MARGIN, math.ceil(surface_size / 64))
  surface.request_to_generate_chunks(target_position, chunk_radius)
  surface.force_generate_chunk_requests()
end

local function destroy_anchor_entity(surface, anchor)
  local entity = anchor.entity

  if entity and entity.valid and entity.destroy then
    entity.destroy({raise_destroy = false})
  elseif anchor.entity_name and anchor.position then
    local entities = surface.find_entities_filtered({
      name = anchor.entity_name,
      position = anchor.position
    })
    entity = entities[1]

    if entity and entity.valid and entity.destroy then
      entity.destroy({raise_destroy = false})
    end
  end

  anchor.entity = nil
end

local function reposition_managed_lines(surface, planet, direction, target_position)
  local managed_lines = planet:get_managed_lines()

  if not (managed_lines and managed_lines.anchors) then
    return
  end

  for _, anchor in ipairs(managed_lines.anchors) do
    if anchor.position then
      local retained_side = defs.get_anchor_side_for_position(
        planet:get_square_size(),
        anchor.position,
        target_position
      )

      if retained_side then
        anchor.side = retained_side
        anchor.direction = defs.get_anchor_direction_for_side(anchor.flow, anchor.kind, retained_side)
      else
        local previous_side = anchor.side

        if anchor.resource and previous_side == direction then
          planet_square.leave_trailing_managed_line_stub(surface, anchor)
        else
          destroy_anchor_entity(surface, anchor)
        end

        anchor.position = defs.move_position(anchor.position, direction, 1)
        anchor.side = defs.get_anchor_side_for_position(
          planet:get_square_size(),
          anchor.position,
          target_position
        ) or previous_side
        anchor.direction = defs.get_anchor_direction_for_side(anchor.flow, anchor.kind, anchor.side)
        anchor.entity = nil
      end
    end
  end
end

function square_move_runtime.get_target_position(square_position, direction)
  if not VALID_DIRECTIONS[direction] then
    return nil
  end

  return defs.move_position(square_position or {x = 0, y = 0}, direction, 1)
end

function square_move_runtime.get_departing_side(direction)
  return OPPOSITE_SIDE[direction]
end

function square_move_runtime.check(planet_name, direction)
  local planet = planet_instance.ensure(planet_name)

  if not planet or not VALID_DIRECTIONS[direction] then
    return {ok = false, reason = "unsupported"}
  end

  local surface = game.surfaces[planet:get_surface_name()]

  if not surface then
    return {ok = false, reason = "unsupported"}
  end

  local square_position = planet:get_square_position()
  local target_position = square_move_runtime.get_target_position(square_position, direction)
  local target_bounds = defs.get_square_bounds(planet:get_square_size(), target_position)
  local departing_side = square_move_runtime.get_departing_side(direction)
  local permitted_connections = build_permitted_connections(planet:get_managed_lines(), departing_side)
  local obstructions = {}
  local entities = surface.find_entities_filtered({
    area = get_departing_area(planet:get_square_size(), square_position, direction)
  })

  for _, entity in ipairs(entities) do
    if entity.valid
      and not is_entity_inside_bounds(entity, target_bounds)
      and not is_permitted_departing_connection(entity, permitted_connections)
    then
      obstructions[#obstructions + 1] = entity
    end
  end

  return {
    ok = #obstructions == 0,
    reason = #obstructions == 0 and nil or "obstructed",
    direction = direction,
    departing_side = departing_side,
    target_position = target_position,
    obstructions = obstructions
  }
end

function square_move_runtime.get_options_for_player(player)
  local options = {}
  local planet = player
    and player.valid
    and player.surface
    and planet_instance.for_surface(player.surface.name)

  for _, direction in ipairs({"north", "east", "south", "west"}) do
    options[direction] = planet
      and square_move_runtime.check(planet:get_name(), direction)
      or {ok = false, reason = "unsupported", direction = direction}
  end

  return options
end

function square_move_runtime.move(planet_name, direction, options)
  options = options or {}
  local check = square_move_runtime.check(planet_name, direction)

  if not check.ok then
    return check
  end

  local planet = planet_instance.ensure(planet_name)
  local surface = game.surfaces[planet:get_surface_name()]
  local tile_updates = get_square_tile_updates(planet, check.target_position)

  ensure_surface_dimensions(surface, planet:get_surface_size(), check.target_position)
  reposition_managed_lines(surface, planet, direction, check.target_position)

  if #tile_updates > 0 then
    surface.set_tiles(tile_updates, true, true, true, false)
  end

  planet:set_square_position(check.target_position)

  if options.managed_line_runtime and options.managed_line_runtime.reconcile then
    options.managed_line_runtime.reconcile(planet_name)
  end

  local force = options.force or game.forces.player

  if force then
    if force.set_spawn_position then
      force.set_spawn_position(check.target_position, surface)
    end

    planet_square.chart_play_area(force, surface, planet:get_surface_size(), check.target_position)
  end

  return {
    ok = true,
    direction = direction,
    planet_name = planet_name,
    square_position = check.target_position
  }
end

function square_move_runtime.move_for_player(player, direction, options)
  local planet = player
    and player.valid
    and player.surface
    and planet_instance.for_surface(player.surface.name)

  if not planet then
    return {ok = false, reason = "unsupported"}
  end

  options = options or {}
  options.force = player.force or options.force

  return square_move_runtime.move(planet:get_name(), direction, options)
end

function square_move_runtime.parse_direction_button_name(name)
  if type(name) ~= "string" then
    return nil
  end

  local direction = string.match(name, "^" .. defs.SQUARE_MOVE_DIRECTION_BUTTON_PREFIX .. "(%w+)$")

  return VALID_DIRECTIONS[direction] and direction or nil
end

return square_move_runtime
