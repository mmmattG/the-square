-- Per-Planet runtime state (Planet Instance and Planet Progression), one table per
-- Planet in storage.planets. The mod plays for the "player" force only.
--
--   square_size                 current Square width in tiles
--   square_position             tile the Square is centred on (Move Square changes it)
--   expansion_research_levels   Square Expansion levels completed on this Planet
--   managed_lines               see managed_line_state
--   managed_lines_initialized   set once the Planet's lines and starter content exist
--   starter_entities_spawned, initial_managed_line_inventory_granted
--                               one-time setup flags
--   uranium_sulfuric_acid_buffer, uranium_ore_progress_carry
--                               Nauvis uranium budget, see managed_line_pump
local mod_settings = require("lib.mod_settings")
local planet_catalog = require("lib.planet_catalog")
local square_layout = require("lib.square_layout")

local planet_state = {}
local planet_methods = {}
planet_methods.__index = planet_methods

-- The state of a supported Planet, created with defaults on first use.
function planet_state.get(planet_name)
  assert(planet_catalog.is_supported(planet_name), "unsupported planet: " .. tostring(planet_name))

  storage.planets = storage.planets or {}

  if not storage.planets[planet_name] then
    storage.planets[planet_name] = {
      square_size = mod_settings.get_starting_square_size(planet_name),
      square_position = {x = 0, y = 0},
      expansion_research_levels = 0
    }
  end

  return setmetatable({name = planet_name, state = storage.planets[planet_name]}, planet_methods)
end

-- The Planet whose Square is on this surface, or nil.
function planet_state.for_surface(surface)
  if not planet_catalog.is_supported(surface.name) then
    return nil
  end

  return planet_state.get(surface.name)
end

function planet_methods:get_name()
  return self.name
end

-- Each Planet's Square is on the surface of the same name. Nil until someone arrives.
function planet_methods:get_surface()
  return game.surfaces[self.name]
end

function planet_methods:get_square_size()
  return self.state.square_size
end

function planet_methods:set_square_size(square_size)
  self.state.square_size = square_size
end

-- The Square plus its Boundary ring.
function planet_methods:get_surface_size()
  return square_layout.get_surface_size(self.state.square_size)
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
  return planet_catalog.get(self.name).floor_tile_name
end

function planet_methods:get_completed_square_expansion_levels()
  return self.state.expansion_research_levels
end

function planet_methods:set_completed_square_expansion_levels(levels)
  self.state.expansion_research_levels = levels
end

function planet_methods:get_managed_lines()
  return self.state.managed_lines
end

function planet_methods:get_state()
  return self.state
end

return planet_state
