local anchor_runtime = require("lib.anchor_runtime")
local bootstrap_runtime = require("lib.bootstrap_runtime")
local defs = require("lib.runtime_defs")
local growth_runtime = require("lib.growth_runtime")
local gui_runtime = require("lib.gui_runtime")
local ingress_runtime = require("lib.ingress_runtime")

local function sync_all_runtime_guis()
  gui_runtime.refresh_all_status_guis()
  gui_runtime.refresh_all_debug_guis()
  gui_runtime.sync_all_shop_guis(anchor_runtime)
end

local function bootstrap_world()
  bootstrap_runtime.bootstrap_world(anchor_runtime, gui_runtime)
end

local function handle_player_join_or_respawn(event)
  local player = game.get_player(event.player_index)

  if player then
    bootstrap_runtime.teleport_player_to_square(player)
    gui_runtime.sync_status_gui(player)
    gui_runtime.sync_dev_gui(player)
    gui_runtime.sync_shop_gui(player, anchor_runtime)
  end
end

script.on_init(function()
  bootstrap_world()
end)

script.on_configuration_changed(function()
  if storage.bootstrap then
    bootstrap_runtime.ensure_bootstrap_state_defaults()
    anchor_runtime.ensure_starter_anchor_state()
    anchor_runtime.sync_ingress_tier_from_research(defs.get_player_force())

    if storage.bootstrap.square_size ~= defs.get_square_size() then
      bootstrap_runtime.notify_square_size_change_applies_to_new_saves()
    end

    local surface = game.surfaces[storage.bootstrap.surface_name]

    if surface then
      bootstrap_runtime.refresh_managed_surface_tiles(surface, storage.bootstrap.square_size, storage.bootstrap.surface_size)
    end

    bootstrap_runtime.refresh_spawn_routing(anchor_runtime, gui_runtime)
    return
  end

  bootstrap_world()
end)

script.on_event(defines.events.on_player_created, handle_player_join_or_respawn)
script.on_event(defines.events.on_player_respawned, handle_player_join_or_respawn)

script.on_event(defines.events.on_player_rotated_entity, function(event)
  anchor_runtime.reset_rotated_anchor(event.entity)
end)

script.on_event(defines.events.on_player_flipped_entity, function(event)
  anchor_runtime.reset_rotated_anchor(event.entity)
end)

local function handle_entity_built(event)
  anchor_runtime.handle_entity_built(event, gui_runtime)
  gui_runtime.sync_all_shop_guis(anchor_runtime)
end

script.on_event(defines.events.on_built_entity, handle_entity_built)
script.on_event(defines.events.on_robot_built_entity, handle_entity_built)
script.on_event(defines.events.script_raised_built, handle_entity_built)
script.on_event(defines.events.script_raised_revive, handle_entity_built)

local function handle_anchor_removed(event)
  anchor_runtime.handle_anchor_mined(event.entity)
  gui_runtime.sync_all_shop_guis(anchor_runtime)
end

script.on_event(defines.events.on_player_mined_entity, handle_anchor_removed)
script.on_event(defines.events.on_robot_mined_entity, handle_anchor_removed)
script.on_event(defines.events.on_entity_died, handle_anchor_removed)

script.on_event(defines.events.on_gui_click, function(event)
  if not (event.element and event.element.valid) then
    return
  end

  local player = game.get_player(event.player_index)

  if event.element.name == defs.DEV_EXPAND_BUTTON_NAME then
    if player and gui_runtime.is_dev_mode_enabled(player) then
      bootstrap_runtime.expand_square(player, gui_runtime, anchor_runtime)
      sync_all_runtime_guis()
    end

    return
  end

  if event.element.name == defs.SHOP_BUTTON_NAME then
    gui_runtime.toggle_shop_gui(player, anchor_runtime)
    return
  end

  local resource = string.match(event.element.name, "^fes_shop_buy__(.+)$")

  if resource and player then
    anchor_runtime.purchase_managed_line(player, resource)
    gui_runtime.refresh_shop_gui(player, anchor_runtime)
    gui_runtime.refresh_all_debug_guis()
    gui_runtime.sync_all_shop_guis(anchor_runtime)
  end
end)

script.on_event(defs.PLACE_MANAGED_ANCHOR_INPUT_NAME, function(event)
  local player = game.get_player(event.player_index)

  if player then
    anchor_runtime.handle_managed_anchor_slot_click(player)
    gui_runtime.sync_all_shop_guis(anchor_runtime)
  end
end)

script.on_event(defines.events.on_runtime_mod_setting_changed, function(event)
  if event.setting == defs.SETTING_STARTING_SQUARE_SIZE then
    if storage.bootstrap then
      bootstrap_runtime.notify_square_size_change_applies_to_new_saves()
    end

    return
  end

  if event.setting == defs.SETTING_ENABLE_LOGISTIC_NETWORK_AUTOMATION then
    anchor_runtime.apply_logistic_network_setting_to_all_forces()
    gui_runtime.refresh_all_status_guis()
    return
  end

  if event.setting == defs.SETTING_LINE_PURCHASE_COST then
    gui_runtime.sync_all_shop_guis(anchor_runtime)
    return
  end

  if event.setting == defs.SETTING_DEV_MODE then
    local player = game.get_player(event.player_index)

    if player then
      gui_runtime.sync_dev_gui(player)
      gui_runtime.sync_shop_gui(player, anchor_runtime)
      gui_runtime.sync_status_gui(player)
    end
  end
end)

script.on_event(defines.events.on_research_finished, function(event)
  local research = event.research

  if not (research and research.valid and research.force) then
    return
  end

  if growth_runtime.handle_expansion_research_finished(research, bootstrap_runtime, gui_runtime, anchor_runtime) then
    sync_all_runtime_guis()
  end

  if anchor_runtime.sync_ingress_tier_from_research(research.force) then
    sync_all_runtime_guis()
  end

  if not defs.is_logistic_network_automation_enabled() then
    anchor_runtime.apply_logistic_network_setting_to_force(research.force)
  end
end)

script.on_nth_tick(1, function()
  ingress_runtime.pump_starter_anchors()
end)

script.on_nth_tick(defs.ITEM_ANCHOR_INTERVAL_TICKS, function()
  anchor_runtime.ensure_starter_anchors()
  anchor_runtime.update_all_player_anchor_previews()
end)
