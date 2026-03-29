local defs = require("lib.runtime_defs")

local gui_runtime = {}

local function build_ingress_edge_check_debug(square_size, position)
  local tile_position = defs.snap_entity_position_to_tile(position)
  local bounds = defs.get_anchor_bounds(square_size)
  local min_x = bounds.left_top.x
  local min_y = bounds.left_top.y
  local max_x = bounds.right_bottom.x - 1
  local max_y = bounds.right_bottom.y - 1
  local north_match = tile_position.y == min_y and tile_position.x > min_x and tile_position.x < max_x
  local east_match = tile_position.x == max_x and tile_position.y > min_y and tile_position.y < max_y
  local south_match = tile_position.y == max_y and tile_position.x > min_x and tile_position.x < max_x
  local west_match = tile_position.x == min_x and tile_position.y > min_y and tile_position.y < max_y
  local detected_side = defs.get_anchor_side_for_position(square_size, tile_position)

  return table.concat({
    "[Expanding Square] Ingress placement debug",
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
  return settings.get_player_settings(player)[defs.SETTING_DEV_MODE].value
end

function gui_runtime.is_ingress_placement_debug_enabled(player)
  return player
    and player.valid
    and settings.get_player_settings(player)[defs.SETTING_INGRESS_PLACEMENT_DEBUG].value
end

function gui_runtime.print_ingress_placement_debug(player, square_size, position)
  if not gui_runtime.is_ingress_placement_debug_enabled(player) then
    return
  end

  player.print(build_ingress_edge_check_debug(square_size, position))
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
    caption = {"gui.fes-debug-title"}
  })
end

local function build_status_lines()
  local bootstrap = storage.bootstrap
  local lines = {}

  if not bootstrap then
    lines[#lines + 1] = "No expansion data yet."
    return lines
  end

  local next_reward = defs.get_next_expansion_tile_reward(bootstrap.square_size)
  local completed_levels = defs.get_completed_expansion_research_levels()
  local next_level = completed_levels + 1
  local next_band = defs.get_expansion_research_band_for_level(next_level)

  lines[#lines + 1] = "Square: " .. bootstrap.square_size .. "x" .. bootstrap.square_size
  lines[#lines + 1] = "Logistics setting: "
    .. (defs.is_logistic_network_automation_enabled() and "enabled" or "disabled")
  lines[#lines + 1] = "Expansion research: " .. completed_levels .. " levels completed"
  lines[#lines + 1] = "Next expansion: level " .. next_level .. " using " .. next_band.label
  lines[#lines + 1] = "Next reward: " .. next_reward .. " tiles and " .. next_reward .. " expansion points"
  lines[#lines + 1] = "Expansions completed: " .. (bootstrap.expansions_completed or 0)
  lines[#lines + 1] = "Expansion points: " .. (bootstrap.expansion_points or 0)
  lines[#lines + 1] = "Ingress tier: " .. defs.build_ingress_tier_summary()

  return lines
end

local function ensure_status_frame(player)
  local frame = player.gui.left[defs.STATUS_FRAME_NAME]

  if frame then
    return frame
  end

  return player.gui.left.add({
    type = "frame",
    name = defs.STATUS_FRAME_NAME,
    direction = "vertical",
    caption = {"gui.fes-status-title"}
  })
end

function gui_runtime.refresh_status_gui(player)
  if not (player and player.valid) then
    return
  end

  local frame = player.gui.left[defs.STATUS_FRAME_NAME]

  if not frame then
    return
  end

  frame.clear()

  for _, line in ipairs(build_status_lines()) do
    frame.add({
      type = "label",
      caption = line
    })
  end
end

function gui_runtime.sync_status_gui(player)
  if not (player and player.valid) then
    return
  end

  ensure_status_frame(player)
  gui_runtime.refresh_status_gui(player)
end

function gui_runtime.refresh_all_status_guis()
  for _, player in pairs(game.players) do
    gui_runtime.sync_status_gui(player)
  end
end

local function build_debug_lines()
  local lines = build_status_lines()

  if lines[1] == "No expansion data yet." then
    return lines
  end

  local bootstrap = storage.bootstrap
  local next_level = defs.get_completed_expansion_research_levels() + 1
  local next_band = defs.get_expansion_research_band_for_level(next_level)

  lines[#lines + 1] = "Expansion trigger: complete one level of square-expansion research."
  lines[#lines + 1] = "Current research band: " .. next_band.name
  lines[#lines + 1] = "Current square area: " .. defs.get_square_area(bootstrap.square_size) .. " tiles"
  lines[#lines + 1] = "Next ring reward: " .. defs.get_next_expansion_tile_reward(bootstrap.square_size) .. " tiles"

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
end

function gui_runtime.refresh_all_debug_guis()
  for _, player in pairs(game.players) do
    gui_runtime.refresh_debug_gui(player)
  end
end

local function ensure_shop_button(player)
  local button = player.gui.top[defs.SHOP_BUTTON_NAME]

  if button then
    return button
  end

  return player.gui.top.add({
    type = "button",
    name = defs.SHOP_BUTTON_NAME,
    caption = {"gui.fes-shop-button"}
  })
end

local function build_shop_status_caption(resource, anchor_runtime)
  local definition = defs.get_input_definition(resource) or defs.get_output_definition(resource)
  local counts = anchor_runtime.get_owned_line_counts(resource)

  if not definition then
    return "Unavailable"
  end

  if counts.owned > 0 then
    return "Owned: " .. counts.owned .. " (" .. counts.placed .. " placed, " .. counts.stashed .. " stashed)"
  end

  if definition.prerequisite_resource and not anchor_runtime.is_resource_unlocked(definition.prerequisite_resource) then
    return "Locked until " .. defs.format_resource_name(definition.prerequisite_resource) .. " is unlocked"
  end

  return "Not yet unlocked"
end

local function ensure_shop_frame(player)
  local frame = player.gui.left[defs.SHOP_FRAME_NAME]

  if frame then
    return frame
  end

  return player.gui.left.add({
    type = "frame",
    name = defs.SHOP_FRAME_NAME,
    direction = "vertical",
    caption = {"gui.fes-shop-title"}
  })
end

function gui_runtime.refresh_shop_gui(player, anchor_runtime)
  if not (player and player.valid) then
    return
  end

  local frame = player.gui.left[defs.SHOP_FRAME_NAME]
  local bootstrap = storage.bootstrap

  if not frame or not bootstrap then
    return
  end

  frame.clear()
  frame.add({
    type = "label",
    caption = {"gui.fes-shop-points", bootstrap.expansion_points or 0}
  })
  frame.add({
    type = "label",
    caption = {"gui.fes-shop-line-cost", defs.get_line_purchase_cost()}
  })

  for _, definition in ipairs(defs.INPUT_DEFINITIONS) do
    local flow = frame.add({
      type = "flow",
      direction = "horizontal"
    })
    local can_purchase = anchor_runtime.can_purchase_line(definition.resource)
    local button = flow.add({
      type = "button",
      name = "fes_shop_buy__" .. definition.resource,
      caption = {"gui.fes-shop-buy", {"item-name." .. defs.get_ingress_item_name(definition.resource)}}
    })

    button.enabled = can_purchase and (bootstrap.expansion_points or 0) >= defs.get_line_purchase_cost()

    flow.add({
      type = "label",
      caption = build_shop_status_caption(definition.resource, anchor_runtime)
    })
  end

  for _, definition in ipairs(defs.OUTPUT_DEFINITIONS) do
    local flow = frame.add({
      type = "flow",
      direction = "horizontal"
    })
    local can_purchase = anchor_runtime.can_purchase_line(definition.resource)
    local button = flow.add({
      type = "button",
      name = "fes_shop_buy__" .. definition.resource,
      caption = {"gui.fes-shop-buy", {"item-name." .. defs.get_egress_item_name(definition.resource)}}
    })

    button.enabled = can_purchase and (bootstrap.expansion_points or 0) >= defs.get_line_purchase_cost()

    flow.add({
      type = "label",
      caption = build_shop_status_caption(definition.resource, anchor_runtime)
    })
  end
end

function gui_runtime.toggle_shop_gui(player, anchor_runtime)
  if not (player and player.valid) then
    return
  end

  local frame = player.gui.left[defs.SHOP_FRAME_NAME]

  if frame then
    frame.destroy()
    return
  end

  ensure_shop_frame(player)
  gui_runtime.refresh_shop_gui(player, anchor_runtime)
end

function gui_runtime.sync_shop_gui(player, anchor_runtime)
  if not (player and player.valid) then
    return
  end

  gui_runtime.sync_status_gui(player)
  ensure_shop_button(player)
  gui_runtime.refresh_shop_gui(player, anchor_runtime)
end

function gui_runtime.sync_all_shop_guis(anchor_runtime)
  for _, player in pairs(game.players) do
    gui_runtime.sync_shop_gui(player, anchor_runtime)
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
        caption = {"gui.fes-dev-expand-button"}
      })
    end

    if not frame then
      ensure_debug_frame(player)
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
