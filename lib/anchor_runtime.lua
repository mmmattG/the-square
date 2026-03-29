local bootstrap_runtime = require("lib.bootstrap_runtime")
local defs = require("lib.runtime_defs")

local anchor_runtime = {}

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

local function find_entity_at_position(surface, prototype_name, position)
  local entities = surface.find_entities_filtered({
    name = prototype_name,
    position = position
  })

  return entities[1]
end

local function get_tile_center_position(position)
  return {
    x = position.x + 0.5,
    y = position.y + 0.5
  }
end

local function configure_source_anchor_entity(entity, direction)
  if not (entity and entity.valid) then
    return
  end

  if direction and entity.direction ~= direction then
    entity.direction = direction
  end

  entity.destructible = false
  entity.operable = false
end

local function is_ingress_entity_name(entity_name)
  for _, definition in ipairs(defs.INPUT_DEFINITIONS) do
    if defs.is_ingress_entity_name_for_resource(definition.resource, entity_name) then
      return true
    end
  end

  return false
end

local function is_egress_entity_name(entity_name)
  for _, definition in ipairs(defs.OUTPUT_DEFINITIONS) do
    if defs.is_egress_entity_name_for_resource(definition.resource, entity_name) then
      return true
    end
  end

  return false
end

function anchor_runtime.is_managed_anchor_entity_name(entity_name)
  return entity_name == defs.ANCHOR_SLOT_PROXY_NAME
    or is_ingress_entity_name(entity_name)
    or is_egress_entity_name(entity_name)
end

local function does_anchor_match_entity_name(anchor, entity_name)
  if not anchor then
    return false
  end

  if anchor.flow == "egress" then
    return defs.is_egress_entity_name_for_resource(anchor.resource, entity_name)
  end

  return defs.is_ingress_entity_name_for_resource(anchor.resource, entity_name)
end

local function find_matching_stashed_anchor(item_or_entity_name)
  local starter_anchors = storage.starter_anchors

  if not starter_anchors then
    return nil
  end

  for _, anchor in ipairs(starter_anchors.anchors) do
    if not anchor.position and (
      anchor.item_name == item_or_entity_name
      or does_anchor_match_entity_name(anchor, item_or_entity_name)
    ) then
      return anchor
    end
  end

  return nil
end

local function find_anchor_by_entity(entity)
  local starter_anchors = storage.starter_anchors

  if not starter_anchors or not (entity and entity.valid) then
    return nil
  end

  for _, anchor in ipairs(starter_anchors.anchors) do
    if anchor.entity == entity then
      return anchor
    end
  end

  return nil
end

local function find_anchor_by_entity_name_and_position(entity_name, position)
  local starter_anchors = storage.starter_anchors

  if not starter_anchors or not position then
    return nil
  end

  local position_key = defs.get_position_key(position)

  for _, anchor in ipairs(starter_anchors.anchors) do
    if anchor.position
      and defs.get_position_key(anchor.position) == position_key
      and does_anchor_match_entity_name(anchor, entity_name)
    then
      return anchor
    end
  end

  return nil
end

local function clear_anchor_entity(anchor)
  if anchor then
    anchor.entity = nil
  end
end

local function stash_anchor(anchor)
  if not anchor then
    return
  end

  anchor.position = nil
  anchor.side = nil
  clear_anchor_entity(anchor)
end

local function assign_anchor_position(anchor, side, position)
  if not (anchor and side and position) then
    return false
  end

  anchor.position = position
  anchor.side = side
  anchor.direction = defs.DIRECTION_BY_SIDE[side]
  anchor.entity_name = defs.get_anchor_entity_name_for_current_tier(anchor)
  anchor.entity = nil

  return true
end

local function is_fluid_anchor_too_close(anchor, position, side)
  local starter_anchors = storage.starter_anchors

  if not starter_anchors or not anchor or anchor.kind ~= "fluid" then
    return false
  end

  for _, other_anchor in ipairs(starter_anchors.anchors) do
    if other_anchor ~= anchor
      and other_anchor.kind == "fluid"
      and other_anchor.side == side
      and other_anchor.position
    then
      local delta

      if side == "north" or side == "south" then
        delta = math.abs(other_anchor.position.x - position.x)
      else
        delta = math.abs(other_anchor.position.y - position.y)
      end

      if delta <= 1 then
        return true
      end
    end
  end

  return false
end

local function entity_overlaps_anchor_ring(square_size, entity)
  if not (entity and entity.valid and entity.bounding_box) then
    return false
  end

  local bounding_box = entity.bounding_box
  local min_x = math.floor(bounding_box.left_top.x + 0.001)
  local min_y = math.floor(bounding_box.left_top.y + 0.001)
  local max_x = math.ceil(bounding_box.right_bottom.x - 0.001) - 1
  local max_y = math.ceil(bounding_box.right_bottom.y - 0.001) - 1

  for y = min_y, max_y do
    for x = min_x, max_x do
      if defs.is_anchor_ring_position(square_size, {x = x, y = y}) then
        return true
      end
    end
  end

  return false
end

local function destroy_entities_at_anchor_position(surface, anchor)
  if not (surface and anchor and anchor.position) then
    return
  end

  for _, entity in ipairs(surface.find_entities_filtered({position = anchor.position})) do
    if entity.valid and entity.name ~= anchor.entity_name and entity.force == game.forces.player then
      entity.destroy({raise_destroy = false})
    end
  end
end

local function ensure_anchor_entity(surface, anchor)
  if not (surface and anchor and anchor.position) then
    return nil
  end

  anchor.entity_name = defs.get_anchor_entity_name_for_current_tier(anchor)

  local entity = anchor.entity

  if entity and entity.valid and entity.name == anchor.entity_name then
    configure_source_anchor_entity(entity, anchor.direction)
    return entity
  end

  if entity and entity.valid then
    entity.destroy({raise_destroy = false})
    anchor.entity = nil
  end

  destroy_entities_at_anchor_position(surface, anchor)

  entity = find_entity_at_position(surface, anchor.entity_name, anchor.position)

  if entity and entity.valid then
    anchor.entity = entity
    configure_source_anchor_entity(entity, anchor.direction)
    return entity
  end

  entity = surface.create_entity({
    name = anchor.entity_name,
    position = anchor.position,
    direction = anchor.direction,
    force = game.forces.player
  })

  if entity then
    anchor.entity = entity
    configure_source_anchor_entity(entity, anchor.direction)
  end

  return entity
end

local function get_anchor_ring_positions(square_size)
  local positions = {}
  local bounds = defs.get_anchor_bounds(square_size)

  for _, side in ipairs({"north", "east", "south", "west"}) do
    local side_positions = get_edge_positions(bounds, side)

    for _, position in ipairs(side_positions) do
      positions[#positions + 1] = position
    end
  end

  return positions
end

local function ensure_anchor_slot_proxies(surface, square_size, starter_anchors)
  if not (surface and starter_anchors) then
    return
  end

  local occupied_positions = {}
  local valid_ring_positions = {}

  for _, anchor in ipairs(starter_anchors.anchors) do
    if anchor.position then
      occupied_positions[defs.get_position_key(anchor.position)] = true
    end
  end

  for _, position in ipairs(get_anchor_ring_positions(square_size)) do
    local position_key = defs.get_position_key(position)
    valid_ring_positions[position_key] = true
    local proxy = find_entity_at_position(surface, defs.ANCHOR_SLOT_PROXY_NAME, get_tile_center_position(position))

    if occupied_positions[position_key] then
      if proxy and proxy.valid then
        proxy.destroy({raise_destroy = false})
      end
    elseif not proxy then
      surface.create_entity({
        name = defs.ANCHOR_SLOT_PROXY_NAME,
        position = get_tile_center_position(position),
        force = game.forces.player
      })
    end
  end

  for _, proxy in ipairs(surface.find_entities_filtered({name = defs.ANCHOR_SLOT_PROXY_NAME})) do
    local proxy_position = defs.snap_entity_position_to_tile(proxy.position)
    local position_key = defs.get_position_key(proxy_position)

    if not valid_ring_positions[position_key] or occupied_positions[position_key] then
      proxy.destroy({raise_destroy = false})
    end
  end
end

local function migrate_anchor_to_anchor_ring(square_size, anchor)
  if not (anchor and anchor.position and anchor.side) then
    return
  end

  if defs.get_anchor_side_for_position(square_size, anchor.position) then
    return
  end

  anchor.position = defs.move_position(anchor.position, anchor.side, 1)
  anchor.direction = defs.DIRECTION_BY_SIDE[anchor.side]
  anchor.entity = nil
end

function anchor_runtime.ensure_starter_anchor_state()
  local bootstrap = storage.bootstrap

  if not bootstrap then
    return nil
  end

  if storage.starter_anchors and storage.starter_anchors.layout_version ~= defs.STARTER_ANCHOR_LAYOUT_VERSION then
    local migrated_anchors = storage.starter_anchors.anchors or {}

    for _, anchor in ipairs(migrated_anchors) do
      anchor.flow = anchor.flow or "ingress"
      anchor.item_progress = anchor.item_progress or {0, 0}
      anchor.item_name = anchor.item_name or (
        anchor.flow == "egress"
          and defs.get_egress_item_name(anchor.resource)
          or defs.get_ingress_item_name(anchor.resource)
      )
      anchor.entity_name = anchor.entity_name or (
        anchor.flow == "egress"
          and defs.get_egress_entity_name(anchor.resource)
          or defs.get_ingress_entity_name(anchor.resource, 1)
      )
      anchor.entity = nil
      migrate_anchor_to_anchor_ring(bootstrap.square_size, anchor)
    end

    storage.starter_anchors = {
      layout_version = defs.STARTER_ANCHOR_LAYOUT_VERSION,
      anchors = migrated_anchors
    }
  end

  storage.starter_anchors = storage.starter_anchors or {
    layout_version = defs.STARTER_ANCHOR_LAYOUT_VERSION,
    anchors = bootstrap_runtime.build_starter_anchor_layout(bootstrap.square_size)
  }

  for _, anchor in ipairs(storage.starter_anchors.anchors) do
    anchor.flow = anchor.flow or "ingress"
    anchor.item_progress = anchor.item_progress or {0, 0}
    migrate_anchor_to_anchor_ring(bootstrap.square_size, anchor)
  end

  return storage.starter_anchors
end

function anchor_runtime.ensure_starter_anchors()
  local bootstrap = storage.bootstrap

  if not bootstrap then
    return
  end

  local surface = game.surfaces[bootstrap.surface_name]

  if not surface then
    return
  end

  local starter_anchors = anchor_runtime.ensure_starter_anchor_state()

  if not starter_anchors then
    return
  end

  for _, anchor in ipairs(starter_anchors.anchors) do
    if anchor.position then
      ensure_anchor_entity(surface, anchor)
    end
  end

  ensure_anchor_slot_proxies(surface, bootstrap.square_size, starter_anchors)
end

function anchor_runtime.reset_rotated_anchor(entity)
  local anchor = find_anchor_by_entity(entity)

  if not anchor or not (entity and entity.valid) then
    return
  end

  if entity.direction ~= anchor.direction then
    entity.direction = anchor.direction
  end
end

local function refund_entity_to_player(player, entity_name)
  if not (player and player.valid and entity_name) then
    return
  end

  player.insert({name = entity_name, count = 1})
end

local function refund_entity_to_robot(robot, entity_name)
  if not (robot and robot.valid and entity_name) then
    return
  end

  if robot.get_inventory(defines.inventory.robot_cargo) then
    robot.get_inventory(defines.inventory.robot_cargo).insert({name = entity_name, count = 1})
  end
end

local function get_entity_refund_item_name(entity)
  if not (entity and entity.valid and entity.prototype and entity.prototype.items_to_place_this) then
    return nil
  end

  local items_to_place = entity.prototype.items_to_place_this

  if #items_to_place == 0 or not items_to_place[1] then
    return nil
  end

  return items_to_place[1].name
end

local function is_forbidden_logistic_container(entity)
  return entity
    and entity.valid
    and entity.type == "logistic-container"
    and defs.FORBIDDEN_LOGISTIC_CONTAINER_NAMES[entity.name] == true
end

local function apply_logistic_network_setting_to_force(force)
  if not (force and force.valid) then
    return
  end

  if defs.is_logistic_network_automation_enabled() then
    force.reset_technology_effects()
    return
  end

  for recipe_name in pairs(defs.FORBIDDEN_LOGISTIC_CONTAINER_NAMES) do
    local recipe = force.recipes[recipe_name]

    if recipe then
      recipe.enabled = false
    end
  end
end

function anchor_runtime.apply_logistic_network_setting_to_all_forces()
  for _, force in pairs(game.forces) do
    apply_logistic_network_setting_to_force(force)
  end
end

local function reject_anchor_placement(entity, actor, message)
  if not (entity and entity.valid) then
    return
  end

  local item_name = get_entity_refund_item_name(entity)

  if actor and actor.valid then
    if actor.object_name == "LuaPlayer" then
      if item_name then
        refund_entity_to_player(actor, item_name)
      end

      if message then
        actor.print(message)
      end
    elseif actor.object_name == "LuaEntity" and actor.type == "construction-robot" then
      if item_name then
        refund_entity_to_robot(actor, item_name)
      end
    end
  end

  entity.destroy({raise_destroy = false})
end

local function player_insert_or_spill(player, item_name)
  if not (player and player.valid and item_name) then
    return false
  end

  local inserted = player.insert({name = item_name, count = 1})

  if inserted > 0 then
    return true
  end

  if player.surface then
    player.surface.spill_item_stack(player.position, {name = item_name, count = 1}, true, player.force, false)
    return true
  end

  return false
end

local function reject_reserved_ring_placement(entity, actor, message)
  if not (entity and entity.valid) then
    return
  end

  local item_name = get_entity_refund_item_name(entity)

  if actor and actor.valid then
    if actor.object_name == "LuaPlayer" then
      if item_name then
        player_insert_or_spill(actor, item_name)
      end

      if message then
        actor.print(message)
      end
    elseif actor.object_name == "LuaEntity" and actor.type == "construction-robot" and item_name then
      refund_entity_to_robot(actor, item_name)
    end
  end

  entity.destroy({raise_destroy = false})
end

local function get_cursor_managed_anchor(player)
  if not (player and player.valid and player.cursor_stack and player.cursor_stack.valid_for_read) then
    return nil, nil
  end

  local item_name = player.cursor_stack.name
  local anchor = find_matching_stashed_anchor(item_name)

  if not anchor then
    return nil, nil
  end

  return anchor, item_name
end

local function consume_cursor_item(player, item_name)
  if not (player and player.valid and player.cursor_stack and player.cursor_stack.valid_for_read) then
    return false
  end

  if player.cursor_stack.name ~= item_name then
    return false
  end

  if player.cursor_stack.count > 1 then
    player.cursor_stack.count = player.cursor_stack.count - 1
  else
    player.cursor_stack.clear()
  end

  return true
end

local function get_selected_anchor_slot_proxy(player)
  if not (player and player.valid and player.selected and player.selected.valid) then
    return nil
  end

  if player.selected.name ~= defs.ANCHOR_SLOT_PROXY_NAME then
    return nil
  end

  return player.selected
end

local function destroy_player_anchor_preview(player_index)
  local preview_ghosts = storage.anchor_preview_ghosts

  if not preview_ghosts then
    return
  end

  local ghost = preview_ghosts[player_index]

  if ghost and ghost.valid then
    ghost.destroy()
  end

  preview_ghosts[player_index] = nil
end

function anchor_runtime.update_player_anchor_preview(player)
  if not (player and player.valid) then
    return
  end

  destroy_player_anchor_preview(player.index)

  local bootstrap = storage.bootstrap

  if not (bootstrap and player.surface and player.surface.name == bootstrap.surface_name) then
    return
  end

  local proxy = get_selected_anchor_slot_proxy(player)
  local anchor = get_cursor_managed_anchor(player)

  if not (proxy and anchor) then
    return
  end

  local tile_position = defs.snap_entity_position_to_tile(proxy.position)
  local side = defs.get_anchor_side_for_position(bootstrap.square_size, tile_position)

  if not side or is_fluid_anchor_too_close(anchor, tile_position, side) then
    return
  end

  storage.anchor_preview_ghosts = storage.anchor_preview_ghosts or {}
  storage.anchor_preview_ghosts[player.index] = rendering.draw_sprite({
    sprite = "entity/" .. defs.get_anchor_entity_name_for_current_tier(anchor),
    target = {x = tile_position.x + 0.5, y = tile_position.y + 0.5},
    surface = player.surface,
    players = {player.index},
    tint = {r = 1, g = 1, b = 1, a = 0.45},
    x_scale = 0.9,
    y_scale = 0.9,
    render_layer = "object"
  })
end

function anchor_runtime.update_all_player_anchor_previews()
  for _, player in pairs(game.players) do
    anchor_runtime.update_player_anchor_preview(player)
  end
end

function anchor_runtime.get_owned_line_counts(resource)
  local starter_anchors = storage.starter_anchors
  local counts = {
    owned = 0,
    placed = 0,
    stashed = 0
  }

  if not starter_anchors then
    return counts
  end

  for _, anchor in ipairs(starter_anchors.anchors) do
    if anchor.resource == resource then
      counts.owned = counts.owned + 1

      if anchor.position then
        counts.placed = counts.placed + 1
      else
        counts.stashed = counts.stashed + 1
      end
    end
  end

  return counts
end

function anchor_runtime.is_resource_unlocked(resource)
  return anchor_runtime.get_owned_line_counts(resource).owned > 0
end

function anchor_runtime.can_purchase_line(resource)
  local definition = defs.get_input_definition(resource) or defs.get_output_definition(resource)

  if not definition then
    return false, "message.fes-shop-resource-unknown", nil
  end

  if anchor_runtime.is_resource_unlocked(resource) or definition.starter_side then
    return true, nil, nil
  end

  if definition.prerequisite_resource and not anchor_runtime.is_resource_unlocked(definition.prerequisite_resource) then
    return false, "message.fes-shop-prerequisite", definition.prerequisite_resource
  end

  return true, nil, nil
end

local function spend_expansion_points(amount)
  local bootstrap = storage.bootstrap

  if not bootstrap or (bootstrap.expansion_points or 0) < amount then
    return false
  end

  bootstrap.expansion_points = bootstrap.expansion_points - amount
  return true
end

local function get_shop_item_name(resource)
  local input_definition = defs.get_input_definition(resource)

  if input_definition then
    return defs.get_ingress_item_name(resource)
  end

  local output_definition = defs.get_output_definition(resource)

  if output_definition then
    return defs.get_egress_item_name(resource)
  end

  return nil
end

function anchor_runtime.purchase_managed_line_for_resource(player, resource)
  local bootstrap = storage.bootstrap
  local definition, flow = defs.get_line_definition(resource)
  local item_name = get_shop_item_name(resource)

  if not bootstrap or not definition or not item_name then
    return
  end

  local can_purchase, message_key, message_resource = anchor_runtime.can_purchase_line(resource)

  if not can_purchase then
    if player and player.valid then
      if message_resource then
        player.print({message_key, {"item-name." .. get_shop_item_name(message_resource)}})
      else
        player.print({message_key, {"item-name." .. item_name}})
      end
    end

    return
  end

  if not spend_expansion_points(defs.LINE_PURCHASE_COST) then
    if player and player.valid then
      player.print({"message.fes-shop-not-enough-points", defs.LINE_PURCHASE_COST})
    end

    return
  end

  storage.starter_anchors = storage.starter_anchors or {
    layout_version = defs.STARTER_ANCHOR_LAYOUT_VERSION,
    anchors = bootstrap_runtime.build_starter_anchor_layout(bootstrap.square_size)
  }
  storage.starter_anchors.anchors[#storage.starter_anchors.anchors + 1] = defs.create_managed_anchor(definition, flow, nil, nil)

  if player and player.valid then
    player_insert_or_spill(player, item_name)
    player.print({
      "message.fes-shop-purchased-line",
      {"item-name." .. item_name},
      defs.LINE_PURCHASE_COST,
      bootstrap.expansion_points
    })
  end
end

function anchor_runtime.purchase_ingress_tier_upgrade(player)
  local bootstrap = storage.bootstrap
  local next_tier_level = defs.get_next_ingress_tier_level()
  local next_tier = next_tier_level and defs.get_ingress_tier_definition(next_tier_level) or nil
  local upgrade_cost = defs.get_ingress_tier_upgrade_cost(next_tier_level)

  if not bootstrap then
    return
  end

  if not next_tier_level or not next_tier or not upgrade_cost then
    if player and player.valid then
      player.print({"message.fes-shop-ingress-max-tier"})
    end

    return
  end

  if not spend_expansion_points(upgrade_cost) then
    if player and player.valid then
      player.print({"message.fes-shop-not-enough-points", upgrade_cost})
    end

    return
  end

  bootstrap.ingress_tier = next_tier_level
  anchor_runtime.ensure_starter_anchors()

  if player and player.valid then
    player.print({
      "message.fes-shop-purchased-ingress-tier",
      next_tier.label,
      upgrade_cost,
      bootstrap.expansion_points
    })
  end
end

local function handle_managed_anchor_built(entity, actor, gui_runtime)
  if not (entity and entity.valid) then
    return
  end

  local bootstrap = storage.bootstrap

  if not bootstrap then
    return
  end

  if entity.surface.name ~= bootstrap.surface_name then
    reject_anchor_placement(entity, actor, {"message.fes-managed-line-invalid-surface"})
    return
  end

  if actor and actor.valid and actor.object_name == "LuaPlayer" and gui_runtime then
    gui_runtime.print_ingress_placement_debug(actor, bootstrap.square_size, entity.position)
  end

  local tile_position = defs.snap_entity_position_to_tile(entity.position)
  local side = defs.get_anchor_side_for_position(bootstrap.square_size, tile_position)
  local anchor_position = tile_position

  if not side then
    side = defs.get_playable_edge_side_for_position(bootstrap.square_size, tile_position)
    anchor_position = side and defs.move_position(tile_position, side, 1) or nil
  end

  if not side then
    reject_anchor_placement(entity, actor, {"message.fes-managed-line-invalid-edge"})
    return
  end

  local anchor = find_matching_stashed_anchor(entity.name)

  if not anchor then
    reject_anchor_placement(entity, actor, {"message.fes-managed-line-unowned"})
    return
  end

  if is_fluid_anchor_too_close(anchor, anchor_position, side) then
    reject_anchor_placement(entity, actor, {"message.fes-managed-line-fluid-gap-required"})
    return
  end

  entity.destroy({raise_destroy = false})
  assign_anchor_position(anchor, side, anchor_position)
  anchor_runtime.ensure_starter_anchors()
end

function anchor_runtime.handle_managed_anchor_slot_click(player)
  local bootstrap = storage.bootstrap

  if not (player and player.valid and bootstrap) then
    return
  end

  local proxy = get_selected_anchor_slot_proxy(player)

  if not proxy then
    return
  end

  local anchor, item_name = get_cursor_managed_anchor(player)

  if not (anchor and item_name) then
    return
  end

  local tile_position = defs.snap_entity_position_to_tile(proxy.position)
  local side = defs.get_anchor_side_for_position(bootstrap.square_size, tile_position)

  if not side then
    player.print({"message.fes-managed-line-invalid-edge"})
    return
  end

  if is_fluid_anchor_too_close(anchor, tile_position, side) then
    player.print({"message.fes-managed-line-fluid-gap-required"})
    return
  end

  if not consume_cursor_item(player, item_name) then
    return
  end

  assign_anchor_position(anchor, side, tile_position)
  anchor_runtime.ensure_starter_anchors()
  anchor_runtime.update_player_anchor_preview(player)
end

function anchor_runtime.handle_anchor_mined(entity)
  if not (entity and entity.valid) then
    return
  end

  local anchor = find_anchor_by_entity(entity) or find_anchor_by_entity_name_and_position(entity.name, entity.position)

  if anchor then
    stash_anchor(anchor)
    anchor_runtime.ensure_starter_anchors()
  end
end

function anchor_runtime.handle_entity_built(event, gui_runtime)
  local entity = event.entity or event.created_entity

  if not (entity and entity.valid) then
    return
  end

  local player = event.player_index and game.get_player(event.player_index) or nil
  local robot = event.robot
  local actor = player or robot
  local bootstrap = storage.bootstrap

  if bootstrap
    and entity.surface.name == bootstrap.surface_name
    and not anchor_runtime.is_managed_anchor_entity_name(entity.name)
    and entity_overlaps_anchor_ring(bootstrap.square_size, entity)
  then
    reject_reserved_ring_placement(entity, actor, {"message.fes-edge-reserved"})
    return
  end

  if is_forbidden_logistic_container(entity) and not defs.is_logistic_network_automation_enabled() then
    reject_reserved_ring_placement(
      entity,
      actor,
      {"message.fes-logistic-network-disabled", {"entity-name." .. entity.name}}
    )
    return
  end

  if anchor_runtime.is_managed_anchor_entity_name(entity.name) then
    handle_managed_anchor_built(entity, actor, gui_runtime)
  end
end

anchor_runtime.apply_logistic_network_setting_to_force = apply_logistic_network_setting_to_force
anchor_runtime.purchase_managed_line = anchor_runtime.purchase_managed_line_for_resource

return anchor_runtime
