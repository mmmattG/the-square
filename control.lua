-- Event routing only. Each handler hands off to the module that owns the behaviour.
local anchor_config_gui = require("lib.anchor_config_gui")
local anchor_runtime = require("lib.anchor_runtime")
local definitions = require("lib.managed_line_definitions")
local gui_runtime = require("lib.gui_runtime")
local managed_line_pump = require("lib.managed_line_pump")
local managed_line_tiers = require("lib.managed_line_tiers")
local mod_settings = require("lib.mod_settings")
local planet_runtime = require("lib.planet_runtime")
local planet_state = require("lib.planet_state")
local square_move_gui = require("lib.square_move_gui")
local square_runtime = require("lib.square_runtime")
local void_item_runtime = require("lib.void_item_runtime")

local function sync_player_guis(player)
  gui_runtime.sync(player)
  square_move_gui.sync(player)
end

local function sync_all_guis()
  for _, player in pairs(game.players) do
    sync_player_guis(player)
  end
end

script.on_init(function()
  planet_runtime.initialize_world()
  sync_all_guis()
end)

script.on_configuration_changed(function()
  planet_runtime.handle_configuration_changed()
  sync_all_guis()
end)

local function handle_player_arrived(event)
  local player = game.get_player(event.player_index)

  planet_runtime.move_player_to_square(player)
  planet_runtime.grant_initial_line_items(player)
  sync_player_guis(player)
end

script.on_event(defines.events.on_player_created, handle_player_arrived)
script.on_event(defines.events.on_player_respawned, handle_player_arrived)

script.on_event(defines.events.on_chunk_generated, function(event)
  planet_runtime.handle_chunk_generated(event.surface, event.area)
end)

local function handle_entity_rotated(event)
  anchor_runtime.handle_entity_rotated(event.entity)
end

script.on_event(defines.events.on_player_rotated_entity, handle_entity_rotated)
script.on_event(defines.events.on_player_flipped_entity, handle_entity_rotated)

local function handle_entity_built(event)
  anchor_runtime.handle_entity_built(event)
  void_item_runtime.destroy_if_in_void(event.entity)
end

script.on_event(defines.events.on_built_entity, handle_entity_built)
script.on_event(defines.events.on_robot_built_entity, handle_entity_built)
script.on_event(defines.events.script_raised_built, handle_entity_built)
script.on_event(defines.events.script_raised_revive, handle_entity_built)

local function handle_item_entity_created(event)
  void_item_runtime.destroy_if_in_void(event.entity)
end

script.on_event(defines.events.on_player_dropped_item, handle_item_entity_created)
script.on_event(defines.events.on_trigger_created_entity, handle_item_entity_created)

local function handle_entity_removed(event)
  anchor_runtime.handle_entity_removed(event.entity)
end

script.on_event(defines.events.on_player_mined_entity, handle_entity_removed)
script.on_event(defines.events.on_robot_mined_entity, handle_entity_removed)
script.on_event(defines.events.on_entity_died, handle_entity_removed)

script.on_event(defines.events.on_gui_opened, function(event)
  if event.entity then
    anchor_config_gui.handle_entity_opened(game.get_player(event.player_index), event.entity)
  end
end)

script.on_event(defines.events.on_gui_closed, function(event)
  local element = event.element

  if not (element and element.valid) then
    return
  end

  local player = game.get_player(event.player_index)

  if not square_move_gui.handle_closed(player, element) then
    anchor_config_gui.handle_closed(player, element)
  end
end)

script.on_event(defines.events.on_gui_click, function(event)
  local element = event.element

  if not element.valid then
    return
  end

  local player = game.get_player(event.player_index)

  if anchor_config_gui.handle_click(player, element) or gui_runtime.handle_click(player, element) then
    return
  end

  if square_move_gui.handle_click(player, element) then
    gui_runtime.refresh_all_debug_panels()
  end
end)

script.on_event(defines.events.on_gui_switch_state_changed, function(event)
  if event.element.valid then
    square_move_gui.handle_switch_changed(game.get_player(event.player_index), event.element)
  end
end)

-- Clicks on Anchors (see the custom inputs in prototypes/managed_lines.lua).
script.on_event(definitions.PLACE_INPUT_NAME, function(event)
  anchor_config_gui.handle_slot_click(game.get_player(event.player_index))
end)

script.on_event(definitions.OPEN_INPUT_NAME, function(event)
  local player = game.get_player(event.player_index)

  if player.selected then
    anchor_config_gui.handle_entity_opened(player, player.selected)
  end
end)

script.on_event(defines.events.on_runtime_mod_setting_changed, function(event)
  if event.setting == mod_settings.BACKGROUND_TILE then
    square_runtime.repaint(planet_state.get("nauvis"))
    gui_runtime.refresh_all_debug_panels()
  elseif event.setting == mod_settings.DEV_MODE or event.setting == mod_settings.CLIFF_EXPLOSIVE_BUTTON then
    gui_runtime.sync(game.get_player(event.player_index))
  end
end)

script.on_event(defines.events.on_research_finished, function(event)
  local expanded = planet_runtime.handle_research_finished(event.research)

  -- Upgrades change which tiers Anchor Slot Configuration offers.
  if expanded or managed_line_tiers.is_upgrade_technology(event.research.name) then
    gui_runtime.refresh_all_debug_panels()
    square_move_gui.sync_all()
  end
end)

script.on_nth_tick(1, function()
  managed_line_pump.pump_all()
end)

script.on_nth_tick(30, function()
  square_move_gui.refresh_all()
end)

-- Used by the playtest launcher (scripts/playtest-world.sh).
remote.add_interface("the-square", {
  sync_research_runtime_state = function()
    gui_runtime.refresh_all_debug_panels()
    square_move_gui.sync_all()
  end,
  set_playtest_debug_enabled = function(enabled)
    storage.the_square_playtest_debug_enabled = enabled and true or nil
    gui_runtime.sync_all()
  end
})
