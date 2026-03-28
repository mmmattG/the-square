local SURFACE_NAME = "fes-bootstrap"
local SETTING_STARTING_SQUARE_SIZE = "fes-starting-square-size"
local SETTING_DEV_MODE = "fes-dev-mode"
local FLOOR_TILE_NAME = "grass-1"
local VOID_TILE_NAME = "out-of-map"
local CHART_MARGIN = 1
local ITEM_ANCHOR_INTERVAL_TICKS = 8
local FLUID_ANCHOR_AMOUNT_PER_INTERVAL = 160
local STARTER_ANCHOR_OUTER_RING_WIDTH = 2
local STARTER_ANCHOR_LAYOUT_VERSION = 7
local DEV_EXPAND_BUTTON_NAME = "fes_dev_expand_button"
local DEBUG_FRAME_NAME = "fes_debug_frame"
local UTILIZATION_UPDATE_INTERVAL_TICKS = 60
local GROWTH_RATE_SIZE_DIVISOR = 12

local COUNTED_CATEGORY_ORDER = {
  "crafting",
  "lab",
  "rocket-silo",
  "beacon",
  "power"
}

local COUNTED_CATEGORY_LABELS = {
  crafting = "Crafting",
  lab = "Labs",
  ["rocket-silo"] = "Rocket silos",
  beacon = "Beacons",
  power = "Power"
}

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

local update_utilization_metrics
local refresh_all_debug_guis

local function get_ingress_item_name(resource)
  return "fes-" .. resource .. "-ingress"
end

local function get_ingress_entity_name(resource)
  return "fes-" .. resource .. "-ingress-anchor"
end

local function build_empty_category_breakdown()
  local categories = {}

  for _, key in ipairs(COUNTED_CATEGORY_ORDER) do
    categories[key] = {
      key = key,
      label = COUNTED_CATEGORY_LABELS[key],
      entity_count = 0,
      footprint_tiles = 0
    }
  end

  return categories
end

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

local function get_square_area(square_size)
  return square_size * square_size
end

local function get_next_expansion_tile_reward(square_size)
  local next_square_size = square_size + 2

  return get_square_area(next_square_size) - get_square_area(square_size)
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
        position = chosen_positions[index],
        item_name = get_ingress_item_name(definition.resource),
        entity_name = get_ingress_entity_name(definition.resource)
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

local function get_anchor_side_for_position(square_size, position)
  local bounds = get_anchor_bounds(square_size)
  local min_x = bounds.left_top.x
  local min_y = bounds.left_top.y
  local max_x = bounds.right_bottom.x - 1
  local max_y = bounds.right_bottom.y - 1

  if position.y == min_y and position.x > min_x and position.x < max_x then
    return "north"
  end

  if position.x == max_x and position.y > min_y and position.y < max_y then
    return "east"
  end

  if position.y == max_y and position.x > min_x and position.x < max_x then
    return "south"
  end

  if position.x == min_x and position.y > min_y and position.y < max_y then
    return "west"
  end

  return nil
end

local function is_anchor_ring_position(square_size, position)
  return get_anchor_side_for_position(square_size, position) ~= nil
end

local function get_managed_tile_name(square_size, surface_size, position)
  local square_bounds = get_square_bounds(square_size)

  if is_inside_bounds(square_bounds, position) then
    return FLOOR_TILE_NAME
  end

  local surface_bounds = get_square_bounds(surface_size)

  if is_inside_bounds(surface_bounds, position) then
    if is_anchor_ring_position(square_size, position) then
      return FLOOR_TILE_NAME
    end

    return VOID_TILE_NAME
  end

  return nil
end

local function build_anchor_ring_tiles(square_size, surface_size, anchors)
  local surface_bounds = get_square_bounds(surface_size)
  local tiles = {}

  for y = surface_bounds.left_top.y, surface_bounds.right_bottom.y - 1 do
    for x = surface_bounds.left_top.x, surface_bounds.right_bottom.x - 1 do
      local position = {x = x, y = y}

      if not is_inside_bounds(get_square_bounds(square_size), position) then
        tiles[#tiles + 1] = {
          name = get_managed_tile_name(square_size, surface_size, position),
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

local function get_entity_footprint_tiles(entity)
  return entity.tile_width * entity.tile_height
end

local function is_active_crafting_machine(entity)
  return entity.status == defines.entity_status.working and entity.is_crafting()
end

local function is_active_lab(entity)
  return entity.status == defines.entity_status.working
end

local function is_active_rocket_silo(entity)
  return entity.status == defines.entity_status.working
    or entity.status == defines.entity_status.preparing_rocket_for_launch
    or entity.status == defines.entity_status.launching_rocket
end

local function is_active_power_entity(entity)
  return entity.status == defines.entity_status.working
end

local function evaluate_counted_entity_category(entity)
  if entity.type == "assembling-machine" or entity.type == "furnace" then
    if is_active_crafting_machine(entity) then
      return "crafting"
    end

    return nil
  end

  if entity.type == "lab" then
    if is_active_lab(entity) then
      return "lab"
    end

    return nil
  end

  if entity.type == "rocket-silo" then
    if is_active_rocket_silo(entity) then
      return "rocket-silo"
    end

    return nil
  end

  if entity.type == "generator"
    or entity.type == "boiler"
    or entity.type == "reactor"
    or entity.type == "solar-panel"
    or entity.type == "burner-generator"
    or entity.type == "fusion-generator"
  then
    if is_active_power_entity(entity) then
      return "power"
    end

    return nil
  end

  return nil
end

local function record_breakdown_entry(storage_table, key, label, footprint_tiles)
  local entry = storage_table[key]

  if not entry then
    entry = {
      key = key,
      label = label,
      entity_count = 0,
      footprint_tiles = 0
    }
    storage_table[key] = entry
  end

  entry.entity_count = entry.entity_count + 1
  entry.footprint_tiles = entry.footprint_tiles + footprint_tiles
end

local function add_entity_to_breakdown(metrics, category_key, entity)
  local footprint_tiles = get_entity_footprint_tiles(entity)

  metrics.active_footprint_tiles = metrics.active_footprint_tiles + footprint_tiles
  metrics.active_entity_count = metrics.active_entity_count + 1
  metrics.categories[category_key].entity_count = metrics.categories[category_key].entity_count + 1
  metrics.categories[category_key].footprint_tiles = metrics.categories[category_key].footprint_tiles + footprint_tiles

  record_breakdown_entry(metrics.entity_types, entity.name, entity.name, footprint_tiles)
end

local function collect_active_beacons_from_machine(entity, active_beacons)
  local success, beacons = pcall(entity.get_beacons, entity)

  if not success or not beacons then
    return
  end

  for _, beacon in ipairs(beacons) do
    if beacon.valid and beacon.unit_number then
      active_beacons[beacon.unit_number] = beacon
    end
  end
end

local function compute_growth_rate_per_second(square_size, utilization_ratio)
  return utilization_ratio * (square_size / GROWTH_RATE_SIZE_DIVISOR)
end

local function sort_breakdown_entries(entries_by_key)
  local entries = {}

  for _, entry in pairs(entries_by_key) do
    entries[#entries + 1] = entry
  end

  table.sort(entries, function(left, right)
    if left.footprint_tiles == right.footprint_tiles then
      if left.entity_count == right.entity_count then
        return left.key < right.key
      end

      return left.entity_count > right.entity_count
    end

    return left.footprint_tiles > right.footprint_tiles
  end)

  return entries
end

local function evaluate_utilization(surface, square_size)
  local square_bounds = get_square_bounds(square_size)
  local total_tiles = get_square_area(square_size)
  local metrics = {
    tick = game.tick,
    square_size = square_size,
    total_tiles = total_tiles,
    active_footprint_tiles = 0,
    active_entity_count = 0,
    utilization_ratio = 0,
    growth_rate_per_second = 0,
    growth_rate_per_minute = 0,
    categories = build_empty_category_breakdown(),
    entity_types = {}
  }
  local active_beacons = {}

  for _, entity in ipairs(surface.find_entities_filtered({area = square_bounds})) do
    if entity.valid then
      local category_key = evaluate_counted_entity_category(entity)

      if category_key then
        add_entity_to_breakdown(metrics, category_key, entity)

        if category_key ~= "power" then
          collect_active_beacons_from_machine(entity, active_beacons)
        end
      end
    end
  end

  for _, beacon in pairs(active_beacons) do
    add_entity_to_breakdown(metrics, "beacon", beacon)
  end

  if total_tiles > 0 then
    metrics.utilization_ratio = metrics.active_footprint_tiles / total_tiles
  end

  metrics.growth_rate_per_second = compute_growth_rate_per_second(square_size, metrics.utilization_ratio)
  metrics.growth_rate_per_minute = metrics.growth_rate_per_second * 60
  metrics.sorted_entity_types = sort_breakdown_entries(metrics.entity_types)

  return metrics
end

local function format_ratio_percent(ratio)
  return string.format("%.1f%%", ratio * 100)
end

local function format_decimal(value)
  return string.format("%.2f", value)
end

local function build_resize_tile_updates(old_square_size, old_surface_size, new_square_size, new_surface_size, anchors)
  local tiles = {}
  local old_bounds = get_square_bounds(old_surface_size)
  local new_bounds = get_square_bounds(new_surface_size)
  local min_x = math.min(old_bounds.left_top.x, new_bounds.left_top.x)
  local min_y = math.min(old_bounds.left_top.y, new_bounds.left_top.y)
  local max_x = math.max(old_bounds.right_bottom.x - 1, new_bounds.right_bottom.x - 1)
  local max_y = math.max(old_bounds.right_bottom.y - 1, new_bounds.right_bottom.y - 1)

  for y = min_y, max_y do
    for x = min_x, max_x do
      local position = {x = x, y = y}
      local previous_tile_name = get_managed_tile_name(old_square_size, old_surface_size, position)
      local next_tile_name = get_managed_tile_name(new_square_size, new_surface_size, position)

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
  storage.bootstrap.growth_progress = storage.bootstrap.growth_progress or 0
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

local function configure_source_anchor_entity(entity, direction)
  if not (entity and entity.valid) then
    return
  end

  if direction and entity.direction ~= direction then
    entity.direction = direction
  end

  entity.destructible = false
  entity.operable = false
end

local function is_ingress_entity_name(entity_name)
  for _, definition in ipairs(STARTER_INPUT_DEFINITIONS) do
    if entity_name == get_ingress_entity_name(definition.resource) then
      return true
    end
  end

  return false
end

local function find_matching_stashed_anchor(item_or_entity_name)
  local starter_anchors = storage.starter_anchors

  if not starter_anchors then
    return nil
  end

  for _, anchor in ipairs(starter_anchors.anchors) do
    if not anchor.position and (anchor.item_name == item_or_entity_name or anchor.entity_name == item_or_entity_name) then
      return anchor
    end
  end

  return nil
end

local function find_anchor_by_entity(entity)
  local starter_anchors = storage.starter_anchors

  if not starter_anchors or not (entity and entity.valid) then
    return nil
  end

  for _, anchor in ipairs(starter_anchors.anchors) do
    if anchor.entity == entity then
      return anchor
    end
  end

  return nil
end

local function find_anchor_by_entity_name_and_position(entity_name, position)
  local starter_anchors = storage.starter_anchors

  if not starter_anchors or not position then
    return nil
  end

  local position_key = get_position_key(position)

  for _, anchor in ipairs(starter_anchors.anchors) do
    if anchor.entity_name == entity_name and anchor.position and get_position_key(anchor.position) == position_key then
      return anchor
    end
  end

  return nil
end

local function clear_anchor_entity(anchor)
  if anchor then
    anchor.entity = nil
  end
end

local function stash_anchor(anchor)
  if not anchor then
    return
  end

  anchor.position = nil
  anchor.side = nil
  clear_anchor_entity(anchor)
end

local function place_anchor(anchor, entity, square_size)
  if not (anchor and entity and entity.valid) then
    return false
  end

  local side = get_anchor_side_for_position(square_size, entity.position)

  if not side then
    return false
  end

  anchor.position = {x = entity.position.x, y = entity.position.y}
  anchor.side = side
  anchor.direction = DIRECTION_BY_SIDE[side]
  anchor.entity = entity
  configure_source_anchor_entity(entity, anchor.direction)

  return true
end

local function destroy_entities_at_anchor_position(surface, anchor)
  if not (surface and anchor and anchor.position) then
    return
  end

  for _, entity in ipairs(surface.find_entities_filtered({position = anchor.position})) do
    if entity.valid and entity.name ~= anchor.entity_name and entity.force == game.forces.player then
      entity.destroy({raise_destroy = false})
    end
  end
end

local function ensure_anchor_entity(surface, anchor)
  if not (surface and anchor and anchor.position) then
    return nil
  end

  local entity = anchor.entity

  if entity and entity.valid then
    configure_source_anchor_entity(entity, anchor.direction)
    return entity
  end

  destroy_entities_at_anchor_position(surface, anchor)

  entity = find_entity_at_position(surface, anchor.entity_name, anchor.position)

  if entity and entity.valid then
    anchor.entity = entity
    configure_source_anchor_entity(entity, anchor.direction)
    return entity
  end

  entity = surface.create_entity({
    name = anchor.entity_name,
    position = anchor.position,
    direction = anchor.direction,
    force = game.forces.player
  })

  if entity then
    anchor.entity = entity
    configure_source_anchor_entity(entity, anchor.direction)
  end

  return entity
end

local function migrate_anchor_to_anchor_ring(square_size, anchor)
  if not (anchor and anchor.position and anchor.side) then
    return
  end

  if get_anchor_side_for_position(square_size, anchor.position) then
    return
  end

  anchor.position = move_position(anchor.position, anchor.side, 1)
  anchor.direction = DIRECTION_BY_SIDE[anchor.side]
  anchor.entity = nil
end

local function ensure_starter_anchor_state()
  local bootstrap = storage.bootstrap

  if not bootstrap then
    return nil
  end

  if storage.starter_anchors and storage.starter_anchors.layout_version ~= STARTER_ANCHOR_LAYOUT_VERSION then
    local migrated_anchors = storage.starter_anchors.anchors or {}

    for _, anchor in ipairs(migrated_anchors) do
      anchor.item_name = anchor.item_name or get_ingress_item_name(anchor.resource)
      anchor.entity_name = anchor.entity_name or get_ingress_entity_name(anchor.resource)
      anchor.entity = nil
      migrate_anchor_to_anchor_ring(bootstrap.square_size, anchor)
    end

    storage.starter_anchors = {
      layout_version = STARTER_ANCHOR_LAYOUT_VERSION,
      anchors = migrated_anchors
    }
  end

  storage.starter_anchors = storage.starter_anchors or create_starter_anchor_state(bootstrap.square_size)

  for _, anchor in ipairs(storage.starter_anchors.anchors) do
    migrate_anchor_to_anchor_ring(bootstrap.square_size, anchor)
  end

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
    if anchor.position then
      ensure_anchor_entity(surface, anchor)
    end
  end
end

local function pump_starter_anchors()
  local starter_anchors = storage.starter_anchors

  if not starter_anchors then
    return
  end

  for _, anchor in ipairs(starter_anchors.anchors) do
    local entity = anchor.position and anchor.entity or nil

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
  local anchor = find_anchor_by_entity(entity)

  if not anchor or not (entity and entity.valid) then
    return
  end

  if entity.direction ~= anchor.direction then
    entity.direction = anchor.direction
  end
end

local function refund_entity_to_player(player, entity_name)
  if not (player and player.valid and entity_name) then
    return
  end

  player.insert({name = entity_name, count = 1})
end

local function refund_entity_to_robot(robot, entity_name)
  if not (robot and robot.valid and entity_name) then
    return
  end

  if robot.get_inventory(defines.inventory.robot_cargo) then
    robot.get_inventory(defines.inventory.robot_cargo).insert({name = entity_name, count = 1})
  end
end

local function reject_anchor_placement(entity, actor, message_key)
  if not (entity and entity.valid) then
    return
  end

  local item_name = string.gsub(entity.name, "-anchor$", "")

  if actor and actor.valid then
    if actor.object_name == "LuaPlayer" then
      refund_entity_to_player(actor, item_name)
      actor.print({message_key})
    elseif actor.object_name == "LuaEntity" and actor.type == "construction-robot" then
      refund_entity_to_robot(actor, item_name)
    end
  end

  entity.destroy({raise_destroy = false})
end

local function handle_ingress_built(entity, actor)
  if not (entity and entity.valid) then
    return
  end

  local bootstrap = storage.bootstrap

  if not bootstrap then
    return
  end

  if entity.surface.name ~= bootstrap.surface_name then
    reject_anchor_placement(entity, actor, "message.fes-ingress-invalid-surface")
    return
  end

  local side = get_anchor_side_for_position(bootstrap.square_size, entity.position)

  if not side then
    reject_anchor_placement(entity, actor, "message.fes-ingress-invalid-edge")
    return
  end

  local anchor = find_matching_stashed_anchor(entity.name)

  if not anchor then
    reject_anchor_placement(entity, actor, "message.fes-ingress-unowned")
    return
  end

  place_anchor(anchor, entity, bootstrap.square_size)
end

local function handle_anchor_mined(entity)
  if not (entity and entity.valid) then
    return
  end

  local anchor = find_anchor_by_entity(entity) or find_anchor_by_entity_name_and_position(entity.name, entity.position)

  if anchor then
    stash_anchor(anchor)
  end
end

local function handle_entity_built(event)
  local entity = event.entity or event.created_entity

  if not (entity and entity.valid) then
    return
  end

  local player = event.player_index and game.get_player(event.player_index) or nil
  local robot = event.robot

  if is_ingress_entity_name(entity.name) then
    handle_ingress_built(entity, player or robot)
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

local function add_growth_progress(amount)
  storage.bootstrap.growth_progress = (storage.bootstrap.growth_progress or 0) + amount
end

local function move_starter_anchors_outward()
  local starter_anchors = storage.starter_anchors

  if not starter_anchors then
    return
  end

  for _, anchor in ipairs(starter_anchors.anchors) do
    if anchor.position and anchor.side then
      anchor.position = move_position(anchor.position, anchor.side, 1)
      anchor.direction = DIRECTION_BY_SIDE[anchor.side]
      anchor.entity = nil
    end
  end
end

local function get_trailing_entity_name(anchor)
  if not anchor then
    return nil
  end

  if anchor.kind == "fluid" then
    return "pipe"
  end

  return "transport-belt"
end

local function leave_trailing_ingress_stub(surface, anchor)
  if not (surface and anchor and anchor.position) then
    return
  end

  local trailing_entity_name = get_trailing_entity_name(anchor)
  local existing_anchor = anchor.entity

  if existing_anchor and existing_anchor.valid then
    existing_anchor.destroy({raise_destroy = false})
  else
    existing_anchor = find_entity_at_position(surface, anchor.entity_name, anchor.position)

    if existing_anchor and existing_anchor.valid then
      existing_anchor.destroy({raise_destroy = false})
    end
  end

  if find_entity_at_position(surface, trailing_entity_name, anchor.position) then
    return
  end

  surface.create_entity({
    name = trailing_entity_name,
    position = anchor.position,
    direction = anchor.direction,
    force = game.forces.player
  })
end

local function leave_trailing_stubs_for_expansion(surface)
  local starter_anchors = storage.starter_anchors

  if not starter_anchors then
    return
  end

  for _, anchor in ipairs(starter_anchors.anchors) do
    if anchor.position then
      leave_trailing_ingress_stub(surface, anchor)
    end
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
  local newly_unlocked_tiles = get_next_expansion_tile_reward(previous_square_size)

  leave_trailing_stubs_for_expansion(surface)
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

  update_utilization_metrics()
  refresh_all_debug_guis()
end

local function is_dev_mode_enabled(player)
  return settings.get_player_settings(player)[SETTING_DEV_MODE].value
end

local function ensure_debug_frame(player)
  local frame = player.gui.left[DEBUG_FRAME_NAME]

  if frame then
    return frame
  end

  return player.gui.left.add({
    type = "frame",
    name = DEBUG_FRAME_NAME,
    direction = "vertical",
    caption = {"gui.fes-debug-title"}
  })
end

local function build_debug_lines()
  local bootstrap = storage.bootstrap
  local metrics = storage.utilization_metrics
  local lines = {}

  if not bootstrap or not metrics then
    lines[#lines + 1] = "No utilization data yet."
    return lines
  end

  local next_reward = get_next_expansion_tile_reward(bootstrap.square_size)

  lines[#lines + 1] = "Square: " .. bootstrap.square_size .. "x" .. bootstrap.square_size
  lines[#lines + 1] = "Utilization: " .. format_ratio_percent(metrics.utilization_ratio)
    .. " (" .. metrics.active_footprint_tiles .. " / " .. metrics.total_tiles .. " tiles)"
  lines[#lines + 1] = "Active entities: " .. metrics.active_entity_count
  lines[#lines + 1] = "Growth rate: " .. format_decimal(metrics.growth_rate_per_second) .. " tiles/s"
    .. " (" .. format_decimal(metrics.growth_rate_per_minute) .. " tiles/min)"
  lines[#lines + 1] = "Formula: growth/s = utilization x (square size / " .. GROWTH_RATE_SIZE_DIVISOR .. ")"
  lines[#lines + 1] = "Current: " .. format_decimal(metrics.growth_rate_per_second)
    .. " = " .. format_decimal(metrics.utilization_ratio)
    .. " x (" .. bootstrap.square_size .. " / " .. GROWTH_RATE_SIZE_DIVISOR .. ")"
  lines[#lines + 1] = "Progress: " .. format_decimal(bootstrap.growth_progress or 0)
    .. " / " .. next_reward
  lines[#lines + 1] = "Next reward: " .. next_reward .. " expansion points"
  lines[#lines + 1] = "Breakdown:"

  for _, key in ipairs(COUNTED_CATEGORY_ORDER) do
    local category = metrics.categories[key]

    if category.entity_count > 0 then
      lines[#lines + 1] = "  " .. category.label .. ": "
        .. category.footprint_tiles .. " tiles across " .. category.entity_count .. " entities"
    end
  end

  if #metrics.sorted_entity_types > 0 then
    lines[#lines + 1] = "Top entity types:"

    local max_rows = math.min(8, #metrics.sorted_entity_types)

    for index = 1, max_rows do
      local entry = metrics.sorted_entity_types[index]
      lines[#lines + 1] = "  " .. entry.label .. ": "
        .. entry.footprint_tiles .. " tiles across " .. entry.entity_count
    end
  end

  return lines
end

local function refresh_debug_gui(player)
  if not (player and player.valid) then
    return
  end

  local frame = player.gui.left[DEBUG_FRAME_NAME]

  if not frame then
    return
  end

  frame.clear()

  for _, line in ipairs(build_debug_lines()) do
    frame.add({
      type = "label",
      caption = line
    })
  end
end

refresh_all_debug_guis = function()
  for _, player in pairs(game.players) do
    refresh_debug_gui(player)
  end
end

local function sync_dev_gui(player)
  if not (player and player.valid) then
    return
  end

  local button = player.gui.top[DEV_EXPAND_BUTTON_NAME]
  local frame = player.gui.left[DEBUG_FRAME_NAME]

  if is_dev_mode_enabled(player) then
    if not button then
      player.gui.top.add({
        type = "button",
        name = DEV_EXPAND_BUTTON_NAME,
        caption = {"gui.fes-dev-expand-button"}
      })
    end

    if not frame then
      ensure_debug_frame(player)
    end

    refresh_debug_gui(player)
  elseif button then
    button.destroy()
  end

  if not is_dev_mode_enabled(player) and frame then
    frame.destroy()
  end
end

local function sync_all_dev_guis()
  for _, player in pairs(game.players) do
    sync_dev_gui(player)
  end
end

update_utilization_metrics = function()
  local bootstrap = storage.bootstrap

  if not bootstrap then
    return nil
  end

  local surface = game.surfaces[bootstrap.surface_name]

  if not surface then
    return nil
  end

  local metrics = evaluate_utilization(surface, bootstrap.square_size)

  storage.utilization_metrics = metrics

  return metrics
end

local function advance_growth_from_utilization()
  local bootstrap = storage.bootstrap

  if not bootstrap then
    return
  end

  ensure_bootstrap_state_defaults()

  local metrics = update_utilization_metrics()

  if not metrics then
    return
  end

  local interval_seconds = UTILIZATION_UPDATE_INTERVAL_TICKS / 60
  local progress_gain = metrics.growth_rate_per_second * interval_seconds

  if progress_gain > 0 then
    add_growth_progress(progress_gain)
  end

  local player = game.players[1]

  while (bootstrap.growth_progress or 0) >= get_next_expansion_tile_reward(bootstrap.square_size) do
    bootstrap.growth_progress = bootstrap.growth_progress - get_next_expansion_tile_reward(bootstrap.square_size)
    expand_square(player)
    metrics = update_utilization_metrics() or metrics
  end

  refresh_all_debug_guis()
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

  update_utilization_metrics()
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

  update_utilization_metrics()
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

script.on_event(defines.events.on_built_entity, function(event)
  handle_entity_built(event)
end)

script.on_event(defines.events.on_robot_built_entity, function(event)
  handle_entity_built(event)
end)

script.on_event(defines.events.script_raised_built, function(event)
  handle_entity_built(event)
end)

script.on_event(defines.events.script_raised_revive, function(event)
  handle_entity_built(event)
end)

script.on_event(defines.events.on_player_mined_entity, function(event)
  handle_anchor_mined(event.entity)
end)

script.on_event(defines.events.on_robot_mined_entity, function(event)
  handle_anchor_mined(event.entity)
end)

script.on_event(defines.events.on_entity_died, function(event)
  handle_anchor_mined(event.entity)
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

script.on_nth_tick(UTILIZATION_UPDATE_INTERVAL_TICKS, function()
  advance_growth_from_utilization()
end)
