-- The Managed Lines a Planet owns, as stored in its planet state.
--
-- Each anchor record is one owned Managed Line (or an empty Anchor being configured):
--   kind, flow      "item"/"fluid", "ingress"/"egress" (nil on an unconfigured Anchor)
--   resource        what it carries (nil until configured)
--   tier_level      purchased item tier, see managed_line_definitions.ITEM_TIERS
--   position, side  its Anchor on the Boundary; nil while the line is stashed
--   direction       entity direction derived from flow, kind and side
--   item_name       the inventory item that represents the line
--   entity_name     the Anchor entity prototype for the line
--   entity          the placed Anchor entity, when there is one
--   item_progress   fractional item emission carried between ticks, per lane
local definitions = require("lib.managed_line_definitions")
local planet_catalog = require("lib.planet_catalog")
local planet_state = require("lib.planet_state")
local square_layout = require("lib.square_layout")

local managed_line_state = {}

-- Bumping this clears stored entity references so every Anchor is re-found or rebuilt.
local LAYOUT_VERSION = 12

-- Ingress items and fluid egress point into the Square; item egress and fluid
-- ingress point out of it.
local INWARD_DIRECTION_BY_SIDE = {
  north = defines.direction.south,
  east = defines.direction.west,
  south = defines.direction.north,
  west = defines.direction.east
}

local OUTWARD_DIRECTION_BY_SIDE = {
  north = defines.direction.north,
  east = defines.direction.east,
  south = defines.direction.south,
  west = defines.direction.west
}

function managed_line_state.get_direction(flow, kind, side)
  local points_inward = (kind == "item") == (flow == "ingress")

  return points_inward and INWARD_DIRECTION_BY_SIDE[side] or OUTWARD_DIRECTION_BY_SIDE[side]
end

function managed_line_state.get_item_name(kind, flow, tier_level)
  return definitions.get_item_name(kind, flow, definitions.get_item_tier_for_level(tier_level or 1).key)
end

function managed_line_state.get_entity_name(anchor)
  if not anchor.resource then
    return definitions.get_generic_entity_name(anchor.kind or "item", anchor.flow or "ingress")
  end

  return definitions.get_entity_name(anchor.kind, anchor.flow, definitions.get_item_tier_for_level(anchor.tier_level or 1).key)
end

local function build_stashed_line(kind, flow)
  return {
    kind = kind,
    flow = flow,
    tier_level = 1,
    item_name = managed_line_state.get_item_name(kind, flow, 1),
    entity_name = definitions.get_generic_entity_name(kind, flow),
    item_progress = {0, 0}
  }
end

-- The stashed Managed Lines a Planet starts with. Their items are also granted to
-- the first player once.
function managed_line_state.build_initial_lines(planet_name)
  local lines = {}

  for _, line in ipairs(planet_catalog.get(planet_name).initial_line_items or {}) do
    lines[#lines + 1] = build_stashed_line(line.kind, line.flow)
  end

  return lines
end

-- Lines from older layouts may sit one tile inside the Boundary; push them out onto it.
local function move_anchor_onto_boundary(anchor, square_size, square_position)
  if not (anchor.position and anchor.side) then
    return
  end

  if square_layout.get_anchor_side_for_position(square_size, anchor.position, square_position) then
    return
  end

  anchor.position = square_layout.move_position(anchor.position, anchor.side, 1)
  anchor.direction = managed_line_state.get_direction(anchor.flow, anchor.kind, anchor.side)
  anchor.entity = nil
end

local function normalize_anchor(anchor, square_size, square_position)
  anchor.item_progress = anchor.item_progress or {0, 0}

  -- An empty Anchor that was opened for configuration but never configured.
  if anchor.position and not anchor.resource and not (anchor.kind or anchor.flow) then
    move_anchor_onto_boundary(anchor, square_size, square_position)
    return
  end

  anchor.flow = anchor.flow or "ingress"
  anchor.item_name = managed_line_state.get_item_name(anchor.kind or "item", anchor.flow, anchor.tier_level)

  if anchor.position then
    anchor.entity_name = managed_line_state.get_entity_name(anchor)
  else
    anchor.entity_name = anchor.entity_name or definitions.get_generic_entity_name(anchor.kind or "item", anchor.flow)
  end

  anchor.direction = anchor.side and managed_line_state.get_direction(anchor.flow, anchor.kind, anchor.side) or nil
  move_anchor_onto_boundary(anchor, square_size, square_position)
end

function managed_line_state.get(planet_name)
  local planet = storage.planets and storage.planets[planet_name]

  return planet and planet.starter_anchors or nil
end

-- Creates the Planet's line set on first use and brings stored lines up to date.
function managed_line_state.initialize(planet_name)
  local planet = planet_state.get(planet_name)
  local state = planet:get_state()

  state.starter_anchors = state.starter_anchors or {
    layout_version = LAYOUT_VERSION,
    anchors = managed_line_state.build_initial_lines(planet_name)
  }

  local managed_lines = state.starter_anchors
  local layout_changed = managed_lines.layout_version ~= LAYOUT_VERSION

  for _, anchor in ipairs(managed_lines.anchors) do
    if layout_changed then
      anchor.entity = nil
    end

    normalize_anchor(anchor, planet:get_square_size(), planet:get_square_position())
  end

  managed_lines.layout_version = LAYOUT_VERSION

  return managed_lines
end

function managed_line_state.find_by_position(managed_lines, position)
  local position_key = square_layout.get_position_key(square_layout.snap_to_tile(position))

  for _, anchor in ipairs(managed_lines.anchors) do
    if anchor.position and square_layout.get_position_key(anchor.position) == position_key then
      return anchor
    end
  end

  return nil
end

-- The line an Anchor entity belongs to, matched by entity reference or by name and tile.
function managed_line_state.find_by_entity(managed_lines, entity)
  for _, anchor in ipairs(managed_lines.anchors) do
    if anchor.entity == entity then
      return anchor
    end
  end

  local anchor = managed_line_state.find_by_position(managed_lines, entity.position)

  if not (anchor and anchor.resource) then
    return nil
  end

  -- Any tier of the line's kind and flow, e.g. "...-item-ingress-managed-anchor-red".
  local yellow_entity_name = definitions.get_entity_name(anchor.kind, anchor.flow, "yellow")

  return string.sub(entity.name, 1, #yellow_entity_name) == yellow_entity_name and anchor or nil
end

function managed_line_state.owns_resource(managed_lines, resource)
  for _, anchor in ipairs(managed_lines.anchors) do
    if anchor.resource == resource then
      return true
    end
  end

  return false
end

-- A stashed line that can be reused for a new configuration of this kind, flow and tier.
function managed_line_state.find_reusable_stashed_line(managed_lines, definition, flow, tier_level)
  for _, candidate in ipairs(managed_lines.anchors) do
    if not candidate.position
      and candidate.kind == definition.kind
      and candidate.flow == flow
      and (candidate.tier_level or 1) == tier_level
      and (not candidate.resource or candidate.resource == definition.resource)
    then
      return candidate
    end
  end

  return nil
end

function managed_line_state.remove(managed_lines, anchor)
  for index, candidate in ipairs(managed_lines.anchors) do
    if candidate == anchor then
      table.remove(managed_lines.anchors, index)
      return
    end
  end
end

-- Points a line at a new resource, flow and tier on its current Anchor.
function managed_line_state.configure(anchor, definition, flow, side, tier_level)
  anchor.resource = definition.resource
  anchor.kind = definition.kind
  anchor.flow = flow
  anchor.side = side
  anchor.direction = managed_line_state.get_direction(flow, definition.kind, side)
  anchor.tier_level = tier_level
  anchor.item_name = managed_line_state.get_item_name(anchor.kind, flow, tier_level)
  anchor.entity_name = managed_line_state.get_entity_name(anchor)
  anchor.item_progress = {0, 0}
end

-- Clears a mined line's configuration but keeps it owned.
function managed_line_state.clear(anchor)
  anchor.resource = nil
  anchor.kind = nil
  anchor.flow = nil
  anchor.direction = nil
  anchor.entity_name = nil
  anchor.item_name = nil
  anchor.item_progress = {0, 0}
  anchor.entity = nil
end

return managed_line_state
