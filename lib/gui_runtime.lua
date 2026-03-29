local defs = require("lib.runtime_defs")

local gui_runtime = {}

local function build_ingress_edge_check_debug(square_size, position)
  local tile_position = defs.snap_entity_position_to_tile(position)
  local bounds = defs.get_square_bounds(square_size)
  local min_x = bounds.left_top.x
  local min_y = bounds.left_top.y
  local max_x = bounds.right_bottom.x - 1
  local max_y = bounds.right_bottom.y - 1
  local north_match = tile_position.y == min_y and tile_position.x > min_x and tile_position.x < max_x
  local east_match = tile_position.x == max_x and tile_position.y > min_y and tile_position.y < max_y
  local south_match = tile_position.y == max_y and tile_position.x > min_x and tile_position.x < max_x
  local west_match = tile_position.x == min_x and tile_position.y > min_y and tile_position.y < max_y
  local detected_side = defs.get_playable_edge_side_for_position(square_size, tile_position)
  local anchor_position = detected_side and defs.move_position(tile_position, detected_side, 1) or nil

  return table.concat({
    "[Expanding Square] Ingress placement debug",
    "raw_position=" .. defs.format_position(position),
    "tile_position=" .. defs.format_position(tile_position),
    "square_size=" .. square_size,
    "playable_bounds.left_top=" .. defs.format_position(bounds.left_top),
    "playable_bounds.right_bottom=" .. defs.format_position(bounds.right_bottom),
    "min=(" .. min_x .. ", " .. min_y .. ")",
    "max=(" .. max_x .. ", " .. max_y .. ")",
    "north=" .. tostring(north_match),
    "east=" .. tostring(east_match),
    "south=" .. tostring(south_match),
    "west=" .. tostring(west_match),
    "detected_side=" .. tostring(detected_side),
    "anchor_position=" .. defs.format_position(anchor_position)
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
  local metrics = storage.utilization_metrics
  local lines = {}

  if not bootstrap or not metrics then
    lines[#lines + 1] = "No utilization data yet."
    return lines
  end

  local next_reward = defs.get_next_expansion_tile_reward(bootstrap.square_size)

  lines[#lines + 1] = "Square: " .. bootstrap.square_size .. "x" .. bootstrap.square_size
  lines[#lines + 1] = "Logistics setting: "
    .. (defs.is_logistic_network_automation_enabled() and "enabled" or "disabled")
  lines[#lines + 1] = "Utilization: " .. defs.format_ratio_percent(metrics.utilization_ratio)
    .. " (" .. metrics.active_footprint_tiles .. " / " .. metrics.total_tiles .. " tiles)"
  lines[#lines + 1] = "Growth rate: " .. defs.format_decimal(metrics.growth_rate_per_second) .. " tiles/s"
    .. " (" .. defs.format_decimal(metrics.growth_rate_per_minute) .. " tiles/min)"
  lines[#lines + 1] = "Progress: " .. defs.format_decimal(bootstrap.growth_progress or 0)
    .. " / " .. next_reward
  lines[#lines + 1] = "Research multiplier: " .. defs.format_decimal(metrics.expansion_speed_multiplier)
    .. "x from " .. metrics.expansion_speed_research_levels .. " expansion-speed levels"
  lines[#lines + 1] = "Active entities: " .. metrics.active_entity_count
  lines[#lines + 1] = "Expansion points: " .. (bootstrap.expansion_points or 0)
  lines[#lines + 1] = "Ingress tier: " .. defs.build_ingress_tier_summary()
  lines[#lines + 1] = "Next reward: " .. next_reward .. " tiles and " .. next_reward .. " expansion points"

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

  if lines[1] == "No utilization data yet." then
    return lines
  end

  local bootstrap = storage.bootstrap
  local metrics = storage.utilization_metrics

  lines[#lines + 1] = "Formula: growth/s = utilization x (square size / " .. defs.GROWTH_RATE_SIZE_DIVISOR .. ")"
  lines[#lines + 1] = "Current: " .. defs.format_decimal(metrics.growth_rate_per_second)
    .. " = " .. defs.format_decimal(metrics.base_growth_rate_per_second)
    .. " x " .. defs.format_decimal(metrics.expansion_speed_multiplier)
  lines[#lines + 1] = "Base: " .. defs.format_decimal(metrics.base_growth_rate_per_second)
    .. " = " .. defs.format_decimal(metrics.utilization_ratio)
    .. " x (" .. bootstrap.square_size .. " / " .. defs.GROWTH_RATE_SIZE_DIVISOR .. ")"
  lines[#lines + 1] = "Breakdown:"

  for _, key in ipairs(defs.COUNTED_CATEGORY_ORDER) do
    local category = metrics.categories[key]

    if category.entity_count > 0 then
      lines[#lines + 1] = "  " .. category.label .. ": "
        .. category.footprint_tiles .. " tiles across " .. category.entity_count .. " entities"
    end
  end

  if #metrics.sorted_entity_types > 0 then
    lines[#lines + 1] = "Top entity types:"

    local max_rows = math.min(8, #metrics.sorted_entity_types)

    for index = 1, max_rows do
      local entry = metrics.sorted_entity_types[index]
      lines[#lines + 1] = "  " .. entry.label .. ": "
        .. entry.footprint_tiles .. " tiles across " .. entry.entity_count
    end
  end

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

local function build_ingress_upgrade_caption(next_tier_level)
  local next_tier = next_tier_level and defs.get_ingress_tier_definition(next_tier_level) or nil

  if not next_tier then
    return "Ingress tier maxed"
  end

  return "Upgrade to " .. next_tier.label
end

local function build_ingress_upgrade_status_caption()
  local current_tier = defs.get_current_ingress_tier()
  local next_tier_level = defs.get_next_ingress_tier_level()
  local next_cost = defs.get_ingress_tier_upgrade_cost(next_tier_level)

  if not next_tier_level or not next_cost then
    return "Current: " .. current_tier.label .. " (maximum tier)"
  end

  return "Current: " .. current_tier.label .. " | Next cost: " .. next_cost
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
    caption = {"gui.fes-shop-line-cost", defs.LINE_PURCHASE_COST}
  })
  do
    local flow = frame.add({
      type = "flow",
      direction = "horizontal"
    })
    local next_tier_level = defs.get_next_ingress_tier_level()
    local next_upgrade_cost = defs.get_ingress_tier_upgrade_cost(next_tier_level)
    local button = flow.add({
      type = "button",
      name = "fes_shop_upgrade_ingress",
      caption = build_ingress_upgrade_caption(next_tier_level)
    })

    button.enabled = next_upgrade_cost ~= nil and (bootstrap.expansion_points or 0) >= next_upgrade_cost

    flow.add({
      type = "label",
      caption = build_ingress_upgrade_status_caption()
    })
  end

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

    button.enabled = can_purchase and (bootstrap.expansion_points or 0) >= defs.LINE_PURCHASE_COST

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

    button.enabled = can_purchase and (bootstrap.expansion_points or 0) >= defs.LINE_PURCHASE_COST

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
