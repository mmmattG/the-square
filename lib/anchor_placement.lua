local defs = require("lib.runtime_defs")
local anchor_identity = require("lib.anchor_identity")

local anchor_placement = {}

function anchor_placement.assign(anchor, side, position)
  if not (anchor and side and position) then
    return false
  end

  anchor.position = position
  anchor.side = side
  anchor.direction = defs.get_anchor_direction_for_side(anchor.flow, anchor.kind, side)
  anchor.entity_name = defs.get_anchor_entity_name_for_current_tier(anchor)
  anchor.entity = nil

  return true
end

function anchor_placement.is_fluid_anchor_too_close(anchor, position, side, starter_anchors)
  if not starter_anchors or not anchor or anchor.kind ~= "fluid" then
    return false
  end

  for _, other_anchor in ipairs(starter_anchors.anchors) do
    if other_anchor ~= anchor
      and other_anchor.kind == "fluid"
      and other_anchor.side == side
      and other_anchor.position
      and position
    then
      local delta

      if side == "north" or side == "south" then
        delta = math.abs(other_anchor.position.x - position.x)
      else
        delta = math.abs(other_anchor.position.y - position.y)
      end

      if delta <= 1 then
        return true
      end
    end
  end

  return false
end

function anchor_placement.find_anchor_by_entity(entity, starter_anchors)
  if not starter_anchors or not (entity and entity.valid) then
    return nil
  end

  for _, anchor in ipairs(starter_anchors.anchors) do
    if anchor.entity == entity then
      return anchor
    end
  end

  return nil
end

function anchor_placement.find_anchor_by_entity_name_and_position(entity_name, position, starter_anchors)
  if not starter_anchors or not position then
    return nil
  end

  local position_key = defs.get_position_key(defs.snap_entity_position_to_tile(position))

  for _, anchor in ipairs(starter_anchors.anchors) do
    if anchor.position
      and defs.get_position_key(anchor.position) == position_key
      and anchor_identity.does_anchor_match_entity_name(anchor, entity_name)
    then
      return anchor
    end
  end

  return nil
end

function anchor_placement.check(anchor, position, square_size, starter_anchors, square_position)
  local side = defs.get_anchor_side_for_position(square_size, position, square_position)

  if not side then
    return false, "invalid-edge", nil
  end

  if anchor_placement.is_fluid_anchor_too_close(anchor, position, side, starter_anchors) then
    return false, "fluid-gap-required", side
  end

  return true, nil, side
end

return anchor_placement
