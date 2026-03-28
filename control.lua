local SURFACE_NAME = "fes-bootstrap"
local SETTING_STARTING_SQUARE_SIZE = "fes-starting-square-size"
local FLOOR_TILE_NAME = "grass-1"
local CHART_MARGIN = 1

local function get_square_size()
  local value = settings.startup[SETTING_STARTING_SQUARE_SIZE].value

  if value % 2 == 0 then
    value = value + 1
  end

  return value
end

local function get_square_bounds(size)
  local half_extent = math.floor(size / 2)

  return {
    left_top = {x = -half_extent, y = -half_extent},
    right_bottom = {x = half_extent + 1, y = half_extent + 1}
  }
end

local function call_freeplay(interface_name, value)
  if remote.interfaces.freeplay and remote.interfaces.freeplay[interface_name] then
    remote.call("freeplay", interface_name, value)
  end
end

local function build_clean_square_tiles(size)
  local half_extent = math.floor(size / 2)
  local tiles = {}

  for y = -half_extent, half_extent do
    for x = -half_extent, half_extent do
      tiles[#tiles + 1] = {
        name = FLOOR_TILE_NAME,
        position = {x = x, y = y}
      }
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
  return {
    width = square_size,
    height = square_size,
    starting_points = {{x = 0, y = 0}},
    peaceful_mode = true,
    no_enemies_mode = true
  }
end

local function ensure_bootstrap_surface()
  local square_size = get_square_size()
  local surface = game.surfaces[SURFACE_NAME]

  if not surface then
    surface = game.create_surface(SURFACE_NAME, build_surface_map_gen_settings(square_size))
  end

  surface.peaceful_mode = true
  surface.no_enemies_mode = true
  surface.request_to_generate_chunks({x = 0, y = 0}, CHART_MARGIN)
  surface.force_generate_chunk_requests()
  surface.destroy_decoratives({})
  surface.clear_hidden_tiles()
  destroy_noise_entities(surface)
  surface.set_tiles(build_clean_square_tiles(square_size), true, true, true, false)

  storage.bootstrap = {
    square_size = square_size,
    surface_name = SURFACE_NAME
  }

  return surface
end

local function teleport_player_to_square(player)
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

  local chart_bounds = get_square_bounds(bootstrap.square_size)
  player.force.chart(surface, {
    {
      chart_bounds.left_top.x - CHART_MARGIN,
      chart_bounds.left_top.y - CHART_MARGIN
    },
    {
      chart_bounds.right_bottom.x + CHART_MARGIN,
      chart_bounds.right_bottom.y + CHART_MARGIN
    }
  })
end

local function bootstrap_world()
  call_freeplay("set_skip_intro", true)
  call_freeplay("set_disable_crashsite", true)

  local surface = ensure_bootstrap_surface()
  game.forces.player.set_spawn_position({x = 0, y = 0}, surface)

  for _, player in pairs(game.players) do
    teleport_player_to_square(player)
  end
end

local function refresh_spawn_routing()
  local bootstrap = storage.bootstrap

  if not bootstrap then
    return
  end

  local surface = game.surfaces[bootstrap.surface_name]

  if not surface then
    return
  end

  call_freeplay("set_skip_intro", true)
  call_freeplay("set_disable_crashsite", true)
  game.forces.player.set_spawn_position({x = 0, y = 0}, surface)

  for _, player in pairs(game.players) do
    teleport_player_to_square(player)
  end
end

script.on_init(function()
  bootstrap_world()
end)

script.on_configuration_changed(function()
  if storage.bootstrap then
    refresh_spawn_routing()
    return
  end

  bootstrap_world()
end)

script.on_event(defines.events.on_player_created, function(event)
  local player = game.get_player(event.player_index)

  if player then
    teleport_player_to_square(player)
  end
end)

script.on_event(defines.events.on_player_respawned, function(event)
  local player = game.get_player(event.player_index)

  if player then
    teleport_player_to_square(player)
  end
end)
