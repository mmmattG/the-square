local defs = require("lib.runtime_defs")
local planet_instance = require("lib.planet_instance")
local planet_square = require("lib.planet_square")

local square_move_runtime = {}

square_move_runtime.MODE_SQUARE = "square"
square_move_runtime.MODE_CONTENTS = "contents"

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

local function is_content_entity_inside_bounds(entity, bounds)
  return defs.is_inside_bounds(bounds, get_entity_tile_position(entity))
end

local function move_bounding_box(bounding_box, direction)
  return {
    left_top = defs.move_position(bounding_box.left_top, direction, 1),
    right_bottom = defs.move_position(bounding_box.right_bottom, direction, 1)
  }
end

local function is_entity_inside_bounds_after_move(entity, bounds, direction)
  if entity.bounding_box then
    return is_bounding_box_inside(bounds, move_bounding_box(entity.bounding_box, direction))
  end

  return defs.is_inside_bounds(bounds, defs.move_position(get_entity_tile_position(entity), direction, 1))
end

local function is_valid_mode(mode)
  return mode == square_move_runtime.MODE_SQUARE or mode == square_move_runtime.MODE_CONTENTS
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

local function get_connected_managed_lines(surface, managed_lines)
  local connected = {}

  if not (managed_lines and managed_lines.anchors) then
    return connected
  end

  for _, anchor in ipairs(managed_lines.anchors) do
    if anchor.resource and anchor.position and anchor.side then
      local connection_position = defs.move_position(anchor.position, anchor.side, -1)
      local permitted_connections = {
        [defs.get_position_key(connection_position)] = {
          kind = anchor.kind,
          direction = anchor.direction
            or defs.get_anchor_direction_for_side(anchor.flow, anchor.kind, anchor.side)
        }
      }

      local connection_area = {
        left_top = copy_position(connection_position),
        right_bottom = {x = connection_position.x + 1, y = connection_position.y + 1}
      }

      for _, entity in ipairs(surface.find_entities_filtered({area = connection_area})) do
        if entity.valid and is_permitted_departing_connection(entity, permitted_connections) then
          connected[anchor] = entity
          break
        end
      end
    end
  end

  return connected
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

local function reposition_managed_lines_for_contents(surface, planet, direction)
  local managed_lines = planet:get_managed_lines()

  if not (managed_lines and managed_lines.anchors) then
    return
  end

  for _, anchor in ipairs(managed_lines.anchors) do
    if anchor.resource and anchor.position and anchor.side then
      if anchor.side ~= OPPOSITE_SIDE[direction] and anchor.side ~= direction then
        local target_position = defs.move_position(anchor.position, direction, 1)
        local target_side = defs.get_anchor_side_for_position(
          planet:get_square_size(),
          target_position,
          planet:get_square_position()
        )

        if target_side == anchor.side then
          destroy_anchor_entity(surface, anchor)
          anchor.position = target_position
          anchor.direction = defs.get_anchor_direction_for_side(anchor.flow, anchor.kind, anchor.side)
        end
      end

      planet_square.ensure_managed_line_connection_stub(surface, anchor)
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

local function check_square_move(planet, surface, direction)
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
    mode = square_move_runtime.MODE_SQUARE,
    direction = direction,
    departing_side = departing_side,
    obstructed_side = departing_side,
    target_position = target_position,
    obstructions = obstructions
  }
end

local function check_contents_move(planet, surface, direction)
  local bounds = defs.get_square_bounds(planet:get_square_size(), planet:get_square_position())
  local obstructions = {}
  local permitted_connections = build_permitted_connections(planet:get_managed_lines(), direction)
  local leading_area = get_departing_area(
    planet:get_square_size(),
    planet:get_square_position(),
    OPPOSITE_SIDE[direction]
  )

  for _, entity in ipairs(surface.find_entities_filtered({area = leading_area})) do
    if entity.valid
      and entity.type ~= "character"
      and is_content_entity_inside_bounds(entity, bounds)
    then
      if not is_entity_inside_bounds_after_move(entity, bounds, direction)
        and not is_permitted_departing_connection(entity, permitted_connections)
      then
        obstructions[#obstructions + 1] = entity
      end
    end
  end

  return {
    ok = #obstructions == 0,
    reason = #obstructions == 0 and nil or "obstructed",
    mode = square_move_runtime.MODE_CONTENTS,
    direction = direction,
    obstructed_side = direction,
    target_position = planet:get_square_position(),
    obstructions = obstructions
  }
end

function square_move_runtime.check(planet_name, direction, mode)
  mode = mode or square_move_runtime.MODE_SQUARE
  local planet = planet_instance.ensure(planet_name)

  if not planet or not VALID_DIRECTIONS[direction] or not is_valid_mode(mode) then
    return {ok = false, reason = "unsupported", mode = mode}
  end

  local surface = game.surfaces[planet:get_surface_name()]

  if not surface then
    return {ok = false, reason = "unsupported", mode = mode}
  end

  if mode == square_move_runtime.MODE_CONTENTS then
    return check_contents_move(planet, surface, direction)
  end

  return check_square_move(planet, surface, direction)
end

function square_move_runtime.get_options_for_player(player, mode)
  local options = {}
  local planet = player
    and player.valid
    and player.surface
    and planet_instance.for_surface(player.surface.name)

  for _, direction in ipairs({"north", "east", "south", "west"}) do
    options[direction] = planet
      and square_move_runtime.check(planet:get_name(), direction, mode)
      or {ok = false, reason = "unsupported", direction = direction, mode = mode}
  end

  return options
end

local function get_contents_tile_updates(surface, planet, direction)
  local bounds = defs.get_square_bounds(planet:get_square_size(), planet:get_square_position())
  local visible_updates = {}
  local hidden_updates = {}

  for y = bounds.left_top.y, bounds.right_bottom.y - 1 do
    for x = bounds.left_top.x, bounds.right_bottom.x - 1 do
      local position = {x = x, y = y}
      local source_position = defs.move_position(position, direction, -1)
      local name
      local hidden_name

      if defs.is_inside_bounds(bounds, source_position) then
        name = surface.get_tile(source_position.x, source_position.y).name

        if surface.get_hidden_tile then
          hidden_name = surface.get_hidden_tile(source_position)
        end
      else
        name = defs.get_managed_tile_name(
          planet:get_square_size(),
          planet:get_surface_size(),
          position,
          planet:get_floor_tile_name(),
          planet:get_square_position()
        )
      end

      visible_updates[#visible_updates + 1] = {name = name, position = position}
      hidden_updates[#hidden_updates + 1] = {name = hidden_name, position = position}
    end
  end

  return visible_updates, hidden_updates
end

local function apply_contents_tile_updates(surface, visible_updates, hidden_updates)
  if #visible_updates > 0 then
    surface.set_tiles(visible_updates, false, false, false, false)
  end

  if surface.set_hidden_tile then
    for _, update in ipairs(hidden_updates) do
      surface.set_hidden_tile(update.position, update.name)
    end
  end
end

local function collect_contents_entities(surface, bounds)
  local entities = {}

  for _, entity in ipairs(surface.find_entities_filtered({area = bounds})) do
    if entity.valid
      and entity.type ~= "character"
      and is_content_entity_inside_bounds(entity, bounds)
    then
      entities[#entities + 1] = entity
    end
  end

  return entities
end

local function destroy_entities(entities)
  for _, entity in ipairs(entities) do
    if entity.valid and entity.destroy then
      entity.destroy({raise_destroy = false})
    end
  end
end

local function delete_buffer_surface(buffer)
  if buffer then
    game.delete_surface(buffer)
  end
end

local function create_buffer_surface(square_size)
  storage.square_move_buffer_sequence = (storage.square_move_buffer_sequence or 0) + 1
  local buffer_name = table.concat({
    defs.SQUARE_MOVE_BUFFER_SURFACE_PREFIX,
    tostring(game.tick or 0),
    tostring(storage.square_move_buffer_sequence)
  }, "-")
  local buffer_size = square_size + 4
  local buffer = game.create_surface(buffer_name, {
    width = buffer_size,
    height = buffer_size,
    starting_points = {{x = 0, y = 0}},
    peaceful_mode = true,
    no_enemies_mode = true
  })

  buffer.request_to_generate_chunks({x = 0, y = 0}, math.ceil(buffer_size / 64))
  buffer.force_generate_chunk_requests()
  destroy_entities(buffer.find_entities())

  return buffer
end

local function clone_tiles_to_buffer(surface, buffer, source_bounds, buffer_bounds)
  surface.clone_area({
    source_area = source_bounds,
    destination_area = buffer_bounds,
    destination_surface = buffer,
    clone_tiles = true,
    clone_entities = false,
    clone_decoratives = false,
    clear_destination_entities = true,
    clear_destination_decoratives = true,
    expand_map = true,
    create_build_effect_smoke = false
  })
end

local function restore_entities_from_buffer(
  surface,
  buffer,
  buffer_entities,
  destination_offset,
  destination_bounds,
  expected_count
)
  buffer.clone_entities({
    entities = buffer_entities,
    destination_offset = destination_offset,
    destination_surface = surface,
    create_build_effect_smoke = false
  })

  return #collect_contents_entities(surface, destination_bounds) == expected_count
end

local function move_contents(planet, surface, direction, options)
  local bounds = defs.get_square_bounds(planet:get_square_size(), planet:get_square_position())
  local buffer_bounds = defs.get_square_bounds(planet:get_square_size(), {x = 0, y = 0})
  local center = planet:get_square_position()
  local to_buffer_offset = {x = -center.x, y = -center.y}
  local to_destination_offset = defs.move_position(center, direction, 1)
  local managed_lines = planet:get_managed_lines()
  local connected_managed_lines = get_connected_managed_lines(surface, managed_lines)
  local permitted_leading_connections = build_permitted_connections(managed_lines, direction)
  local movable_entities = {}
  local held_leading_connections = {}

  for _, entity in ipairs(collect_contents_entities(surface, bounds)) do
    if is_permitted_departing_connection(entity, permitted_leading_connections) then
      held_leading_connections[#held_leading_connections + 1] = entity
    else
      movable_entities[#movable_entities + 1] = entity
    end
  end

  local visible_tile_updates, hidden_tile_updates = get_contents_tile_updates(surface, planet, direction)
  local buffer = create_buffer_surface(planet:get_square_size())
  clone_tiles_to_buffer(surface, buffer, bounds, buffer_bounds)

  surface.clone_entities({
    entities = movable_entities,
    destination_offset = to_buffer_offset,
    destination_surface = buffer,
    create_build_effect_smoke = false
  })

  local buffer_entities = collect_contents_entities(buffer, buffer_bounds)

  if #buffer_entities ~= #movable_entities then
    delete_buffer_surface(buffer)
    return {
      ok = false,
      reason = "unmovable",
      mode = square_move_runtime.MODE_CONTENTS,
      direction = direction
    }
  end

  destroy_entities(movable_entities)
  destroy_entities(held_leading_connections)

  if not restore_entities_from_buffer(
    surface,
    buffer,
    buffer_entities,
    to_destination_offset,
    bounds,
    #movable_entities
  ) then
    destroy_entities(collect_contents_entities(surface, bounds))
    restore_entities_from_buffer(
      surface,
      buffer,
      buffer_entities,
      center,
      bounds,
      #movable_entities
    )

    for anchor, connection in pairs(connected_managed_lines) do
      if connection and anchor.side == direction then
        planet_square.ensure_managed_line_connection_stub(surface, anchor)
      end
    end

    delete_buffer_surface(buffer)
    return {
      ok = false,
      reason = "unmovable",
      mode = square_move_runtime.MODE_CONTENTS,
      direction = direction
    }
  end

  apply_contents_tile_updates(surface, visible_tile_updates, hidden_tile_updates)
  reposition_managed_lines_for_contents(surface, planet, direction)
  delete_buffer_surface(buffer)

  if options.managed_line_runtime and options.managed_line_runtime.reconcile then
    options.managed_line_runtime.reconcile(planet:get_name())
  end

  return {
    ok = true,
    mode = square_move_runtime.MODE_CONTENTS,
    direction = direction,
    planet_name = planet:get_name(),
    square_position = copy_position(center),
    moved_entity_count = #movable_entities
  }
end

local function move_square(planet_name, direction, check, options)
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
    mode = square_move_runtime.MODE_SQUARE,
    direction = direction,
    planet_name = planet_name,
    square_position = check.target_position
  }
end

function square_move_runtime.move(planet_name, direction, options)
  options = options or {}
  local mode = options.mode or square_move_runtime.MODE_SQUARE
  local check = square_move_runtime.check(planet_name, direction, mode)

  if not check.ok then
    return check
  end

  if mode == square_move_runtime.MODE_CONTENTS then
    local planet = planet_instance.ensure(planet_name)
    local surface = game.surfaces[planet:get_surface_name()]

    return move_contents(planet, surface, direction, options)
  end

  return move_square(planet_name, direction, check, options)
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
