local bootstrap_layout = {}

function bootstrap_layout.get_square_bounds(size)
  local left = -math.floor(size / 2)

  return {
    left_top = {x = left, y = left},
    right_bottom = {x = left + size, y = left + size}
  }
end

function bootstrap_layout.get_surface_size(square_size, outer_ring_width)
  return square_size + (outer_ring_width * 2)
end

function bootstrap_layout.get_anchor_bounds(square_size)
  return bootstrap_layout.get_square_bounds(square_size + 2)
end

function bootstrap_layout.is_inside_bounds(bounds, position)
  return position.x >= bounds.left_top.x
    and position.x < bounds.right_bottom.x
    and position.y >= bounds.left_top.y
    and position.y < bounds.right_bottom.y
end

function bootstrap_layout.get_anchor_side_for_position(square_size, position)
  local bounds = bootstrap_layout.get_anchor_bounds(square_size)
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

function bootstrap_layout.is_anchor_ring_position(square_size, position)
  return bootstrap_layout.get_anchor_side_for_position(square_size, position) ~= nil
end

function bootstrap_layout.get_managed_tile_name(square_size, surface_size, floor_tile_name, void_tile_name, position)
  local square_bounds = bootstrap_layout.get_square_bounds(square_size)

  if bootstrap_layout.is_inside_bounds(square_bounds, position) then
    return floor_tile_name
  end

  local surface_bounds = bootstrap_layout.get_square_bounds(surface_size)

  if bootstrap_layout.is_inside_bounds(surface_bounds, position) then
    if bootstrap_layout.is_anchor_ring_position(square_size, position) then
      return floor_tile_name
    end

    return void_tile_name
  end

  return nil
end

return bootstrap_layout
