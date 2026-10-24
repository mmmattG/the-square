-- Dev mode travel between Planets for testing (Space Age only): unlock a Planet,
-- jump into a paused, indestructible debug platform in its orbit, or land straight
-- in its Square without the cargo pod ride.
local planet_state = require("lib.planet_state")
local square_runtime = require("lib.square_runtime")

local dev_travel_runtime = {}

local function ensure_storage()
  storage.debug_space_platforms = storage.debug_space_platforms or {}
  return storage.debug_space_platforms
end

local function get_force_key(force)
  return tostring(force.index or force.name or "unknown")
end

local function get_platform_name(force, planet_name)
  return "[the-square debug] " .. (force.name or "force") .. " " .. planet_name .. " orbit"
end

local function get_stored_platform(force, planet_name)
  local platforms_by_force = ensure_storage()[get_force_key(force)]
  local platform_index = platforms_by_force and platforms_by_force[planet_name]

  if not platform_index or not force.platforms then
    return nil
  end

  local platform = force.platforms[platform_index]

  if platform and platform.valid then
    return platform
  end

  platforms_by_force[planet_name] = nil
  return nil
end

local function find_existing_platform(force, planet_name)
  local expected_name = get_platform_name(force, planet_name)

  if not force.platforms then
    return nil
  end

  for _, platform in pairs(force.platforms) do
    if platform and platform.valid and platform.name == expected_name then
      return platform
    end
  end

  return nil
end

local function remember_platform(force, planet_name, platform)
  local platforms = ensure_storage()
  local force_key = get_force_key(force)

  platforms[force_key] = platforms[force_key] or {}
  platforms[force_key][planet_name] = platform.index
end

local function make_entity_indestructible(entity)
  if entity and entity.valid then
    entity.destructible = false
  end
end

local function make_platform_indestructible(platform)
  make_entity_indestructible(platform.hub)

  for _, entity in ipairs(platform.surface.find_entities_filtered({force = platform.force})) do
    make_entity_indestructible(entity)
  end
end

local function apply_starter_pack(platform)
  make_entity_indestructible(platform.apply_starter_pack())

  make_platform_indestructible(platform)
end

local function create_platform(force, planet_name)
  local platform = force.create_space_platform({
    name = get_platform_name(force, planet_name),
    planet = planet_name,
    starter_pack = {name = "space-platform-starter-pack", quality = "normal"}
  })

  if platform then
    platform.paused = true
    apply_starter_pack(platform)
    remember_platform(force, planet_name, platform)
  end

  return platform
end

function dev_travel_runtime.is_space_age_active()
  return script.active_mods["space-age"] ~= nil
end

local function ensure_platform(force, planet_name)
  local platform = get_stored_platform(force, planet_name) or find_existing_platform(force, planet_name)

  if platform then
    remember_platform(force, planet_name, platform)
    apply_starter_pack(platform)
    return platform
  end

  return create_platform(force, planet_name)
end

-- Space Age's technology that unlocks travel to a Planet. Nauvis has none.
function dev_travel_runtime.get_discovery_technology(force, planet_name)
  return force.technologies["planet-discovery-" .. planet_name]
end

function dev_travel_runtime.unlock_planet(force, planet_name)
  local technology = dev_travel_runtime.get_discovery_technology(force, planet_name)

  if technology then
    technology.researched = true
  end
end

-- A player sitting in a platform hub can't enter another platform, and teleporting a
-- player in remote view only moves the view. This puts the player back in control of
-- their character, wherever it stands.
local function return_to_character(player)
  if player.hub then
    player.leave_space_platform()
  end

  if player.controller_type == defines.controllers.remote then
    player.exit_remote_view()
  end
end

function dev_travel_runtime.go_to_orbit(player, planet_name)
  local platform = ensure_platform(player.force, planet_name)

  if not platform then
    return {ok = false, error = "Could not create a debug platform above " .. planet_name}
  end

  if player.hub and player.hub == platform.hub then
    return {ok = true}
  end

  return_to_character(player)

  if not player.enter_space_platform(platform) then
    return {ok = false, error = "Could not enter the debug platform above " .. planet_name}
  end

  return {ok = true}
end

-- Teleports the player's character into the Planet's Square. A Planet nobody has
-- visited has no surface yet, so this creates it; generating the Square's chunks
-- paints them and sets the Planet up, as a normal first landing would.
function dev_travel_runtime.land(player, planet_name)
  local surface = game.surfaces[planet_name] or game.planets[planet_name].create_surface()
  local planet = planet_state.get(planet_name)
  local center = planet:get_square_position()

  square_runtime.ensure_surface_dimensions(surface, planet:get_surface_size(), center)

  local position = surface.find_non_colliding_position("character", center, 16, 0.5) or center

  return_to_character(player)

  if not player.teleport(position, surface) then
    return {ok = false, error = "Could not land on " .. planet_name}
  end

  return {ok = true}
end

return dev_travel_runtime
