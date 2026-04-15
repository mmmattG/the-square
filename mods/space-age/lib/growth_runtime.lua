local defs = require("lib.runtime_defs")
local expansion_research = require("lib.expansion_research")
local planet_state = require("lib.planet_state")

local growth_runtime = {}

function growth_runtime.handle_expansion_research_finished(research, bootstrap_runtime, gui_runtime, anchor_runtime)
  if not (research and research.valid and research.force and defs.is_expansion_research_name(research.name)) then
    return false
  end

  local research_definition = expansion_research.get_definition_from_technology_name(research.name)

  if not research_definition then
    return false
  end

  local state = planet_state.ensure_planet(research_definition.planet_key)
  state.expansion_research_levels = research_definition.level

  if research_definition.planet_key == "nauvis" then
    storage.bootstrap = storage.bootstrap or {}
    bootstrap_runtime.ensure_bootstrap_state_defaults()
    storage.bootstrap.expansion_research_levels = research_definition.level
  end

  if not bootstrap_runtime.expand_planet_square(research_definition.planet_key, game.players[1], gui_runtime, anchor_runtime) then
    return false
  end

  if gui_runtime then
    gui_runtime.refresh_all_debug_guis()
  end

  research.force.print({
    "message.fes-expansion-research-completed",
    research_definition.level,
    state.square_size
  })

  return true
end

return growth_runtime
