local defs = require("lib.runtime_defs")
local planet_config = require("lib.planet_config")
local planet_instance = require("lib.planet_instance")
local planet_square = require("lib.planet_square")

local bootstrap_runtime = {}
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

function bootstrap_runtime.build_starter_anchor_layout(square_size, planet_name)
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

local function call_freeplay(interface_name, value)
  if remote.interfaces.freeplay and remote.interfaces.freeplay[interface_name] then
    remote.call("freeplay", interface_name, value)
  end
end

local function build_managed_surface_tiles(square_size, surface_size, floor_tile_name)
  local surface_bounds = defs.get_square_bounds(surface_size)
  local tiles = {}

  for y = surface_bounds.left_top.y, surface_bounds.right_bottom.y - 1 do
    for x = surface_bounds.left_top.x, surface_bounds.right_bottom.x - 1 do
      tiles[#tiles + 1] = {
        name = defs.get_managed_tile_name(square_size, surface_size, {x = x, y = y}, floor_tile_name),
        position = {x = x, y = y}
      }
    end
  end

  return tiles
end

function bootstrap_runtime.refresh_managed_surface_tiles(surface, square_size, surface_size, floor_tile_name)
  if not surface then
    return
  end

  local tile_updates = build_managed_surface_tiles(square_size, surface_size, floor_tile_name)

  if #tile_updates > 0 then
    -- Keep tile correction enabled so Factorio rebuilds the soft edge transition
    -- between the playable floor and the out-of-map ring immediately.
    surface.set_tiles(tile_updates, true, true, true, false)
  end
end

local function build_bootstrap_tiles(square_size, surface_size)
  return build_managed_surface_tiles(square_size, surface_size)
end

function bootstrap_runtime.build_generated_chunk_tiles(square_size, surface_size, area, floor_tile_name)
  local tiles = {}

  for y = area.left_top.y, area.right_bottom.y - 1 do
    for x = area.left_top.x, area.right_bottom.x - 1 do
      local position = {x = x, y = y}
      local tile_name = defs.get_managed_tile_name(square_size, surface_size, position, floor_tile_name) or defs.VOID_TILE_NAME

      tiles[#tiles + 1] = {
        name = tile_name,
        position = position
      }
    end
  end

  return tiles
end

function bootstrap_runtime.refresh_generated_chunk_tiles(surface, square_size, surface_size, area, floor_tile_name)
  if not (surface and area) then
    return
  end

  local tile_updates = bootstrap_runtime.build_generated_chunk_tiles(square_size, surface_size, area, floor_tile_name)

  if #tile_updates > 0 then
    surface.set_tiles(tile_updates, true, true, true, false)
  end
end

function bootstrap_runtime.refresh_all_generated_chunk_tiles(surface, square_size, surface_size)
  if not surface then
    return
  end

  for chunk in surface.get_chunks() do
    bootstrap_runtime.refresh_generated_chunk_tiles(surface, square_size, surface_size, {
      left_top = {x = chunk.x * 32, y = chunk.y * 32},
      right_bottom = {x = (chunk.x + 1) * 32, y = (chunk.y + 1) * 32}
    })
  end
end

function bootstrap_runtime.refresh_generated_chunk_for_planet_surface(surface, area)
  if not (surface and area) then
    return false
  end

  local planet = planet_instance.for_surface(surface.name)

  if not planet then
    return false
  end

  bootstrap_runtime.refresh_generated_chunk_tiles(
    surface,
    planet:get_square_size(),
    planet:get_surface_size(),
    area,
    planet:get_floor_tile_name()
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

function bootstrap_runtime.ensure_bootstrap_state_defaults()
  local nauvis = planet_instance.ensure_nauvis()

  if not nauvis then
    return
  end

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
  local nauvis_config = planet_config.get("nauvis")
  local square_size = nauvis_config.square_size
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
  local nauvis = planet_instance.from_bootstrap(storage.bootstrap)
  nauvis:set_square_size(square_size)
  nauvis:set_surface_name(defs.SURFACE_NAME)
  bootstrap_runtime.ensure_bootstrap_state_defaults()

  return surface
end

function bootstrap_runtime.clear_surface_chart(surface)
  if not surface then
    return
  end

  for _, force in pairs(game.forces) do
    if force.valid and force.clear_chart then
      force.clear_chart(surface)
    end
  end
end

function bootstrap_runtime.chart_play_area(force, surface, surface_size)
  planet_square.chart_play_area(force, surface, surface_size)
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
  local nauvis = planet_instance.ensure_nauvis()

  if not nauvis then
    return
  end

  nauvis:add_expansion_points(amount)
end

function bootstrap_runtime.expand_planet_square(planet_name, player, gui_runtime, anchor_runtime)
  local planet_square_runtime = require("lib.planet_square_runtime")

  return planet_square_runtime.expand(planet_name, {
    player = player,
    gui_runtime = gui_runtime,
    anchor_runtime = anchor_runtime
  }) ~= nil
end

function bootstrap_runtime.expand_square(player, gui_runtime, anchor_runtime)
  local planet_square_runtime = require("lib.planet_square_runtime")

  return planet_square_runtime.expand("nauvis", {
    player = player,
    gui_runtime = gui_runtime,
    anchor_runtime = anchor_runtime,
    announce_global = true
  })
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
    gui_runtime.sync_all_dev_guis()
    gui_runtime.sync_all_screenshot_guis()
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
    gui_runtime.sync_all_dev_guis()
    gui_runtime.sync_all_shop_guis(anchor_runtime)
  end
end

function bootstrap_runtime.notify_square_size_change_applies_to_new_saves()
  local requested_size = defs.get_square_size()

  if storage.bootstrap and storage.bootstrap.square_size == requested_size then
    return
  end

  game.print(
    {"",
      "[the-square] Starting square size changes only apply to new saves. ",
      "This save remains at ",
      storage.bootstrap and storage.bootstrap.square_size or "?",
      " and the current map setting is ",
      requested_size,
      "."
    }
  )
end

return bootstrap_runtime
