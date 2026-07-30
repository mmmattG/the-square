local defs = require("lib.runtime_defs")
local planet_config = require("lib.planet_config")
local planet_catalog = require("lib.planet_catalog")

local planet_instance = {}
local planet_methods = {}
planet_methods.__index = planet_methods

local function get_target_surface_size(square_size)
  return defs.get_surface_size(square_size)
end

local function ensure_planets_storage()
  storage.planets = storage.planets or {}
  return storage.planets
end

local function ensure_planet_state_defaults(planet_name, state)
  local config = planet_config.get(planet_name)

  if not config then
    return nil
  end

  state.name = planet_name
  state.surface_name = state.surface_name or config.surface_name

  local nauvis_catalog = planet_catalog.get("nauvis")
  local nauvis_default_square_size = nauvis_catalog and nauvis_catalog.default_square_size or 7

  if state.square_size == nil
    or (
      planet_catalog.get(planet_name) ~= nauvis_catalog
      and state.square_size == nauvis_default_square_size
      and (state.expansion_research_levels or 0) == 0
      and (state.expansions_completed or 0) == 0
    )
  then
    state.square_size = config.square_size
  end

  state.surface_size = defs.get_surface_size(state.square_size)
  state.floor_tile_name = state.floor_tile_name or config.floor_tile_name
  state.expansions_completed = state.expansions_completed or 0
  state.expansion_research_levels = state.expansion_research_levels or 0
  state.square_position = state.square_position or {x = 0, y = 0}

  if planet_name == "nauvis" then
    state.ingress_tier = state.ingress_tier or 1
    state.uranium_ore_progress_carry = state.uranium_ore_progress_carry or 0
    state.growth_progress = nil
    state.expansion_speed_research_levels = nil
  end

  return state
end

local function wrap_planet(state)
  return setmetatable({state = state}, planet_methods)
end

function planet_instance.ensure(planet_name)
  assert(planet_name, "planet_name is required")

  local planets = ensure_planets_storage()
  planets[planet_name] = planets[planet_name] or {}
  local state = ensure_planet_state_defaults(planet_name, planets[planet_name])

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

function planet_methods:get_square_size()
  return self.state.square_size
end

function planet_methods:get_name()
  return self.state.name
end

function planet_methods:get_square_position()
  local position = self.state.square_position or {x = 0, y = 0}

  return {x = position.x, y = position.y}
end

function planet_methods:set_square_position(position)
  self.state.square_position = {
    x = position and position.x or 0,
    y = position and position.y or 0
  }
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

function planet_methods:get_completed_square_expansion_levels()
  return self.state.expansion_research_levels or 0
end

function planet_methods:set_completed_square_expansion_levels(levels)
  self.state.expansion_research_levels = levels
end

function planet_methods:get_managed_lines()
  return self.state.starter_anchors
end

function planet_methods:get_state()
  return self.state
end

return planet_instance
