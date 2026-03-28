local SURFACE_NAME = "fes-bootstrap"
local SETTING_STARTING_SQUARE_SIZE = "fes-starting-square-size"
local FLOOR_TILE_NAME = "grass-1"
local CHART_MARGIN = 1
local ITEM_ANCHOR_INTERVAL_TICKS = 8
local FLUID_ANCHOR_AMOUNT_PER_INTERVAL = 160

local STARTER_INPUT_DEFINITIONS = {
  {resource = "iron-ore", kind = "item", side = "north"},
  {resource = "copper-ore", kind = "item", side = "north"},
  {resource = "coal", kind = "item", side = "south"},
  {resource = "stone", kind = "item", side = "south"},
  {resource = "water", kind = "fluid", side = "west"},
  {resource = "wood", kind = "item", side = "east"}
}

local DIRECTION_BY_SIDE = {
  north = defines.direction.south,
  east = defines.direction.west,
  south = defines.direction.north,
  west = defines.direction.east
}

local ITEM_ANCHOR_PROTOTYPE_NAME = "transport-belt"
local FLUID_ANCHOR_PROTOTYPE_NAME = "pipe"

local function get_square_size()
  return settings.global[SETTING_STARTING_SQUARE_SIZE].value
end

local function get_square_bounds(size)
  local left = -math.floor(size / 2)

  return {
    left_top = {x = left, y = left},
    right_bottom = {x = left + size, y = left + size}
  }
end

local function get_edge_positions(bounds, side)
  local positions = {}
  local min_x = bounds.left_top.x
  local min_y = bounds.left_top.y
  local max_x = bounds.right_bottom.x - 1
  local max_y = bounds.right_bottom.y - 1

  if side == "north" then
    for x = min_x + 1, max_x - 1 do
      positions[#positions + 1] = {x = x, y = min_y}
    end
  elseif side == "south" then
    for x = min_x + 1, max_x - 1 do
      positions[#positions + 1] = {x = x, y = max_y}
    end
  elseif side == "west" then
    for y = min_y + 1, max_y - 1 do
      positions[#positions + 1] = {x = min_x, y = y}
    end
  elseif side == "east" then
    for y = min_y + 1, max_y - 1 do
      positions[#positions + 1] = {x = max_x, y = y}
    end
  end

  return positions
end

local function choose_spread_positions(positions, count, side)
  local chosen = {}
  local position_count = #positions

  if count > position_count then
    error("Not enough border tiles available for starter input anchors on side " .. side)
  end

  for i = 1, count do
    local index = math.floor((i * (position_count + 1)) / (count + 1))
    index = math.max(1, math.min(position_count, index))
    chosen[#chosen + 1] = positions[index]
  end

  return chosen
end

local function build_starter_anchor_layout(square_size)
  local bounds = get_square_bounds(square_size)
  local resources_by_side = {}
  local anchors = {}

  for _, definition in ipairs(STARTER_INPUT_DEFINITIONS) do
    resources_by_side[definition.side] = resources_by_side[definition.side] or {}
    resources_by_side[definition.side][#resources_by_side[definition.side] + 1] = definition
  end

  for _, side in ipairs({"north", "east", "south", "west"}) do
    local side_resources = resources_by_side[side] or {}
    local side_positions = get_edge_positions(bounds, side)
    local chosen_positions = choose_spread_positions(side_positions, #side_resources, side)

    for index, definition in ipairs(side_resources) do
      anchors[#anchors + 1] = {
        resource = definition.resource,
        kind = definition.kind,
        side = side,
        direction = DIRECTION_BY_SIDE[side],
        position = chosen_positions[index]
      }
    end
  end

  return anchors
end

local function call_freeplay(interface_name, value)
  if remote.interfaces.freeplay and remote.interfaces.freeplay[interface_name] then
    remote.call("freeplay", interface_name, value)
  end
end

local function build_clean_square_tiles(size)
  local bounds = get_square_bounds(size)
  local tiles = {}

  for y = bounds.left_top.y, bounds.right_bottom.y - 1 do
    for x = bounds.left_top.x, bounds.right_bottom.x - 1 do
      tiles[#tiles + 1] = {
        name = FLOOR_TILE_NAME,
        position = {x = x, y = y}
      }
    end
  end

  return tiles
end

local function destroy_noise_entities(surface)
  for _, entity in ipairs(surface.find_entities()) do
    if entity.valid and entity.type ~= "character" then
      entity.destroy()
    end
  end
end

local function build_surface_map_gen_settings(square_size)
  return {
    width = square_size,
    height = square_size,
    starting_points = {{x = 0, y = 0}},
    peaceful_mode = true,
    no_enemies_mode = true
  }
end

local function validate_anchor_prototypes()
  if not game.entity_prototypes[ITEM_ANCHOR_PROTOTYPE_NAME] then
    error("Missing starter item anchor prototype: " .. ITEM_ANCHOR_PROTOTYPE_NAME)
  end
end

local function ensure_bootstrap_surface()
  validate_anchor_prototypes()
  local square_size = get_square_size()
  local surface = game.surfaces[SURFACE_NAME]

  if not surface then
    surface = game.create_surface(SURFACE_NAME, build_surface_map_gen_settings(square_size))
  end

  surface.peaceful_mode = true
  surface.no_enemies_mode = true
  surface.request_to_generate_chunks({x = 0, y = 0}, CHART_MARGIN)
  surface.force_generate_chunk_requests()
  surface.destroy_decoratives({})
  surface.clear_hidden_tiles()
  destroy_noise_entities(surface)
  surface.set_tiles(build_clean_square_tiles(square_size), true, true, true, false)

  storage.bootstrap = {
    square_size = square_size,
    surface_name = SURFACE_NAME
  }

  return surface
end

local function find_entity_at_position(surface, prototype_name, position)
  local entities = surface.find_entities_filtered({
    name = prototype_name,
    position = position
  })

  return entities[1]
end

local function configure_anchor_entity(entity)
  entity.minable = false
  entity.destructible = false
  entity.operable = false
end

local function ensure_item_anchor(surface, anchor)
  local entity = anchor.entity

  if entity and entity.valid then
    if entity.direction ~= anchor.direction then
      entity.direction = anchor.direction
    end

    configure_anchor_entity(entity)
    return entity
  end

  entity = find_entity_at_position(surface, ITEM_ANCHOR_PROTOTYPE_NAME, anchor.position)

  if entity and entity.valid then
    entity.direction = anchor.direction
    configure_anchor_entity(entity)
    anchor.entity = entity
    return entity
  end

  entity = surface.create_entity({
    name = ITEM_ANCHOR_PROTOTYPE_NAME,
    position = anchor.position,
    direction = anchor.direction,
    force = game.forces.player
  })

  configure_anchor_entity(entity)
  anchor.entity = entity

  return entity
end

local function ensure_fluid_anchor(surface, anchor)
  local entity = anchor.entity

  if entity and entity.valid then
    configure_anchor_entity(entity)
    return entity
  end

  entity = find_entity_at_position(surface, FLUID_ANCHOR_PROTOTYPE_NAME, anchor.position)

  if entity and entity.valid then
    configure_anchor_entity(entity)
    anchor.entity = entity
    return entity
  end

  entity = surface.create_entity({
    name = FLUID_ANCHOR_PROTOTYPE_NAME,
    position = anchor.position,
    force = game.forces.player
  })

  configure_anchor_entity(entity)
  anchor.entity = entity

  return entity
end

local function ensure_starter_anchors()
  local bootstrap = storage.bootstrap

  if not bootstrap then
    return
  end

  local surface = game.surfaces[bootstrap.surface_name]

  if not surface then
    return
  end

  storage.starter_anchors = storage.starter_anchors or {
    square_size = bootstrap.square_size,
    anchors = build_starter_anchor_layout(bootstrap.square_size)
  }

  if storage.starter_anchors.square_size ~= bootstrap.square_size then
    storage.starter_anchors = {
      square_size = bootstrap.square_size,
      anchors = build_starter_anchor_layout(bootstrap.square_size)
    }
  end

  for _, anchor in ipairs(storage.starter_anchors.anchors) do
    if anchor.kind == "item" then
      ensure_item_anchor(surface, anchor)
    else
      ensure_fluid_anchor(surface, anchor)
    end
  end
end

local function pump_starter_anchors()
  local starter_anchors = storage.starter_anchors

  if not starter_anchors then
    return
  end

  for _, anchor in ipairs(starter_anchors.anchors) do
    local entity = anchor.entity

    if entity and entity.valid then
      if anchor.kind == "item" then
        local line = entity.get_transport_line(1)

        if line and line.can_insert_at_back() then
          line.insert_at_back({name = anchor.resource, count = 1})
        end
      else
        entity.insert_fluid({
          name = anchor.resource,
          amount = FLUID_ANCHOR_AMOUNT_PER_INTERVAL
        })
      end
    end
  end
end

local function reset_rotated_anchor(entity)
  local starter_anchors = storage.starter_anchors

  if not starter_anchors or not (entity and entity.valid) then
    return
  end

  for _, anchor in ipairs(starter_anchors.anchors) do
    if anchor.entity == entity and entity.direction ~= anchor.direction then
      entity.direction = anchor.direction
      return
    end
  end
end

local function teleport_player_to_square(player)
  local bootstrap = storage.bootstrap

  if not bootstrap then
    return
  end

  local surface = game.surfaces[bootstrap.surface_name]

  if not surface then
    return
  end

  local target_position = {x = 0, y = 0}
  player.force.set_spawn_position(target_position, surface)
  player.teleport(target_position, surface)

  local chart_bounds = get_square_bounds(bootstrap.square_size)
  player.force.chart(surface, {
    {
      chart_bounds.left_top.x - CHART_MARGIN,
      chart_bounds.left_top.y - CHART_MARGIN
    },
    {
      chart_bounds.right_bottom.x + CHART_MARGIN,
      chart_bounds.right_bottom.y + CHART_MARGIN
    }
  })
end

local function bootstrap_world()
  call_freeplay("set_skip_intro", true)
  call_freeplay("set_disable_crashsite", true)

  local surface = ensure_bootstrap_surface()
  game.forces.player.set_spawn_position({x = 0, y = 0}, surface)
  ensure_starter_anchors()

  for _, player in pairs(game.players) do
    teleport_player_to_square(player)
  end
end

local function refresh_spawn_routing()
  local bootstrap = storage.bootstrap

  if not bootstrap then
    return
  end

  local surface = game.surfaces[bootstrap.surface_name]

  if not surface then
    return
  end

  call_freeplay("set_skip_intro", true)
  call_freeplay("set_disable_crashsite", true)
  game.forces.player.set_spawn_position({x = 0, y = 0}, surface)
  ensure_starter_anchors()

  for _, player in pairs(game.players) do
    teleport_player_to_square(player)
  end
end

local function notify_square_size_change_applies_to_new_saves()
  local requested_size = settings.global[SETTING_STARTING_SQUARE_SIZE].value

  if storage.bootstrap and storage.bootstrap.square_size == requested_size then
    return
  end

  game.print(
    {"",
      "[Expanding Square] Starting square size changes only apply to new saves. ",
      "This save remains at ",
      storage.bootstrap and storage.bootstrap.square_size or "?",
      " and the current map setting is ",
      requested_size,
      "."
    }
  )
end

script.on_init(function()
  bootstrap_world()
end)

script.on_configuration_changed(function()
  if storage.bootstrap then
    refresh_spawn_routing()
    return
  end

  bootstrap_world()
end)

script.on_event(defines.events.on_player_created, function(event)
  local player = game.get_player(event.player_index)

  if player then
    teleport_player_to_square(player)
  end
end)

script.on_event(defines.events.on_player_respawned, function(event)
  local player = game.get_player(event.player_index)

  if player then
    teleport_player_to_square(player)
  end
end)

script.on_event(defines.events.on_player_rotated_entity, function(event)
  reset_rotated_anchor(event.entity)
end)

script.on_event(defines.events.on_player_flipped_entity, function(event)
  reset_rotated_anchor(event.entity)
end)

script.on_event(defines.events.on_runtime_mod_setting_changed, function(event)
  if event.setting ~= SETTING_STARTING_SQUARE_SIZE then
    return
  end

  if storage.bootstrap then
    notify_square_size_change_applies_to_new_saves()
  end
end)

script.on_nth_tick(ITEM_ANCHOR_INTERVAL_TICKS, function()
  ensure_starter_anchors()
  pump_starter_anchors()
end)
