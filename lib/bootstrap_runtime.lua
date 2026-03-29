local defs = require("lib.runtime_defs")

local bootstrap_runtime = {}
local ensure_surface_dimensions

local function get_target_surface_size(square_size, expansions_completed)
  return square_size + 2
end

local function get_edge_positions(bounds, side)
  local positions = {}
  local min_x = bounds.left_top.x
  local min_y = bounds.left_top.y
  local max_x = bounds.right_bottom.x - 1
  local max_y = bounds.right_bottom.y - 1

  if side == "north" then
    for x = min_x + 1, max_x - 1 do
      positions[#positions + 1] = {x = x, y = min_y}
    end
  elseif side == "south" then
    for x = min_x + 1, max_x - 1 do
      positions[#positions + 1] = {x = x, y = max_y}
    end
  elseif side == "west" then
    for y = min_y + 1, max_y - 1 do
      positions[#positions + 1] = {x = min_x, y = y}
    end
  elseif side == "east" then
    for y = min_y + 1, max_y - 1 do
      positions[#positions + 1] = {x = max_x, y = y}
    end
  end

  return positions
end

local function choose_spread_positions(positions, count, side)
  local chosen = {}
  local position_count = #positions
  local selected_indexes = {}

  if count > position_count then
    error("Not enough border tiles available for starter input anchors on side " .. side)
  end

  if count == 0 then
    return chosen
  end

  if position_count % 2 == 1 then
    local center = math.floor((position_count + 1) / 2)
    local step = 1

    if count % 2 == 1 then
      selected_indexes[#selected_indexes + 1] = center
    end

    while #selected_indexes < count do
      selected_indexes[#selected_indexes + 1] = center - step

      if #selected_indexes < count then
        selected_indexes[#selected_indexes + 1] = center + step
      end

      step = step + 1
    end
  else
    local left = position_count / 2
    local right = left + 1
    local step = 0

    if count % 2 == 1 then
      selected_indexes[#selected_indexes + 1] = left
      step = 1
    end

    while #selected_indexes < count do
      selected_indexes[#selected_indexes + 1] = left - step

      if #selected_indexes < count then
        selected_indexes[#selected_indexes + 1] = right + step
      end

      step = step + 1
    end
  end

  table.sort(selected_indexes)

  for _, index in ipairs(selected_indexes) do
    chosen[#chosen + 1] = positions[index]
  end

  return chosen
end

function bootstrap_runtime.build_starter_anchor_layout(square_size)
  local bounds = defs.get_anchor_bounds(square_size)
  local resources_by_side = {}
  local anchors = {}

  for _, definition in ipairs(defs.INPUT_DEFINITIONS) do
    if definition.starter_side then
      resources_by_side[definition.starter_side] = resources_by_side[definition.starter_side] or {}
      resources_by_side[definition.starter_side][#resources_by_side[definition.starter_side] + 1] = definition
    end
  end

  for _, side in ipairs({"north", "east", "south", "west"}) do
    local side_resources = resources_by_side[side] or {}
    local side_positions = get_edge_positions(bounds, side)
    local chosen_positions = choose_spread_positions(side_positions, #side_resources, side)

    for index, definition in ipairs(side_resources) do
      anchors[#anchors + 1] = defs.create_managed_anchor(definition, "ingress", side, chosen_positions[index])
    end
  end

  return anchors
end

local function call_freeplay(interface_name, value)
  if remote.interfaces.freeplay and remote.interfaces.freeplay[interface_name] then
    remote.call("freeplay", interface_name, value)
  end
end

local function build_managed_surface_tiles(square_size, surface_size)
  local surface_bounds = defs.get_square_bounds(surface_size)
  local tiles = {}

  for y = surface_bounds.left_top.y, surface_bounds.right_bottom.y - 1 do
    for x = surface_bounds.left_top.x, surface_bounds.right_bottom.x - 1 do
      tiles[#tiles + 1] = {
        name = defs.get_managed_tile_name(square_size, surface_size, {x = x, y = y}),
        position = {x = x, y = y}
      }
    end
  end

  return tiles
end

function bootstrap_runtime.refresh_managed_surface_tiles(surface, square_size, surface_size)
  if not surface then
    return
  end

  local tile_updates = build_managed_surface_tiles(square_size, surface_size)

  if #tile_updates > 0 then
    -- Keep tile correction enabled so Factorio rebuilds the soft edge transition
    -- between the playable floor and the out-of-map ring immediately.
    surface.set_tiles(tile_updates, true, true, true, false)
  end
end

local function build_bootstrap_tiles(square_size, surface_size)
  return build_managed_surface_tiles(square_size, surface_size)
end

local function build_resize_tile_updates(old_square_size, old_surface_size, new_square_size, new_surface_size)
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
      local previous_tile_name = defs.get_managed_tile_name(old_square_size, old_surface_size, position)
      local next_tile_name = defs.get_managed_tile_name(new_square_size, new_surface_size, position)

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

local function destroy_noise_entities(surface)
  for _, entity in ipairs(surface.find_entities()) do
    if entity.valid and entity.type ~= "character" then
      entity.destroy()
    end
  end
end

local function build_surface_map_gen_settings(square_size)
  local surface_size = get_target_surface_size(square_size, 0)

  return {
    width = surface_size,
    height = surface_size,
    starting_points = {{x = 0, y = 0}},
    peaceful_mode = true,
    no_enemies_mode = true
  }
end

function bootstrap_runtime.ensure_bootstrap_state_defaults()
  if not storage.bootstrap then
    return
  end

  local target_surface_size = get_target_surface_size(
    storage.bootstrap.square_size,
    storage.bootstrap.expansions_completed or 0
  )

  storage.bootstrap.surface_name = storage.bootstrap.surface_name or defs.SURFACE_NAME
  storage.bootstrap.surface_size = target_surface_size
  storage.bootstrap.expansion_points = storage.bootstrap.expansion_points or 0
  storage.bootstrap.expansions_completed = storage.bootstrap.expansions_completed or 0
  storage.bootstrap.ingress_tier = storage.bootstrap.ingress_tier or 1
  storage.bootstrap.expansion_research_levels = storage.bootstrap.expansion_research_levels or 0
  storage.bootstrap.uranium_ore_progress_carry = storage.bootstrap.uranium_ore_progress_carry or 0
  storage.bootstrap.growth_progress = nil
  storage.bootstrap.expansion_speed_research_levels = nil
  storage.utilization_metrics = nil
end

ensure_surface_dimensions = function(surface, target_surface_size)
  local map_gen_settings = surface.map_gen_settings

  if map_gen_settings.width ~= target_surface_size or map_gen_settings.height ~= target_surface_size then
    map_gen_settings.width = target_surface_size
    map_gen_settings.height = target_surface_size
    surface.map_gen_settings = map_gen_settings
  end

  surface.request_to_generate_chunks({x = 0, y = 0}, defs.CHART_MARGIN)
  surface.force_generate_chunk_requests()
end

function bootstrap_runtime.ensure_bootstrap_surface(anchor_runtime)
  local square_size = defs.get_square_size()
  local surface_size = get_target_surface_size(square_size, 0)
  local surface = game.surfaces[defs.SURFACE_NAME]

  if not surface then
    surface = game.create_surface(defs.SURFACE_NAME, build_surface_map_gen_settings(square_size))
  end

  surface.peaceful_mode = true
  surface.no_enemies_mode = true
  ensure_surface_dimensions(surface, surface_size)
  surface.destroy_decoratives({})
  surface.clear_hidden_tiles()
  destroy_noise_entities(surface)
  -- Bootstrap writes need the same correction pass or the initial void edge stays hard
  -- until some later edit causes Factorio to recompute neighboring transitions.
  surface.set_tiles(build_bootstrap_tiles(square_size, surface_size), true, true, true, false)

  storage.bootstrap = storage.bootstrap or {}
  storage.bootstrap.square_size = square_size
  storage.bootstrap.surface_size = surface_size
  storage.bootstrap.surface_name = defs.SURFACE_NAME
  bootstrap_runtime.ensure_bootstrap_state_defaults()

  return surface
end

function bootstrap_runtime.chart_play_area(force, surface, surface_size)
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

function bootstrap_runtime.teleport_player_to_square(player)
  local bootstrap = storage.bootstrap

  if not bootstrap then
    return
  end

  local surface = game.surfaces[bootstrap.surface_name]

  if not surface then
    return
  end

  local target_position = {x = 0, y = 0}
  player.force.set_spawn_position(target_position, surface)
  player.teleport(target_position, surface)
  bootstrap_runtime.chart_play_area(player.force, surface, bootstrap.surface_size or bootstrap.square_size)
end

function bootstrap_runtime.add_expansion_points(amount)
  storage.bootstrap.expansion_points = (storage.bootstrap.expansion_points or 0) + amount
end

local function move_starter_anchors_outward()
  local starter_anchors = storage.starter_anchors

  if not starter_anchors then
    return
  end

  for _, anchor in ipairs(starter_anchors.anchors) do
    if anchor.position and anchor.side then
      anchor.position = defs.move_position(anchor.position, anchor.side, 1)
      anchor.direction = defs.DIRECTION_BY_SIDE[anchor.side]
      anchor.entity = nil
    end
  end
end

local function get_trailing_entity_name(anchor)
  if not anchor then
    return nil
  end

  if anchor.kind == "fluid" then
    return "pipe"
  end

  local belt_tier_key = defs.ITEM_INGRESS_BELT_TIER_BY_INGRESS_TIER[defs.get_current_ingress_tier_level()] or "yellow"

  if belt_tier_key == "red" then
    return "fast-transport-belt"
  end

  if belt_tier_key == "blue" then
    return "express-transport-belt"
  end

  return "transport-belt"
end

local function find_entity_at_position(surface, prototype_name, position)
  local entities = surface.find_entities_filtered({
    name = prototype_name,
    position = position
  })

  return entities[1]
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
    direction = anchor.direction,
    force = game.forces.player
  })
end

local function leave_trailing_stubs_for_expansion(surface)
  local starter_anchors = storage.starter_anchors

  if not starter_anchors then
    return
  end

  for _, anchor in ipairs(starter_anchors.anchors) do
    if anchor.position then
      leave_trailing_ingress_stub(surface, anchor)
    end
  end
end

local function apply_square_resize(surface, old_square_size, old_surface_size, new_square_size, new_surface_size)
  ensure_surface_dimensions(surface, new_surface_size)

  local tile_updates = build_resize_tile_updates(
    old_square_size,
    old_surface_size,
    new_square_size,
    new_surface_size
  )

  if #tile_updates > 0 then
    -- Expansion only paints the changed ring, so correction must stay on here as well
    -- to refresh the softened border around the updated out-of-map tiles.
    surface.set_tiles(tile_updates, true, true, true, false)
  end
end

function bootstrap_runtime.expand_square(player, gui_runtime, anchor_runtime)
  local bootstrap = storage.bootstrap

  if not bootstrap then
    return
  end

  local surface = game.surfaces[bootstrap.surface_name]

  if not surface then
    return
  end

  local previous_square_size = bootstrap.square_size
  local previous_surface_size = bootstrap.surface_size or get_target_surface_size(
    previous_square_size,
    bootstrap.expansions_completed or 0
  )
  local next_square_size = previous_square_size + 2
  local next_expansions_completed = (bootstrap.expansions_completed or 0) + 1
  local next_surface_size = get_target_surface_size(next_square_size, next_expansions_completed)
  local newly_unlocked_tiles = defs.get_next_expansion_tile_reward(previous_square_size)

  leave_trailing_stubs_for_expansion(surface)
  move_starter_anchors_outward()

  bootstrap.square_size = next_square_size
  bootstrap.surface_size = next_surface_size
  bootstrap.expansions_completed = next_expansions_completed
  bootstrap_runtime.add_expansion_points(newly_unlocked_tiles)

  apply_square_resize(surface, previous_square_size, previous_surface_size, next_square_size, next_surface_size)
  bootstrap_runtime.chart_play_area(game.forces.player, surface, next_surface_size)

  if anchor_runtime then
    anchor_runtime.ensure_starter_anchors()
  end

  game.print(
    {"",
      "[Expanding Square] Square expanded from ",
      previous_square_size,
      "x",
      previous_square_size,
      " to ",
      next_square_size,
      "x",
      next_square_size,
      ". Awarded ",
      newly_unlocked_tiles,
      " expansion points (total: ",
      bootstrap.expansion_points,
      ")."
    }
  )

  if player and player.valid then
    player.play_sound({path = "utility/new_objective"})
  end

  if gui_runtime then
    gui_runtime.refresh_all_debug_guis()
  end
end

function bootstrap_runtime.bootstrap_world(anchor_runtime, gui_runtime)
  call_freeplay("set_skip_intro", true)
  call_freeplay("set_disable_crashsite", true)

  storage.starter_anchors = {
    layout_version = defs.STARTER_ANCHOR_LAYOUT_VERSION,
    anchors = bootstrap_runtime.build_starter_anchor_layout(defs.get_square_size())
  }

  local surface = bootstrap_runtime.ensure_bootstrap_surface(anchor_runtime)
  game.forces.player.set_spawn_position({x = 0, y = 0}, surface)

  if anchor_runtime then
    anchor_runtime.ensure_starter_anchors()
    anchor_runtime.apply_logistic_network_setting_to_all_forces()
  end

  for _, player in pairs(game.players) do
    bootstrap_runtime.teleport_player_to_square(player)
  end

  if gui_runtime then
    gui_runtime.refresh_all_status_guis()
    gui_runtime.sync_all_dev_guis()
    gui_runtime.sync_all_shop_guis(anchor_runtime)
  end
end

function bootstrap_runtime.refresh_spawn_routing(anchor_runtime, gui_runtime)
  local bootstrap = storage.bootstrap

  if not bootstrap then
    return
  end

  bootstrap_runtime.ensure_bootstrap_state_defaults()

  local surface = game.surfaces[bootstrap.surface_name]

  if not surface then
    return
  end

  call_freeplay("set_skip_intro", true)
  call_freeplay("set_disable_crashsite", true)
  game.forces.player.set_spawn_position({x = 0, y = 0}, surface)
  ensure_surface_dimensions(surface, bootstrap.surface_size or defs.get_surface_size(bootstrap.square_size))

  if anchor_runtime then
    anchor_runtime.ensure_starter_anchors()
    anchor_runtime.apply_logistic_network_setting_to_all_forces()
  end

  for _, player in pairs(game.players) do
    bootstrap_runtime.teleport_player_to_square(player)
  end

  if gui_runtime then
    gui_runtime.refresh_all_status_guis()
    gui_runtime.sync_all_dev_guis()
    gui_runtime.sync_all_shop_guis(anchor_runtime)
  end
end

function bootstrap_runtime.notify_square_size_change_applies_to_new_saves()
  local requested_size = settings.global[defs.SETTING_STARTING_SQUARE_SIZE].value

  if storage.bootstrap and storage.bootstrap.square_size == requested_size then
    return
  end

  game.print(
    {"",
      "[Expanding Square] Starting square size changes only apply to new saves. ",
      "This save remains at ",
      storage.bootstrap and storage.bootstrap.square_size or "?",
      " and the current map setting is ",
      requested_size,
      "."
    }
  )
end

return bootstrap_runtime
