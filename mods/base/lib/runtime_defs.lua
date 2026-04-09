local bootstrap_layout = require("lib.bootstrap_layout")
local expansion_research = require("lib.expansion_research")
local item_ingress = require("lib.item_ingress")

local runtime_defs = {}

runtime_defs.SURFACE_NAME = "fes-bootstrap"
runtime_defs.BASE_SCREENSHOT_MARGIN_TILES = 2
runtime_defs.BASE_SCREENSHOT_DIRECTORY = "the-square"
runtime_defs.SETTING_STARTING_SQUARE_SIZE = "fes-starting-square-size"
runtime_defs.SETTING_EXPANSION_TILES_PER_RESEARCH = "fes-expansion-tiles-per-research"
runtime_defs.SETTING_LINE_PURCHASE_COST = "fes-line-purchase-cost"
runtime_defs.SETTING_ENABLE_LOGISTIC_NETWORK_AUTOMATION = "fes-enable-logistic-network-automation"
runtime_defs.SETTING_BACKGROUND_TILE = "fes-background-tile"
runtime_defs.SETTING_SCREENSHOT_PIXELS_PER_TILE = "fes-screenshot-pixels-per-tile"
runtime_defs.SETTING_SCREENSHOT_ALT_MODE = "fes-screenshot-alt-mode"
runtime_defs.SETTING_DEV_MODE = "fes-dev-mode"
runtime_defs.SETTING_INGRESS_PLACEMENT_DEBUG = "fes-ingress-placement-debug"
runtime_defs.FLOOR_TILE_NAME = "grass-1"
runtime_defs.VOID_TILE_NAME = "out-of-map"
runtime_defs.DEFAULT_BACKGROUND_TILE_NAME = "grass-1"
runtime_defs.CHECKERBOARD_BACKGROUND_TILE_NAME = "checkerboard"
runtime_defs.CHECKERBOARD_TILE_NAMES = {
  even = "lab-dark-1",
  odd = "lab-dark-2"
}
runtime_defs.CHART_MARGIN = 1
runtime_defs.ITEM_ANCHOR_INTERVAL_TICKS = 8
runtime_defs.ANCHOR_SLOT_PROXY_NAME = "fes-anchor-slot-proxy"
runtime_defs.PLACE_MANAGED_ANCHOR_INPUT_NAME = "fes-place-managed-anchor"
runtime_defs.STARTER_ANCHOR_OUTER_RING_WIDTH = 1
runtime_defs.STARTER_ANCHOR_LAYOUT_VERSION = 12
runtime_defs.DEV_EXPAND_BUTTON_NAME = "fes_dev_expand_button"
runtime_defs.DEBUG_FRAME_NAME = "fes_debug_frame"
runtime_defs.SHOP_BUTTON_NAME = "fes_shop_button"
runtime_defs.SCREENSHOT_BUTTON_NAME = "fes_screenshot_button"
runtime_defs.SHOP_FRAME_NAME = "fes_shop_frame"
runtime_defs.MAX_INGRESS_TIER = 4
runtime_defs.INGRESS_RESEARCH_DEFINITIONS = {
  {
    technology_name = "fes-ingress-dual-lane",
    prerequisite_technology_name = "logistics",
    tier_level = 2
  },
  {
    technology_name = "fes-ingress-red",
    prerequisite_technology_name = "logistics-2",
    tier_level = 3
  },
  {
    technology_name = "fes-ingress-blue",
    prerequisite_technology_name = "logistics-3",
    tier_level = 4
  }
}
runtime_defs.EXPANSION_RESEARCH_LEVELS_PER_TIER = 10
runtime_defs.FINAL_FINITE_EXPANSION_RESEARCH_LEVEL = expansion_research.FINAL_FINITE_LEVEL
runtime_defs.INFINITE_EXPANSION_RESEARCH_START_LEVEL = expansion_research.INFINITE_START_LEVEL
runtime_defs.EXPANSION_RESEARCH_BANDS = {
  {
    name = "Automation science",
    start_level = 1,
    label = "Automation science"
  },
  {
    name = "Automation + logistic science",
    start_level = 11,
    label = "Automation + logistic science"
  },
  {
    name = "Automation + logistic + chemical science",
    start_level = 21,
    label = "Automation + logistic + chemical science"
  },
  {
    name = "Automation + logistic + chemical + production + utility science",
    start_level = 31,
    label = "Automation + logistic + chemical + production + utility science"
  },
  {
    name = "All science through space",
    start_level = 41,
    label = "All science through space"
  }
}
runtime_defs.FORBIDDEN_LOGISTIC_CONTAINER_NAMES = {
  ["active-provider-chest"] = true,
  ["buffer-chest"] = true,
  ["requester-chest"] = true,
  ["storage-chest"] = true
}
runtime_defs.COUNTED_CATEGORY_ORDER = {
  "crafting",
  "lab",
  "rocket-silo",
  "beacon",
  "power"
}
runtime_defs.COUNTED_CATEGORY_LABELS = {
  crafting = "Crafting",
  lab = "Labs",
  ["rocket-silo"] = "Rocket silos",
  beacon = "Beacons",
  power = "Power"
}
runtime_defs.INPUT_DEFINITIONS = {
  {resource = "iron-ore", kind = "item", starter_side = "north", prerequisite_resource = nil},
  {resource = "copper-ore", kind = "item", starter_side = "north", prerequisite_resource = nil},
  {resource = "coal", kind = "item", starter_side = "south", prerequisite_resource = nil},
  {resource = "stone", kind = "item", starter_side = "south", prerequisite_resource = nil},
  {resource = "water", kind = "fluid", starter_side = "west", prerequisite_resource = nil},
  {resource = "wood", kind = "item", starter_side = "east", prerequisite_resource = nil},
  {resource = "crude-oil", kind = "fluid", starter_side = nil, prerequisite_resource = nil},
  {resource = "uranium-ore", kind = "item", starter_side = nil, prerequisite_resource = "crude-oil"}
}
runtime_defs.OUTPUT_DEFINITIONS = {
  {resource = "sulfuric-acid", kind = "fluid", starter_side = nil, prerequisite_resource = "uranium-ore"}
}
runtime_defs.DIRECTION_BY_SIDE = {
  north = defines.direction.south,
  east = defines.direction.west,
  south = defines.direction.north,
  west = defines.direction.east
}
runtime_defs.REVERSED_DIRECTION_BY_SIDE = {
  north = defines.direction.north,
  east = defines.direction.east,
  south = defines.direction.south,
  west = defines.direction.west
}
runtime_defs.OFFSET_BY_SIDE = {
  north = {x = 0, y = -1},
  east = {x = 1, y = 0},
  south = {x = 0, y = 1},
  west = {x = -1, y = 0}
}
runtime_defs.ITEM_INGRESS_BELT_TIER_BY_INGRESS_TIER = {
  [1] = "yellow",
  [2] = "yellow",
  [3] = "red",
  [4] = "blue"
}
runtime_defs.INGRESS_TIER_DEFINITIONS = {
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

function runtime_defs.get_ingress_item_name(resource)
  return "fes-" .. resource .. "-ingress"
end

function runtime_defs.get_ingress_entity_name(resource, ingress_tier_level)
  local definition = nil

  for _, input_definition in ipairs(runtime_defs.INPUT_DEFINITIONS) do
    if input_definition.resource == resource then
      definition = input_definition
      break
    end
  end

  if not definition or definition.kind ~= "item" then
    return "fes-" .. resource .. "-ingress-anchor"
  end

  local belt_tier_key = runtime_defs.ITEM_INGRESS_BELT_TIER_BY_INGRESS_TIER[ingress_tier_level or 1] or "yellow"

  if belt_tier_key == "yellow" then
    return "fes-" .. resource .. "-ingress-anchor"
  end

  return "fes-" .. resource .. "-ingress-anchor-" .. belt_tier_key
end

function runtime_defs.is_ingress_entity_name_for_resource(resource, entity_name)
  if entity_name == runtime_defs.get_ingress_entity_name(resource, 1) then
    return true
  end

  for tier_level = 2, runtime_defs.MAX_INGRESS_TIER do
    if entity_name == runtime_defs.get_ingress_entity_name(resource, tier_level) then
      return true
    end
  end

  return false
end

function runtime_defs.get_input_definition(resource)
  for _, definition in ipairs(runtime_defs.INPUT_DEFINITIONS) do
    if definition.resource == resource then
      return definition
    end
  end

  return nil
end

function runtime_defs.get_output_definition(resource)
  for _, definition in ipairs(runtime_defs.OUTPUT_DEFINITIONS) do
    if definition.resource == resource then
      return definition
    end
  end

  return nil
end

function runtime_defs.get_line_definition(resource)
  local input_definition = runtime_defs.get_input_definition(resource)

  if input_definition then
    return input_definition, "ingress"
  end

  local output_definition = runtime_defs.get_output_definition(resource)

  if output_definition then
    return output_definition, "egress"
  end

  return nil, nil
end

function runtime_defs.get_egress_item_name(resource)
  return "fes-" .. resource .. "-egress"
end

function runtime_defs.get_egress_entity_name(resource)
  return "fes-" .. resource .. "-egress-anchor"
end

function runtime_defs.is_egress_entity_name_for_resource(resource, entity_name)
  return entity_name == runtime_defs.get_egress_entity_name(resource)
end

function runtime_defs.create_managed_anchor(definition, flow, side, position)
  return {
    resource = definition.resource,
    kind = definition.kind,
    flow = flow,
    side = side,
    direction = side and runtime_defs.get_anchor_direction_for_side(flow, definition.kind, side) or nil,
    position = position,
    item_name = flow == "egress"
      and runtime_defs.get_egress_item_name(definition.resource)
      or runtime_defs.get_ingress_item_name(definition.resource),
    entity_name = flow == "egress"
      and runtime_defs.get_egress_entity_name(definition.resource)
      or runtime_defs.get_ingress_entity_name(definition.resource),
    item_progress = {0, 0}
  }
end

function runtime_defs.get_anchor_direction_for_side(flow, kind, side)
  if not side then
    return nil
  end

  if kind == "fluid" then
    if flow == "egress" then
      return runtime_defs.DIRECTION_BY_SIDE[side]
    end

    return runtime_defs.REVERSED_DIRECTION_BY_SIDE[side]
  end

  return runtime_defs.DIRECTION_BY_SIDE[side]
end

function runtime_defs.get_square_size()
  return settings.global[runtime_defs.SETTING_STARTING_SQUARE_SIZE].value
end

function runtime_defs.get_expansion_tiles_per_research()
  return settings.startup[runtime_defs.SETTING_EXPANSION_TILES_PER_RESEARCH].value
end

function runtime_defs.get_line_purchase_cost()
  return settings.global[runtime_defs.SETTING_LINE_PURCHASE_COST].value
end

function runtime_defs.is_logistic_network_automation_enabled()
  return settings.global[runtime_defs.SETTING_ENABLE_LOGISTIC_NETWORK_AUTOMATION].value
end

function runtime_defs.get_square_bounds(size)
  return bootstrap_layout.get_square_bounds(size)
end

function runtime_defs.get_surface_size(square_size)
  return bootstrap_layout.get_surface_size(square_size, runtime_defs.STARTER_ANCHOR_OUTER_RING_WIDTH)
end

function runtime_defs.get_background_tile_name()
  local background_tile_setting = settings.global[runtime_defs.SETTING_BACKGROUND_TILE]

  if background_tile_setting and background_tile_setting.value then
    return background_tile_setting.value
  end

  return runtime_defs.DEFAULT_BACKGROUND_TILE_NAME
end

function runtime_defs.get_screenshot_pixels_per_tile()
  local screenshot_pixels_per_tile_setting = settings.global[runtime_defs.SETTING_SCREENSHOT_PIXELS_PER_TILE]

  if screenshot_pixels_per_tile_setting and screenshot_pixels_per_tile_setting.value then
    return screenshot_pixels_per_tile_setting.value
  end

  return 32
end

---@return boolean
function runtime_defs.is_screenshot_alt_mode_enabled()
  local screenshot_alt_mode_setting = settings.global[runtime_defs.SETTING_SCREENSHOT_ALT_MODE]

  if screenshot_alt_mode_setting == nil or screenshot_alt_mode_setting.value == nil then
    return true
  end

  return screenshot_alt_mode_setting.value == true
end

---@param square_size integer
---@return BoundingBox
function runtime_defs.get_anchor_bounds(square_size)
  return bootstrap_layout.get_anchor_bounds(square_size)
end

function runtime_defs.get_square_area(square_size)
  return square_size * square_size
end

function runtime_defs.get_ingress_tier_definition(tier_level)
  return runtime_defs.INGRESS_TIER_DEFINITIONS[tier_level] or runtime_defs.INGRESS_TIER_DEFINITIONS[1]
end

function runtime_defs.get_current_ingress_tier_level()
  local bootstrap = storage.bootstrap

  if not bootstrap then
    return 1
  end

  local tier_level = bootstrap.ingress_tier or 1

  if tier_level < 1 then
    return 1
  end

  if tier_level > runtime_defs.MAX_INGRESS_TIER then
    return runtime_defs.MAX_INGRESS_TIER
  end

  return tier_level
end

function runtime_defs.get_current_ingress_tier()
  return runtime_defs.get_ingress_tier_definition(runtime_defs.get_current_ingress_tier_level())
end

function runtime_defs.get_ingress_tier_level_for_force(force)
  local tier_level = 1

  if not (force and force.valid and force.technologies) then
    return tier_level
  end

  for _, definition in ipairs(runtime_defs.INGRESS_RESEARCH_DEFINITIONS) do
    local technology = force.technologies[definition.technology_name]

    if technology and technology.researched and definition.tier_level > tier_level then
      tier_level = definition.tier_level
    end
  end

  return tier_level
end

function runtime_defs.get_next_expansion_tile_reward(square_size)
  local next_square_size = square_size + 2

  return runtime_defs.get_square_area(next_square_size) - runtime_defs.get_square_area(square_size)
end

function runtime_defs.get_completed_expansion_research_levels()
  if not storage.bootstrap then
    return 0
  end

  return storage.bootstrap.expansion_research_levels or 0
end

function runtime_defs.get_expansion_research_band_for_level(level)
  local band = runtime_defs.EXPANSION_RESEARCH_BANDS[1]

  for _, candidate in ipairs(runtime_defs.EXPANSION_RESEARCH_BANDS) do
    if level >= candidate.start_level then
      band = candidate
    else
      break
    end
  end

  return band
end

function runtime_defs.is_expansion_research_name(research_name)
  return expansion_research.is_expansion_technology_name(research_name)
end

function runtime_defs.is_inside_bounds(bounds, position)
  return bootstrap_layout.is_inside_bounds(bounds, position)
end

function runtime_defs.get_position_key(position)
  return position.x .. ":" .. position.y
end

function runtime_defs.move_position(position, side, distance)
  local offset = runtime_defs.OFFSET_BY_SIDE[side]

  return {
    x = position.x + (offset.x * distance),
    y = position.y + (offset.y * distance)
  }
end

---@param square_size integer
---@param position MapPosition
---@return "north"|"east"|"south"|"west"|nil
function runtime_defs.get_anchor_side_for_position(square_size, position)
  return bootstrap_layout.get_anchor_side_for_position(square_size, position)
end

function runtime_defs.is_anchor_ring_position(square_size, position)
  return bootstrap_layout.is_anchor_ring_position(square_size, position)
end

function runtime_defs.get_managed_tile_name(square_size, surface_size, position)
  local background_tile_name = runtime_defs.get_background_tile_name()

  if background_tile_name == runtime_defs.CHECKERBOARD_BACKGROUND_TILE_NAME
    and bootstrap_layout.is_inside_bounds(bootstrap_layout.get_square_bounds(square_size), position) then
    local parity = math.abs(position.x + position.y) % 2 == 0 and "even" or "odd"

    return runtime_defs.CHECKERBOARD_TILE_NAMES[parity]
  end

  return bootstrap_layout.get_managed_tile_name(
    square_size,
    surface_size,
    background_tile_name,
    runtime_defs.VOID_TILE_NAME,
    position
  )
end

function runtime_defs.get_player_force()
  return game and game.forces and game.forces.player or nil
end

function runtime_defs.format_ratio_percent(ratio)
  return string.format("%.1f%%", ratio * 100)
end

function runtime_defs.format_decimal(value)
  return string.format("%.2f", value)
end

function runtime_defs.format_resource_name(resource)
  return string.gsub(resource, "%-", " ")
end

function runtime_defs.format_position(position)
  if not position then
    return "(nil)"
  end

  return "(" .. position.x .. ", " .. position.y .. ")"
end

---@param position MapPosition
---@return MapPosition
function runtime_defs.snap_entity_position_to_tile(position)
  return {
    x = math.floor(position.x),
    y = math.floor(position.y)
  }
end

function runtime_defs.get_anchor_entity_name_for_current_tier(anchor)
  if not anchor then
    return nil
  end

  if anchor.flow == "egress" then
    return runtime_defs.get_egress_entity_name(anchor.resource)
  end

  if anchor.kind == "item" then
    return runtime_defs.get_ingress_entity_name(anchor.resource, runtime_defs.get_current_ingress_tier_level())
  end

  return runtime_defs.get_ingress_entity_name(anchor.resource, 1)
end

function runtime_defs.build_ingress_tier_summary()
  local tier = runtime_defs.get_current_ingress_tier()
  local item_rate_per_second = runtime_defs.get_ingress_item_rate_per_second()
  local fluid_rate_per_second = runtime_defs.get_ingress_fluid_rate_per_second()

  return tier.label
    .. " | item/s per anchor: "
    .. runtime_defs.format_decimal(item_rate_per_second)
    .. " | fluid/s per anchor: "
    .. runtime_defs.format_decimal(fluid_rate_per_second)
end

function runtime_defs.get_ingress_item_rate_per_second()
  local tier = runtime_defs.get_current_ingress_tier()

  return item_ingress.get_total_items_per_second(
    tier.item_lane_counts or {0, 0},
    runtime_defs.ITEM_ANCHOR_INTERVAL_TICKS
  )
end

function runtime_defs.get_ingress_fluid_rate_per_second()
  local tier = runtime_defs.get_current_ingress_tier()
  return (tier.fluid_amount_per_interval or 0) * (60 / runtime_defs.ITEM_ANCHOR_INTERVAL_TICKS)
end

return runtime_defs
