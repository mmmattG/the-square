-- Pure geometry of a Square and its Boundary. Positions are tile positions; a
-- center (default {0, 0}) lets a moved Square reuse the same maths.
local square_layout = {}

square_layout.SIDES = {"north", "east", "south", "west"}

square_layout.OPPOSITE_SIDE = {
  north = "south",
  east = "west",
  south = "north",
  west = "east"
}

local OFFSET_BY_SIDE = {
  north = {x = 0, y = -1},
  east = {x = 1, y = 0},
  south = {x = 0, y = 1},
  west = {x = -1, y = 0}
}

local function normalize_center(center)
  return center or {x = 0, y = 0}
end

function square_layout.get_square_bounds(size, center)
  center = normalize_center(center)
  local left = -math.floor(size / 2)

  return {
    left_top = {x = left + center.x, y = left + center.y},
    right_bottom = {x = left + size + center.x, y = left + size + center.y}
  }
end

-- The managed surface area: the Square plus its one-tile Boundary ring on every side.
function square_layout.get_surface_size(square_size)
  return square_size + 2
end

-- The Boundary ring, where Anchors live, sits just outside the Square.
function square_layout.get_anchor_bounds(square_size, center)
  return square_layout.get_square_bounds(square_size + 2, center)
end

function square_layout.is_inside_bounds(bounds, position)
  return position.x >= bounds.left_top.x
    and position.x < bounds.right_bottom.x
    and position.y >= bounds.left_top.y
    and position.y < bounds.right_bottom.y
end

-- The side of the Boundary a tile is on, or nil if it is not an Anchor tile.
-- Corners are not Anchors.
function square_layout.get_anchor_side_for_position(square_size, position, center)
  local bounds = square_layout.get_anchor_bounds(square_size, center)
  local min_x = bounds.left_top.x
  local min_y = bounds.left_top.y
  local max_x = bounds.right_bottom.x - 1
  local max_y = bounds.right_bottom.y - 1

  if position.y == min_y and position.x > min_x and position.x < max_x then
    return "north"
  end

  if position.x == max_x and position.y > min_y and position.y < max_y then
    return "east"
  end

  if position.y == max_y and position.x > min_x and position.x < max_x then
    return "south"
  end

  if position.x == min_x and position.y > min_y and position.y < max_y then
    return "west"
  end

  return nil
end

function square_layout.is_anchor_ring_position(square_size, position, center)
  return square_layout.get_anchor_side_for_position(square_size, position, center) ~= nil
end

-- Every Anchor tile, side by side.
function square_layout.get_anchor_ring_positions(square_size, center)
  local bounds = square_layout.get_anchor_bounds(square_size, center)
  local min_x = bounds.left_top.x
  local min_y = bounds.left_top.y
  local max_x = bounds.right_bottom.x - 1
  local max_y = bounds.right_bottom.y - 1
  local positions = {}

  for x = min_x + 1, max_x - 1 do
    positions[#positions + 1] = {x = x, y = min_y}
  end

  for y = min_y + 1, max_y - 1 do
    positions[#positions + 1] = {x = max_x, y = y}
  end

  for x = min_x + 1, max_x - 1 do
    positions[#positions + 1] = {x = x, y = max_y}
  end

  for y = min_y + 1, max_y - 1 do
    positions[#positions + 1] = {x = min_x, y = y}
  end

  return positions
end

-- The tile a managed surface position should have: floor inside the Square, void on
-- the Boundary ring, and nil (leave alone) beyond it.
function square_layout.get_managed_tile_name(square_size, surface_size, floor_tile_name, void_tile_name, position, center)
  if square_layout.is_inside_bounds(square_layout.get_square_bounds(square_size, center), position) then
    return floor_tile_name
  end

  if square_layout.is_inside_bounds(square_layout.get_square_bounds(surface_size, center), position) then
    return void_tile_name
  end

  return nil
end

function square_layout.get_position_key(position)
  return position.x .. ":" .. position.y
end

function square_layout.move_position(position, side, distance)
  local offset = OFFSET_BY_SIDE[side]

  return {
    x = position.x + (offset.x * distance),
    y = position.y + (offset.y * distance)
  }
end

-- The tile under an entity position, such as {x = 3.5, y = -2.5} -> {x = 3, y = -3}.
function square_layout.snap_to_tile(position)
  return {
    x = math.floor(position.x),
    y = math.floor(position.y)
  }
end

return square_layout
