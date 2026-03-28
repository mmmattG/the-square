local SURFACE_NAME = "fes-bootstrap"
local SETTING_STARTING_SQUARE_SIZE = "fes-starting-square-size"
local SETTING_DEV_MODE = "fes-dev-mode"
local FLOOR_TILE_NAME = "grass-1"
local VOID_TILE_NAME = "out-of-map"
local CHART_MARGIN = 1
local ITEM_ANCHOR_INTERVAL_TICKS = 8
local FLUID_ANCHOR_AMOUNT_PER_INTERVAL = 160
local STARTER_ANCHOR_OUTER_RING_WIDTH = 2
local STARTER_ANCHOR_LAYOUT_VERSION = 4
local DEV_EXPAND_BUTTON_NAME = "fes_dev_expand_button"

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

local OFFSET_BY_SIDE = {
  north = {x = 0, y = -1},
  east = {x = 1, y = 0},
  south = {x = 0, y = 1},
  west = {x = -1, y = 0}
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

local function get_surface_size(square_size)
  return square_size + (STARTER_ANCHOR_OUTER_RING_WIDTH * 2)
end

local function get_anchor_bounds(square_size)
  return get_square_bounds(square_size + 2)
end

local function is_inside_bounds(bounds, position)
  return position.x >= bounds.left_top.x
    and position.x < bounds.right_bottom.x
    and position.y >= bounds.left_top.y
    and position.y < bounds.right_bottom.y
end

local function get_position_key(position)
  return position.x .. ":" .. position.y
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
  local selected_indexes = {}

  if count > position_count then
    error("Not enough border tiles available for starter input anchors on side " .. side)
  end

  if count == 0 then
    return chosen
  end

  if position_count % 2 == 1 then
    local center = math.floor((position_count + 1) / 2)
    local step = 1

    if count % 2 == 1 then
      selected_indexes[#selected_indexes + 1] = center
    end

    while #selected_indexes < count do
      selected_indexes[#selected_indexes + 1] = center - step

      if #selected_indexes < count then
        selected_indexes[#selected_indexes + 1] = center + step
      end

      step = step + 1
    end
  else
    local left = position_count / 2
    local right = left + 1
    local step = 0

    if count % 2 == 1 then
      selected_indexes[#selected_indexes + 1] = left
      step = 1
    end

    while #selected_indexes < count do
      selected_indexes[#selected_indexes + 1] = left - step

      if #selected_indexes < count then
        selected_indexes[#selected_indexes + 1] = right + step
      end

      step = step + 1
    end
  end

  table.sort(selected_indexes)

  for _, index in ipairs(selected_indexes) do
    chosen[#chosen + 1] = positions[index]
  end

  return chosen
end

local function build_starter_anchor_layout(square_size)
  local bounds = get_anchor_bounds(square_size)
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

local function move_position(position, side, distance)
  local offset = OFFSET_BY_SIDE[side]

  return {
    x = position.x + (offset.x * distance),
    y = position.y + (offset.y * distance)
  }
end

local function build_anchor_position_lookup(anchors)
  local positions = {}

  for _, anchor in ipairs(anchors or {}) do
    positions[get_position_key(anchor.position)] = true
  end

  return positions
end

local function get_managed_tile_name(square_size, surface_size, anchor_positions, position)
  local square_bounds = get_square_bounds(square_size)

  if is_inside_bounds(square_bounds, position) then
    return FLOOR_TILE_NAME
  end

  local surface_bounds = get_square_bounds(surface_size)

  if is_inside_bounds(surface_bounds, position) then
    if anchor_positions[get_position_key(position)] then
      return FLOOR_TILE_NAME
    end

    return VOID_TILE_NAME
  end

  return nil
end

local function build_anchor_ring_tiles(square_size, surface_size, anchors)
  local surface_bounds = get_square_bounds(surface_size)
  local tiles = {}
  local anchor_positions = build_anchor_position_lookup(anchors)

  for y = surface_bounds.left_top.y, surface_bounds.right_bottom.y - 1 do
    for x = surface_bounds.left_top.x, surface_bounds.right_bottom.x - 1 do
      local position = {x = x, y = y}

      if not is_inside_bounds(get_square_bounds(square_size), position) then
        tiles[#tiles + 1] = {
          name = get_managed_tile_name(square_size, surface_size, anchor_positions, position),
          position = position
        }
      end
    end
  end

  return tiles
end

local function build_bootstrap_tiles(square_size, surface_size, anchors)
  local tiles = build_clean_square_tiles(square_size)
  local anchor_ring_tiles = build_anchor_ring_tiles(square_size, surface_size, anchors)

  for _, tile in ipairs(anchor_ring_tiles) do
    tiles[#tiles + 1] = tile
  end

  return tiles
end

local function build_resize_tile_updates(old_square_size, old_surface_size, new_square_size, new_surface_size, anchors)
  local tiles = {}
  local anchor_positions = build_anchor_position_lookup(anchors)
  local old_bounds = get_square_bounds(old_surface_size)
  local new_bounds = get_square_bounds(new_surface_size)
  local min_x = math.min(old_bounds.left_top.x, new_bounds.left_top.x)
  local min_y = math.min(old_bounds.left_top.y, new_bounds.left_top.y)
  local max_x = math.max(old_bounds.right_bottom.x - 1, new_bounds.right_bottom.x - 1)
  local max_y = math.max(old_bounds.right_bottom.y - 1, new_bounds.right_bottom.y - 1)

  for y = min_y, max_y do
    for x = min_x, max_x do
      local position = {x = x, y = y}
      local previous_tile_name = get_managed_tile_name(old_square_size, old_surface_size, {}, position)
      local next_tile_name = get_managed_tile_name(new_square_size, new_surface_size, anchor_positions, position)

      if next_tile_name and next_tile_name ~= previous_tile_name then
        tiles[#tiles + 1] = {
          name = next_tile_name,
          position = position
        }
      end
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
  local surface_size = get_surface_size(square_size)

  return {
    width = surface_size,
    height = surface_size,
    starting_points = {{x = 0, y = 0}},
    peaceful_mode = true,
    no_enemies_mode = true
  }
end

local function create_starter_anchor_state(square_size)
  return {
    layout_version = STARTER_ANCHOR_LAYOUT_VERSION,
    anchors = build_starter_anchor_layout(square_size)
  }
end

local function ensure_bootstrap_state_defaults()
  if not storage.bootstrap then
    return
  end

  storage.bootstrap.surface_name = storage.bootstrap.surface_name or SURFACE_NAME
  storage.bootstrap.surface_size = storage.bootstrap.surface_size or get_surface_size(storage.bootstrap.square_size)
  storage.bootstrap.expansion_points = storage.bootstrap.expansion_points or 0
  storage.bootstrap.expansions_completed = storage.bootstrap.expansions_completed or 0
end

local function ensure_surface_dimensions(surface, target_surface_size)
  local map_gen_settings = surface.map_gen_settings

  if map_gen_settings.width ~= target_surface_size or map_gen_settings.height ~= target_surface_size then
    map_gen_settings.width = target_surface_size
    map_gen_settings.height = target_surface_size
    surface.map_gen_settings = map_gen_settings
  end

  surface.request_to_generate_chunks({x = 0, y = 0}, CHART_MARGIN)
  surface.force_generate_chunk_requests()
end

local function ensure_bootstrap_surface()
  local square_size = get_square_size()
  local surface_size = get_surface_size(square_size)
  local surface = game.surfaces[SURFACE_NAME]
  local starter_anchors = storage.starter_anchors and storage.starter_anchors.anchors or build_starter_anchor_layout(square_size)

  if not surface then
    surface = game.create_surface(SURFACE_NAME, build_surface_map_gen_settings(square_size))
  end

  surface.peaceful_mode = true
  surface.no_enemies_mode = true
  ensure_surface_dimensions(surface, surface_size)
  surface.destroy_decoratives({})
  surface.clear_hidden_tiles()
  destroy_noise_entities(surface)
  surface.set_tiles(build_bootstrap_tiles(square_size, surface_size, starter_anchors), false, true, true, false)

  storage.bootstrap = storage.bootstrap or {}
  storage.bootstrap.square_size = square_size
  storage.bootstrap.surface_size = surface_size
  storage.bootstrap.surface_name = SURFACE_NAME
  ensure_bootstrap_state_defaults()

  return surface
end

local function find_entity_at_position(surface, prototype_name, position)
  local entities = surface.find_entities_filtered({
    name = prototype_name,
    position = position
  })

  return entities[1]
end

local function configure_source_anchor_entity(entity)
  entity.minable = false
  entity.destructible = false
  entity.operable = false
end

local function release_anchor_entity(entity)
  if not (entity and entity.valid) then
    return
  end

  entity.minable = true
  entity.destructible = true
  entity.operable = true
end

local function ensure_item_anchor(surface, anchor)
  local entity = anchor.entity

  if entity and entity.valid then
    if entity.direction ~= anchor.direction then
      entity.direction = anchor.direction
    end

    configure_source_anchor_entity(entity)
    return entity
  end

  entity = find_entity_at_position(surface, ITEM_ANCHOR_PROTOTYPE_NAME, anchor.position)

  if entity and entity.valid then
    entity.direction = anchor.direction
    configure_source_anchor_entity(entity)
    anchor.entity = entity
    return entity
  end

  entity = surface.create_entity({
    name = ITEM_ANCHOR_PROTOTYPE_NAME,
    position = anchor.position,
    direction = anchor.direction,
    force = game.forces.player
  })

  configure_source_anchor_entity(entity)
  anchor.entity = entity

  return entity
end

local function ensure_fluid_anchor(surface, anchor)
  local entity = anchor.entity

  if entity and entity.valid then
    configure_source_anchor_entity(entity)
    return entity
  end

  entity = find_entity_at_position(surface, FLUID_ANCHOR_PROTOTYPE_NAME, anchor.position)

  if entity and entity.valid then
    configure_source_anchor_entity(entity)
    anchor.entity = entity
    return entity
  end

  entity = surface.create_entity({
    name = FLUID_ANCHOR_PROTOTYPE_NAME,
    position = anchor.position,
    force = game.forces.player
  })

  configure_source_anchor_entity(entity)
  anchor.entity = entity

  return entity
end

local function ensure_starter_anchor_state()
  local bootstrap = storage.bootstrap

  if not bootstrap then
    return nil
  end

  if storage.starter_anchors and storage.starter_anchors.layout_version ~= STARTER_ANCHOR_LAYOUT_VERSION then
    storage.starter_anchors = nil
  end

  storage.starter_anchors = storage.starter_anchors or create_starter_anchor_state(bootstrap.square_size)

  return storage.starter_anchors
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

  local starter_anchors = ensure_starter_anchor_state()

  if not starter_anchors then
    return
  end

  for _, anchor in ipairs(starter_anchors.anchors) do
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

local function chart_play_area(force, surface, surface_size)
  local chart_bounds = get_square_bounds(surface_size)

  force.chart(surface, {
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
  chart_play_area(player.force, surface, bootstrap.surface_size or bootstrap.square_size)
end

local function add_expansion_points(amount)
  storage.bootstrap.expansion_points = (storage.bootstrap.expansion_points or 0) + amount
end

local function release_starter_anchor_entities()
  local starter_anchors = storage.starter_anchors

  if not starter_anchors then
    return
  end

  for _, anchor in ipairs(starter_anchors.anchors) do
    release_anchor_entity(anchor.entity)
    anchor.entity = nil
  end
end

local function move_starter_anchors_outward()
  local starter_anchors = storage.starter_anchors

  if not starter_anchors then
    return
  end

  for _, anchor in ipairs(starter_anchors.anchors) do
    anchor.position = move_position(anchor.position, anchor.side, 1)
  end
end

local function apply_square_resize(surface, old_square_size, old_surface_size, new_square_size, new_surface_size)
  ensure_surface_dimensions(surface, new_surface_size)

  local tile_updates = build_resize_tile_updates(
    old_square_size,
    old_surface_size,
    new_square_size,
    new_surface_size,
    storage.starter_anchors and storage.starter_anchors.anchors or {}
  )

  if #tile_updates > 0 then
    surface.set_tiles(tile_updates, false, true, true, false)
  end
end

local function expand_square(player)
  local bootstrap = storage.bootstrap

  if not bootstrap then
    return
  end

  local surface = game.surfaces[bootstrap.surface_name]

  if not surface then
    return
  end

  ensure_starter_anchor_state()

  local previous_square_size = bootstrap.square_size
  local previous_surface_size = bootstrap.surface_size or get_surface_size(previous_square_size)
  local next_square_size = previous_square_size + 2
  local next_surface_size = get_surface_size(next_square_size)
  local newly_unlocked_tiles = (next_square_size * next_square_size) - (previous_square_size * previous_square_size)

  release_starter_anchor_entities()
  move_starter_anchors_outward()

  bootstrap.square_size = next_square_size
  bootstrap.surface_size = next_surface_size
  bootstrap.expansions_completed = (bootstrap.expansions_completed or 0) + 1
  add_expansion_points(newly_unlocked_tiles)

  apply_square_resize(surface, previous_square_size, previous_surface_size, next_square_size, next_surface_size)
  ensure_starter_anchors()
  chart_play_area(game.forces.player, surface, next_surface_size)

  game.print(
    {"",
      "[Expanding Square] Square expanded from ",
      previous_square_size,
      "x",
      previous_square_size,
      " to ",
      next_square_size,
      "x",
      next_square_size,
      ". Awarded ",
      newly_unlocked_tiles,
      " expansion points (total: ",
      bootstrap.expansion_points,
      ")."
    }
  )

  if player and player.valid then
    player.play_sound({path = "utility/new_objective"})
  end
end

local function is_dev_mode_enabled(player)
  return settings.get_player_settings(player)[SETTING_DEV_MODE].value
end

local function sync_dev_gui(player)
  if not (player and player.valid) then
    return
  end

  local button = player.gui.top[DEV_EXPAND_BUTTON_NAME]

  if is_dev_mode_enabled(player) then
    if not button then
      player.gui.top.add({
        type = "button",
        name = DEV_EXPAND_BUTTON_NAME,
        caption = {"gui.fes-dev-expand-button"}
      })
    end
  elseif button then
    button.destroy()
  end
end

local function sync_all_dev_guis()
  for _, player in pairs(game.players) do
    sync_dev_gui(player)
  end
end

local function bootstrap_world()
  call_freeplay("set_skip_intro", true)
  call_freeplay("set_disable_crashsite", true)

  storage.starter_anchors = create_starter_anchor_state(get_square_size())

  local surface = ensure_bootstrap_surface()
  game.forces.player.set_spawn_position({x = 0, y = 0}, surface)
  ensure_starter_anchors()

  for _, player in pairs(game.players) do
    teleport_player_to_square(player)
  end

  sync_all_dev_guis()
end

local function refresh_spawn_routing()
  local bootstrap = storage.bootstrap

  if not bootstrap then
    return
  end

  ensure_bootstrap_state_defaults()

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

  sync_all_dev_guis()
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
    ensure_bootstrap_state_defaults()
    ensure_starter_anchor_state()
    refresh_spawn_routing()
    return
  end

  bootstrap_world()
end)

script.on_event(defines.events.on_player_created, function(event)
  local player = game.get_player(event.player_index)

  if player then
    teleport_player_to_square(player)
    sync_dev_gui(player)
  end
end)

script.on_event(defines.events.on_player_respawned, function(event)
  local player = game.get_player(event.player_index)

  if player then
    teleport_player_to_square(player)
    sync_dev_gui(player)
  end
end)

script.on_event(defines.events.on_player_rotated_entity, function(event)
  reset_rotated_anchor(event.entity)
end)

script.on_event(defines.events.on_player_flipped_entity, function(event)
  reset_rotated_anchor(event.entity)
end)

script.on_event(defines.events.on_gui_click, function(event)
  if event.element and event.element.valid and event.element.name == DEV_EXPAND_BUTTON_NAME then
    local player = game.get_player(event.player_index)

    if player and is_dev_mode_enabled(player) then
      expand_square(player)
    end
  end
end)

script.on_event(defines.events.on_runtime_mod_setting_changed, function(event)
  if event.setting == SETTING_STARTING_SQUARE_SIZE then
    if storage.bootstrap then
      notify_square_size_change_applies_to_new_saves()
    end

    return
  end

  if event.setting == SETTING_DEV_MODE then
    local player = game.get_player(event.player_index)

    if player then
      sync_dev_gui(player)
    end
  end
end)

script.on_nth_tick(ITEM_ANCHOR_INTERVAL_TICKS, function()
  ensure_starter_anchors()
  pump_starter_anchors()
end)
