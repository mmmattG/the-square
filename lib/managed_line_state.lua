local bootstrap_runtime = require("lib.bootstrap_runtime")
local defs = require("lib.runtime_defs")
local planet_instance = require("lib.planet_instance")

local managed_line_state = {}

local function migrate_anchor_to_anchor_ring(square_size, anchor)
  if not (anchor and anchor.position and anchor.side) then
    return
  end

  if defs.get_anchor_side_for_position(square_size, anchor.position) then
    return
  end

  anchor.position = defs.move_position(anchor.position, anchor.side, 1)
  anchor.direction = defs.get_anchor_direction_for_side(anchor.flow, anchor.kind, anchor.side)
  anchor.entity = nil
end

local function normalize_anchor(anchor, square_size)
  anchor.flow = anchor.flow or "ingress"
  anchor.item_progress = anchor.item_progress or {0, 0}
  anchor.item_name = defs.get_generic_anchor_item_name(anchor.kind or "item", anchor.flow)
  if anchor.position then
    anchor.entity_name = defs.get_generic_anchor_entity_name(anchor.kind or "item", anchor.flow)
  else
    anchor.entity_name = anchor.entity_name or defs.get_generic_anchor_entity_name(anchor.kind or "item", anchor.flow)
  end
  anchor.direction = anchor.side and defs.get_anchor_direction_for_side(anchor.flow, anchor.kind, anchor.side) or nil
  migrate_anchor_to_anchor_ring(square_size, anchor)
end

local function migrate_legacy_nauvis_state(bootstrap)
  if not (storage.starter_anchors and storage.starter_anchors.layout_version ~= defs.STARTER_ANCHOR_LAYOUT_VERSION) then
    return
  end

  local migrated_anchors = storage.starter_anchors.anchors or {}

  for _, anchor in ipairs(migrated_anchors) do
    anchor.flow = anchor.flow or "ingress"
    anchor.item_progress = anchor.item_progress or {0, 0}
    anchor.direction = anchor.side and defs.get_anchor_direction_for_side(anchor.flow, anchor.kind, anchor.side) or nil
    anchor.item_name = anchor.item_name or (
      anchor.flow == "egress"
        and defs.get_egress_item_name(anchor.resource)
        or defs.get_ingress_item_name(anchor.resource)
    )
    anchor.entity_name = anchor.entity_name or (
      anchor.flow == "egress"
        and defs.get_egress_entity_name(anchor.resource)
        or defs.get_ingress_entity_name(anchor.resource, 1)
    )
    anchor.entity = nil
    migrate_anchor_to_anchor_ring(bootstrap.square_size, anchor)
  end

  storage.starter_anchors = {
    layout_version = defs.STARTER_ANCHOR_LAYOUT_VERSION,
    anchors = migrated_anchors
  }
end

function managed_line_state.get(planet_name)
  planet_name = planet_name or "nauvis"

  if planet_name == "nauvis" then
    return storage.starter_anchors
  end

  local planet_state = storage.planets and storage.planets[planet_name]
  return planet_state and planet_state.starter_anchors or nil
end

function managed_line_state.ensure(planet_name)
  planet_name = planet_name or "nauvis"
  local planet = planet_instance.ensure(planet_name)

  if not planet then
    return nil
  end

  local state

  if planet_name == "nauvis" then
    local bootstrap = planet:get_bootstrap_storage()
    migrate_legacy_nauvis_state(bootstrap)
    storage.starter_anchors = storage.starter_anchors or {
      layout_version = defs.STARTER_ANCHOR_LAYOUT_VERSION,
      anchors = bootstrap_runtime.build_starter_anchor_layout(bootstrap.square_size)
    }
    state = storage.starter_anchors
  else
    local bootstrap = planet:get_bootstrap_storage()
    bootstrap.starter_anchors = bootstrap.starter_anchors or {
      layout_version = defs.STARTER_ANCHOR_LAYOUT_VERSION,
      anchors = bootstrap_runtime.build_starter_anchor_layout(planet:get_square_size(), planet_name)
    }
    state = bootstrap.starter_anchors
  end

  for _, anchor in ipairs(state.anchors) do
    normalize_anchor(anchor, planet:get_square_size())
  end

  return state
end

return managed_line_state
