local anchor_runtime = require("lib.anchor_runtime")
local ingress_runtime = require("lib.ingress_runtime")
local managed_line_state = require("lib.managed_line_state")
local planet_config = require("lib.planet_config")

local managed_line_runtime = {}

function managed_line_runtime.get(planet_name)
  return managed_line_state.get(planet_name)
end

function managed_line_runtime.ensure_state(planet_name)
  return managed_line_state.ensure(planet_name or "nauvis")
end

function managed_line_runtime.ensure(planet_name)
  planet_name = planet_name or "nauvis"
  managed_line_state.ensure(planet_name)
  return anchor_runtime.ensure_planet_starter_anchors(planet_name)
end

function managed_line_runtime.ensure_all()
  for _, planet_name in ipairs(planet_config.SUPPORTED_PLANETS) do
    managed_line_runtime.ensure(planet_name)
  end
end

function managed_line_runtime.pump(planet_name)
  planet_name = planet_name or "nauvis"
  return ingress_runtime.pump_planet_anchors(planet_name)
end

function managed_line_runtime.pump_all()
  for _, planet_name in ipairs(planet_config.SUPPORTED_PLANETS) do
    managed_line_runtime.pump(planet_name)
  end
end

function managed_line_runtime.purchase(player, resource)
  return anchor_runtime.purchase_managed_line_for_resource(player, resource)
end

function managed_line_runtime.sync_tier(force)
  return anchor_runtime.sync_anchor_tiers_from_research(force)
end

function managed_line_runtime.handle_built(event, gui_runtime)
  return anchor_runtime.handle_entity_built(event, gui_runtime)
end

function managed_line_runtime.handle_mined(entity)
  return anchor_runtime.handle_anchor_mined(entity)
end

function managed_line_runtime.handle_rotated(entity)
  return anchor_runtime.reset_rotated_anchor(entity)
end

function managed_line_runtime.handle_gui_opened(entity, player)
  return anchor_runtime.handle_anchor_gui_opened(entity, player)
end

function managed_line_runtime.handle_recipe_changed(entity, actor)
  return anchor_runtime.handle_anchor_recipe_changed(entity, actor)
end

function managed_line_runtime.handle_slot_click(player)
  return anchor_runtime.handle_managed_anchor_slot_click(player)
end

function managed_line_runtime.apply_logistic_network_setting_to_all_forces()
  return anchor_runtime.apply_logistic_network_setting_to_all_forces()
end

function managed_line_runtime.apply_logistic_network_setting_to_force(force)
  return anchor_runtime.apply_logistic_network_setting_to_force(force)
end

function managed_line_runtime.get_owned_line_counts(resource)
  return anchor_runtime.get_owned_line_counts(resource)
end

function managed_line_runtime.is_resource_unlocked(resource)
  return anchor_runtime.is_resource_unlocked(resource)
end

function managed_line_runtime.unlock_planet_bootstrap_research(planet_name, force)
  return anchor_runtime.unlock_planet_bootstrap_research(planet_name, force)
end

return managed_line_runtime
