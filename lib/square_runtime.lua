-- A Planet's Square on the map: painting floor and Void tiles, keeping the surface
-- big enough, charting it, and Square Expansion (adding a Ring and shifting lines).
local anchor_runtime = require("lib.anchor_runtime")
local mod_settings = require("lib.mod_settings")
local planet_state = require("lib.planet_state")
local square_layout = require("lib.square_layout")

local square_runtime = {}

square_runtime.VOID_TILE_NAME = "out-of-map"

local CHECKERBOARD_TILE_NAMES = {even = "lab-dark-1", odd = "lab-dark-2"}

-- The tile for one position of a managed surface. A nil floor_tile_name means the
-- Planet uses the Background tile map setting (Nauvis).
function square_runtime.get_tile_name(square_size, surface_size, position, floor_tile_name, center)
  local background_tile_name = floor_tile_name or mod_settings.get_background_tile()

  if not floor_tile_name
    and background_tile_name == mod_settings.CHECKERBOARD_BACKGROUND
    and square_layout.is_inside_bounds(square_layout.get_square_bounds(square_size, center), position)
  then
    local parity = math.abs(position.x + position.y) % 2 == 0 and "even" or "odd"

    return CHECKERBOARD_TILE_NAMES[parity]
  end

  return square_layout.get_managed_tile_name(
    square_size,
    surface_size,
    background_tile_name,
    square_runtime.VOID_TILE_NAME,
    position,
    center
  )
end

-- Grows the surface's map limits to hold the Square and generates its chunks.
function square_runtime.ensure_surface_dimensions(surface, surface_size, square_position)
  local map_gen_settings = surface.map_gen_settings
  local target_width = surface_size + (math.abs(square_position.x) * 2)
  local target_height = surface_size + (math.abs(square_position.y) * 2)

  if map_gen_settings.width < target_width or map_gen_settings.height < target_height then
    map_gen_settings.width = math.max(map_gen_settings.width, target_width)
    map_gen_settings.height = math.max(map_gen_settings.height, target_height)
    surface.map_gen_settings = map_gen_settings
  end

  surface.request_to_generate_chunks(square_position, math.max(1, math.ceil(surface_size / 64)))
  surface.force_generate_chunk_requests()
end

-- Tile writes keep tile correction on, so Factorio rebuilds the soft transition
-- between the floor and the Void straight away.
local function set_tiles(surface, tiles)
  if #tiles > 0 then
    surface.set_tiles(tiles, true, true, true, false)
  end
end

-- Paints an area: managed positions get floor or Void, everything else Void.
-- With only_changes, tiles that are already right are left alone. Rewriting a Void
-- tile would destroy the Anchor entity standing on it.
local function paint_area(surface, planet, area, only_changes)
  local square_size = planet:get_square_size()
  local surface_size = planet:get_surface_size()
  local square_position = planet:get_square_position()
  local floor_tile_name = planet:get_floor_tile_name()
  local tiles = {}

  for y = area.left_top.y, area.right_bottom.y - 1 do
    for x = area.left_top.x, area.right_bottom.x - 1 do
      local position = {x = x, y = y}
      local name = square_runtime.get_tile_name(square_size, surface_size, position, floor_tile_name, square_position)
        or square_runtime.VOID_TILE_NAME

      if not (only_changes and surface.get_tile(x, y).name == name) then
        tiles[#tiles + 1] = {name = name, position = position}
      end
    end
  end

  set_tiles(surface, tiles)
end

function square_runtime.paint_chunk(planet, area)
  paint_area(planet:get_surface(), planet, area, false)
end

-- Paints the Square and its Boundary.
function square_runtime.paint_square(planet)
  local area = square_layout.get_square_bounds(planet:get_surface_size(), planet:get_square_position())

  paint_area(planet:get_surface(), planet, area, false)
end

-- Repaints every generated chunk where it differs, e.g. after the Background tile
-- setting changes. Buildings and Anchors are kept.
function square_runtime.repaint(planet)
  local surface = planet:get_surface()

  for chunk in surface.get_chunks() do
    paint_area(surface, planet, chunk.area, true)
  end
end

function square_runtime.chart(force, planet)
  local bounds = square_layout.get_square_bounds(planet:get_surface_size(), planet:get_square_position())

  force.chart(planet:get_surface(), {
    {bounds.left_top.x - 1, bounds.left_top.y - 1},
    {bounds.right_bottom.x + 1, bounds.right_bottom.y + 1}
  })
end

-- Forgets everything charted on the surface, so only the Square shows on the map.
function square_runtime.clear_chart(planet)
  for _, force in pairs(game.forces) do
    force.clear_chart(planet:get_surface())
  end
end

-- Tile changes between two Square sizes, so only the new Ring is repainted.
local function get_resize_tiles(planet, old_square_size, new_square_size)
  local floor_tile_name = planet:get_floor_tile_name()
  local square_position = planet:get_square_position()
  local old_surface_size = square_layout.get_surface_size(old_square_size)
  local new_surface_size = square_layout.get_surface_size(new_square_size)
  local bounds = square_layout.get_square_bounds(math.max(old_surface_size, new_surface_size), square_position)
  local tiles = {}

  for y = bounds.left_top.y, bounds.right_bottom.y - 1 do
    for x = bounds.left_top.x, bounds.right_bottom.x - 1 do
      local position = {x = x, y = y}
      local old_name = square_runtime.get_tile_name(old_square_size, old_surface_size, position, floor_tile_name, square_position)
      local new_name = square_runtime.get_tile_name(new_square_size, new_surface_size, position, floor_tile_name, square_position)

      if new_name and new_name ~= old_name then
        tiles[#tiles + 1] = {name = new_name, position = position}
      end
    end
  end

  return tiles
end

-- Planet-Local Expansion: grows a Planet's Square by one Ring and shifts its placed
-- Managed Lines out to the new Boundary. Returns the old and new sizes.
function square_runtime.expand(planet_name)
  local planet = planet_state.get(planet_name)
  local surface = planet:get_surface()
  local previous_square_size = planet:get_square_size()
  local square_size = previous_square_size + 2
  local managed_lines = planet:get_managed_lines()

  planet:set_square_size(square_size)
  planet:set_completed_square_expansion_levels(planet:get_completed_square_expansion_levels() + 1)

  -- Research finished before anyone reaches the Planet still counts: its surface is
  -- painted at the grown size when it is first generated.
  if not surface then
    return {previous_square_size = previous_square_size, square_size = square_size}
  end

  square_runtime.ensure_surface_dimensions(surface, planet:get_surface_size(), planet:get_square_position())
  set_tiles(surface, get_resize_tiles(planet, previous_square_size, square_size))

  if managed_lines then
    for _, anchor in ipairs(managed_lines.anchors) do
      if anchor.position and anchor.resource then
        anchor_runtime.leave_connector(surface, anchor)
      end
    end

    -- Anchor Shift.
    for _, anchor in ipairs(managed_lines.anchors) do
      if anchor.position and anchor.side then
        anchor.position = square_layout.move_position(anchor.position, anchor.side, 1)
        anchor.entity = nil
      end
    end
  end

  square_runtime.chart(game.forces.player, planet)
  anchor_runtime.reconcile(planet_name)

  return {previous_square_size = previous_square_size, square_size = square_size}
end

return square_runtime
