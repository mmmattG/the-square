local defs = require("lib.runtime_defs")
local planet_config = require("lib.planet_config")

local planet_instance = {}
local planet_methods = {}
planet_methods.__index = planet_methods
local nauvis_methods = {}
nauvis_methods.__index = nauvis_methods

local function get_target_surface_size(square_size)
  return defs.get_surface_size(square_size)
end

local function clear_managed_line_entity_refs()
  if not (storage and storage.starter_anchors and storage.starter_anchors.anchors) then
    return
  end

  for _, anchor in ipairs(storage.starter_anchors.anchors) do
    anchor.entity = nil
  end
end

local function ensure_bootstrap_defaults(bootstrap)
  bootstrap.square_size = bootstrap.square_size or defs.get_square_size()
  local target_surface_size = get_target_surface_size(bootstrap.square_size)

  if not bootstrap.surface_name or bootstrap.surface_name == defs.LEGACY_SURFACE_NAME then
    bootstrap.surface_name = defs.SURFACE_NAME
    clear_managed_line_entity_refs()
  end
  bootstrap.surface_size = target_surface_size
  bootstrap.expansion_points = bootstrap.expansion_points or 0
  bootstrap.expansions_completed = bootstrap.expansions_completed or 0
  bootstrap.ingress_tier = bootstrap.ingress_tier or 1
  bootstrap.expansion_research_levels = bootstrap.expansion_research_levels or 0
  bootstrap.uranium_ore_progress_carry = bootstrap.uranium_ore_progress_carry or 0
  bootstrap.growth_progress = nil
  bootstrap.expansion_speed_research_levels = nil

  return bootstrap
end

local function wrap_bootstrap(bootstrap)
  return setmetatable({bootstrap = bootstrap}, nauvis_methods)
end

local function ensure_planets_storage()
  storage.planets = storage.planets or {}
  return storage.planets
end

local function ensure_planet_defaults(planet_name, state)
  local config = planet_config.get(planet_name)

  if not config then
    return nil
  end

  state.name = planet_name
  state.surface_name = state.surface_name or config.surface_name
  state.square_size = state.square_size or config.square_size
  state.surface_size = defs.get_surface_size(state.square_size)
  state.floor_tile_name = state.floor_tile_name or config.floor_tile_name
  state.expansion_points = state.expansion_points or 0
  state.expansions_completed = state.expansions_completed or 0
  state.expansion_research_levels = state.expansion_research_levels or 0

  return state
end

local function wrap_planet(state)
  return setmetatable({state = state}, planet_methods)
end

function planet_instance.ensure_nauvis()
  if not storage.bootstrap then
    return nil
  end

  return wrap_bootstrap(ensure_bootstrap_defaults(storage.bootstrap))
end

function planet_instance.from_bootstrap(bootstrap)
  if not bootstrap then
    return nil
  end

  return wrap_bootstrap(ensure_bootstrap_defaults(bootstrap))
end

function planet_instance.ensure(planet_name)
  if planet_name == "nauvis" then
    if storage.bootstrap then
      return planet_instance.ensure_nauvis()
    end

    local config = planet_config.get("nauvis")
    storage.bootstrap = {
      square_size = config.square_size,
      surface_name = config.surface_name
    }
    return planet_instance.ensure_nauvis()
  end

  local planets = ensure_planets_storage()
  planets[planet_name] = planets[planet_name] or {}
  local state = ensure_planet_defaults(planet_name, planets[planet_name])

  if not state then
    planets[planet_name] = nil
    return nil
  end

  return wrap_planet(state)
end

function planet_instance.for_surface(surface_name)
  if not planet_config.is_supported_planet(surface_name) then
    return nil
  end

  return planet_instance.ensure(surface_name)
end

function nauvis_methods:get_square_size()
  return self.bootstrap.square_size
end

function nauvis_methods:set_square_size(square_size)
  self.bootstrap.square_size = square_size
  self.bootstrap.surface_size = get_target_surface_size(square_size)
end

function nauvis_methods:get_surface_name()
  return self.bootstrap.surface_name
end

function nauvis_methods:set_surface_name(surface_name)
  self.bootstrap.surface_name = surface_name
end

function nauvis_methods:get_surface_size()
  return self.bootstrap.surface_size
end

function nauvis_methods:get_floor_tile_name()
  return nil
end

function nauvis_methods:get_expansion_points()
  return self.bootstrap.expansion_points or 0
end

function nauvis_methods:add_expansion_points(amount)
  self.bootstrap.expansion_points = self:get_expansion_points() + amount
end

function nauvis_methods:get_completed_square_expansion_levels()
  return self.bootstrap.expansion_research_levels or 0
end

function nauvis_methods:set_completed_square_expansion_levels(levels)
  self.bootstrap.expansion_research_levels = levels
end

function nauvis_methods:get_managed_lines()
  return storage.starter_anchors
end

function nauvis_methods:get_bootstrap_storage()
  return self.bootstrap
end

function planet_methods:get_square_size()
  return self.state.square_size
end

function planet_methods:set_square_size(square_size)
  self.state.square_size = square_size
  self.state.surface_size = get_target_surface_size(square_size)
end

function planet_methods:get_surface_name()
  return self.state.surface_name
end

function planet_methods:set_surface_name(surface_name)
  self.state.surface_name = surface_name
end

function planet_methods:get_surface_size()
  return self.state.surface_size
end

function planet_methods:get_floor_tile_name()
  return self.state.floor_tile_name
end

function planet_methods:get_expansion_points()
  return self.state.expansion_points or 0
end

function planet_methods:add_expansion_points(amount)
  self.state.expansion_points = self:get_expansion_points() + amount
end

function planet_methods:get_completed_square_expansion_levels()
  return self.state.expansion_research_levels or 0
end

function planet_methods:set_completed_square_expansion_levels(levels)
  self.state.expansion_research_levels = levels
end

function planet_methods:get_managed_lines()
  return nil
end

function planet_methods:get_bootstrap_storage()
  return self.state
end

return planet_instance
