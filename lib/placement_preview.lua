local defs = require("lib.runtime_defs")

local placement_preview = {}

local function abs(value)
  return math.abs(value or 0)
end

function placement_preview.infer_side(position)
  if not position then
    return nil
  end

  local x = position.x or 0
  local y = position.y or 0
  local abs_x = abs(x)
  local abs_y = abs(y)

  if abs_x == 0 and abs_y == 0 then
    return "north"
  end

  if abs_y > abs_x then
    if y < 0 then
      return "north"
    end

    return "south"
  end

  if abs_x > abs_y then
    if x < 0 then
      return "west"
    end

    return "east"
  end

  if x > 0 and y < 0 then
    return "north"
  end

  if x < 0 and y < 0 then
    return "west"
  end

  if x < 0 and y > 0 then
    return "south"
  end

  return "east"
end

function placement_preview.infer_side_and_direction(position)
  local side = placement_preview.infer_side(position)

  if not side then
    return nil, nil
  end

  return side, defs.DIRECTION_BY_SIDE[side]
end

return placement_preview
