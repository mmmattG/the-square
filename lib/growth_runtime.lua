local planet_square_runtime = require("lib.planet_square_runtime")

local growth_runtime = {}

function growth_runtime.handle_expansion_research_finished(research, bootstrap_runtime, gui_runtime, anchor_runtime)
  return planet_square_runtime.expand_after_research(research, {
    gui_runtime = gui_runtime,
    anchor_runtime = anchor_runtime
  })
end

return growth_runtime
