-- Per-Planet runtime state (Planet Instance and Planet Progression) in storage.planets.
-- The mod plays for the "player" force only.
local mod_settings = require("lib.mod_settings")
local planet_catalog = require("lib.planet_catalog")
local square_layout = require("lib.square_layout")

local planet_state = {}
local planet_methods = {}
planet_methods.__index = planet_methods

local function ensure_planet_state_defaults(planet_name, state)
  local planet = planet_catalog.get(planet_name)
  local starting_square_size = mod_settings.get_starting_square_size(planet_name)
  local nauvis_default_square_size = planet_catalog.get("nauvis").default_square_size

  state.name = planet_name
  state.surface_name = state.surface_name or planet_name

  if state.square_size == nil
    or (
      planet_name ~= "nauvis"
      and state.square_size == nauvis_default_square_size
      and (state.expansion_research_levels or 0) == 0
      and (state.expansions_completed or 0) == 0
    )
  then
    state.square_size = starting_square_size
  end

  state.surface_size = square_layout.get_surface_size(state.square_size)
  state.floor_tile_name = state.floor_tile_name or planet.floor_tile_name
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

-- The state of a supported Planet, created on first use. Errors for unsupported names.
function planet_state.get(planet_name)
  assert(planet_catalog.is_supported(planet_name), "unsupported planet: " .. tostring(planet_name))

  storage.planets = storage.planets or {}
  storage.planets[planet_name] = storage.planets[planet_name] or {}

  return setmetatable({state = ensure_planet_state_defaults(planet_name, storage.planets[planet_name])}, planet_methods)
end

-- The Planet whose Square is on this surface, or nil.
function planet_state.for_surface(surface)
  if not planet_catalog.is_supported(surface.name) then
    return nil
  end

  return planet_state.get(surface.name)
end

function planet_methods:get_name()
  return self.state.name
end

function planet_methods:get_surface()
  return game.surfaces[self.state.surface_name]
end

function planet_methods:get_surface_name()
  return self.state.surface_name
end

function planet_methods:set_surface_name(surface_name)
  self.state.surface_name = surface_name
end

function planet_methods:get_square_size()
  return self.state.square_size
end

function planet_methods:set_square_size(square_size)
  self.state.square_size = square_size
  self.state.surface_size = square_layout.get_surface_size(square_size)
end

function planet_methods:get_surface_size()
  return self.state.surface_size
end

function planet_methods:get_square_position()
  local position = self.state.square_position

  return {x = position.x, y = position.y}
end

function planet_methods:set_square_position(position)
  self.state.square_position = {x = position.x, y = position.y}
end

-- nil means "use the Background tile map setting" (Nauvis).
function planet_methods:get_floor_tile_name()
  return self.state.floor_tile_name
end

function planet_methods:get_completed_square_expansion_levels()
  return self.state.expansion_research_levels
end

function planet_methods:set_completed_square_expansion_levels(levels)
  self.state.expansion_research_levels = levels
  self.state.expansions_completed = levels
end

function planet_methods:get_managed_lines()
  return self.state.starter_anchors
end

function planet_methods:get_state()
  return self.state
end

return planet_state
