-- Planet lifecycle: setting up the world, a Planet's first arrival, refreshing
-- after mod updates, and Square Expansion research.
local anchor_runtime = require("lib.anchor_runtime")
local expansion_research = require("lib.expansion_research")
local managed_line_state = require("lib.managed_line_state")
local mod_settings = require("lib.mod_settings")
local planet_catalog = require("lib.planet_catalog")
local planet_state = require("lib.planet_state")
local square_runtime = require("lib.square_runtime")

local planet_runtime = {}

-- The freeplay scenario's intro, crash site and starting drill don't fit a Square.
-- Other scenarios have no freeplay interface.
local function configure_freeplay()
  local freeplay = remote.interfaces.freeplay

  if not freeplay then
    return
  end

  if freeplay.set_skip_intro then
    remote.call("freeplay", "set_skip_intro", true)
  end

  if freeplay.set_disable_crashsite then
    remote.call("freeplay", "set_disable_crashsite", true)
  end

  if freeplay.get_created_items and freeplay.set_created_items then
    local created_items = remote.call("freeplay", "get_created_items")

    created_items["burner-mining-drill"] = nil
    remote.call("freeplay", "set_created_items", created_items)
  end
end

local function unlock_starter_research(planet_name)
  local technologies = game.forces.player.technologies

  for _, technology_name in ipairs(planet_catalog.get(planet_name).starter_research or {}) do
    if technologies[technology_name] then
      technologies[technology_name].researched = true
    end
  end
end

local function spawn_starter_entities(planet)
  local state = planet:get_state()

  if state.starter_entities_spawned then
    return
  end

  local surface = planet:get_surface()

  for _, starter_entity in ipairs(planet_catalog.get(planet:get_name()).starter_entities or {}) do
    local entity = surface.find_entities_filtered({name = starter_entity.name, position = starter_entity.position})[1]
      or surface.create_entity({
        name = starter_entity.name,
        position = starter_entity.position,
        force = "player",
        raise_built = false
      })

    -- create_entity returns nil when something blocks the spot; skip that entity.
    if entity and starter_entity.items then
      local inventory = entity.get_inventory(defines.inventory.chest)

      inventory.clear()

      for _, stack in ipairs(starter_entity.items) do
        inventory.insert(stack)
      end
    end
  end

  state.starter_entities_spawned = true
end

-- Sets up a Planet's Managed Lines and starter content once its surface exists, and
-- brings them up to date after a mod update.
function planet_runtime.refresh_planet(planet_name)
  local planet = planet_state.get(planet_name)

  if not planet:get_surface() then
    return
  end

  managed_line_state.initialize(planet_name)
  unlock_starter_research(planet_name)
  anchor_runtime.reconcile(planet_name)
  spawn_starter_entities(planet)
  planet:get_state().managed_lines_initialized = true
end

local function ensure_planet_initialized(planet_name)
  local planet = planet_state.get(planet_name)

  if not (planet:get_state().managed_lines_initialized and managed_line_state.get(planet_name)) then
    planet_runtime.refresh_planet(planet_name)
  end
end

-- Every new chunk on a Planet surface is painted as Square, Boundary or Void. The
-- first chunk on a Planet sets the Planet up.
function planet_runtime.handle_chunk_generated(surface, area)
  local planet = planet_state.for_surface(surface)

  if not planet then
    return
  end

  square_runtime.paint_chunk(planet, area)
  ensure_planet_initialized(planet:get_name())
end

-- Puts the player in Nauvis's Square and makes it the force's spawn point.
function planet_runtime.move_player_to_square(player)
  local planet = planet_state.get("nauvis")
  local surface = planet:get_surface()
  local position = planet:get_square_position()

  player.force.set_spawn_position(position, surface)
  player.teleport(position, surface)
  square_runtime.chart(player.force, planet)
end

-- Nauvis's stashed starting Managed Lines, given once to the first player to join.
function planet_runtime.grant_initial_line_items(player)
  local state = planet_state.get("nauvis"):get_state()

  if state.initial_managed_line_inventory_granted then
    return
  end

  for _, line in ipairs(managed_line_state.build_initial_lines("nauvis")) do
    player.insert({name = line.item_name, count = 1})
  end

  state.initial_managed_line_inventory_granted = true
end

local function clear_surface(surface)
  surface.destroy_decoratives({})
  surface.clear_hidden_tiles()

  for _, entity in ipairs(surface.find_entities()) do
    if entity.valid and entity.type ~= "character" then
      entity.destroy()
    end
  end
end

-- Turns Nauvis into a Square: runs on a new game, or when the mod is added to a save.
function planet_runtime.initialize_world()
  configure_freeplay()

  local planet = planet_state.get("nauvis")
  local surface = planet:get_surface()

  surface.peaceful_mode = true
  surface.no_enemies_mode = true
  square_runtime.ensure_surface_dimensions(surface, planet:get_surface_size(), planet:get_square_position())
  clear_surface(surface)
  square_runtime.paint_square(planet)
  game.forces.player.set_spawn_position({x = 0, y = 0}, surface)
  ensure_planet_initialized("nauvis")

  for _, player in pairs(game.players) do
    planet_runtime.move_player_to_square(player)
  end
end

local function notify_if_starting_size_changed()
  local planet = planet_state.get("nauvis")
  local starting_square_size = mod_settings.get_starting_square_size("nauvis")

  if planet:get_square_size() == starting_square_size then
    return
  end

  game.print({"",
    "[the-square] Starting square size changes only apply to new saves. ",
    "This save remains at ",
    planet:get_square_size(),
    " and the current map setting is ",
    starting_square_size,
    "."
  })
end

-- Brings every Planet up to date after the mod or its startup settings change.
function planet_runtime.handle_configuration_changed()
  if not (storage.planets and storage.planets.nauvis) then
    planet_runtime.initialize_world()
    return
  end

  for _, planet_name in ipairs(planet_catalog.SUPPORTED_PLANETS) do
    planet_runtime.refresh_planet(planet_name)
  end

  notify_if_starting_size_changed()

  local nauvis = planet_state.get("nauvis")

  square_runtime.repaint(nauvis)
  square_runtime.clear_chart(nauvis)
  configure_freeplay()
  game.forces.player.set_spawn_position(nauvis:get_square_position(), nauvis:get_surface())
  square_runtime.ensure_surface_dimensions(nauvis:get_surface(), nauvis:get_surface_size(), nauvis:get_square_position())
  anchor_runtime.reconcile("nauvis")

  for _, player in pairs(game.players) do
    planet_runtime.move_player_to_square(player)
  end
end

-- Grows the Planet a finished Square Expansion technology belongs to. Returns false
-- for other research.
function planet_runtime.handle_research_finished(research)
  local planet_name = expansion_research.get_planet_for_technology_name(research.name)

  if not planet_name then
    return false
  end

  if square_runtime.expand(planet_name) and game.players[1] then
    game.players[1].play_sound({path = "utility/new_objective"})
  end

  local planet = planet_state.get(planet_name)

  research.force.print({
    "message.the-square-expansion-research-completed",
    planet:get_completed_square_expansion_levels(),
    planet:get_square_size()
  })

  return true
end

-- The dev mode Expand button grows Nauvis without research.
function planet_runtime.expand_from_dev_button(player)
  local result = square_runtime.expand("nauvis")

  if not result then
    return
  end

  player.play_sound({path = "utility/new_objective"})
  game.print({"",
    "[the-square] Square expanded from ",
    result.previous_square_size, "x", result.previous_square_size,
    " to ",
    result.square_size, "x", result.square_size,
    "."
  })
end

return planet_runtime
