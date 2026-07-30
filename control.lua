local managed_line_runtime = require("lib.managed_line_runtime")
local planet_runtime = require("lib.planet_runtime")
local defs = require("lib.runtime_defs")
local debug_platform_runtime = require("lib.debug_platform_runtime")
local planet_square_runtime = require("lib.planet_square_runtime")
local gui_runtime = require("lib.gui_runtime")
local screenshot_runtime = require("lib.screenshot_runtime")
local square_move_runtime = require("lib.square_move_runtime")
local void_item_runtime = require("lib.void_item_runtime")

local function sync_all_runtime_guis()
  gui_runtime.refresh_all_debug_guis()
  gui_runtime.sync_all_square_move_guis()
end

local function sync_research_runtime_state(force)
  local target_force = force or defs.get_player_force()

  if target_force then
    managed_line_runtime.sync_tier(target_force)
    if not defs.is_logistic_network_automation_enabled() then
      managed_line_runtime.apply_logistic_network_setting_to_force(target_force)
    end
  end

  sync_all_runtime_guis()
end

local function initialize_world()
  planet_runtime.initialize_world(managed_line_runtime, gui_runtime)
end

local function handle_player_join_or_respawn(event)
  local player = game.get_player(event.player_index)

  if player then
    planet_runtime.teleport_player_to_planet_square(player, "nauvis")
    planet_runtime.grant_initial_managed_line_inventory(player, "nauvis")
    gui_runtime.sync_dev_gui(player)
    gui_runtime.sync_screenshot_gui(player)
    gui_runtime.sync_square_move_gui(player)
    gui_runtime.sync_cliff_explosive_gui(player)
  end
end

script.on_init(function()
  initialize_world()
end)

script.on_configuration_changed(function()
  local nauvis = storage.planets and storage.planets.nauvis and planet_runtime.ensure_planet_state("nauvis")

  if nauvis then
    local planet_state = nauvis:get_state()
    managed_line_runtime.refresh_existing_planets()
    managed_line_runtime.sync_tier(defs.get_player_force())

    if nauvis:get_square_size() ~= defs.get_square_size() then
      planet_runtime.notify_square_size_change_applies_to_new_saves("nauvis")
    end

    local surface = game.surfaces[nauvis:get_surface_name()]

    if surface then
      planet_runtime.refresh_all_generated_chunk_tiles(
        surface,
        nauvis:get_square_size(),
        nauvis:get_surface_size(),
        planet_state.square_position
      )
      planet_runtime.clear_surface_chart(surface)
    end

    gui_runtime.sync_all_dev_guis()
    gui_runtime.sync_all_screenshot_guis()
    gui_runtime.sync_all_square_move_guis()
    gui_runtime.sync_all_cliff_explosive_guis()
    planet_runtime.refresh_spawn_routing("nauvis", managed_line_runtime, gui_runtime)
    return
  end

  initialize_world()
end)

script.on_event(defines.events.on_player_created, handle_player_join_or_respawn)
script.on_event(defines.events.on_player_respawned, handle_player_join_or_respawn)

script.on_event(defines.events.on_chunk_generated, function(event)
  if planet_runtime.refresh_generated_chunk_for_planet_surface(event.surface, event.area) then
    managed_line_runtime.initialize(event.surface.name)
  end
end)

script.on_event(defines.events.on_player_rotated_entity, function(event)
  managed_line_runtime.handle_rotated(event.entity)
end)

script.on_event(defines.events.on_player_flipped_entity, function(event)
  managed_line_runtime.handle_rotated(event.entity)
end)

if defines.events.on_entity_settings_pasted then
  script.on_event(defines.events.on_entity_settings_pasted, function(event)
    managed_line_runtime.handle_recipe_changed(event.destination, game.get_player(event.player_index))
  end)
end

if defines.events.on_gui_opened then
  script.on_event(defines.events.on_gui_opened, function(event)
    if event.entity then
      managed_line_runtime.handle_gui_opened(event.entity, game.get_player(event.player_index))
    end
  end)
end

if defines.events.on_gui_closed then
  script.on_event(defines.events.on_gui_closed, function(event)
    if event.element and gui_runtime.handle_square_move_gui_closed(game.get_player(event.player_index), event.element) then
      return
    end

    if event.element and managed_line_runtime.handle_config_gui_closed(game.get_player(event.player_index), event.element) then
      return
    end

    if event.entity then
      managed_line_runtime.handle_recipe_changed(event.entity, game.get_player(event.player_index))
    end
  end)
end

local function handle_entity_built(event)
  managed_line_runtime.handle_built(event, gui_runtime)
  void_item_runtime.destroy_if_void_item(event)
end

script.on_event(defines.events.on_built_entity, handle_entity_built)
script.on_event(defines.events.on_robot_built_entity, handle_entity_built)
script.on_event(defines.events.script_raised_built, handle_entity_built)
script.on_event(defines.events.script_raised_revive, handle_entity_built)

if defines.events.on_player_dropped_item then
  script.on_event(defines.events.on_player_dropped_item, function(event)
    void_item_runtime.destroy_if_void_item(event)
  end)
end

if defines.events.on_trigger_created_entity then
  script.on_event(defines.events.on_trigger_created_entity, function(event)
    void_item_runtime.destroy_if_void_item(event)
  end)
end

local function handle_anchor_removed(event)
  managed_line_runtime.handle_mined(event.entity)
end

script.on_event(defines.events.on_player_mined_entity, handle_anchor_removed)
script.on_event(defines.events.on_robot_mined_entity, handle_anchor_removed)
script.on_event(defines.events.on_entity_died, handle_anchor_removed)

script.on_event(defines.events.on_gui_click, function(event)
  if not (event.element and event.element.valid) then
    return
  end

  local player = game.get_player(event.player_index)

  if managed_line_runtime.handle_config_gui_click(player, event.element) then
    return
  end

  if event.element.name == defs.DEV_EXPAND_BUTTON_NAME then
    if player and gui_runtime.is_dev_mode_enabled(player) then
      planet_square_runtime.expand("nauvis", {
        player = player,
        gui_runtime = gui_runtime,
        managed_line_runtime = managed_line_runtime,
        announce_global = true
      })
      sync_all_runtime_guis()
    end

    return
  end

  local debug_orbit_planet = debug_platform_runtime.get_button_planet_name(event.element.name)

  if debug_orbit_planet then
    if player and gui_runtime.is_dev_mode_enabled(player) and debug_platform_runtime.is_space_age_active() then
      local result = debug_platform_runtime.teleport_player_to_planet_platform(player, debug_orbit_planet)

      if not result.ok then
        player.print(result.error)
      end
    end

    return
  end

  if event.element.name == defs.SCREENSHOT_BUTTON_NAME then
    screenshot_runtime.take_base_screenshot(player)
    return
  end

  if event.element.name == defs.SQUARE_MOVE_BUTTON_NAME then
    gui_runtime.toggle_square_move_gui(player, square_move_runtime)
    return
  end

  local square_move_direction = square_move_runtime.parse_direction_button_name(event.element.name)

  if square_move_direction then
    local result = square_move_runtime.move_for_player(player, square_move_direction, {
      managed_line_runtime = managed_line_runtime,
      mode = gui_runtime.get_square_move_mode(player)
    })

    if not result.ok and player then
      if result.reason == "obstructed" then
        player.print({
          result.mode == square_move_runtime.MODE_CONTENTS
              and "message.the-square-move-contents-obstructed"
            or "message.the-square-move-obstructed",
          {"the-square-direction." .. result.obstructed_side}
        })
      elseif result.reason == "unmovable" then
        player.print({"message.the-square-move-contents-unmovable"})
      else
        player.print({"message.the-square-move-unsupported"})
      end
    end

    gui_runtime.refresh_all_square_move_guis(square_move_runtime)
    gui_runtime.refresh_all_debug_guis()
    return
  end

  if event.element.name == defs.CLIFF_EXPLOSIVE_BUTTON_NAME then
    if player and gui_runtime.is_cliff_explosive_button_enabled(player) then
      player.insert({name = "cliff-explosives", count = 1})
    end

    return
  end

end)

script.on_event(defines.events.on_gui_switch_state_changed, function(event)
  if not (event.element and event.element.valid) then
    return
  end

  gui_runtime.handle_square_move_mode_changed(
    game.get_player(event.player_index),
    event.element,
    square_move_runtime
  )
end)

script.on_event(defs.PLACE_MANAGED_ANCHOR_INPUT_NAME, function(event)
  local player = game.get_player(event.player_index)

  if player then
    managed_line_runtime.handle_slot_click(player)
  end
end)

script.on_event(defs.OPEN_MANAGED_ANCHOR_INPUT_NAME, function(event)
  local player = game.get_player(event.player_index)

  if player and player.selected then
    managed_line_runtime.handle_gui_opened(player.selected, player)
  end
end)

script.on_event(defines.events.on_runtime_mod_setting_changed, function(event)
  if event.setting == defs.SETTING_ENABLE_LOGISTIC_NETWORK_AUTOMATION then
    managed_line_runtime.apply_logistic_network_setting_to_all_forces()
    return
  end

  if event.setting == defs.SETTING_BACKGROUND_TILE then
    local nauvis_state = storage.planets and storage.planets.nauvis
    local surface = nauvis_state and game.surfaces[nauvis_state.surface_name]

    if surface and nauvis_state then
      planet_runtime.refresh_all_generated_chunk_tiles(
        surface,
        nauvis_state.square_size,
        nauvis_state.surface_size,
        nauvis_state.square_position
      )
    end

    gui_runtime.refresh_all_debug_guis()
    return
  end

  if event.setting == defs.SETTING_DEV_MODE then
    local player = game.get_player(event.player_index)

    if player then
      gui_runtime.sync_dev_gui(player)
    end

    return
  end

  if event.setting == defs.SETTING_CLIFF_EXPLOSIVE_BUTTON then
    local player = game.get_player(event.player_index)

    if player then
      gui_runtime.sync_cliff_explosive_gui(player)
    end
  end
end)

script.on_event(defines.events.on_research_finished, function(event)
  local research = event.research

  if not (research and research.valid and research.force) then
    return
  end

  if planet_square_runtime.expand_after_research(research, {
    gui_runtime = gui_runtime,
    managed_line_runtime = managed_line_runtime
  }) then
    sync_all_runtime_guis()
  end

  if managed_line_runtime.sync_tier(research.force) then
    sync_all_runtime_guis()
  end

  if not defs.is_logistic_network_automation_enabled() then
    managed_line_runtime.apply_logistic_network_setting_to_force(research.force)
  end
end)

script.on_nth_tick(1, function()
  managed_line_runtime.pump_all()
end)

script.on_nth_tick(30, function()
  gui_runtime.refresh_all_square_move_guis(square_move_runtime)
end)

remote.add_interface("the-square", {
  sync_research_runtime_state = function(force_name)
    local force = force_name and game.forces[force_name] or defs.get_player_force()
    sync_research_runtime_state(force)
  end,
  set_playtest_debug_enabled = function(enabled)
    storage.the_square_playtest_debug_enabled = enabled and true or nil
    gui_runtime.sync_all_dev_guis()
  end
})
