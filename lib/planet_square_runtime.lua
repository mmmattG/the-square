local defs = require("lib.runtime_defs")
local planet_instance = require("lib.planet_instance")
local planet_square = require("lib.planet_square")

local planet_square_runtime = {}

local function get_expanded_planet_message(result)
  return {"",
    "[the-square] Square expanded from ",
    result.previous_square_size,
    "x",
    result.previous_square_size,
    " to ",
    result.square_size,
    "x",
    result.square_size,
    "."
  }
end

function planet_square_runtime.expand(planet_name, options)
  options = options or {}
  planet_name = planet_name or "nauvis"

  local result = planet_square.apply_square_expansion(planet_name, {
    player = options.player,
    gui_runtime = options.gui_runtime,
    anchor_runtime = options.managed_line_runtime or options.anchor_runtime
  })

  if not result then
    return nil
  end

  if options.announce_global and game and game.print then
    game.print(get_expanded_planet_message(result))
  end

  if options.gui_runtime then
    options.gui_runtime.refresh_all_debug_guis()
  end

  return result
end

function planet_square_runtime.expand_after_research(research, options)
  options = options or {}

  if not (research and research.valid and research.force and defs.is_expansion_research_name(research.name)) then
    return false
  end

  local planet_name = defs.get_expansion_research_planet_name(research.name) or "nauvis"
  planet_instance.ensure(planet_name)

  planet_square_runtime.expand(planet_name, {
    player = options.player or (game and game.players and game.players[1]),
    gui_runtime = options.gui_runtime,
    managed_line_runtime = options.managed_line_runtime,
    anchor_runtime = options.anchor_runtime
  })

  local planet = planet_instance.ensure(planet_name)

  research.force.print({
    "message.the-square-expansion-research-completed",
    planet and planet:get_completed_square_expansion_levels() or 0,
    planet and planet:get_square_size() or 0
  })

  if options.gui_runtime then
    options.gui_runtime.refresh_all_debug_guis()
  end

  return true
end

return planet_square_runtime
