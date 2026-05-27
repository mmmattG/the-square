local bootstrap_layout = require("lib.bootstrap_layout")
local expansion_research = require("lib.expansion_research")
local item_ingress = require("lib.item_ingress")
local planet_catalog = require("lib.planet_catalog")

local runtime_defs = {}

runtime_defs.SURFACE_NAME = "nauvis"
runtime_defs.LEGACY_SURFACE_NAME = "fes-bootstrap"
runtime_defs.BASE_SCREENSHOT_MARGIN_TILES = 2
runtime_defs.BASE_SCREENSHOT_DIRECTORY = "the-square"
runtime_defs.SETTING_NAUVIS_STARTING_SQUARE_SIZE = "the-square-nauvis-starting-square-size"
runtime_defs.SETTING_EXPANSION_TILES_PER_RESEARCH = "the-square-expansion-tiles-per-research"
runtime_defs.SETTING_ENABLE_LOGISTIC_NETWORK_AUTOMATION = "the-square-enable-logistic-network-automation"
runtime_defs.SETTING_BACKGROUND_TILE = "the-square-background-tile"
runtime_defs.SETTING_SCREENSHOT_PIXELS_PER_TILE = "the-square-screenshot-pixels-per-tile"
runtime_defs.SETTING_SCREENSHOT_ALT_MODE = "the-square-screenshot-alt-mode"
runtime_defs.SETTING_DEV_MODE = "the-square-dev-mode"
runtime_defs.SETTING_INGRESS_PLACEMENT_DEBUG = "the-square-ingress-placement-debug"
runtime_defs.SETTING_CLIFF_EXPLOSIVE_BUTTON = "the-square-cliff-explosive-button"
runtime_defs.LEGACY_SETTING_NAMES = {
  [runtime_defs.SETTING_EXPANSION_TILES_PER_RESEARCH] = "fes-expansion-tiles-per-research",
  [runtime_defs.SETTING_ENABLE_LOGISTIC_NETWORK_AUTOMATION] = "fes-enable-logistic-network-automation",
  [runtime_defs.SETTING_BACKGROUND_TILE] = "fes-background-tile",
  [runtime_defs.SETTING_SCREENSHOT_PIXELS_PER_TILE] = "fes-screenshot-pixels-per-tile",
  [runtime_defs.SETTING_SCREENSHOT_ALT_MODE] = "fes-screenshot-alt-mode",
  [runtime_defs.SETTING_DEV_MODE] = "fes-dev-mode",
  [runtime_defs.SETTING_INGRESS_PLACEMENT_DEBUG] = "fes-ingress-placement-debug"
}
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
runtime_defs.ANCHOR_SLOT_PROXY_NAME = "the-square-anchor-slot-proxy"
runtime_defs.GENERIC_ANCHOR_ITEMS = {
  item_ingress = "the-square-item-ingress-anchor",
  item_egress = "the-square-item-egress-anchor",
  fluid_ingress = "the-square-fluid-ingress-anchor",
  fluid_egress = "the-square-fluid-egress-anchor"
}
runtime_defs.GENERIC_ANCHOR_ENTITIES = {
  item_ingress = "the-square-generic-item-ingress-anchor",
  item_egress = "the-square-generic-item-egress-anchor",
  fluid_ingress = "the-square-generic-fluid-ingress-anchor",
  fluid_egress = "the-square-generic-fluid-egress-anchor"
}
runtime_defs.PLACE_MANAGED_ANCHOR_INPUT_NAME = "the-square-place-managed-anchor"
runtime_defs.OPEN_MANAGED_ANCHOR_INPUT_NAME = "the-square-open-managed-anchor"
runtime_defs.STARTER_ANCHOR_OUTER_RING_WIDTH = 1
runtime_defs.STARTER_ANCHOR_LAYOUT_VERSION = 12
runtime_defs.DEV_EXPAND_BUTTON_NAME = "the_square_dev_expand_button"
runtime_defs.DEV_ORBIT_TELEPORT_BUTTON_PREFIX = "the_square_dev_orbit_teleport__"
runtime_defs.DEBUG_FRAME_NAME = "the_square_debug_frame"
runtime_defs.SHOP_BUTTON_NAME = "the_square_shop_button"
runtime_defs.SCREENSHOT_BUTTON_NAME = "the_square_screenshot_button"
runtime_defs.CLIFF_EXPLOSIVE_BUTTON_NAME = "the_square_cliff_explosive_button"
runtime_defs.SHOP_FRAME_NAME = "the_square_shop_frame"
runtime_defs.ANCHOR_CONFIG_FRAME_NAME = "the_square_anchor_config_frame"
runtime_defs.ANCHOR_CONFIG_BUTTON_PREFIX = "the_square_anchor_config_pick__"
runtime_defs.ANCHOR_CONFIG_TIER_BUTTON_PREFIX = "the_square_anchor_config_tier__"
runtime_defs.MAX_INGRESS_TIER = 5
runtime_defs.MAX_EGRESS_TIER = 5
runtime_defs.MANAGED_LINE_ITEM_TIERS = {
  {key = "yellow", label = "Yellow", tier_level = 1, research_tier_level = 1},
  {key = "red", label = "Red", tier_level = 3, research_tier_level = 3},
  {key = "blue", label = "Blue", tier_level = 4, research_tier_level = 4},
  {key = "turbo", label = "Green", tier_level = 5, research_tier_level = 5}
}
runtime_defs.CONFIG_RESOURCE_TECH_UNLOCKS = {
  ingress = {
    ["crude-oil"] = {"oil-gathering", "oil-processing"},
    ["uranium-ore"] = {"uranium-mining"},
    ["sulfuric-acid"] = {"uranium-mining"},
    ["biter-egg"] = {"captivity"}
  },
  egress = {
    ["sulfuric-acid"] = {"uranium-mining"},
    bioflux = {"captivity"}
  }
}
runtime_defs.DEBUG_SPACE_AGE_PLANETS = {
  {name = "nauvis", label = "Nauvis"},
  {name = "vulcanus", label = "Vulcanus"},
  {name = "gleba", label = "Gleba"},
  {name = "fulgora", label = "Fulgora"},
  {name = "aquilo", label = "Aquilo"}
}
runtime_defs.INGRESS_RESEARCH_DEFINITIONS = {
  {
    technology_name = "the-square-ingress-dual-lane",
    prerequisite_technology_name = "logistics",
    tier_level = 2
  },
  {
    technology_name = "the-square-ingress-red",
    prerequisite_technology_name = "logistics-2",
    tier_level = 3
  },
  {
    technology_name = "the-square-ingress-blue",
    prerequisite_technology_name = "logistics-3",
    tier_level = 4
  },
  {
    technology_name = "the-square-egress-turbo",
    prerequisite_technology_name = "turbo-transport-belt",
    tier_level = 5
  }
}
runtime_defs.EGRESS_RESEARCH_DEFINITIONS = {
  {
    technology_name = "the-square-ingress-dual-lane",
    tier_level = 2
  },
  {
    technology_name = "the-square-ingress-red",
    tier_level = 3
  },
  {
    technology_name = "the-square-ingress-blue",
    tier_level = 4
  },
  {
    technology_name = "the-square-egress-turbo",
    tier_level = 5
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
runtime_defs.INPUT_DEFINITIONS_BY_PLANET = planet_catalog.build_native_free_resources_by_planet()
runtime_defs.OUTPUT_DEFINITIONS_BY_PLANET = planet_catalog.build_opt_in_egress_resources_by_planet()
runtime_defs.INPUT_DEFINITIONS = runtime_defs.INPUT_DEFINITIONS_BY_PLANET.nauvis
runtime_defs.OUTPUT_DEFINITIONS = runtime_defs.OUTPUT_DEFINITIONS_BY_PLANET.nauvis
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
  [4] = "blue",
  [5] = "turbo"
}
runtime_defs.ITEM_EGRESS_BELT_TIER_BY_EGRESS_TIER = {
  [1] = "yellow",
  [2] = "yellow",
  [3] = "red",
  [4] = "blue",
  [5] = "turbo"
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
  },
  [5] = {
    key = "turbo-double",
    label = "Turbo double lane",
    item_lane_counts = {4, 4},
    fluid_amount_per_interval = 1280
  }
}

local function get_generic_anchor_key(kind, flow)
  return (kind or "item") .. "_" .. (flow or "ingress")
end

function runtime_defs.get_generic_anchor_item_name(kind, flow)
  return runtime_defs.GENERIC_ANCHOR_ITEMS[get_generic_anchor_key(kind, flow)]
end

function runtime_defs.get_generic_anchor_item_name_for_tier(kind, flow, tier_level)
  local base_name = runtime_defs.get_generic_anchor_item_name(kind, flow)

  if not base_name then
    return nil
  end

  if kind == "fluid" then
    return base_name
  end

  local tier_key = runtime_defs.get_managed_line_item_tier_key(tier_level)

  if not tier_key or tier_key == "yellow" then
    return base_name
  end

  return base_name .. "-" .. tier_key
end

function runtime_defs.get_generic_anchor_entity_name(kind, flow)
  return runtime_defs.GENERIC_ANCHOR_ENTITIES[get_generic_anchor_key(kind, flow)]
end

function runtime_defs.get_managed_line_item_tier_key(tier_level)
  for _, tier in ipairs(runtime_defs.MANAGED_LINE_ITEM_TIERS) do
    if tier.tier_level == tier_level then
      return tier.key
    end
  end

  return "yellow"
end

function runtime_defs.get_managed_line_item_tier_by_key(tier_key)
  for _, tier in ipairs(runtime_defs.MANAGED_LINE_ITEM_TIERS) do
    if tier.key == tier_key then
      return tier
    end
  end

  return runtime_defs.MANAGED_LINE_ITEM_TIERS[1]
end

function runtime_defs.get_researched_managed_line_item_tiers(force)
  local ingress_tier = runtime_defs.get_ingress_tier_level_for_force(force)
  local egress_tier = runtime_defs.get_egress_tier_level_for_force(force)
  local max_tier = math.max(ingress_tier, egress_tier)
  local tiers = {}

  for _, tier in ipairs(runtime_defs.MANAGED_LINE_ITEM_TIERS) do
    if tier.research_tier_level <= max_tier then
      tiers[#tiers + 1] = tier
    end
  end

  return tiers
end

local function are_all_force_technologies_researched(force, technology_names)
  if not technology_names then
    return false
  end

  if not (force and force.valid ~= false and force.technologies) then
    return false
  end

  for _, technology_name in ipairs(technology_names) do
    local technology = force.technologies[technology_name]

    if not (technology and technology.researched) then
      return false
    end
  end

  return true
end

function runtime_defs.is_config_definition_unlocked(definition, flow, force)
  if not definition then
    return false
  end

  if definition.starter_side then
    return true
  end

  local unlocks_by_flow = runtime_defs.CONFIG_RESOURCE_TECH_UNLOCKS[flow]
  local technology_names = unlocks_by_flow and unlocks_by_flow[definition.resource]

  if not technology_names then
    return false
  end

  return are_all_force_technologies_researched(force or runtime_defs.get_player_force(), technology_names)
end

function runtime_defs.get_config_recipe_name(resource, flow)
  return "the-square-configure-" .. resource .. "-" .. flow
end

function runtime_defs.parse_config_recipe_name(recipe_name)
  if type(recipe_name) ~= "string" then
    return nil, nil
  end

  local resource, flow = string.match(recipe_name, "^the%-square%-configure%-(.+)%-(ingress)$")
  if resource then
    return resource, flow
  end

  resource, flow = string.match(recipe_name, "^the%-square%-configure%-(.+)%-(egress)$")
  return resource, flow
end

function runtime_defs.get_config_definition(resource, flow, planet_name)
  if flow == "egress" then
    return runtime_defs.get_output_definition(resource, planet_name)
  end

  if flow == "ingress" then
    return runtime_defs.get_input_definition(resource, planet_name)
  end

  return nil
end

function runtime_defs.get_ingress_item_name(resource)
  local definition = runtime_defs.get_input_definition(resource)
  return runtime_defs.get_generic_anchor_item_name(definition and definition.kind or "item", "ingress")
end

local function get_input_kind_for_resource(resource)
  for _, definitions in pairs(runtime_defs.INPUT_DEFINITIONS_BY_PLANET) do
    for _, input_definition in ipairs(definitions) do
      if input_definition.resource == resource then
        return input_definition.kind
      end
    end
  end

  return nil
end

function runtime_defs.get_ingress_entity_name(resource, ingress_tier_level)
  if not resource then
    return runtime_defs.get_generic_anchor_entity_name("item", "ingress")
  end

  if get_input_kind_for_resource(resource) ~= "item" then
    return "the-square-" .. resource .. "-ingress-anchor"
  end

  local belt_tier_key = runtime_defs.ITEM_INGRESS_BELT_TIER_BY_INGRESS_TIER[ingress_tier_level or 1] or "yellow"

  if belt_tier_key == "yellow" then
    return "the-square-" .. resource .. "-ingress-anchor"
  end

  return "the-square-" .. resource .. "-ingress-anchor-" .. belt_tier_key
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

function runtime_defs.get_input_definitions(planet_name)
  return runtime_defs.INPUT_DEFINITIONS_BY_PLANET[planet_name or "nauvis"] or runtime_defs.INPUT_DEFINITIONS
end

function runtime_defs.get_output_definitions(planet_name)
  return runtime_defs.OUTPUT_DEFINITIONS_BY_PLANET[planet_name or "nauvis"] or runtime_defs.OUTPUT_DEFINITIONS
end

function runtime_defs.get_input_definition(resource, planet_name)
  for _, definition in ipairs(runtime_defs.get_input_definitions(planet_name)) do
    if definition.resource == resource then
      return definition
    end
  end

  return nil
end

function runtime_defs.get_output_definition(resource, planet_name)
  for _, definition in ipairs(runtime_defs.get_output_definitions(planet_name)) do
    if definition.resource == resource then
      return definition
    end
  end

  return nil
end

function runtime_defs.get_line_definition(resource, planet_name)
  local input_definition = runtime_defs.get_input_definition(resource, planet_name)

  if input_definition then
    return input_definition, "ingress"
  end

  local output_definition = runtime_defs.get_output_definition(resource, planet_name)

  if output_definition then
    return output_definition, "egress"
  end

  return nil, nil
end

function runtime_defs.get_egress_item_name(resource)
  local definition = runtime_defs.get_output_definition(resource)
  return runtime_defs.get_generic_anchor_item_name(definition and definition.kind or "item", "egress")
end

local function get_output_kind_for_resource(resource)
  for _, definitions in pairs(runtime_defs.OUTPUT_DEFINITIONS_BY_PLANET) do
    for _, output_definition in ipairs(definitions) do
      if output_definition.resource == resource then
        return output_definition.kind
      end
    end
  end

  return nil
end

function runtime_defs.get_egress_entity_name(resource, egress_tier_level)
  if not resource then
    return runtime_defs.get_generic_anchor_entity_name("item", "egress")
  end

  if get_output_kind_for_resource(resource) ~= "item" then
    return "the-square-" .. resource .. "-egress-anchor"
  end

  local belt_tier_key = runtime_defs.ITEM_EGRESS_BELT_TIER_BY_EGRESS_TIER[egress_tier_level or 1] or "yellow"

  if belt_tier_key == "yellow" then
    return "the-square-" .. resource .. "-egress-anchor"
  end

  return "the-square-" .. resource .. "-egress-anchor-" .. belt_tier_key
end

function runtime_defs.is_egress_entity_name_for_resource(resource, entity_name)
  if entity_name == runtime_defs.get_egress_entity_name(resource, 1) then
    return true
  end

  for tier_level = 2, runtime_defs.MAX_EGRESS_TIER do
    if entity_name == runtime_defs.get_egress_entity_name(resource, tier_level) then
      return true
    end
  end

  return false
end

function runtime_defs.get_anchor_presentation(flow, kind, resource)
  if flow == "egress" and kind == "item" then
    return "underground-belt-outward"
  end

  if flow == "egress" and kind == "fluid" then
    return "underground-pipe"
  end

  if kind == "fluid" then
    return "offshore-pump"
  end

  return "underground-belt-inward"
end

function runtime_defs.create_managed_anchor(definition, flow, side, position, tier_level)
  tier_level = tier_level or 1

  return {
    resource = definition.resource,
    kind = definition.kind,
    flow = flow,
    side = side,
    direction = side and runtime_defs.get_anchor_direction_for_side(flow, definition.kind, side) or nil,
    position = position,
    tier_level = tier_level,
    item_name = runtime_defs.get_generic_anchor_item_name_for_tier(definition.kind, flow, tier_level),
    entity_name = flow == "egress"
      and runtime_defs.get_egress_entity_name(definition.resource, tier_level)
      or runtime_defs.get_ingress_entity_name(definition.resource, tier_level),
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

  if flow == "egress" then
    return runtime_defs.REVERSED_DIRECTION_BY_SIDE[side]
  end

  return runtime_defs.DIRECTION_BY_SIDE[side]
end

local function get_setting_value(scope, setting_name, default_value)
  local setting = scope and scope[setting_name]
  local legacy_setting_name = runtime_defs.LEGACY_SETTING_NAMES[setting_name]
  local legacy_setting = legacy_setting_name and scope and scope[legacy_setting_name]

  if setting and setting.value ~= nil then
    return setting.value
  end

  if legacy_setting and legacy_setting.value ~= nil then
    return legacy_setting.value
  end

  return default_value
end

function runtime_defs.get_square_size()
  return get_setting_value(settings.startup, runtime_defs.SETTING_NAUVIS_STARTING_SQUARE_SIZE, 7)
end

function runtime_defs.get_expansion_tiles_per_research()
  return get_setting_value(settings.startup, runtime_defs.SETTING_EXPANSION_TILES_PER_RESEARCH, 7)
end

function runtime_defs.is_logistic_network_automation_enabled()
  return get_setting_value(settings.global, runtime_defs.SETTING_ENABLE_LOGISTIC_NETWORK_AUTOMATION, false)
end

function runtime_defs.get_square_bounds(size)
  return bootstrap_layout.get_square_bounds(size)
end

function runtime_defs.get_surface_size(square_size)
  return bootstrap_layout.get_surface_size(square_size, runtime_defs.STARTER_ANCHOR_OUTER_RING_WIDTH)
end

function runtime_defs.get_background_tile_name()
  return get_setting_value(settings.global, runtime_defs.SETTING_BACKGROUND_TILE, runtime_defs.DEFAULT_BACKGROUND_TILE_NAME)
end

function runtime_defs.get_screenshot_pixels_per_tile()
  return get_setting_value(settings.global, runtime_defs.SETTING_SCREENSHOT_PIXELS_PER_TILE, 32)
end

function runtime_defs.is_screenshot_alt_mode_enabled()
  return get_setting_value(settings.global, runtime_defs.SETTING_SCREENSHOT_ALT_MODE, true)
end

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

local function get_researched_tier_level_for_force(force, research_definitions)
  local tier_level = 1

  if not (force and force.valid and force.technologies) then
    return tier_level
  end

  for _, definition in ipairs(research_definitions) do
    local technology = force.technologies[definition.technology_name]

    if technology and technology.researched and definition.tier_level > tier_level then
      tier_level = definition.tier_level
    end
  end

  return tier_level
end

function runtime_defs.get_ingress_tier_level_for_force(force)
  return get_researched_tier_level_for_force(force, runtime_defs.INGRESS_RESEARCH_DEFINITIONS)
end

function runtime_defs.get_egress_tier_level_for_force(force)
  return get_researched_tier_level_for_force(force, runtime_defs.EGRESS_RESEARCH_DEFINITIONS)
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

function runtime_defs.get_expansion_research_planet_name(research_name)
  return expansion_research.get_planet_from_technology_name(research_name)
end

function runtime_defs.is_expansion_research_name(research_name)
  return expansion_research.is_expansion_technology_name(research_name)
end

function runtime_defs.is_inside_bounds(bounds, position)
  return bootstrap_layout.is_inside_bounds(bounds, position)
end

function runtime_defs.get_square_bounds(square_size)
  return bootstrap_layout.get_square_bounds(square_size)
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

function runtime_defs.get_anchor_side_for_position(square_size, position)
  return bootstrap_layout.get_anchor_side_for_position(square_size, position)
end

function runtime_defs.is_anchor_ring_position(square_size, position)
  return bootstrap_layout.is_anchor_ring_position(square_size, position)
end

function runtime_defs.get_managed_tile_name(square_size, surface_size, position, floor_tile_name)
  local background_tile_name = floor_tile_name or runtime_defs.get_background_tile_name()

  if not floor_tile_name
    and background_tile_name == runtime_defs.CHECKERBOARD_BACKGROUND_TILE_NAME
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

function runtime_defs.is_debug_space_age_planet_name(planet_name)
  for _, planet in ipairs(runtime_defs.DEBUG_SPACE_AGE_PLANETS) do
    if planet.name == planet_name then
      return true
    end
  end

  return false
end

function runtime_defs.format_position(position)
  if not position then
    return "(nil)"
  end

  return "(" .. position.x .. ", " .. position.y .. ")"
end

function runtime_defs.snap_entity_position_to_tile(position)
  if not position then
    return nil
  end

  return {
    x = math.floor(position.x),
    y = math.floor(position.y)
  }
end

function runtime_defs.get_current_egress_tier_level()
  local bootstrap = storage.bootstrap

  if not bootstrap then
    return 1
  end

  local tier_level = bootstrap.egress_tier or runtime_defs.get_current_ingress_tier_level()

  if tier_level < 1 then
    return 1
  end

  if tier_level > runtime_defs.MAX_EGRESS_TIER then
    return runtime_defs.MAX_EGRESS_TIER
  end

  return tier_level
end

function runtime_defs.get_anchor_entity_name_for_current_tier(anchor)
  if not anchor then
    return nil
  end

  if not anchor.resource then
    return runtime_defs.get_generic_anchor_entity_name(anchor.kind, anchor.flow)
  end

  if anchor.flow == "egress" then
    return runtime_defs.get_egress_entity_name(anchor.resource, anchor.tier_level or runtime_defs.get_current_egress_tier_level())
  end

  if anchor.kind == "item" then
    return runtime_defs.get_ingress_entity_name(anchor.resource, anchor.tier_level or runtime_defs.get_current_ingress_tier_level())
  end

  return runtime_defs.get_ingress_entity_name(anchor.resource, 1)
end

function runtime_defs.get_effective_ingress_tier_for_anchor(anchor)
  local tier_level = anchor and anchor.tier_level or 1

  if tier_level == 1 and runtime_defs.get_current_ingress_tier_level() >= 2 then
    tier_level = 2
  end

  return runtime_defs.get_ingress_tier_definition(tier_level)
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
