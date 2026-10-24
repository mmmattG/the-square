-- The Move Square window: a top-bar button opens a small window with a mode switch
-- (move the Square, or move its contents) and four direction buttons.
local square_move_runtime = require("lib.square_move_runtime")

local square_move_gui = {}

local MODES = square_move_runtime.MODES
local BUTTON_NAME = "the_square_move_button"
local FRAME_NAME = "the_square_move_frame"
local DIRECTION_BUTTON_PREFIX = "the_square_move_direction__"
local MODE_SWITCH_NAME = "the_square_move_mode_switch"
local MODE_INFO_NAME = "the_square_move_mode_info"
local MODE_INFO_SPRITE = "info"
local DESCRIPTION_NAME = "the_square_move_description"

-- A 3x3 grid with the four directions on the edges.
local GRID = {
  false, "north", false,
  "west", false, "east",
  false, "south", false
}

local function get_mode(player)
  return storage.square_move_modes[player.index]
end

local function direction_name(direction)
  return {"the-square-direction." .. direction}
end

local function build_direction_tooltip(direction, result, mode)
  local contents = mode == MODES.CONTENTS

  if result.ok then
    return {
      contents and "gui.the-square-move-contents-direction-tooltip" or "gui.the-square-move-direction-tooltip",
      direction_name(direction)
    }
  end

  if result.reason == "obstructed" then
    return {
      contents and "gui.the-square-move-contents-obstructed-tooltip" or "gui.the-square-move-obstructed-tooltip",
      direction_name(direction),
      direction_name(result.obstructed_side)
    }
  end

  if result.reason == "unmovable" then
    return {"gui.the-square-move-contents-unmovable-tooltip"}
  end

  return {"gui.the-square-move-unsupported-tooltip"}
end

local function get_description(mode)
  return {mode == MODES.CONTENTS and "gui.the-square-move-contents-description" or "gui.the-square-move-description"}
end

local function get_direction_table(player)
  local frame = player.gui.screen[FRAME_NAME]

  return frame and frame.the_square_move_direction_flow.the_square_move_direction_table
end

local function open(player)
  local mode = get_mode(player)
  local frame = player.gui.screen.add({type = "frame", name = FRAME_NAME, direction = "vertical"})
  local titlebar = frame.add({type = "flow", name = "the_square_move_titlebar", direction = "horizontal"})

  titlebar.style.horizontally_stretchable = true

  local title = titlebar.add({type = "label", caption = {"gui.the-square-move-title"}, style = "frame_title"})
  title.drag_target = frame

  local drag_space = titlebar.add({type = "empty-widget", style = "draggable_space_header"})
  drag_space.style.horizontally_stretchable = true
  drag_space.style.height = 24
  drag_space.drag_target = frame

  titlebar.add({
    type = "switch",
    name = MODE_SWITCH_NAME,
    left_label_caption = {"gui.the-square-move-mode-square"},
    right_label_caption = {"gui.the-square-move-mode-contents"},
    switch_state = mode == MODES.CONTENTS and "right" or "left",
    allow_none_state = false
  })
  titlebar.add({
    type = "sprite",
    name = MODE_INFO_NAME,
    sprite = MODE_INFO_SPRITE,
    tooltip = {"gui.the-square-move-mode-tooltip"}
  })
  frame.add({type = "label", name = DESCRIPTION_NAME, caption = get_description(mode)})

  local direction_flow = frame.add({type = "flow", name = "the_square_move_direction_flow", direction = "horizontal"})

  direction_flow.style.horizontally_stretchable = true
  direction_flow.style.horizontal_align = "center"

  local directions = direction_flow.add({type = "table", name = "the_square_move_direction_table", column_count = 3})
  local options = square_move_runtime.get_options_for_player(player, mode)

  for _, direction in ipairs(GRID) do
    if direction then
      local button = directions.add({
        type = "button",
        name = DIRECTION_BUTTON_PREFIX .. direction,
        caption = {"gui.the-square-move-" .. direction},
        tooltip = build_direction_tooltip(direction, options[direction], mode),
        enabled = options[direction].ok
      })

      button.style.width = 48
      button.style.height = 48
      button.style.font = "default-large-bold"
    else
      local spacer = directions.add({type = "empty-widget"})

      spacer.style.width = 48
      spacer.style.height = 48
    end
  end

  frame.force_auto_center()
  player.opened = frame
end

-- Updates which directions are possible right now.
function square_move_gui.refresh(player)
  local directions = get_direction_table(player)

  if not directions then
    return
  end

  local mode = get_mode(player)
  local options = square_move_runtime.get_options_for_player(player, mode)

  player.gui.screen[FRAME_NAME][DESCRIPTION_NAME].caption = get_description(mode)

  for direction, result in pairs(options) do
    local button = directions[DIRECTION_BUTTON_PREFIX .. direction]

    button.enabled = result.ok
    button.tooltip = build_direction_tooltip(direction, result, mode)
  end
end

function square_move_gui.refresh_all()
  for _, player in pairs(game.players) do
    square_move_gui.refresh(player)
  end
end

-- Adds the top-bar button and the player's saved mode.
function square_move_gui.sync(player)
  storage.square_move_modes = storage.square_move_modes or {}
  storage.square_move_modes[player.index] = storage.square_move_modes[player.index] or MODES.SQUARE

  if not player.gui.top[BUTTON_NAME] then
    player.gui.top.add({
      type = "button",
      name = BUTTON_NAME,
      caption = {"gui.the-square-move-button"},
      tooltip = {"gui.the-square-move-button-tooltip"}
    })
  end
end

function square_move_gui.sync_all()
  for _, player in pairs(game.players) do
    square_move_gui.sync(player)
  end
end

local function print_move_failure(player, result)
  if result.reason == "obstructed" then
    local message = result.mode == MODES.CONTENTS and "message.the-square-move-contents-obstructed"
      or "message.the-square-move-obstructed"

    player.print({message, direction_name(result.obstructed_side)})
  elseif result.reason == "unmovable" then
    player.print({"message.the-square-move-contents-unmovable"})
  else
    player.print({"message.the-square-move-unsupported"})
  end
end

-- Returns true when the click belonged to this window. A successful move returns
-- true as its second value.
function square_move_gui.handle_click(player, element)
  if element.name == BUTTON_NAME then
    local frame = player.gui.screen[FRAME_NAME]

    if frame then
      frame.destroy()
    else
      open(player)
    end

    return true, false
  end

  local direction = string.match(element.name, "^" .. DIRECTION_BUTTON_PREFIX .. "(%w+)$")

  if not (direction and square_move_runtime.is_valid_direction(direction)) then
    return false, false
  end

  local result = square_move_runtime.move_for_player(player, direction, get_mode(player))

  if not result.ok then
    print_move_failure(player, result)
  end

  square_move_gui.refresh_all()

  return true, result.ok
end

function square_move_gui.handle_switch_changed(player, element)
  if element.name ~= MODE_SWITCH_NAME then
    return
  end

  storage.square_move_modes[player.index] = element.switch_state == "right" and MODES.CONTENTS or MODES.SQUARE
  square_move_gui.refresh(player)
end

function square_move_gui.handle_closed(player, element)
  if element.name ~= FRAME_NAME then
    return false
  end

  element.destroy()

  return true
end

return square_move_gui
