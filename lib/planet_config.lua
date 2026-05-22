local defs = require("lib.runtime_defs")

local planet_config = {}

planet_config.SUPPORTED_PLANETS = {"nauvis", "vulcanus", "fulgora", "gleba", "aquilo"}

local labels = {
  nauvis = "Nauvis",
  vulcanus = "Vulcanus",
  fulgora = "Fulgora",
  gleba = "Gleba",
  aquilo = "Aquilo"
}

local defaults = {
  nauvis = 7,
  vulcanus = 7,
  fulgora = 7,
  gleba = 7,
  aquilo = 7
}

local function get_setting_value(scope, setting_name, default_value)
  local setting = scope and scope[setting_name]

  if setting and setting.value ~= nil then
    return setting.value
  end

  return default_value
end

function planet_config.get_starting_square_size_setting_name(planet_name)
  return "the-square-" .. planet_name .. "-starting-square-size"
end

function planet_config.is_supported_planet(planet_name)
  return labels[planet_name] ~= nil
end

function planet_config.get(planet_name)
  if not planet_config.is_supported_planet(planet_name) then
    return nil
  end

  local default_square_size = defaults[planet_name] or 7
  local square_size = get_setting_value(
    settings.startup,
    planet_config.get_starting_square_size_setting_name(planet_name),
    nil
  )

  if square_size == nil and planet_name == "nauvis" then
    square_size = defs.get_square_size()
  end

  square_size = square_size or default_square_size

  return {
    name = planet_name,
    label = labels[planet_name],
    surface_name = planet_name,
    square_size = square_size,
    surface_size = defs.get_surface_size(square_size)
  }
end

function planet_config.each_supported_planet()
  local index = 0

  return function()
    index = index + 1
    local planet_name = planet_config.SUPPORTED_PLANETS[index]

    if planet_name then
      return planet_config.get(planet_name)
    end
  end
end

return planet_config
