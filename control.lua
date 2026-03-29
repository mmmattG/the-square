local SURFACE_NAME = "fes-bootstrap"
local bootstrap_layout = require("lib.bootstrap_layout")
local resource_balance = require("lib.resource_balance")
local SETTING_STARTING_SQUARE_SIZE = "fes-starting-square-size"
local SETTING_ENABLE_LOGISTIC_NETWORK_AUTOMATION = "fes-enable-logistic-network-automation"
local SETTING_DEV_MODE = "fes-dev-mode"
local SETTING_INGRESS_PLACEMENT_DEBUG = "fes-ingress-placement-debug"
local FLOOR_TILE_NAME = "grass-1"
local VOID_TILE_NAME = "out-of-map"
local CHART_MARGIN = 1
local ITEM_ANCHOR_INTERVAL_TICKS = 8
local STARTER_ANCHOR_OUTER_RING_WIDTH = 2
local STARTER_ANCHOR_LAYOUT_VERSION = 8
local DEV_EXPAND_BUTTON_NAME = "fes_dev_expand_button"
local DEBUG_FRAME_NAME = "fes_debug_frame"
local STATUS_FRAME_NAME = "fes_status_frame"
local SHOP_BUTTON_NAME = "fes_shop_button"
local SHOP_FRAME_NAME = "fes_shop_frame"
local UTILIZATION_UPDATE_INTERVAL_TICKS = 60
local GROWTH_RATE_SIZE_DIVISOR = 12
local LINE_PURCHASE_COST = 12
local MAX_INGRESS_TIER = 4
local EXPANSION_SPEED_RESEARCH_PER_LEVEL_MULTIPLIER = 0.05
local EXPANSION_SPEED_RESEARCH_BANDS = {
  {name = "fes-expansion-speed-automation", start_level = 1},
  {name = "fes-expansion-speed-logistic", start_level = 6},
  {name = "fes-expansion-speed-chemical", start_level = 11},
  {name = "fes-expansion-speed-production-utility", start_level = 16},
  {name = "fes-expansion-speed-space", start_level = 21}
}
local DIRECTION_BY_SIDE
local OFFSET_BY_SIDE
local INGRESS_TIER_DEFINITIONS
local ITEM_INGRESS_BELT_TIER_BY_INGRESS_TIER
local FORBIDDEN_LOGISTIC_CONTAINER_NAMES = {
  ["active-provider-chest"] = true,
  ["buffer-chest"] = true,
  ["requester-chest"] = true,
  ["storage-chest"] = true
}

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

local INPUT_DEFINITIONS = {
  {resource = "iron-ore", kind = "item", starter_side = "north", prerequisite_resource = nil},
  {resource = "copper-ore", kind = "item", starter_side = "north", prerequisite_resource = nil},
  {resource = "coal", kind = "item", starter_side = "south", prerequisite_resource = nil},
  {resource = "stone", kind = "item", starter_side = "south", prerequisite_resource = nil},
  {resource = "water", kind = "fluid", starter_side = "west", prerequisite_resource = nil},
  {resource = "wood", kind = "item", starter_side = "east", prerequisite_resource = nil},
  {resource = "crude-oil", kind = "fluid", starter_side = nil, prerequisite_resource = nil},
  {resource = "uranium-ore", kind = "item", starter_side = nil, prerequisite_resource = "crude-oil"}
}

local OUTPUT_DEFINITIONS = {
  {resource = "sulfuric-acid", kind = "fluid", starter_side = nil, prerequisite_resource = "uranium-ore"}
}

DIRECTION_BY_SIDE = {
  north = defines.direction.south,
  east = defines.direction.west,
  south = defines.direction.north,
  west = defines.direction.east
}

OFFSET_BY_SIDE = {
  north = {x = 0, y = -1},
  east = {x = 1, y = 0},
  south = {x = 0, y = 1},
  west = {x = -1, y = 0}
}

ITEM_INGRESS_BELT_TIER_BY_INGRESS_TIER = {
  [1] = "yellow",
  [2] = "yellow",
  [3] = "red",
  [4] = "blue"
}

INGRESS_TIER_DEFINITIONS = {
  [1] = {
    key = "yellow-single",
    label = "Yellow single lane",
    item_lane_counts = {1, 0},
    fluid_amount_per_interval = 160
  },
  [2] = {
    key = "yellow-double",
    label = "Yellow double lane",
    item_lane_counts = {1, 1},
    fluid_amount_per_interval = 320
  },
  [3] = {
    key = "red-double",
    label = "Red double lane",
    item_lane_counts = {2, 2},
    fluid_amount_per_interval = 640
  },
  [4] = {
    key = "blue-double",
    label = "Blue double lane",
    item_lane_counts = {3, 3},
    fluid_amount_per_interval = 960
  }
}

local update_utilization_metrics
local refresh_all_debug_guis
local refresh_all_status_guis
local print_ingress_placement_debug
local snap_entity_position_to_tile
local sync_all_shop_guis
local player_insert_or_spill
local get_anchor_entity_name_for_current_tier

local function get_ingress_item_name(resource)
  return "fes-" .. resource .. "-ingress"
end

local function get_ingress_entity_name(resource, ingress_tier_level)
  local definition = nil

  for _, input_definition in ipairs(INPUT_DEFINITIONS) do
    if input_definition.resource == resource then
      definition = input_definition
      break
    end
  end

  if not definition then
    return "fes-" .. resource .. "-ingress-anchor"
  end

  if definition.kind ~= "item" then
    return "fes-" .. resource .. "-ingress-anchor"
  end

  local belt_tier_key = ITEM_INGRESS_BELT_TIER_BY_INGRESS_TIER[ingress_tier_level or 1] or "yellow"

  if belt_tier_key == "yellow" then
    return "fes-" .. resource .. "-ingress-anchor"
  end

  return "fes-" .. resource .. "-ingress-anchor-" .. belt_tier_key
end

local function is_ingress_entity_name_for_resource(resource, entity_name)
  if entity_name == get_ingress_entity_name(resource, 1) then
    return true
  end

  for tier_level = 2, MAX_INGRESS_TIER do
    if entity_name == get_ingress_entity_name(resource, tier_level) then
      return true
    end
  end

  return false
end

local function get_input_definition(resource)
  for _, definition in ipairs(INPUT_DEFINITIONS) do
    if definition.resource == resource then
      return definition
    end
  end

  return nil
end

local function get_output_definition(resource)
  for _, definition in ipairs(OUTPUT_DEFINITIONS) do
    if definition.resource == resource then
      return definition
    end
  end

  return nil
end

local function get_line_definition(resource)
  local input_definition = get_input_definition(resource)

  if input_definition then
    return input_definition, "ingress"
  end

  local output_definition = get_output_definition(resource)

  if output_definition then
    return output_definition, "egress"
  end

  return nil, nil
end

local function get_egress_item_name(resource)
  return "fes-" .. resource .. "-egress"
end

local function get_egress_entity_name(resource)
  return "fes-" .. resource .. "-egress-anchor"
end

local function is_egress_entity_name_for_resource(resource, entity_name)
  return entity_name == get_egress_entity_name(resource)
end

local function create_managed_anchor(definition, flow, side, position)
  return {
    resource = definition.resource,
    kind = definition.kind,
    flow = flow,
    side = side,
    direction = side and DIRECTION_BY_SIDE[side] or nil,
    position = position,
    item_name = flow == "egress"
      and get_egress_item_name(definition.resource)
      or get_ingress_item_name(definition.resource),
    entity_name = flow == "egress"
      and get_egress_entity_name(definition.resource)
      or get_ingress_entity_name(definition.resource)
  }
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

local function is_logistic_network_automation_enabled()
  return settings.global[SETTING_ENABLE_LOGISTIC_NETWORK_AUTOMATION].value
end

local function get_square_bounds(size)
  return bootstrap_layout.get_square_bounds(size)
end

local function get_surface_size(square_size)
  return bootstrap_layout.get_surface_size(square_size, STARTER_ANCHOR_OUTER_RING_WIDTH)
end

local function get_anchor_bounds(square_size)
  return bootstrap_layout.get_anchor_bounds(square_size)
end

local function get_square_area(square_size)
  return square_size * square_size
end

local function get_ingress_tier_definition(tier_level)
  return INGRESS_TIER_DEFINITIONS[tier_level] or INGRESS_TIER_DEFINITIONS[1]
end

local function get_current_ingress_tier_level()
  local bootstrap = storage.bootstrap

  if not bootstrap then
    return 1
  end

  local tier_level = bootstrap.ingress_tier or 1

  if tier_level < 1 then
    return 1
  end

  if tier_level > MAX_INGRESS_TIER then
    return MAX_INGRESS_TIER
  end

  return tier_level
end

local function get_current_ingress_tier()
  return get_ingress_tier_definition(get_current_ingress_tier_level())
end

local function get_next_ingress_tier_level()
  local next_level = get_current_ingress_tier_level() + 1

  if next_level > MAX_INGRESS_TIER then
    return nil
  end

  return next_level
end

local function get_ingress_tier_upgrade_cost(next_tier_level)
  if not next_tier_level then
    return nil
  end

  return LINE_PURCHASE_COST * next_tier_level
end

local function get_next_expansion_tile_reward(square_size)
  local next_square_size = square_size + 2

  return get_square_area(next_square_size) - get_square_area(square_size)
end

local function is_inside_bounds(bounds, position)
  return bootstrap_layout.is_inside_bounds(bounds, position)
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

  for _, definition in ipairs(INPUT_DEFINITIONS) do
    if definition.starter_side then
      resources_by_side[definition.starter_side] = resources_by_side[definition.starter_side] or {}
      resources_by_side[definition.starter_side][#resources_by_side[definition.starter_side] + 1] = definition
    end
  end

  for _, side in ipairs({"north", "east", "south", "west"}) do
    local side_resources = resources_by_side[side] or {}
    local side_positions = get_edge_positions(bounds, side)
    local chosen_positions = choose_spread_positions(side_positions, #side_resources, side)

    for index, definition in ipairs(side_resources) do
      anchors[#anchors + 1] = create_managed_anchor(definition, "ingress", side, chosen_positions[index])
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
  return bootstrap_layout.get_anchor_side_for_position(square_size, position)
end

local function is_anchor_ring_position(square_size, position)
  return bootstrap_layout.is_anchor_ring_position(square_size, position)
end

local function get_playable_edge_side_for_position(square_size, position)
  return bootstrap_layout.get_playable_edge_side_for_position(square_size, position)
end

local function get_managed_tile_name(square_size, surface_size, position)
  return bootstrap_layout.get_managed_tile_name(
    square_size,
    surface_size,
    FLOOR_TILE_NAME,
    VOID_TILE_NAME,
    position
  )
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

local function refresh_managed_surface_tiles(surface, square_size, surface_size)
  if not surface then
    return
  end

  local tile_updates = build_anchor_ring_tiles(square_size, surface_size, {})

  if #tile_updates > 0 then
    surface.set_tiles(tile_updates, false, true, true, false)
  end
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

local function get_completed_expansion_speed_research_levels()
  if not storage.bootstrap then
    return 0
  end

  return storage.bootstrap.expansion_speed_research_levels or 0
end

local function get_expansion_speed_multiplier()
  local levels = get_completed_expansion_speed_research_levels()

  return math.pow(1 + EXPANSION_SPEED_RESEARCH_PER_LEVEL_MULTIPLIER, levels), levels
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
  local expansion_speed_multiplier, expansion_speed_research_levels = get_expansion_speed_multiplier()
  local metrics = {
    tick = game.tick,
    square_size = square_size,
    total_tiles = total_tiles,
    active_footprint_tiles = 0,
    active_entity_count = 0,
    utilization_ratio = 0,
    base_growth_rate_per_second = 0,
    growth_rate_per_second = 0,
    growth_rate_per_minute = 0,
    expansion_speed_multiplier = expansion_speed_multiplier,
    expansion_speed_research_levels = expansion_speed_research_levels,
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

  metrics.base_growth_rate_per_second = compute_growth_rate_per_second(square_size, metrics.utilization_ratio)
  metrics.growth_rate_per_second = metrics.base_growth_rate_per_second * expansion_speed_multiplier
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

local function format_resource_name(resource)
  return string.gsub(resource, "%-", " ")
end

local function build_ingress_tier_summary()
  local tier = get_current_ingress_tier()
  local item_lane_counts = tier.item_lane_counts or {0, 0}
  local total_item_count = (item_lane_counts[1] or 0) + (item_lane_counts[2] or 0)
  local item_rate_per_second = total_item_count * (60 / ITEM_ANCHOR_INTERVAL_TICKS)
  local fluid_rate_per_second = (tier.fluid_amount_per_interval or 0) * (60 / ITEM_ANCHOR_INTERVAL_TICKS)

  return tier.label
    .. " | item/s per anchor: "
    .. format_decimal(item_rate_per_second)
    .. " | fluid/s per anchor: "
    .. format_decimal(fluid_rate_per_second)
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
  storage.bootstrap.ingress_tier = storage.bootstrap.ingress_tier or 1
  storage.bootstrap.expansion_speed_research_levels = storage.bootstrap.expansion_speed_research_levels or 0
  storage.bootstrap.uranium_ore_progress_carry = storage.bootstrap.uranium_ore_progress_carry or 0
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
  for _, definition in ipairs(INPUT_DEFINITIONS) do
    if is_ingress_entity_name_for_resource(definition.resource, entity_name) then
      return true
    end
  end

  return false
end

local function is_egress_entity_name(entity_name)
  for _, definition in ipairs(OUTPUT_DEFINITIONS) do
    if is_egress_entity_name_for_resource(definition.resource, entity_name) then
      return true
    end
  end

  return false
end

local function is_managed_anchor_entity_name(entity_name)
  return is_ingress_entity_name(entity_name) or is_egress_entity_name(entity_name)
end

local function does_anchor_match_entity_name(anchor, entity_name)
  if not anchor then
    return false
  end

  if anchor.flow == "egress" then
    return is_egress_entity_name_for_resource(anchor.resource, entity_name)
  end

  return is_ingress_entity_name_for_resource(anchor.resource, entity_name)
end

local function find_matching_stashed_anchor(item_or_entity_name)
  local starter_anchors = storage.starter_anchors

  if not starter_anchors then
    return nil
  end

  for _, anchor in ipairs(starter_anchors.anchors) do
    if not anchor.position and (
      anchor.item_name == item_or_entity_name
      or does_anchor_match_entity_name(anchor, item_or_entity_name)
    ) then
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
    if anchor.position
      and get_position_key(anchor.position) == position_key
      and does_anchor_match_entity_name(anchor, entity_name)
    then
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

  local tile_position = snap_entity_position_to_tile(entity.position)
  local side = get_anchor_side_for_position(square_size, tile_position)

  if not side then
    return false
  end

  anchor.position = tile_position
  anchor.side = side
  anchor.direction = DIRECTION_BY_SIDE[side]
  anchor.entity_name = get_anchor_entity_name_for_current_tier(anchor)
  anchor.entity = entity
  configure_source_anchor_entity(entity, anchor.direction)

  return true
end

local function assign_anchor_position(anchor, side, position)
  if not (anchor and side and position) then
    return false
  end

  anchor.position = position
  anchor.side = side
  anchor.direction = DIRECTION_BY_SIDE[side]
  anchor.entity_name = get_anchor_entity_name_for_current_tier(anchor)
  anchor.entity = nil

  return true
end

local function is_fluid_anchor_too_close(anchor, position, side)
  local starter_anchors = storage.starter_anchors

  if not starter_anchors or not anchor or anchor.kind ~= "fluid" then
    return false
  end

  for _, other_anchor in ipairs(starter_anchors.anchors) do
    if other_anchor ~= anchor
      and other_anchor.kind == "fluid"
      and other_anchor.side == side
      and other_anchor.position
    then
      local delta

      if side == "north" or side == "south" then
        delta = math.abs(other_anchor.position.x - position.x)
      else
        delta = math.abs(other_anchor.position.y - position.y)
      end

      if delta <= 1 then
        return true
      end
    end
  end

  return false
end

local function entity_overlaps_anchor_ring(square_size, entity)
  if not (entity and entity.valid and entity.bounding_box) then
    return false
  end

  local bounding_box = entity.bounding_box
  local min_x = math.floor(bounding_box.left_top.x + 0.001)
  local min_y = math.floor(bounding_box.left_top.y + 0.001)
  local max_x = math.ceil(bounding_box.right_bottom.x - 0.001) - 1
  local max_y = math.ceil(bounding_box.right_bottom.y - 0.001) - 1

  for y = min_y, max_y do
    for x = min_x, max_x do
      if is_anchor_ring_position(square_size, {x = x, y = y}) then
        return true
      end
    end
  end

  return false
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

get_anchor_entity_name_for_current_tier = function(anchor)
  if not anchor then
    return nil
  end

  if anchor.flow == "egress" then
    return get_egress_entity_name(anchor.resource)
  end

  if anchor.kind == "item" then
    return get_ingress_entity_name(anchor.resource, get_current_ingress_tier_level())
  end

  return get_ingress_entity_name(anchor.resource, 1)
end

local function ensure_anchor_entity(surface, anchor)
  if not (surface and anchor and anchor.position) then
    return nil
  end

  anchor.entity_name = get_anchor_entity_name_for_current_tier(anchor)

  local entity = anchor.entity

  if entity and entity.valid and entity.name == anchor.entity_name then
    configure_source_anchor_entity(entity, anchor.direction)
    return entity
  end

  if entity and entity.valid then
    entity.destroy({raise_destroy = false})
    anchor.entity = nil
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
      anchor.flow = anchor.flow or "ingress"
      anchor.item_name = anchor.item_name or (
        anchor.flow == "egress"
          and get_egress_item_name(anchor.resource)
          or get_ingress_item_name(anchor.resource)
      )
      anchor.entity_name = anchor.entity_name or (
        anchor.flow == "egress"
          and get_egress_entity_name(anchor.resource)
          or get_ingress_entity_name(anchor.resource, 1)
      )
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
    anchor.flow = anchor.flow or "ingress"
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

local function pump_item_anchor(entity, resource, lane_index, item_count)
  if item_count <= 0 then
    return 0
  end

  local line = entity.get_transport_line(lane_index)

  if not line then
    return 0
  end

  local inserted = 0

  for _ = 1, item_count do
    if not line.can_insert_at_back() then
      return inserted
    end

    line.insert_at_back({name = resource, count = 1})
    inserted = inserted + 1
  end

  return inserted
end

local function drain_fluid_anchor(entity, resource, amount)
  if not (entity and entity.valid) or amount <= 0 then
    return 0
  end

  local removed = entity.remove_fluid({
    name = resource,
    amount = amount
  })

  return removed or 0
end

local function get_player_force()
  return game and game.forces and game.forces.player or nil
end

local function get_mining_productivity_bonus()
  local player_force = get_player_force()

  if not (player_force and player_force.valid) then
    return 0
  end

  return player_force.mining_drill_productivity_bonus or 0
end

local function get_active_uranium_anchors(ingress_tier)
  local anchors = {}

  for _, anchor in ipairs(storage.starter_anchors.anchors) do
    local entity = anchor.position and anchor.entity or nil

    if anchor.flow == "ingress"
      and anchor.resource == "uranium-ore"
      and entity
      and entity.valid
    then
      anchors[#anchors + 1] = {
        anchor = anchor,
        entity = entity,
        capacity = (ingress_tier.item_lane_counts[1] or 0) + (ingress_tier.item_lane_counts[2] or 0)
      }
    end
  end

  return anchors
end

local function get_active_uranium_budget_per_interval(uranium_anchors)
  local bootstrap = storage.bootstrap

  if not bootstrap or #uranium_anchors == 0 then
    return 0
  end

  local ingress_tier = get_current_ingress_tier()
  local mining_productivity_bonus = get_mining_productivity_bonus()
  local total_capacity = 0

  for _, uranium_anchor in ipairs(uranium_anchors) do
    total_capacity = total_capacity + uranium_anchor.capacity
  end

  if total_capacity <= 0 then
    return 0
  end

  local sulfuric_acid_needed = total_capacity / (
    resource_balance.URANIUM_ORE_PER_SULFURIC_ACID * (1 + mining_productivity_bonus)
  )
  local sulfuric_acid_egressed = 0

  for _, anchor in ipairs(storage.starter_anchors.anchors) do
    local entity = anchor.position and anchor.entity or nil

    if anchor.flow == "egress"
      and anchor.resource == "sulfuric-acid"
      and entity
      and entity.valid
    then
      local remaining_needed = sulfuric_acid_needed - sulfuric_acid_egressed

      if remaining_needed <= 0 then
        break
      end

      sulfuric_acid_egressed = sulfuric_acid_egressed + drain_fluid_anchor(
        entity,
        anchor.resource,
        math.min(ingress_tier.fluid_amount_per_interval, remaining_needed)
      )
    end
  end

  local budget = resource_balance.compute_uranium_budget(
    sulfuric_acid_egressed,
    mining_productivity_bonus,
    bootstrap.uranium_ore_progress_carry or 0
  )

  bootstrap.uranium_ore_progress_carry = budget.remaining_ore_progress
  return budget.ore_budget
end

local function pump_uranium_ingress_anchor(entity, ingress_tier, shared_budget)
  if shared_budget <= 0 then
    return 0
  end

  local lane_one_target = math.min(shared_budget, ingress_tier.item_lane_counts[1] or 0)
  local inserted = pump_item_anchor(entity, "uranium-ore", 1, lane_one_target)
  local remaining_budget = shared_budget - inserted
  local lane_two_target = math.min(remaining_budget, ingress_tier.item_lane_counts[2] or 0)

  inserted = inserted + pump_item_anchor(entity, "uranium-ore", 2, lane_two_target)
  return inserted
end

local function pump_starter_anchors()
  local starter_anchors = storage.starter_anchors

  if not starter_anchors then
    return
  end

  local ingress_tier = get_current_ingress_tier()
  local uranium_anchors = get_active_uranium_anchors(ingress_tier)
  local uranium_budget = get_active_uranium_budget_per_interval(uranium_anchors)
  local uranium_capacities = {}

  for index, uranium_anchor in ipairs(uranium_anchors) do
    uranium_capacities[index] = uranium_anchor.capacity
  end

  local uranium_allocations = resource_balance.allocate_shared_budget(uranium_budget, uranium_capacities).allocations
  local uranium_anchor_index = 1

  for _, anchor in ipairs(starter_anchors.anchors) do
    local entity = anchor.position and anchor.entity or nil

    if entity and entity.valid and anchor.flow == "ingress" then
      if anchor.kind == "item" then
        if anchor.resource == "uranium-ore" then
          local allocated_budget = uranium_allocations[uranium_anchor_index] or 0
          pump_uranium_ingress_anchor(entity, ingress_tier, allocated_budget)
          uranium_anchor_index = uranium_anchor_index + 1
        else
          pump_item_anchor(entity, anchor.resource, 1, ingress_tier.item_lane_counts[1] or 0)
          pump_item_anchor(entity, anchor.resource, 2, ingress_tier.item_lane_counts[2] or 0)
        end
      else
        entity.insert_fluid({
          name = anchor.resource,
          amount = ingress_tier.fluid_amount_per_interval
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

local function get_entity_refund_item_name(entity)
  if not (entity and entity.valid and entity.prototype and entity.prototype.items_to_place_this) then
    return nil
  end

  local items_to_place = entity.prototype.items_to_place_this

  if #items_to_place == 0 or not items_to_place[1] then
    return nil
  end

  return items_to_place[1].name
end

local function is_forbidden_logistic_container(entity)
  return entity
    and entity.valid
    and entity.type == "logistic-container"
    and FORBIDDEN_LOGISTIC_CONTAINER_NAMES[entity.name] == true
end

local function apply_logistic_network_setting_to_force(force)
  if not (force and force.valid) then
    return
  end

  if is_logistic_network_automation_enabled() then
    force.reset_technology_effects()
    return
  end

  for recipe_name in pairs(FORBIDDEN_LOGISTIC_CONTAINER_NAMES) do
    local recipe = force.recipes[recipe_name]

    if recipe then
      recipe.enabled = false
    end
  end
end

local function apply_logistic_network_setting_to_all_forces()
  for _, force in pairs(game.forces) do
    apply_logistic_network_setting_to_force(force)
  end
end

local function reject_anchor_placement(entity, actor, message)
  if not (entity and entity.valid) then
    return
  end

  local item_name = get_entity_refund_item_name(entity)

  if actor and actor.valid then
    if actor.object_name == "LuaPlayer" then
      if item_name then
        refund_entity_to_player(actor, item_name)
      end

      if message then
        actor.print(message)
      end
    elseif actor.object_name == "LuaEntity" and actor.type == "construction-robot" then
      if item_name then
        refund_entity_to_robot(actor, item_name)
      end
    end
  end

  entity.destroy({raise_destroy = false})
end

local function reject_reserved_ring_placement(entity, actor, message)
  if not (entity and entity.valid) then
    return
  end

  local item_name = get_entity_refund_item_name(entity)

  if actor and actor.valid then
    if actor.object_name == "LuaPlayer" then
      if item_name then
        player_insert_or_spill(actor, item_name)
      end

      if message then
        actor.print(message)
      end
    elseif actor.object_name == "LuaEntity" and actor.type == "construction-robot" and item_name then
      refund_entity_to_robot(actor, item_name)
    end
  end

  entity.destroy({raise_destroy = false})
end

player_insert_or_spill = function(player, item_name)
  if not (player and player.valid and item_name) then
    return false
  end

  local inserted = player.insert({name = item_name, count = 1})

  if inserted > 0 then
    return true
  end

  if player.surface then
    player.surface.spill_item_stack(player.position, {name = item_name, count = 1}, true, player.force, false)
    return true
  end

  return false
end

local function get_owned_line_counts(resource)
  local starter_anchors = storage.starter_anchors
  local counts = {
    owned = 0,
    placed = 0,
    stashed = 0
  }

  if not starter_anchors then
    return counts
  end

  for _, anchor in ipairs(starter_anchors.anchors) do
    if anchor.resource == resource then
      counts.owned = counts.owned + 1

      if anchor.position then
        counts.placed = counts.placed + 1
      else
        counts.stashed = counts.stashed + 1
      end
    end
  end

  return counts
end

local function is_resource_unlocked(resource)
  return get_owned_line_counts(resource).owned > 0
end

local function can_purchase_line(resource)
  local definition = get_input_definition(resource) or get_output_definition(resource)

  if not definition then
    return false, "message.fes-shop-resource-unknown", nil
  end

  if is_resource_unlocked(resource) or definition.starter_side then
    return true, nil, nil
  end

  if definition.prerequisite_resource and not is_resource_unlocked(definition.prerequisite_resource) then
    return false, "message.fes-shop-prerequisite", definition.prerequisite_resource
  end

  return true, nil, nil
end

local function spend_expansion_points(amount)
  local bootstrap = storage.bootstrap

  if not bootstrap or (bootstrap.expansion_points or 0) < amount then
    return false
  end

  bootstrap.expansion_points = bootstrap.expansion_points - amount
  return true
end

local function get_shop_item_name(resource)
  local input_definition = get_input_definition(resource)

  if input_definition then
    return get_ingress_item_name(resource)
  end

  local output_definition = get_output_definition(resource)

  if output_definition then
    return get_egress_item_name(resource)
  end

  return nil
end

local function purchase_managed_line(player, resource)
  local bootstrap = storage.bootstrap
  local definition, flow = get_line_definition(resource)
  local item_name = get_shop_item_name(resource)

  if not bootstrap or not definition or not item_name then
    return
  end

  local can_purchase, message_key, message_resource = can_purchase_line(resource)

  if not can_purchase then
    if player and player.valid then
      if message_resource then
        player.print({message_key, {"item-name." .. get_shop_item_name(message_resource)}})
      else
        player.print({message_key, {"item-name." .. item_name}})
      end
    end

    return
  end

  if not spend_expansion_points(LINE_PURCHASE_COST) then
    if player and player.valid then
      player.print({"message.fes-shop-not-enough-points", LINE_PURCHASE_COST})
    end

    return
  end

  storage.starter_anchors = storage.starter_anchors or create_starter_anchor_state(bootstrap.square_size)
  storage.starter_anchors.anchors[#storage.starter_anchors.anchors + 1] = create_managed_anchor(definition, flow, nil, nil)

  if player and player.valid then
    player_insert_or_spill(player, item_name)
    player.print({
      "message.fes-shop-purchased-line",
      {"item-name." .. item_name},
      LINE_PURCHASE_COST,
      bootstrap.expansion_points
    })
  end
end

local function purchase_ingress_tier_upgrade(player)
  local bootstrap = storage.bootstrap
  local next_tier_level = get_next_ingress_tier_level()
  local next_tier = next_tier_level and get_ingress_tier_definition(next_tier_level) or nil
  local upgrade_cost = get_ingress_tier_upgrade_cost(next_tier_level)

  if not bootstrap then
    return
  end

  if not next_tier_level or not next_tier or not upgrade_cost then
    if player and player.valid then
      player.print({"message.fes-shop-ingress-max-tier"})
    end

    return
  end

  if not spend_expansion_points(upgrade_cost) then
    if player and player.valid then
      player.print({"message.fes-shop-not-enough-points", upgrade_cost})
    end

    return
  end

  bootstrap.ingress_tier = next_tier_level
  ensure_starter_anchors()

  if player and player.valid then
    player.print({
      "message.fes-shop-purchased-ingress-tier",
      next_tier.label,
      upgrade_cost,
      bootstrap.expansion_points
    })
  end
end

local function handle_managed_anchor_built(entity, actor)
  if not (entity and entity.valid) then
    return
  end

  local bootstrap = storage.bootstrap

  if not bootstrap then
    return
  end

  if entity.surface.name ~= bootstrap.surface_name then
    reject_anchor_placement(entity, actor, {"message.fes-managed-line-invalid-surface"})
    return
  end

  if actor and actor.valid and actor.object_name == "LuaPlayer" then
    print_ingress_placement_debug(actor, bootstrap.square_size, entity.position)
  end

  local tile_position = snap_entity_position_to_tile(entity.position)
  local side = get_playable_edge_side_for_position(bootstrap.square_size, tile_position)
  local anchor_position = side and move_position(tile_position, side, 1) or nil

  if not side then
    reject_anchor_placement(entity, actor, {"message.fes-managed-line-invalid-edge"})
    return
  end

  local anchor = find_matching_stashed_anchor(entity.name)

  if not anchor then
    reject_anchor_placement(entity, actor, {"message.fes-managed-line-unowned"})
    return
  end

  if is_fluid_anchor_too_close(anchor, anchor_position, side) then
    reject_anchor_placement(entity, actor, {"message.fes-managed-line-fluid-gap-required"})
    return
  end

  entity.destroy({raise_destroy = false})
  assign_anchor_position(anchor, side, anchor_position)

  ensure_starter_anchors()
  sync_all_shop_guis()
end

local function handle_anchor_mined(entity)
  if not (entity and entity.valid) then
    return
  end

  local anchor = find_anchor_by_entity(entity) or find_anchor_by_entity_name_and_position(entity.name, entity.position)

  if anchor then
    stash_anchor(anchor)
    sync_all_shop_guis()
  end
end

local function handle_entity_built(event)
  local entity = event.entity or event.created_entity

  if not (entity and entity.valid) then
    return
  end

  local player = event.player_index and game.get_player(event.player_index) or nil
  local robot = event.robot
  local actor = player or robot
  local bootstrap = storage.bootstrap

  if bootstrap
    and entity.surface.name == bootstrap.surface_name
    and not is_managed_anchor_entity_name(entity.name)
    and entity_overlaps_anchor_ring(bootstrap.square_size, entity)
  then
    reject_reserved_ring_placement(entity, actor, {"message.fes-edge-reserved"})
    return
  end

  if is_forbidden_logistic_container(entity) and not is_logistic_network_automation_enabled() then
    reject_reserved_ring_placement(
      entity,
      actor,
      {"message.fes-logistic-network-disabled", {"entity-name." .. entity.name}}
    )
    return
  end

  if is_managed_anchor_entity_name(entity.name) then
    handle_managed_anchor_built(entity, actor)
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

  local belt_tier_key = ITEM_INGRESS_BELT_TIER_BY_INGRESS_TIER[get_current_ingress_tier_level()] or "yellow"

  if belt_tier_key == "red" then
    return "fast-transport-belt"
  end

  if belt_tier_key == "blue" then
    return "express-transport-belt"
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
  sync_all_shop_guis()
end

local function is_dev_mode_enabled(player)
  return settings.get_player_settings(player)[SETTING_DEV_MODE].value
end

local function is_ingress_placement_debug_enabled(player)
  return player
    and player.valid
    and settings.get_player_settings(player)[SETTING_INGRESS_PLACEMENT_DEBUG].value
end

local function format_position(position)
  if not position then
    return "(nil)"
  end

  return "(" .. position.x .. ", " .. position.y .. ")"
end

snap_entity_position_to_tile = function(position)
  if not position then
    return nil
  end

  return {
    x = math.floor(position.x),
    y = math.floor(position.y)
  }
end

local function build_ingress_edge_check_debug(square_size, position)
  local tile_position = snap_entity_position_to_tile(position)
  local bounds = get_square_bounds(square_size)
  local min_x = bounds.left_top.x
  local min_y = bounds.left_top.y
  local max_x = bounds.right_bottom.x - 1
  local max_y = bounds.right_bottom.y - 1
  local north_match = tile_position.y == min_y and tile_position.x > min_x and tile_position.x < max_x
  local east_match = tile_position.x == max_x and tile_position.y > min_y and tile_position.y < max_y
  local south_match = tile_position.y == max_y and tile_position.x > min_x and tile_position.x < max_x
  local west_match = tile_position.x == min_x and tile_position.y > min_y and tile_position.y < max_y
  local detected_side = get_playable_edge_side_for_position(square_size, tile_position)
  local anchor_position = detected_side and move_position(tile_position, detected_side, 1) or nil

  return table.concat({
    "[Expanding Square] Ingress placement debug",
    "raw_position=" .. format_position(position),
    "tile_position=" .. format_position(tile_position),
    "square_size=" .. square_size,
    "playable_bounds.left_top=" .. format_position(bounds.left_top),
    "playable_bounds.right_bottom=" .. format_position(bounds.right_bottom),
    "min=(" .. min_x .. ", " .. min_y .. ")",
    "max=(" .. max_x .. ", " .. max_y .. ")",
    "north=" .. tostring(north_match),
    "east=" .. tostring(east_match),
    "south=" .. tostring(south_match),
    "west=" .. tostring(west_match),
    "detected_side=" .. tostring(detected_side),
    "anchor_position=" .. format_position(anchor_position)
  }, " | ")
end

print_ingress_placement_debug = function(player, square_size, position)
  if not is_ingress_placement_debug_enabled(player) then
    return
  end

  player.print(build_ingress_edge_check_debug(square_size, position))
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

local function build_status_lines()
  local bootstrap = storage.bootstrap
  local metrics = storage.utilization_metrics
  local lines = {}

  if not bootstrap or not metrics then
    lines[#lines + 1] = "No utilization data yet."
    return lines
  end

  local next_reward = get_next_expansion_tile_reward(bootstrap.square_size)

  lines[#lines + 1] = "Square: " .. bootstrap.square_size .. "x" .. bootstrap.square_size
  lines[#lines + 1] = "Logistics setting: "
    .. (is_logistic_network_automation_enabled() and "enabled" or "disabled")
  lines[#lines + 1] = "Utilization: " .. format_ratio_percent(metrics.utilization_ratio)
    .. " (" .. metrics.active_footprint_tiles .. " / " .. metrics.total_tiles .. " tiles)"
  lines[#lines + 1] = "Growth rate: " .. format_decimal(metrics.growth_rate_per_second) .. " tiles/s"
    .. " (" .. format_decimal(metrics.growth_rate_per_minute) .. " tiles/min)"
  lines[#lines + 1] = "Progress: " .. format_decimal(bootstrap.growth_progress or 0)
    .. " / " .. next_reward
  lines[#lines + 1] = "Research multiplier: " .. format_decimal(metrics.expansion_speed_multiplier)
    .. "x from " .. metrics.expansion_speed_research_levels .. " expansion-speed levels"
  lines[#lines + 1] = "Active entities: " .. metrics.active_entity_count
  lines[#lines + 1] = "Expansion points: " .. (bootstrap.expansion_points or 0)
  lines[#lines + 1] = "Ingress tier: " .. build_ingress_tier_summary()
  lines[#lines + 1] = "Next reward: " .. next_reward .. " tiles and " .. next_reward .. " expansion points"

  return lines
end

local function ensure_status_frame(player)
  local frame = player.gui.left[STATUS_FRAME_NAME]

  if frame then
    return frame
  end

  return player.gui.left.add({
    type = "frame",
    name = STATUS_FRAME_NAME,
    direction = "vertical",
    caption = {"gui.fes-status-title"}
  })
end

local function refresh_status_gui(player)
  if not (player and player.valid) then
    return
  end

  local frame = player.gui.left[STATUS_FRAME_NAME]

  if not frame then
    return
  end

  frame.clear()

  for _, line in ipairs(build_status_lines()) do
    frame.add({
      type = "label",
      caption = line
    })
  end
end

local function sync_status_gui(player)
  if not (player and player.valid) then
    return
  end

  ensure_status_frame(player)
  refresh_status_gui(player)
end

refresh_all_status_guis = function()
  for _, player in pairs(game.players) do
    sync_status_gui(player)
  end
end

local function build_debug_lines()
  local lines = build_status_lines()

  if lines[1] == "No utilization data yet." then
    return lines
  end

  local bootstrap = storage.bootstrap
  local metrics = storage.utilization_metrics

  lines[#lines + 1] = "Formula: growth/s = utilization x (square size / " .. GROWTH_RATE_SIZE_DIVISOR .. ")"
  lines[#lines + 1] = "Current: " .. format_decimal(metrics.growth_rate_per_second)
    .. " = " .. format_decimal(metrics.base_growth_rate_per_second)
    .. " x " .. format_decimal(metrics.expansion_speed_multiplier)
  lines[#lines + 1] = "Base: " .. format_decimal(metrics.base_growth_rate_per_second)
    .. " = " .. format_decimal(metrics.utilization_ratio)
    .. " x (" .. bootstrap.square_size .. " / " .. GROWTH_RATE_SIZE_DIVISOR .. ")"
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

local function ensure_shop_button(player)
  local button = player.gui.top[SHOP_BUTTON_NAME]

  if button then
    return button
  end

  return player.gui.top.add({
    type = "button",
    name = SHOP_BUTTON_NAME,
    caption = {"gui.fes-shop-button"}
  })
end

local function build_shop_status_caption(resource)
  local definition = get_input_definition(resource) or get_output_definition(resource)
  local counts = get_owned_line_counts(resource)

  if not definition then
    return "Unavailable"
  end

  if counts.owned > 0 then
    return "Owned: " .. counts.owned .. " (" .. counts.placed .. " placed, " .. counts.stashed .. " stashed)"
  end

  if definition.prerequisite_resource and not is_resource_unlocked(definition.prerequisite_resource) then
    return "Locked until " .. format_resource_name(definition.prerequisite_resource) .. " is unlocked"
  end

  return "Not yet unlocked"
end

local function build_ingress_upgrade_caption(next_tier_level)
  local next_tier = next_tier_level and get_ingress_tier_definition(next_tier_level) or nil

  if not next_tier then
    return "Ingress tier maxed"
  end

  return "Upgrade to " .. next_tier.label
end

local function build_ingress_upgrade_status_caption()
  local current_tier = get_current_ingress_tier()
  local next_tier_level = get_next_ingress_tier_level()
  local next_cost = get_ingress_tier_upgrade_cost(next_tier_level)

  if not next_tier_level or not next_cost then
    return "Current: " .. current_tier.label .. " (maximum tier)"
  end

  return "Current: " .. current_tier.label .. " | Next cost: " .. next_cost
end

local function ensure_shop_frame(player)
  local frame = player.gui.left[SHOP_FRAME_NAME]

  if frame then
    return frame
  end

  return player.gui.left.add({
    type = "frame",
    name = SHOP_FRAME_NAME,
    direction = "vertical",
    caption = {"gui.fes-shop-title"}
  })
end

local function refresh_shop_gui(player)
  if not (player and player.valid) then
    return
  end

  local frame = player.gui.left[SHOP_FRAME_NAME]
  local bootstrap = storage.bootstrap

  if not frame or not bootstrap then
    return
  end

  frame.clear()
  frame.add({
    type = "label",
    caption = {"gui.fes-shop-points", bootstrap.expansion_points or 0}
  })
  frame.add({
    type = "label",
    caption = {"gui.fes-shop-line-cost", LINE_PURCHASE_COST}
  })
  do
    local flow = frame.add({
      type = "flow",
      direction = "horizontal"
    })
    local next_tier_level = get_next_ingress_tier_level()
    local next_upgrade_cost = get_ingress_tier_upgrade_cost(next_tier_level)
    local button = flow.add({
      type = "button",
      name = "fes_shop_upgrade_ingress",
      caption = build_ingress_upgrade_caption(next_tier_level)
    })

    button.enabled = next_upgrade_cost ~= nil and (bootstrap.expansion_points or 0) >= next_upgrade_cost

    flow.add({
      type = "label",
      caption = build_ingress_upgrade_status_caption()
    })
  end

  for _, definition in ipairs(INPUT_DEFINITIONS) do
    local flow = frame.add({
      type = "flow",
      direction = "horizontal"
    })
    local can_purchase = can_purchase_line(definition.resource)
    local button = flow.add({
      type = "button",
      name = "fes_shop_buy__" .. definition.resource,
      caption = {"gui.fes-shop-buy", {"item-name." .. get_ingress_item_name(definition.resource)}}
    })

    button.enabled = can_purchase and (bootstrap.expansion_points or 0) >= LINE_PURCHASE_COST

    flow.add({
      type = "label",
      caption = build_shop_status_caption(definition.resource)
    })
  end

  for _, definition in ipairs(OUTPUT_DEFINITIONS) do
    local flow = frame.add({
      type = "flow",
      direction = "horizontal"
    })
    local can_purchase = can_purchase_line(definition.resource)
    local button = flow.add({
      type = "button",
      name = "fes_shop_buy__" .. definition.resource,
      caption = {"gui.fes-shop-buy", {"item-name." .. get_egress_item_name(definition.resource)}}
    })

    button.enabled = can_purchase and (bootstrap.expansion_points or 0) >= LINE_PURCHASE_COST

    flow.add({
      type = "label",
      caption = build_shop_status_caption(definition.resource)
    })
  end
end

local function toggle_shop_gui(player)
  if not (player and player.valid) then
    return
  end

  local frame = player.gui.left[SHOP_FRAME_NAME]

  if frame then
    frame.destroy()
    return
  end

  ensure_shop_frame(player)
  refresh_shop_gui(player)
end

local function sync_shop_gui(player)
  if not (player and player.valid) then
    return
  end

  sync_status_gui(player)
  ensure_shop_button(player)
  refresh_shop_gui(player)
end

sync_all_shop_guis = function()
  for _, player in pairs(game.players) do
    sync_shop_gui(player)
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
  refresh_all_status_guis()

  return metrics
end

local function announce_expansion_speed_research(force)
  local multiplier, levels = get_expansion_speed_multiplier()

  force.print({
    "message.fes-expansion-speed-updated",
    levels,
    format_decimal(multiplier)
  })
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

  apply_logistic_network_setting_to_all_forces()
  update_utilization_metrics()
  refresh_all_status_guis()
  sync_all_dev_guis()
  sync_all_shop_guis()
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

  apply_logistic_network_setting_to_all_forces()
  update_utilization_metrics()
  refresh_all_status_guis()
  sync_all_dev_guis()
  sync_all_shop_guis()
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
    local surface = game.surfaces[storage.bootstrap.surface_name]

    if surface then
      refresh_managed_surface_tiles(surface, storage.bootstrap.square_size, storage.bootstrap.surface_size)
    end

    refresh_spawn_routing()
    return
  end

  bootstrap_world()
end)

script.on_event(defines.events.on_player_created, function(event)
  local player = game.get_player(event.player_index)

  if player then
    teleport_player_to_square(player)
    sync_status_gui(player)
    sync_dev_gui(player)
    sync_shop_gui(player)
  end
end)

script.on_event(defines.events.on_player_respawned, function(event)
  local player = game.get_player(event.player_index)

  if player then
    teleport_player_to_square(player)
    sync_status_gui(player)
    sync_dev_gui(player)
    sync_shop_gui(player)
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
  if not (event.element and event.element.valid) then
    return
  end

  local player = game.get_player(event.player_index)

  if event.element.name == DEV_EXPAND_BUTTON_NAME then
    if player and is_dev_mode_enabled(player) then
      expand_square(player)
    end

    return
  end

  if event.element.name == SHOP_BUTTON_NAME then
    toggle_shop_gui(player)
    return
  end

  if event.element.name == "fes_shop_upgrade_ingress" then
    if player then
      purchase_ingress_tier_upgrade(player)
      refresh_shop_gui(player)
      refresh_all_debug_guis()
      sync_all_shop_guis()
    end

    return
  end

  local resource = string.match(event.element.name, "^fes_shop_buy__(.+)$")

  if resource and player then
    purchase_managed_line(player, resource)
    refresh_shop_gui(player)
    refresh_all_debug_guis()
    sync_all_shop_guis()
  end
end)

script.on_event(defines.events.on_runtime_mod_setting_changed, function(event)
  if event.setting == SETTING_STARTING_SQUARE_SIZE then
    if storage.bootstrap then
      notify_square_size_change_applies_to_new_saves()
    end

    return
  end

  if event.setting == SETTING_ENABLE_LOGISTIC_NETWORK_AUTOMATION then
    apply_logistic_network_setting_to_all_forces()
    refresh_all_status_guis()
    return
  end

  if event.setting == SETTING_DEV_MODE then
    local player = game.get_player(event.player_index)

    if player then
      sync_dev_gui(player)
      sync_shop_gui(player)
      sync_status_gui(player)
    end
  end
end)

script.on_event(defines.events.on_research_finished, function(event)
  local research = event.research

  if not (research and research.valid and research.force) then
    return
  end

  for _, band in ipairs(EXPANSION_SPEED_RESEARCH_BANDS) do
    if research.name == band.name then
      storage.bootstrap = storage.bootstrap or {}
      storage.bootstrap.expansion_speed_research_levels = (storage.bootstrap.expansion_speed_research_levels or 0) + 1
      update_utilization_metrics()
      refresh_all_debug_guis()
      refresh_all_status_guis()
      announce_expansion_speed_research(research.force)
      break
    end
  end

  if not is_logistic_network_automation_enabled() then
    apply_logistic_network_setting_to_force(research.force)
  end
end)

script.on_nth_tick(ITEM_ANCHOR_INTERVAL_TICKS, function()
  ensure_starter_anchors()
  pump_starter_anchors()
end)

script.on_nth_tick(UTILIZATION_UPDATE_INTERVAL_TICKS, function()
  advance_growth_from_utilization()
end)
