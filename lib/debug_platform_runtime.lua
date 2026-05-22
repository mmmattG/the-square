local defs = require("lib.runtime_defs")

local debug_platform_runtime = {}

local function ensure_storage()
  storage.debug_space_platforms = storage.debug_space_platforms or {}
  return storage.debug_space_platforms
end

local function get_force_key(force)
  return tostring(force.index or force.name or "unknown")
end

local function get_platform_name(force, planet_name)
  return "[the-square debug] " .. (force.name or "force") .. " " .. defs.format_resource_name(planet_name) .. " orbit"
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
  if entity and entity.valid and entity.destructible ~= nil then
    entity.destructible = false
  end
end

local function make_platform_indestructible(platform)
  make_entity_indestructible(platform.hub)

  if not (platform.surface and platform.surface.find_entities_filtered) then
    return
  end

  for _, entity in ipairs(platform.surface.find_entities_filtered({force = platform.force})) do
    make_entity_indestructible(entity)
  end
end

local function apply_starter_pack(platform)
  if platform.apply_starter_pack then
    make_entity_indestructible(platform:apply_starter_pack())
  end

  make_platform_indestructible(platform)
end

local function create_platform(force, planet_name)
  if not force.create_space_platform then
    return nil, "This Factorio runtime does not expose space platform creation."
  end

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

function debug_platform_runtime.is_space_age_active()
  return script and script.active_mods and script.active_mods["space-age"] ~= nil
end

function debug_platform_runtime.get_button_planet_name(element_name)
  return string.match(element_name or "", "^" .. defs.DEV_ORBIT_TELEPORT_BUTTON_PREFIX .. "(.+)$")
end

function debug_platform_runtime.ensure_platform(force, planet_name)
  if not (force and planet_name and defs.is_debug_space_age_planet_name(planet_name)) then
    return nil, "Unknown debug planet: " .. tostring(planet_name)
  end

  local platform = get_stored_platform(force, planet_name) or find_existing_platform(force, planet_name)

  if platform then
    remember_platform(force, planet_name, platform)
    apply_starter_pack(platform)
    return platform
  end

  return create_platform(force, planet_name)
end

function debug_platform_runtime.teleport_player_to_planet_platform(player, planet_name)
  if not (player and player.valid and player.force) then
    return {ok = false, error = "Invalid player"}
  end

  local platform, err = debug_platform_runtime.ensure_platform(player.force, planet_name)

  if not platform then
    return {ok = false, error = err or "Could not create debug space platform"}
  end

  if not player.enter_space_platform then
    return {ok = false, error = "This Factorio runtime does not expose player space platform entry."}
  end

  local ok = player.enter_space_platform(platform)

  if not ok then
    return {ok = false, error = "Could not enter debug space platform"}
  end

  return {ok = true, platform = platform}
end

return debug_platform_runtime
