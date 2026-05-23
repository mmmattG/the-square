local defs = require("lib.runtime_defs")
local planet_instance = require("lib.planet_instance")

local planet_square = {}

local function get_target_surface_size(square_size)
  return defs.get_surface_size(square_size)
end

local function ensure_surface_dimensions(surface, target_surface_size)
  local map_gen_settings = surface.map_gen_settings

  if map_gen_settings.width ~= target_surface_size or map_gen_settings.height ~= target_surface_size then
    map_gen_settings.width = target_surface_size
    map_gen_settings.height = target_surface_size
    surface.map_gen_settings = map_gen_settings
  end

  surface.request_to_generate_chunks({x = 0, y = 0}, defs.CHART_MARGIN)
  surface.force_generate_chunk_requests()
end

local function build_resize_tile_updates(old_square_size, old_surface_size, new_square_size, new_surface_size, floor_tile_name)
  local tiles = {}
  local old_bounds = defs.get_square_bounds(old_surface_size)
  local new_bounds = defs.get_square_bounds(new_surface_size)
  local min_x = math.min(old_bounds.left_top.x, new_bounds.left_top.x)
  local min_y = math.min(old_bounds.left_top.y, new_bounds.left_top.y)
  local max_x = math.max(old_bounds.right_bottom.x - 1, new_bounds.right_bottom.x - 1)
  local max_y = math.max(old_bounds.right_bottom.y - 1, new_bounds.right_bottom.y - 1)

  for y = min_y, max_y do
    for x = min_x, max_x do
      local position = {x = x, y = y}
      local previous_tile_name = defs.get_managed_tile_name(old_square_size, old_surface_size, position, floor_tile_name)
      local next_tile_name = defs.get_managed_tile_name(new_square_size, new_surface_size, position, floor_tile_name)

      if next_tile_name and next_tile_name ~= previous_tile_name then
        tiles[#tiles + 1] = {
          name = next_tile_name,
          position = position
        }
      end
    end
  end

  return tiles
end

local function apply_square_resize(surface, old_square_size, old_surface_size, new_square_size, new_surface_size, floor_tile_name)
  ensure_surface_dimensions(surface, new_surface_size)

  local tile_updates = build_resize_tile_updates(
    old_square_size,
    old_surface_size,
    new_square_size,
    new_surface_size,
    floor_tile_name
  )

  if #tile_updates > 0 then
    surface.set_tiles(tile_updates, true, true, true, false)
  end
end

local function find_entity_at_position(surface, prototype_name, position)
  local entities = surface.find_entities_filtered({
    name = prototype_name,
    position = position
  })

  return entities[1]
end

local function get_trailing_entity_name(anchor)
  if not anchor then
    return nil
  end

  if anchor.kind == "fluid" then
    return "pipe"
  end

  local tier_level = anchor.flow == "egress" and defs.get_current_egress_tier_level() or defs.get_current_ingress_tier_level()
  local tier_map = anchor.flow == "egress" and defs.ITEM_EGRESS_BELT_TIER_BY_EGRESS_TIER or defs.ITEM_INGRESS_BELT_TIER_BY_INGRESS_TIER
  local belt_tier_key = tier_map[tier_level] or "yellow"

  if belt_tier_key == "red" then
    return "fast-transport-belt"
  end

  if belt_tier_key == "blue" then
    return "express-transport-belt"
  end

  if belt_tier_key == "turbo" then
    return "turbo-transport-belt"
  end

  return "transport-belt"
end

local function leave_trailing_ingress_stub(surface, anchor)
  if not (surface and anchor and anchor.position) then
    return
  end

  local trailing_entity_name = get_trailing_entity_name(anchor)
  local existing_anchor = anchor.entity

  if existing_anchor and existing_anchor.valid then
    existing_anchor.destroy({raise_destroy = false})
  else
    existing_anchor = find_entity_at_position(surface, anchor.entity_name, anchor.position)

    if existing_anchor and existing_anchor.valid then
      existing_anchor.destroy({raise_destroy = false})
    end
  end

  if find_entity_at_position(surface, trailing_entity_name, anchor.position) then
    return
  end

  surface.create_entity({
    name = trailing_entity_name,
    position = anchor.position,
    direction = anchor.kind == "item" and defs.DIRECTION_BY_SIDE[anchor.side] or anchor.direction,
    force = game.forces.player
  })
end

local function leave_trailing_stubs_for_expansion(surface, managed_lines)
  if not managed_lines then
    return
  end

  for _, anchor in ipairs(managed_lines.anchors) do
    if anchor.position then
      leave_trailing_ingress_stub(surface, anchor)
    end
  end
end

local function move_managed_lines_outward(managed_lines)
  if not managed_lines then
    return
  end

  for _, anchor in ipairs(managed_lines.anchors) do
    if anchor.position and anchor.side then
      anchor.position = defs.move_position(anchor.position, anchor.side, 1)
      anchor.direction = defs.get_anchor_direction_for_side(anchor.flow, anchor.kind, anchor.side)
      anchor.entity = nil
    end
  end
end

function planet_square.chart_play_area(force, surface, surface_size)
  local chart_bounds = defs.get_square_bounds(surface_size)

  force.chart(surface, {
    {
      chart_bounds.left_top.x - defs.CHART_MARGIN,
      chart_bounds.left_top.y - defs.CHART_MARGIN
    },
    {
      chart_bounds.right_bottom.x + defs.CHART_MARGIN,
      chart_bounds.right_bottom.y + defs.CHART_MARGIN
    }
  })
end

function planet_square.apply_square_expansion(planet_name, options)
  options = options or {}
  planet_name = planet_name or "nauvis"

  local planet = planet_instance.ensure(planet_name)

  if not planet then
    return nil
  end

  local surface = game.surfaces[planet:get_surface_name()]

  if not surface then
    return nil
  end

  local previous_square_size = planet:get_square_size()
  local previous_surface_size = planet:get_surface_size()
  local next_square_size = previous_square_size + 2
  local next_expansion_level = planet:get_completed_square_expansion_levels() + 1
  local next_surface_size = get_target_surface_size(next_square_size)
  local newly_unlocked_tiles = defs.get_next_expansion_tile_reward(previous_square_size)
  local managed_lines = planet:get_managed_lines()

  planet:set_square_size(next_square_size)
  planet:set_completed_square_expansion_levels(next_expansion_level)
  planet:add_expansion_points(newly_unlocked_tiles)

  local bootstrap = planet:get_bootstrap_storage()
  bootstrap.expansions_completed = next_expansion_level

  apply_square_resize(surface, previous_square_size, previous_surface_size, next_square_size, next_surface_size, planet:get_floor_tile_name())
  leave_trailing_stubs_for_expansion(surface, managed_lines)
  move_managed_lines_outward(managed_lines)
  planet_square.chart_play_area(game.forces.player, surface, next_surface_size)

  if options.anchor_runtime then
    if planet_name == "nauvis" and options.anchor_runtime.ensure_starter_anchors then
      options.anchor_runtime.ensure_starter_anchors()
    elseif options.anchor_runtime.ensure_planet_starter_anchors then
      options.anchor_runtime.ensure_planet_starter_anchors(planet_name)
    end
  end

  if options.player and options.player.valid then
    options.player.play_sound({path = "utility/new_objective"})
  end

  if options.gui_runtime then
    options.gui_runtime.refresh_all_debug_guis()
  end

  return {
    planet_name = planet_name,
    previous_square_size = previous_square_size,
    square_size = next_square_size,
    surface_size = next_surface_size,
    expansion_research_levels = next_expansion_level,
    awarded_expansion_points = newly_unlocked_tiles,
    expansion_points = planet:get_expansion_points()
  }
end

return planet_square
