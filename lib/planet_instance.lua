local defs = require("lib.runtime_defs")
local planet_config = require("lib.planet_config")
local planet_catalog = require("lib.planet_catalog")

local planet_instance = {}
local planet_methods = {}
planet_methods.__index = planet_methods

local function get_target_surface_size(square_size)
  return defs.get_surface_size(square_size)
end

local function clear_managed_line_entity_refs(state)
  local starter_anchors = state and state.starter_anchors or storage and storage.starter_anchors
  if not (starter_anchors and starter_anchors.anchors) then
    return
  end

  for _, anchor in ipairs(starter_anchors.anchors) do
    anchor.entity = nil
  end
end

local function ensure_bootstrap_defaults(bootstrap)
  bootstrap.square_size = bootstrap.square_size or defs.get_square_size()
  local target_surface_size = get_target_surface_size(bootstrap.square_size)

  if not bootstrap.surface_name or bootstrap.surface_name == defs.LEGACY_SURFACE_NAME then
    bootstrap.surface_name = defs.SURFACE_NAME
    clear_managed_line_entity_refs(bootstrap)
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
  state.expansion_points = state.expansion_points or 0
  state.expansions_completed = state.expansions_completed or 0
  state.expansion_research_levels = state.expansion_research_levels or 0

  return state
end

local function wrap_planet(state)
  return setmetatable({state = state}, planet_methods)
end

local function migrate_nauvis_state()
  local planets = ensure_planets_storage()
  local state = storage.bootstrap or planets.nauvis or {}

  if planets.nauvis and planets.nauvis ~= state then
    for key, value in pairs(planets.nauvis) do
      if state[key] == nil then
        state[key] = value
      end
    end
  end

  if storage.starter_anchors then
    state.starter_anchors = storage.starter_anchors
  end

  planets.nauvis = ensure_bootstrap_defaults(state)
  storage.bootstrap = planets.nauvis
  storage.starter_anchors = planets.nauvis.starter_anchors

  return planets.nauvis
end

function planet_instance.ensure_nauvis()
  return wrap_planet(migrate_nauvis_state())
end

function planet_instance.from_bootstrap(bootstrap)
  if not bootstrap then
    return nil
  end

  storage.bootstrap = bootstrap
  return planet_instance.ensure_nauvis()
end

local ensure_overrides = {
  nauvis = planet_instance.ensure_nauvis
}

function planet_instance.ensure(planet_name)
  planet_name = planet_name or "nauvis"

  local ensure_override = ensure_overrides[planet_name]
  if ensure_override then
    return ensure_override()
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
  return self.state.starter_anchors
end

function planet_methods:get_bootstrap_storage()
  return self.state
end

return planet_instance
