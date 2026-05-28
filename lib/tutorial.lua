local defs = require("lib.runtime_defs")

local tutorial = {}

local STEP_CLICK_ANCHOR_SLOT = "click_anchor_slot"
local STEP_SELECT_INGRESS = "select_ingress"
local STEP_PICK_UP_RESOURCE = "pick_up_resource"
local STEP_COMPLETE = "complete"
local MODAL_STEPS = {
  [STEP_CLICK_ANCHOR_SLOT] = true,
  [STEP_COMPLETE] = true
}

local function ensure_state()
  storage.the_square_tutorial = storage.the_square_tutorial or {
    players = {}
  }
  storage.the_square_tutorial.players = storage.the_square_tutorial.players or {}
  return storage.the_square_tutorial
end

local function get_player_state(player)
  if not (player and player.valid and player.index) then
    return nil
  end

  local state = ensure_state()
  state.players[player.index] = state.players[player.index] or {
    step = STEP_CLICK_ANCHOR_SLOT
  }

  return state.players[player.index]
end

local function get_step_text(step, resource)
  if step == STEP_SELECT_INGRESS then
    return {"gui.the-square-tutorial-select-ingress"}
  end

  if step == STEP_PICK_UP_RESOURCE then
    return {"gui.the-square-tutorial-pick-up-resource", {"item-name." .. resource}}
  end

  if step == STEP_COMPLETE then
    return {"gui.the-square-tutorial-complete"}
  end

  return {"gui.the-square-tutorial-click-anchor-slot"}
end

local function get_goal_text(step, resource)
  if step == STEP_SELECT_INGRESS then
    return {"gui.the-square-tutorial-goal-select-ingress"}
  end

  if step == STEP_PICK_UP_RESOURCE then
    return {"gui.the-square-tutorial-goal-pick-up-resource", {"item-name." .. resource}}
  end

  return {"gui.the-square-tutorial-goal-click-anchor-slot"}
end

local function set_goal(player, goal)
  if player and player.valid and player.set_goal_description then
    player.set_goal_description(goal)
  end
end

local function clear_goal(player)
  if player and player.valid and player.set_goal_description then
    player.set_goal_description("")
  end
end

local function clear_arrow(player_state)
  local arrow = player_state and player_state.arrow

  if arrow and arrow.valid and arrow.destroy then
    arrow.destroy()
  end

  if player_state then
    player_state.arrow = nil
  end
end

local function show_message(player, param)
  if not (player and player.valid) then
    return false
  end

  if game and game.is_multiplayer and game.is_multiplayer() then
    player.print(param.text)
    return true
  end

  if game and game.show_message_dialog then
    game.show_message_dialog(param)
    return true
  end

  if player.print then
    player.print(param.text)
    return true
  end

  return false
end

local function find_anchor_slot_proxy(player)
  if not (player and player.surface and player.surface.find_entities_filtered) then
    return nil
  end

  local proxies = player.surface.find_entities_filtered({
    name = defs.ANCHOR_SLOT_PROXY_NAME
  })

  local leftmost = nil

  for _, proxy in ipairs(proxies or {}) do
    if proxy.valid and (
      not leftmost
      or ((proxy.position and proxy.position.x) or 0) < ((leftmost.position and leftmost.position.x) or 0)
    ) then
      leftmost = proxy
    end
  end

  return leftmost
end

local function is_item_ingress_anchor(anchor)
  return anchor
    and anchor.position
    and anchor.flow == "ingress"
    and anchor.kind == "item"
    and anchor.resource
end

local function find_configured_item_ingress(managed_line_runtime, player)
  if not managed_line_runtime then
    return nil
  end

  local planet_name = player and player.surface and player.surface.name or "nauvis"
  local state = managed_line_runtime.get(planet_name) or managed_line_runtime.get("nauvis")

  for _, anchor in ipairs((state and state.anchors) or {}) do
    if is_item_ingress_anchor(anchor) then
      return anchor
    end
  end

  return nil
end

local function get_item_count(player, item_name)
  if not (player and player.valid and item_name and player.get_item_count) then
    return 0
  end

  return player.get_item_count(item_name) or 0
end

local function get_point_to(player, player_state)
  if player_state.step == STEP_CLICK_ANCHOR_SLOT then
    local proxy = find_anchor_slot_proxy(player)

    if proxy then
      return {type = "entity", entity = proxy}
    end
  end

  if player_state.step == STEP_SELECT_INGRESS then
    return {type = "active_window"}
  end

  if player_state.step == STEP_PICK_UP_RESOURCE then
    local anchor = player_state.anchor

    if anchor and anchor.entity and anchor.entity.valid then
      return {type = "entity", entity = anchor.entity}
    end

    if anchor and anchor.position then
      return {type = "position", position = anchor.position}
    end
  end

  return nil
end

local function get_arrow_position(player, player_state)
  if player_state.step == STEP_CLICK_ANCHOR_SLOT then
    local proxy = find_anchor_slot_proxy(player)
    return proxy and proxy.position or nil
  end

  if player_state.step == STEP_PICK_UP_RESOURCE then
    local anchor = player_state.anchor

    if anchor and anchor.entity and anchor.entity.valid then
      return anchor.entity.position
    end

    return anchor and anchor.position or nil
  end

  return nil
end

local function set_arrow(player, player_state)
  clear_arrow(player_state)

  if not (player and player.valid and player.surface and player.surface.create_entity) then
    return
  end

  local position = get_arrow_position(player, player_state)

  if not position then
    return
  end

  player_state.arrow = player.surface.create_entity({
    name = "orange-arrow-with-circle",
    position = position
  })
end

local function render(player, options)
  local player_state = get_player_state(player)

  if not player_state or player_state.step == player_state.shown_step then
    return false
  end

  if MODAL_STEPS[player_state.step] then
    local param = {
      text = get_step_text(player_state.step, player_state.resource)
    }
    local point_to = get_point_to(player, player_state)

    if point_to then
      param.point_to = point_to
    end

    if not show_message(player, param) then
      return false
    end
  end

  if player_state.step == STEP_COMPLETE then
    clear_arrow(player_state)
    clear_goal(player)
  elseif not (options and options.skip_goal) then
    set_goal(player, get_goal_text(player_state.step, player_state.resource))
    set_arrow(player, player_state)
  end

  player_state.shown_step = player_state.step
  return true
end

function tutorial.show_world_creation(player)
  return render(player)
end

function tutorial.handle_anchor_slot_clicked(player)
  local player_state = get_player_state(player)

  if not player_state or player_state.step ~= STEP_CLICK_ANCHOR_SLOT then
    return false
  end

  if not (player.gui and player.gui.screen and player.gui.screen[defs.ANCHOR_CONFIG_FRAME_NAME]) then
    return false
  end

  player_state.step = STEP_SELECT_INGRESS
  return render(player)
end

function tutorial.handle_anchor_config_changed(player, managed_line_runtime)
  local player_state = get_player_state(player)

  if not player_state or player_state.step ~= STEP_SELECT_INGRESS then
    return false
  end

  local anchor = find_configured_item_ingress(managed_line_runtime, player)

  if not anchor then
    return false
  end

  player_state.step = STEP_PICK_UP_RESOURCE
  player_state.resource = anchor.resource
  player_state.anchor = anchor
  player_state.baseline_count = get_item_count(player, anchor.resource)

  return render(player)
end

function tutorial.handle_inventory_changed(player)
  local player_state = get_player_state(player)

  if not player_state or player_state.step ~= STEP_PICK_UP_RESOURCE or not player_state.resource then
    return false
  end

  if get_item_count(player, player_state.resource) <= (player_state.baseline_count or 0) then
    return false
  end

  player_state.step = STEP_COMPLETE
  return render(player, {skip_goal = true})
end

return tutorial
