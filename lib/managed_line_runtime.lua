local anchor_runtime = require("lib.anchor_runtime")
local ingress_runtime = require("lib.ingress_runtime")
local managed_line_state = require("lib.managed_line_state")
local planet_config = require("lib.planet_config")

local managed_line_runtime = {}

-- Deep Managed Line seam. These are the preferred names for callers that work
-- with Planet-local Managed Lines. Legacy exports are re-exported below during
-- the migration so existing tests and modules can move incrementally.
function managed_line_runtime.get(planet_name)
  return managed_line_state.get(planet_name)
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

-- Compatibility exports from anchor_runtime.
for name, value in pairs(anchor_runtime) do
  if managed_line_runtime[name] == nil then
    managed_line_runtime[name] = value
  end
end

-- Compatibility exports from ingress_runtime.
for name, value in pairs(ingress_runtime) do
  if managed_line_runtime[name] == nil then
    managed_line_runtime[name] = value
  end
end

-- Compatibility exports from managed_line_state. Keep get/ensure pointing at
-- the deeper interface above.
for name, value in pairs(managed_line_state) do
  if managed_line_runtime[name] == nil then
    managed_line_runtime[name] = value
  end
end

managed_line_runtime.purchase_managed_line = managed_line_runtime.purchase
managed_line_runtime.purchase_managed_line_for_resource = managed_line_runtime.purchase
managed_line_runtime.sync_ingress_tier_from_research = managed_line_runtime.sync_tier

return managed_line_runtime
