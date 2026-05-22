local defs = require("lib.runtime_defs")

local growth_runtime = {}

function growth_runtime.handle_expansion_research_finished(research, bootstrap_runtime, gui_runtime, anchor_runtime)
  if not (research and research.valid and research.force and defs.is_expansion_research_name(research.name)) then
    return false
  end

  storage.bootstrap = storage.bootstrap or {}
  bootstrap_runtime.ensure_bootstrap_state_defaults()
  storage.bootstrap.expansion_research_levels = defs.get_completed_expansion_research_levels() + 1
  bootstrap_runtime.expand_square(game.players[1], gui_runtime, anchor_runtime)

  if gui_runtime then
    gui_runtime.refresh_all_debug_guis()
  end

  research.force.print({
    "message.the-square-expansion-research-completed",
    storage.bootstrap.expansion_research_levels,
    storage.bootstrap.square_size
  })

  return true
end

return growth_runtime
