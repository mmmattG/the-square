local defs = require("lib.runtime_defs")
local planet_instance = require("lib.planet_instance")

local growth_runtime = {}

function growth_runtime.handle_expansion_research_finished(research, bootstrap_runtime, gui_runtime, anchor_runtime)
  if not (research and research.valid and research.force and defs.is_expansion_research_name(research.name)) then
    return false
  end

  local planet_name = defs.get_expansion_research_planet_name(research.name) or "nauvis"

  planet_instance.ensure(planet_name)

  bootstrap_runtime.expand_planet_square(planet_name, game.players[1], gui_runtime, anchor_runtime)

  local planet = planet_instance.ensure(planet_name)

  research.force.print({
    "message.the-square-expansion-research-completed",
    planet and planet:get_completed_square_expansion_levels() or 0,
    planet and planet:get_square_size() or 0
  })

  if gui_runtime then
    gui_runtime.refresh_all_debug_guis()
  end

  return true
end

return growth_runtime
