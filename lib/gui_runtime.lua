local defs = require("lib.runtime_defs")
local debug_platform_runtime = require("lib.debug_platform_runtime")

local gui_runtime = {}
local MOVE_MODES = defs.SQUARE_MOVE_MODES

local function destroy_child(parent, name)
  local child = parent and parent[name]

  if child and child.valid then
    child.destroy()
  end
end

local function build_ingress_edge_check_debug(square_size, position, square_position)
  local tile_position = defs.snap_entity_position_to_tile(position)
  local bounds = defs.get_anchor_bounds(square_size, square_position)
  local min_x = bounds.left_top.x
  local min_y = bounds.left_top.y
  local max_x = bounds.right_bottom.x - 1
  local max_y = bounds.right_bottom.y - 1
  local north_match = tile_position.y == min_y and tile_position.x > min_x and tile_position.x < max_x
  local east_match = tile_position.x == max_x and tile_position.y > min_y and tile_position.y < max_y
  local south_match = tile_position.y == max_y and tile_position.x > min_x and tile_position.x < max_x
  local west_match = tile_position.x == min_x and tile_position.y > min_y and tile_position.y < max_y
  local detected_side = defs.get_anchor_side_for_position(square_size, tile_position, square_position)

  return table.concat({
    "[the-square] Ingress placement debug",
    "raw_position=" .. defs.format_position(position),
    "tile_position=" .. defs.format_position(tile_position),
    "square_size=" .. square_size,
    "anchor_bounds.left_top=" .. defs.format_position(bounds.left_top),
    "anchor_bounds.right_bottom=" .. defs.format_position(bounds.right_bottom),
    "min=(" .. min_x .. ", " .. min_y .. ")",
    "max=(" .. max_x .. ", " .. max_y .. ")",
    "north=" .. tostring(north_match),
    "east=" .. tostring(east_match),
    "south=" .. tostring(south_match),
    "west=" .. tostring(west_match),
    "detected_side=" .. tostring(detected_side)
  }, " | ")
end

function gui_runtime.is_dev_mode_enabled(player)
  if storage and storage.the_square_playtest_debug_enabled then
    return true
  end

  return settings.get_player_settings(player)[defs.SETTING_DEV_MODE].value
end

function gui_runtime.is_ingress_placement_debug_enabled(player)
  if storage and storage.the_square_playtest_debug_enabled then
    return true
  end

  return player
    and player.valid
    and settings.get_player_settings(player)[defs.SETTING_INGRESS_PLACEMENT_DEBUG].value
end

function gui_runtime.is_cliff_explosive_button_enabled(player)
  return player
    and player.valid
    and settings.get_player_settings(player)[defs.SETTING_CLIFF_EXPLOSIVE_BUTTON].value
end

function gui_runtime.print_ingress_placement_debug(player, square_size, position, square_position)
  if not gui_runtime.is_ingress_placement_debug_enabled(player) then
    return
  end

  player.print(build_ingress_edge_check_debug(square_size, position, square_position))
end

local function ensure_debug_frame(player)
  local frame = player.gui.left[defs.DEBUG_FRAME_NAME]

  if frame then
    return frame
  end

  return player.gui.left.add({
    type = "frame",
    name = defs.DEBUG_FRAME_NAME,
    direction = "vertical",
    caption = {"gui.the-square-debug-title"}
  })
end

local function build_status_lines()
  local planet_state = storage.planets and storage.planets.nauvis
  local lines = {}

  if not planet_state then
    lines[#lines + 1] = "No expansion data yet."
    return lines
  end

  local next_reward = defs.get_next_expansion_tile_reward(planet_state.square_size)
  local completed_levels = defs.get_completed_expansion_research_levels("nauvis")
  local next_level = completed_levels + 1
  local next_band = defs.get_expansion_research_band_for_level(next_level)

  lines[#lines + 1] = "Square: " .. planet_state.square_size .. "x" .. planet_state.square_size
  lines[#lines + 1] = "Background tile: " .. defs.get_background_tile_name()
  lines[#lines + 1] = "Logistics setting: "
    .. (defs.is_logistic_network_automation_enabled() and "enabled" or "disabled")
  lines[#lines + 1] = "Expansion research: " .. completed_levels .. " levels completed"
  lines[#lines + 1] = "Next expansion: level " .. next_level .. " using " .. next_band.label
  lines[#lines + 1] = "Next expansion unlocks " .. next_reward .. " tiles"
  lines[#lines + 1] = "Expansions completed: " .. (planet_state.expansions_completed or 0)

  return lines
end

local function build_debug_lines()
  local lines = build_status_lines()

  if lines[1] == "No expansion data yet." then
    return lines
  end

  local planet_state = storage.planets.nauvis
  local next_level = defs.get_completed_expansion_research_levels("nauvis") + 1
  local next_band = defs.get_expansion_research_band_for_level(next_level)

  lines[#lines + 1] = "Expansion trigger: complete one level of square-expansion research."
  lines[#lines + 1] = "Current research band: " .. next_band.name
  lines[#lines + 1] = "Current square area: " .. defs.get_square_area(planet_state.square_size) .. " tiles"
  lines[#lines + 1] = "Next ring reward: " .. defs.get_next_expansion_tile_reward(planet_state.square_size) .. " tiles"

  return lines
end

function gui_runtime.refresh_debug_gui(player)
  if not (player and player.valid) then
    return
  end

  local frame = player.gui.left[defs.DEBUG_FRAME_NAME]

  if not frame then
    return
  end

  frame.clear()

  for _, line in ipairs(build_debug_lines()) do
    frame.add({
      type = "label",
      caption = line
    })
  end

  if debug_platform_runtime.is_space_age_active() then
    frame.add({
      type = "label",
      caption = {"gui.the-square-dev-orbit-teleport-title"}
    })

    for _, planet in ipairs(defs.DEBUG_SPACE_AGE_PLANETS) do
      frame.add({
        type = "button",
        name = defs.DEV_ORBIT_TELEPORT_BUTTON_PREFIX .. planet.name,
        caption = {"gui.the-square-dev-orbit-teleport-button", planet.label}
      })
    end
  end
end

function gui_runtime.refresh_all_debug_guis()
  for _, player in pairs(game.players) do
    gui_runtime.refresh_debug_gui(player)
  end
end

local function ensure_screenshot_button(player)
  local button = player.gui.top[defs.SCREENSHOT_BUTTON_NAME]

  if button then
    return button
  end

  return player.gui.top.add({
    type = "button",
    name = defs.SCREENSHOT_BUTTON_NAME,
    caption = {"gui.the-square-screenshot-button"},
    tooltip = {"gui.the-square-screenshot-button-tooltip", defs.BASE_SCREENSHOT_DIRECTORY}
  })
end

local function ensure_square_move_button(player)
  local button = player.gui.top[defs.SQUARE_MOVE_BUTTON_NAME]

  if button then
    return button
  end

  return player.gui.top.add({
    type = "button",
    name = defs.SQUARE_MOVE_BUTTON_NAME,
    caption = {"gui.the-square-move-button"},
    tooltip = {"gui.the-square-move-button-tooltip"}
  })
end

local function destroy_square_move_frame(player)
  if player and player.valid and player.gui and player.gui.screen then
    destroy_child(player.gui.screen, defs.SQUARE_MOVE_FRAME_NAME)
  end
end

local function get_square_move_mode(player)
  return storage.square_move_modes[player.index]
end

local function initialize_square_move_mode(player)
  if not storage.square_move_modes then
    storage.square_move_modes = {}
  end

  if not storage.square_move_modes[player.index] then
    storage.square_move_modes[player.index] = MOVE_MODES.SQUARE
  end
end

local function set_square_move_mode(player, mode)
  storage.square_move_modes[player.index] = mode
end

local function build_square_move_tooltip(direction, result, mode)
  if result.ok then
    if mode == MOVE_MODES.CONTENTS then
      return {
        "gui.the-square-move-contents-direction-tooltip",
        {"the-square-direction." .. direction}
      }
    end

    return {
      "gui.the-square-move-direction-tooltip",
      {"the-square-direction." .. direction}
    }
  end

  if result.reason == "obstructed" then
    if mode == MOVE_MODES.CONTENTS then
      return {
        "gui.the-square-move-contents-obstructed-tooltip",
        {"the-square-direction." .. direction},
        {"the-square-direction." .. result.obstructed_side}
      }
    end

    return {
      "gui.the-square-move-obstructed-tooltip",
      {"the-square-direction." .. direction},
      {"the-square-direction." .. result.obstructed_side}
    }
  end

  if result.reason == "unmovable" then
    return {"gui.the-square-move-contents-unmovable-tooltip"}
  end

  return {"gui.the-square-move-unsupported-tooltip"}
end

local function get_square_move_description(mode)
  if mode == MOVE_MODES.CONTENTS then
    return "gui.the-square-move-contents-description"
  end

  return "gui.the-square-move-description"
end

local function add_square_move_cell(table_element, direction, result, mode)
  if not direction then
    local spacer = table_element.add({type = "empty-widget"})
    spacer.style.width = 48
    spacer.style.height = 48
    return
  end

  local button = table_element.add({
    type = "button",
    name = defs.SQUARE_MOVE_DIRECTION_BUTTON_PREFIX .. direction,
    caption = {"gui.the-square-move-" .. direction},
    tooltip = build_square_move_tooltip(direction, result, mode),
    enabled = result.ok
  })
  button.style.width = 48
  button.style.height = 48
  button.style.font = "default-large-bold"
end

local function open_square_move_gui(player, square_move_runtime)
  local mode = get_square_move_mode(player)
  local switch_state = "left"

  if mode == MOVE_MODES.CONTENTS then
    switch_state = "right"
  end

  local frame = player.gui.screen.add({
    type = "frame",
    name = defs.SQUARE_MOVE_FRAME_NAME,
    direction = "vertical"
  })
  local titlebar = frame.add({
    type = "flow",
    name = "the_square_move_titlebar",
    direction = "horizontal"
  })
  titlebar.style.horizontally_stretchable = true

  local title = titlebar.add({
    type = "label",
    caption = {"gui.the-square-move-title"},
    style = "frame_title"
  })
  title.drag_target = frame

  local drag_space = titlebar.add({
    type = "empty-widget",
    style = "draggable_space_header"
  })
  drag_space.style.horizontally_stretchable = true
  drag_space.style.height = 24
  drag_space.drag_target = frame

  titlebar.add({
    type = "switch",
    name = defs.SQUARE_MOVE_MODE_SWITCH_NAME,
    left_label_caption = {"gui.the-square-move-mode-square"},
    right_label_caption = {"gui.the-square-move-mode-contents"},
    switch_state = switch_state,
    allow_none_state = false
  })

  titlebar.add({
    type = "sprite",
    name = defs.SQUARE_MOVE_MODE_INFO_NAME,
    sprite = defs.SQUARE_MOVE_MODE_INFO_SPRITE,
    tooltip = {"gui.the-square-move-mode-tooltip"}
  })

  frame.add({
    type = "label",
    name = defs.SQUARE_MOVE_DESCRIPTION_NAME,
    caption = {get_square_move_description(mode)}
  })

  local direction_flow = frame.add({
    type = "flow",
    name = "the_square_move_direction_flow",
    direction = "horizontal"
  })
  direction_flow.style.horizontally_stretchable = true
  direction_flow.style.horizontal_align = "center"

  local directions = direction_flow.add({
    type = "table",
    name = "the_square_move_direction_table",
    column_count = 3
  })
  local options = square_move_runtime.get_options_for_player(player, mode)

  add_square_move_cell(directions, nil, nil, mode)
  add_square_move_cell(directions, "north", options.north, mode)
  add_square_move_cell(directions, nil, nil, mode)
  add_square_move_cell(directions, "west", options.west, mode)
  add_square_move_cell(directions, nil, nil, mode)
  add_square_move_cell(directions, "east", options.east, mode)
  add_square_move_cell(directions, nil, nil, mode)
  add_square_move_cell(directions, "south", options.south, mode)
  add_square_move_cell(directions, nil, nil, mode)

  if frame.force_auto_center then
    frame.force_auto_center()
  end

  player.opened = frame
end

function gui_runtime.refresh_square_move_gui(player, square_move_runtime)
  if not (player and player.valid and square_move_runtime) then
    return
  end

  local frame = player.gui.screen[defs.SQUARE_MOVE_FRAME_NAME]
  local direction_flow = frame and frame.the_square_move_direction_flow
  local directions = direction_flow and direction_flow.the_square_move_direction_table
  local description = frame and frame[defs.SQUARE_MOVE_DESCRIPTION_NAME]

  if not directions then
    return
  end

  local mode = get_square_move_mode(player)
  local options = square_move_runtime.get_options_for_player(player, mode)

  if description then
    description.caption = {get_square_move_description(mode)}
  end

  for _, direction in ipairs({"north", "east", "south", "west"}) do
    local button = directions[defs.SQUARE_MOVE_DIRECTION_BUTTON_PREFIX .. direction]
    local result = options[direction]

    if button then
      button.enabled = result.ok
      button.tooltip = build_square_move_tooltip(direction, result, mode)
    end
  end
end

function gui_runtime.get_square_move_mode(player)
  return get_square_move_mode(player)
end

function gui_runtime.handle_square_move_mode_changed(player, element, square_move_runtime)
  if not (player and player.valid and element and element.valid) then
    return false
  end

  if element.name ~= defs.SQUARE_MOVE_MODE_SWITCH_NAME then
    return false
  end

  local mode = MOVE_MODES.SQUARE

  if element.switch_state == "right" then
    mode = MOVE_MODES.CONTENTS
  end

  set_square_move_mode(player, mode)
  gui_runtime.refresh_square_move_gui(player, square_move_runtime)
  return true
end

function gui_runtime.toggle_square_move_gui(player, square_move_runtime)
  if not (player and player.valid) then
    return
  end

  local frame = player.gui.screen[defs.SQUARE_MOVE_FRAME_NAME]

  if frame then
    destroy_square_move_frame(player)
    return
  end

  open_square_move_gui(player, square_move_runtime)
end

function gui_runtime.handle_square_move_gui_closed(player, element)
  if not (player and player.valid and element and element.valid) then
    return false
  end

  if element.name ~= defs.SQUARE_MOVE_FRAME_NAME then
    return false
  end

  destroy_square_move_frame(player)
  return true
end

function gui_runtime.sync_screenshot_gui(player)
  if not (player and player.valid) then
    return
  end

  ensure_screenshot_button(player)
end

function gui_runtime.sync_square_move_gui(player)
  if not (player and player.valid) then
    return
  end

  initialize_square_move_mode(player)
  ensure_square_move_button(player)
end

function gui_runtime.sync_cliff_explosive_gui(player)
  if not (player and player.valid) then
    return
  end

  local button = player.gui.top[defs.CLIFF_EXPLOSIVE_BUTTON_NAME]

  if gui_runtime.is_cliff_explosive_button_enabled(player) then
    if not button then
      player.gui.top.add({
        type = "button",
        name = defs.CLIFF_EXPLOSIVE_BUTTON_NAME,
        caption = {"gui.the-square-cliff-explosive-button"}
      })
    end
  elseif button then
    button.destroy()
  end
end

function gui_runtime.sync_all_cliff_explosive_guis()
  for _, player in pairs(game.players) do
    gui_runtime.sync_cliff_explosive_gui(player)
  end
end

function gui_runtime.sync_all_screenshot_guis()
  for _, player in pairs(game.players) do
    gui_runtime.sync_screenshot_gui(player)
  end
end

function gui_runtime.sync_all_square_move_guis()
  for _, player in pairs(game.players) do
    gui_runtime.sync_square_move_gui(player)
  end
end

function gui_runtime.refresh_all_square_move_guis(square_move_runtime)
  for _, player in pairs(game.players) do
    gui_runtime.refresh_square_move_gui(player, square_move_runtime)
  end
end

function gui_runtime.sync_dev_gui(player)
  if not (player and player.valid) then
    return
  end

  local button = player.gui.top[defs.DEV_EXPAND_BUTTON_NAME]
  local frame = player.gui.left[defs.DEBUG_FRAME_NAME]

  if gui_runtime.is_dev_mode_enabled(player) then
    if not button then
      player.gui.top.add({
        type = "button",
        name = defs.DEV_EXPAND_BUTTON_NAME,
        caption = {"gui.the-square-dev-expand-button"}
      })
    end

    if not frame then
      frame = ensure_debug_frame(player)
    end

    gui_runtime.refresh_debug_gui(player)
  elseif button then
    button.destroy()
  end

  if not gui_runtime.is_dev_mode_enabled(player) and frame then
    frame.destroy()
  end
end

function gui_runtime.sync_all_dev_guis()
  for _, player in pairs(game.players) do
    gui_runtime.sync_dev_gui(player)
  end
end

return gui_runtime
