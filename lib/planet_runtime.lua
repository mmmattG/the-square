local defs = require("lib.runtime_defs")
local planet_config = require("lib.planet_config")
local planet_instance = require("lib.planet_instance")
local planet_square = require("lib.planet_square")

local planet_runtime = {}
local ensure_surface_dimensions

local function get_target_surface_size(square_size, expansions_completed)
  return defs.get_surface_size(square_size)
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

function planet_runtime.build_starter_anchor_layout(square_size, planet_name)
  assert(planet_name, "planet_name is required")
  local bounds = defs.get_anchor_bounds(square_size)
  local resources_by_side = {}
  local anchors = {}

  for _, definition in ipairs(defs.get_input_definitions(planet_name)) do
    if definition.starter_side then
      resources_by_side[definition.starter_side] = resources_by_side[definition.starter_side] or {}
      resources_by_side[definition.starter_side][#resources_by_side[definition.starter_side] + 1] = definition
    end
  end

  for _, definition in ipairs(defs.get_output_definitions(planet_name)) do
    if definition.starter_side then
      resources_by_side[definition.starter_side] = resources_by_side[definition.starter_side] or {}
      resources_by_side[definition.starter_side][#resources_by_side[definition.starter_side] + 1] = {
        resource = definition.resource,
        kind = definition.kind,
        starter_side = definition.starter_side,
        flow = "egress"
      }
    end
  end

  for _, side in ipairs({"north", "east", "south", "west"}) do
    local side_resources = resources_by_side[side] or {}
    local side_positions = get_edge_positions(bounds, side)
    local chosen_positions = choose_spread_positions(side_positions, #side_resources, side)

    for index, definition in ipairs(side_resources) do
      local flow = definition.flow or "ingress"
      anchors[#anchors + 1] = defs.create_managed_anchor(definition, flow, side, chosen_positions[index])
    end
  end

  return anchors
end

local function build_stashed_managed_anchor(kind, flow)
  return {
    kind = kind,
    flow = flow,
    tier_level = 1,
    item_name = defs.get_generic_anchor_item_name_for_tier(kind, flow, 1),
    entity_name = defs.get_generic_anchor_entity_name(kind, flow),
    item_progress = {0, 0}
  }
end

function planet_runtime.build_initial_managed_line_state(planet_name)
  assert(planet_name, "planet_name is required")
  local anchors = {}

  if planet_name == "nauvis" then
    anchors[#anchors + 1] = build_stashed_managed_anchor("fluid", "ingress")
    anchors[#anchors + 1] = build_stashed_managed_anchor("item", "ingress")
    anchors[#anchors + 1] = build_stashed_managed_anchor("item", "ingress")
  end

  return {
    layout_version = defs.STARTER_ANCHOR_LAYOUT_VERSION,
    anchors = anchors
  }
end

function planet_runtime.grant_initial_managed_line_inventory(player, planet_name)
  local planet = planet_runtime.ensure_planet_state(planet_name)
  local planet_state = planet and planet:get_state()

  if not planet_state or planet_state.initial_managed_line_inventory_granted then
    return
  end

  if not (player and player.valid and player.insert) then
    return
  end

  for _, anchor in ipairs(planet_runtime.build_initial_managed_line_state(planet_name).anchors) do
    player.insert({name = anchor.item_name, count = 1})
  end

  planet_state.initial_managed_line_inventory_granted = true
end

local function call_freeplay(interface_name, value)
  if remote.interfaces.freeplay and remote.interfaces.freeplay[interface_name] then
    return remote.call("freeplay", interface_name, value)
  end
end

function planet_runtime.configure_freeplay()
  call_freeplay("set_skip_intro", true)
  call_freeplay("set_disable_crashsite", true)

  if not (
    remote.interfaces.freeplay
    and remote.interfaces.freeplay.get_created_items
    and remote.interfaces.freeplay.set_created_items
  ) then
    return
  end

  local created_items = call_freeplay("get_created_items")

  if created_items then
    created_items["burner-mining-drill"] = nil
    call_freeplay("set_created_items", created_items)
  end
end

local function build_managed_surface_tiles(square_size, surface_size, floor_tile_name, square_position)
  local surface_bounds = defs.get_square_bounds(surface_size, square_position)
  local tiles = {}

  for y = surface_bounds.left_top.y, surface_bounds.right_bottom.y - 1 do
    for x = surface_bounds.left_top.x, surface_bounds.right_bottom.x - 1 do
      tiles[#tiles + 1] = {
        name = defs.get_managed_tile_name(
          square_size,
          surface_size,
          {x = x, y = y},
          floor_tile_name,
          square_position
        ),
        position = {x = x, y = y}
      }
    end
  end

  return tiles
end

function planet_runtime.refresh_managed_surface_tiles(
  surface,
  square_size,
  surface_size,
  floor_tile_name,
  square_position
)
  if not surface then
    return
  end

  local tile_updates = build_managed_surface_tiles(
    square_size,
    surface_size,
    floor_tile_name,
    square_position
  )

  if #tile_updates > 0 then
    -- Keep tile correction enabled so Factorio rebuilds the soft edge transition
    -- between the playable floor and the out-of-map ring immediately.
    surface.set_tiles(tile_updates, true, true, true, false)
  end
end

local function build_initial_surface_tiles(square_size, surface_size)
  return build_managed_surface_tiles(square_size, surface_size)
end

function planet_runtime.build_generated_chunk_tiles(
  square_size,
  surface_size,
  area,
  floor_tile_name,
  square_position
)
  local tiles = {}

  for y = area.left_top.y, area.right_bottom.y - 1 do
    for x = area.left_top.x, area.right_bottom.x - 1 do
      local position = {x = x, y = y}
      local tile_name = defs.get_managed_tile_name(
        square_size,
        surface_size,
        position,
        floor_tile_name,
        square_position
      ) or defs.VOID_TILE_NAME

      tiles[#tiles + 1] = {
        name = tile_name,
        position = position
      }
    end
  end

  return tiles
end

function planet_runtime.refresh_generated_chunk_tiles(
  surface,
  square_size,
  surface_size,
  area,
  floor_tile_name,
  square_position
)
  if not (surface and area) then
    return
  end

  local tile_updates = planet_runtime.build_generated_chunk_tiles(
    square_size,
    surface_size,
    area,
    floor_tile_name,
    square_position
  )

  if #tile_updates > 0 then
    surface.set_tiles(tile_updates, true, true, true, false)
  end
end

function planet_runtime.refresh_all_generated_chunk_tiles(surface, square_size, surface_size, square_position)
  if not surface then
    return
  end

  for chunk in surface.get_chunks() do
    planet_runtime.refresh_generated_chunk_tiles(surface, square_size, surface_size, {
      left_top = {x = chunk.x * 32, y = chunk.y * 32},
      right_bottom = {x = (chunk.x + 1) * 32, y = (chunk.y + 1) * 32}
    }, nil, square_position)
  end
end

function planet_runtime.refresh_generated_chunk_for_planet_surface(surface, area)
  if not (surface and area) then
    return false
  end

  local planet = planet_instance.for_surface(surface.name)

  if not planet then
    return false
  end

  planet_runtime.refresh_generated_chunk_tiles(
    surface,
    planet:get_square_size(),
    planet:get_surface_size(),
    area,
    planet:get_floor_tile_name(),
    planet:get_square_position()
  )

  return true
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

function planet_runtime.ensure_planet_state(planet_name)
  assert(planet_name, "planet_name is required")
  return planet_instance.ensure(planet_name)
end

ensure_surface_dimensions = function(surface, target_surface_size, square_position)
  square_position = square_position or {x = 0, y = 0}
  local map_gen_settings = surface.map_gen_settings
  local target_width = target_surface_size + (math.abs(square_position.x) * 2)
  local target_height = target_surface_size + (math.abs(square_position.y) * 2)

  if map_gen_settings.width < target_width or map_gen_settings.height < target_height then
    map_gen_settings.width = math.max(map_gen_settings.width, target_width)
    map_gen_settings.height = math.max(map_gen_settings.height, target_height)
    surface.map_gen_settings = map_gen_settings
  end

  local chunk_radius = math.max(defs.CHART_MARGIN, math.ceil(target_surface_size / 64))
  surface.request_to_generate_chunks(square_position, chunk_radius)
  surface.force_generate_chunk_requests()
end

function planet_runtime.initialize_planet_surface(planet_name)
  assert(planet_name, "planet_name is required")
  local config = planet_config.get(planet_name)

  if not config then
    return nil
  end

  local square_size = config.square_size
  local surface_size = get_target_surface_size(square_size, 0)
  local surface = game.surfaces[config.surface_name]

  if not surface then
    surface = game.create_surface(config.surface_name, build_surface_map_gen_settings(square_size))
  end

  surface.peaceful_mode = true
  surface.no_enemies_mode = true
  ensure_surface_dimensions(surface, surface_size)
  surface.destroy_decoratives({})
  surface.clear_hidden_tiles()
  destroy_noise_entities(surface)
  -- Initial surface writes need the same correction pass or the initial void edge stays hard
  -- until some later edit causes Factorio to recompute neighboring transitions.
  surface.set_tiles(build_initial_surface_tiles(square_size, surface_size), true, true, true, false)

  local planet = planet_runtime.ensure_planet_state(planet_name)
  planet:set_square_size(square_size)
  planet:set_surface_name(config.surface_name)

  return surface
end

function planet_runtime.clear_surface_chart(surface)
  if not surface then
    return
  end

  for _, force in pairs(game.forces) do
    if force.valid and force.clear_chart then
      force.clear_chart(surface)
    end
  end
end

function planet_runtime.chart_play_area(force, surface, surface_size, square_position)
  planet_square.chart_play_area(force, surface, surface_size, square_position)
end

function planet_runtime.teleport_player_to_planet_square(player, planet_name)
  assert(planet_name, "planet_name is required")
  local planet = planet_instance.ensure(planet_name)

  if not planet then
    return
  end

  local surface = game.surfaces[planet:get_surface_name()]

  if not surface then
    return
  end

  local target_position = planet:get_square_position()
  player.force.set_spawn_position(target_position, surface)
  player.teleport(target_position, surface)
  planet_runtime.chart_play_area(
    player.force,
    surface,
    planet:get_surface_size(),
    target_position
  )
end

function planet_runtime.expand_planet_square(planet_name, player, gui_runtime, anchor_runtime)
  assert(planet_name, "planet_name is required")
  local planet_square_runtime = require("lib.planet_square_runtime")

  return planet_square_runtime.expand(planet_name, {
    player = player,
    gui_runtime = gui_runtime,
    anchor_runtime = anchor_runtime
  }) ~= nil
end

function planet_runtime.initialize_world(anchor_runtime, gui_runtime)
  planet_runtime.configure_freeplay()

  local surface = planet_runtime.initialize_planet_surface("nauvis")
  game.forces.player.set_spawn_position({x = 0, y = 0}, surface)

  if anchor_runtime then
    anchor_runtime.initialize("nauvis")
    anchor_runtime.apply_logistic_network_setting_to_all_forces()
  end

  for _, player in pairs(game.players) do
    planet_runtime.teleport_player_to_planet_square(player, "nauvis")
  end

  if gui_runtime then
    gui_runtime.sync_all_dev_guis()
    gui_runtime.sync_all_screenshot_guis()
    gui_runtime.sync_all_square_move_guis()
  end
end

function planet_runtime.refresh_spawn_routing(planet_name, anchor_runtime, gui_runtime)
  assert(planet_name, "planet_name is required")
  local planet = planet_runtime.ensure_planet_state(planet_name)

  if not planet then
    return
  end

  local surface = game.surfaces[planet:get_surface_name()]

  if not surface then
    return
  end

  planet_runtime.configure_freeplay()
  local square_position = planet:get_square_position()
  game.forces.player.set_spawn_position(square_position, surface)
  ensure_surface_dimensions(
    surface,
    planet:get_surface_size(),
    square_position
  )

  if anchor_runtime then
    anchor_runtime.reconcile(planet_name)
    anchor_runtime.apply_logistic_network_setting_to_all_forces()
  end

  for _, player in pairs(game.players) do
    planet_runtime.teleport_player_to_planet_square(player, planet_name)
  end

  if gui_runtime then
    gui_runtime.sync_all_dev_guis()
    gui_runtime.sync_all_square_move_guis()
  end
end

function planet_runtime.notify_square_size_change_applies_to_new_saves(planet_name)
  assert(planet_name, "planet_name is required")
  local planet = planet_instance.ensure(planet_name)
  local config = planet_config.get(planet_name)

  if not (planet and config) or planet:get_square_size() == config.square_size then
    return
  end

  game.print(
    {"",
      "[the-square] Starting square size changes only apply to new saves. ",
      "This save remains at ",
      planet:get_square_size(),
      " and the current map setting is ",
      config.square_size,
      "."
    }
  )
end

return planet_runtime
