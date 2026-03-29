local defs = require("lib.runtime_defs")
local expansion_research = require("lib.expansion_research")

local growth_runtime = {}

local function get_starting_square_size_for_save()
  local bootstrap = storage.bootstrap

  if bootstrap and bootstrap.square_size then
    return expansion_research.get_starting_square_size(
      bootstrap.square_size,
      defs.get_completed_expansion_research_levels()
    )
  end

  return defs.get_square_size()
end

function growth_runtime.apply_expansion_research_costs_to_force(force)
  if not (force and force.valid) then
    return
  end

  local starting_square_size = get_starting_square_size_for_save()
  local tiles_per_research = defs.get_expansion_tiles_per_research()

  for _, band in ipairs(defs.EXPANSION_RESEARCH_BANDS) do
    local technology = force.technologies[band.name]

    if technology and technology.valid then
      technology.research_unit_count = expansion_research.get_research_unit_count(
        starting_square_size,
        tiles_per_research,
        technology.level
      )
    end
  end
end

function growth_runtime.apply_expansion_research_costs_to_all_forces()
  for _, force in pairs(game.forces) do
    growth_runtime.apply_expansion_research_costs_to_force(force)
  end
end

function growth_runtime.handle_expansion_research_finished(research, bootstrap_runtime, gui_runtime, anchor_runtime)
  if not (research and research.valid and research.force and defs.is_expansion_research_name(research.name)) then
    return false
  end

  storage.bootstrap = storage.bootstrap or {}
  bootstrap_runtime.ensure_bootstrap_state_defaults()
  storage.bootstrap.expansion_research_levels = defs.get_completed_expansion_research_levels() + 1
  bootstrap_runtime.expand_square(game.players[1], gui_runtime, anchor_runtime)
  growth_runtime.apply_expansion_research_costs_to_force(research.force)

  if gui_runtime then
    gui_runtime.refresh_all_status_guis()
    gui_runtime.refresh_all_debug_guis()
  end

  research.force.print({
    "message.fes-expansion-research-completed",
    storage.bootstrap.expansion_research_levels,
    storage.bootstrap.square_size
  })

  return true
end

return growth_runtime
