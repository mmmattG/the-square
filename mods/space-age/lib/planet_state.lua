local planet_catalog = require("lib.planet_catalog")

local planet_state = {}

local function create_default_state(definition)
  local config = definition.config or {}
  local square_config = config.square or {}
  local economy_config = config.economy or {}

  return {
    planet_key = definition.key,
    surface_name = definition.surface_name,
    square_size = square_config.starting_size or definition.starting_square_size,
    surface_size = nil,
    expansions_completed = 0,
    expansion_points = economy_config.starting_expansion_points or 0,
    ingress_tier = 1,
    expansion_research_levels = 0,
    uranium_ore_progress_carry = 0
  }
end

function planet_state.ensure_storage()
  storage.planets = storage.planets or {}
  return storage.planets
end

function planet_state.ensure_planet(planet_key)
  local definition = planet_catalog.get_planet(planet_key)

  if not definition then
    error("Unknown planet key: " .. tostring(planet_key))
  end

  local planets = planet_state.ensure_storage()
  planets[planet_key] = planets[planet_key] or create_default_state(definition)
  return planets[planet_key]
end

function planet_state.ensure_all_planets()
  for _, definition in ipairs(planet_catalog.get_all()) do
    planet_state.ensure_planet(definition.key)
  end

  return storage.planets
end

function planet_state.get_planet(planet_key)
  local planets = storage.planets
  return planets and planets[planet_key] or nil
end

function planet_state.get_planet_for_surface(surface_name)
  local definition = planet_catalog.get_planet_for_surface(surface_name)
  return definition and planet_state.get_planet(definition.key) or nil
end

function planet_state.get_or_create_for_surface(surface_name)
  local definition = planet_catalog.get_planet_for_surface(surface_name)

  if not definition then
    return nil
  end

  return planet_state.ensure_planet(definition.key)
end

function planet_state.add_expansion_points(planet_key, amount)
  local state = planet_state.ensure_planet(planet_key)
  state.expansion_points = (state.expansion_points or 0) + amount
  return state.expansion_points
end

function planet_state.try_spend_expansion_points(planet_key, amount)
  local state = planet_state.ensure_planet(planet_key)

  if (state.expansion_points or 0) < amount then
    return false, state.expansion_points or 0
  end

  state.expansion_points = state.expansion_points - amount
  return true, state.expansion_points
end

function planet_state.sync_planet_from_bootstrap(planet_key, bootstrap)
  if not bootstrap then
    return nil
  end

  local state = planet_state.ensure_planet(planet_key)

  state.surface_name = bootstrap.surface_name or state.surface_name
  state.square_size = bootstrap.square_size or state.square_size
  state.surface_size = bootstrap.surface_size or state.surface_size
  state.expansions_completed = bootstrap.expansions_completed or state.expansions_completed
  state.expansion_points = bootstrap.expansion_points or state.expansion_points
  state.ingress_tier = bootstrap.ingress_tier or state.ingress_tier
  state.expansion_research_levels = bootstrap.expansion_research_levels or state.expansion_research_levels
  state.uranium_ore_progress_carry = bootstrap.uranium_ore_progress_carry or state.uranium_ore_progress_carry

  return state
end

return planet_state
