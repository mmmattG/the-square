-- Rules for which Anchor a Managed Line may be configured into. Pure logic.
local square_layout = require("lib.square_layout")

local anchor_placement = {}

-- Fluid Managed Lines on the same side need at least one empty Anchor between them,
-- or their pipes would join.
function anchor_placement.is_fluid_anchor_too_close(anchor, position, side, managed_lines)
  if anchor.kind ~= "fluid" then
    return false
  end

  for _, other_anchor in ipairs(managed_lines.anchors) do
    if other_anchor ~= anchor
      and other_anchor.kind == "fluid"
      and other_anchor.side == side
      and other_anchor.position
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

-- Returns ok, rejection reason ("invalid-edge" or "fluid-gap-required"), and the
-- Boundary side of the position.
function anchor_placement.check(anchor, position, square_size, managed_lines, square_position)
  local side = square_layout.get_anchor_side_for_position(square_size, position, square_position)

  if not side then
    return false, "invalid-edge", nil
  end

  if anchor_placement.is_fluid_anchor_too_close(anchor, position, side, managed_lines) then
    return false, "fluid-gap-required", side
  end

  return true, nil, side
end

return anchor_placement
