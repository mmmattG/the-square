local planet_runtime = require("lib.planet_runtime")
local defs = require("lib.runtime_defs")
local planet_instance = require("lib.planet_instance")

local managed_line_state = {}

local function migrate_anchor_to_anchor_ring(square_size, anchor, square_position)
  if not (anchor and anchor.position and anchor.side) then
    return
  end

  if defs.get_anchor_side_for_position(square_size, anchor.position, square_position) then
    return
  end

  anchor.position = defs.move_position(anchor.position, anchor.side, 1)
  anchor.direction = defs.get_anchor_direction_for_side(anchor.flow, anchor.kind, anchor.side)
  anchor.entity = nil
end

local function normalize_anchor(anchor, square_size, square_position)
  if anchor.position and not anchor.resource and not (anchor.kind or anchor.flow) then
    anchor.item_progress = anchor.item_progress or {0, 0}
    migrate_anchor_to_anchor_ring(square_size, anchor, square_position)
    return
  end

  anchor.flow = anchor.flow or "ingress"
  anchor.item_progress = anchor.item_progress or {0, 0}
  anchor.item_name = defs.get_generic_anchor_item_name_for_tier(anchor.kind or "item", anchor.flow, anchor.tier_level or 1)
  if anchor.position then
    anchor.entity_name = defs.get_anchor_entity_name_for_current_tier(anchor)
  else
    anchor.entity_name = anchor.entity_name or defs.get_generic_anchor_entity_name(anchor.kind or "item", anchor.flow)
  end
  anchor.direction = anchor.side and defs.get_anchor_direction_for_side(anchor.flow, anchor.kind, anchor.side) or nil
  migrate_anchor_to_anchor_ring(square_size, anchor, square_position)
end

function managed_line_state.get(planet_name)
  assert(planet_name, "planet_name is required")

  local planet_state = storage.planets and storage.planets[planet_name]
  return planet_state and planet_state.starter_anchors or nil
end

function managed_line_state.initialize(planet_name)
  assert(planet_name, "planet_name is required")
  local planet = planet_instance.ensure(planet_name)

  if not planet then
    return nil
  end

  local planet_state = planet:get_state()
  planet_state.starter_anchors = planet_state.starter_anchors or {
    layout_version = defs.STARTER_ANCHOR_LAYOUT_VERSION,
    anchors = planet_runtime.build_initial_managed_line_state(planet_name).anchors
  }
  local state = planet_state.starter_anchors
  local layout_changed = state.layout_version ~= defs.STARTER_ANCHOR_LAYOUT_VERSION

  for _, anchor in ipairs(state.anchors) do
    if layout_changed then
      anchor.entity = nil
    end

    normalize_anchor(anchor, planet:get_square_size(), planet:get_square_position())
  end

  state.layout_version = defs.STARTER_ANCHOR_LAYOUT_VERSION

  return state
end

return managed_line_state
