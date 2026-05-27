local bootstrap_runtime = require("lib.bootstrap_runtime")
local defs = require("lib.runtime_defs")
local planet_config = require("lib.planet_config")
local planet_instance = require("lib.planet_instance")
local managed_line_state = require("lib.managed_line_state")
local anchor_identity = require("lib.anchor_identity")
local anchor_placement = require("lib.anchor_placement")

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
  entity.operable = true
  if entity.active ~= nil then
    entity.active = false
  end
end

local function get_required_underground_belt_type(anchor)
  if not (anchor and anchor.flow == "ingress" and anchor.kind == "item") then
    return nil
  end

  if anchor_identity.is_generic_entity_name(anchor.entity_name) then
    return nil
  end

  return "output"
end

local function get_planet_name_for_surface_name(surface_name)
  if surface_name == (storage.bootstrap and storage.bootstrap.surface_name)
    or surface_name == defs.LEGACY_SURFACE_NAME
  then
    return "nauvis"
  end

  if storage.planets then
    for planet_name, planet_state in pairs(storage.planets) do
      if planet_state.surface_name == surface_name then
        return planet_name
      end
    end
  end

  if planet_config.is_supported_planet(surface_name) then
    return surface_name
  end

  return nil
end

local function get_anchor_state_for_surface(surface)
  local planet_name = surface and get_planet_name_for_surface_name(surface.name) or nil

  if not planet_name then
    return nil, nil, nil
  end

  local planet = planet_instance.ensure(planet_name)

  if not planet then
    return nil, nil, nil
  end

  return managed_line_state.ensure(planet_name), planet, planet_name
end

function anchor_runtime.is_managed_anchor_entity_name(entity_name)
  return anchor_identity.is_managed_entity_name(entity_name)
end

local function find_matching_stashed_anchor(item_or_entity_name, starter_anchors)
  return anchor_placement.find_matching_stashed_anchor(item_or_entity_name, starter_anchors or storage.starter_anchors)
end

local function find_anchor_by_entity(entity, starter_anchors)
  return anchor_placement.find_anchor_by_entity(entity, starter_anchors or storage.starter_anchors)
end

local function find_anchor_by_entity_name_and_position(entity_name, position, starter_anchors)
  return anchor_placement.find_anchor_by_entity_name_and_position(entity_name, position, starter_anchors or storage.starter_anchors)
end

local function find_anchor_by_position(position, starter_anchors)
  if not (position and starter_anchors) then
    return nil
  end

  local position_key = defs.get_position_key(defs.snap_entity_position_to_tile(position))

  for _, anchor in ipairs(starter_anchors.anchors) do
    if anchor.position and defs.get_position_key(anchor.position) == position_key then
      return anchor
    end
  end

  return nil
end

local function print_anchor_debug_message(recipient, message)
  if not (
    recipient
    and recipient.valid
    and recipient.object_name == "LuaPlayer"
    and type(recipient.print) == "function"
    and settings
    and type(settings.get_player_settings) == "function"
  ) then
    return
  end

  local player_settings = settings.get_player_settings(recipient)

  if not (player_settings and player_settings[defs.SETTING_DEV_MODE] and player_settings[defs.SETTING_DEV_MODE].value) then
    return
  end

  recipient.print(message)
end

local function are_all_prerequisites_researched(technology)
  if not technology or technology.valid == false then
    return false
  end

  local prerequisites = technology.prerequisites or {}

  for _, prerequisite in pairs(prerequisites) do
    if not prerequisite.researched then
      return false
    end
  end

  return true
end

local function try_unlock_ingress_technology(anchor, force, debug_recipient, resource_name, technology_name, resource_label)
  if not (
    anchor
    and anchor.flow == "ingress"
    and anchor.resource == resource_name
    and force
    and force.valid ~= false
    and force.technologies
  ) then
    return
  end

  local technology = force.technologies[technology_name]

  if not technology then
    print_anchor_debug_message(debug_recipient, "the-square debug: " .. technology_name .. " technology not found")
    return
  end

  if technology.researched then
    print_anchor_debug_message(debug_recipient, "the-square debug: " .. technology_name .. " already researched")
    return
  end

  if not are_all_prerequisites_researched(technology) then
    print_anchor_debug_message(
      debug_recipient,
      "the-square debug: " .. resource_label .. " ingress placed but " .. technology_name .. " prerequisites are not researched"
    )
    return
  end

  technology.researched = true
  if type(force.play_sound) == "function" then
    force.play_sound({path = "utility/research_completed"})
  end
  print_anchor_debug_message(
    debug_recipient,
    "the-square debug: unlocked " .. technology_name .. " from " .. resource_label .. " ingress placement"
  )
end

local function try_unlock_oil_processing(anchor, force, debug_recipient)
  try_unlock_ingress_technology(anchor, force, debug_recipient, "crude-oil", "oil-processing", "crude oil")
end

local function try_unlock_uranium_processing(anchor, force, debug_recipient)
  try_unlock_ingress_technology(anchor, force, debug_recipient, "uranium-ore", "uranium-processing", "uranium ore")
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

  local positions = {anchor.position, get_tile_center_position(anchor.position)}

  for _, position in ipairs(positions) do
    for _, entity in ipairs(surface.find_entities_filtered({position = position})) do
      if entity.valid
        and entity.name ~= anchor.entity_name
        and entity.force == game.forces.player
      then
        entity.destroy({raise_destroy = false})
      end
    end
  end
end

local function ensure_anchor_entity(surface, anchor)
  if not (surface and anchor and anchor.position) then
    return nil
  end

  if not anchor_identity.is_config_proxy_entity_name(anchor.entity_name) then
    anchor.entity_name = defs.get_anchor_entity_name_for_current_tier(anchor)
  end

  local entity = anchor.entity

  if entity and entity.valid and entity.name == anchor.entity_name then
    local required_belt_type = get_required_underground_belt_type(anchor)

    if not required_belt_type or entity.belt_to_ground_type == required_belt_type then
      configure_source_anchor_entity(entity, anchor.direction)
      destroy_entities_at_anchor_position(surface, anchor)
      return entity
    end
  end

  if entity and entity.valid and entity.destroy then
    entity.destroy({raise_destroy = false})
    anchor.entity = nil
  end

  destroy_entities_at_anchor_position(surface, anchor)

  entity = find_entity_at_position(surface, anchor.entity_name, anchor.position)

  if entity and entity.valid then
    local required_belt_type = get_required_underground_belt_type(anchor)

    if not required_belt_type or entity.belt_to_ground_type == required_belt_type then
      anchor.entity = entity
      configure_source_anchor_entity(entity, anchor.direction)
      destroy_entities_at_anchor_position(surface, anchor)
      return entity
    end

    entity.destroy({raise_destroy = false})
  end

  entity = surface.create_entity({
    name = anchor.entity_name,
    position = anchor.position,
    direction = anchor.direction,
    force = game.forces.player,
    type = get_required_underground_belt_type(anchor)
  })

  if entity then
    anchor.entity = entity
    configure_source_anchor_entity(entity, anchor.direction)
    destroy_entities_at_anchor_position(surface, anchor)
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
    if anchor.position and anchor.resource then
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

function anchor_runtime.ensure_starter_anchor_state()
  return managed_line_state.ensure("nauvis")
end

local function ensure_anchor_set(surface, square_size, starter_anchors)
  if not (surface and starter_anchors) then
    return
  end

  for _, anchor in ipairs(starter_anchors.anchors) do
    if anchor.position and anchor.resource then
      ensure_anchor_entity(surface, anchor)
    elseif anchor.position and anchor.entity then
      if anchor.entity.valid and anchor.entity.destroy then
        anchor.entity.destroy({raise_destroy = false})
      end
      anchor.entity = nil
    end
  end

  ensure_anchor_slot_proxies(surface, square_size, starter_anchors)
end

local function fill_starter_entity_inventory(entity, inventory_config)
  if not (entity and inventory_config and entity.get_inventory and defines and defines.inventory) then
    return
  end

  local inventory = entity.get_inventory(defines.inventory.chest)

  if not inventory then
    return
  end

  inventory.clear()

  for _, stack in ipairs(inventory_config.articles or {}) do
    inventory.insert(stack)
  end
end

local function ensure_planet_starter_entities(surface, planet_name, planet)
  local state = planet and planet.state

  if state and state.starter_entities_spawned then
    return
  end

  local force = game.forces.player

  for _, starter_entity in ipairs(planet_config.get_starter_entities(planet_name)) do
    local existing = surface.find_entities_filtered({name = starter_entity.name, position = starter_entity.position})[1]
    local entity = existing

    if not (entity and entity.valid) then
      entity = surface.create_entity({
        name = starter_entity.name,
        position = starter_entity.position,
        force = force,
        raise_built = false
      })
    end

    fill_starter_entity_inventory(entity, starter_entity.inventory)
  end

  if state then
    state.starter_entities_spawned = true
  end
end

function anchor_runtime.unlock_planet_bootstrap_research(planet_name, force)
  if not (planet_name and force and force.technologies) then
    return
  end

  for _, technology_name in ipairs(planet_config.get_bootstrap_research(planet_name)) do
    local technology = force.technologies[technology_name]

    if technology then
      technology.researched = true
    end
  end
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

  ensure_anchor_set(surface, bootstrap.square_size, starter_anchors)
end

function anchor_runtime.ensure_planet_starter_anchor_state(planet_name)
  return managed_line_state.ensure(planet_name)
end

function anchor_runtime.ensure_planet_starter_anchors(planet_name)
  local planet = planet_instance.ensure(planet_name)

  if not planet then
    return
  end

  local surface = game.surfaces[planet:get_surface_name()]

  if not surface then
    return
  end

  anchor_runtime.unlock_planet_bootstrap_research(planet_name, game.forces.player)
  ensure_anchor_set(surface, planet:get_square_size(), anchor_runtime.ensure_planet_starter_anchor_state(planet_name))
  ensure_planet_starter_entities(surface, planet_name, planet)
end

function anchor_runtime.ensure_all_planet_starter_anchors()
  for _, planet_name in ipairs(planet_config.SUPPORTED_PLANETS) do
    anchor_runtime.ensure_planet_starter_anchors(planet_name)
  end
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

local function get_selected_anchor_slot_proxy(player)
  if not (player and player.valid and player.selected and player.selected.valid) then
    return nil
  end

  if player.selected.name ~= defs.ANCHOR_SLOT_PROXY_NAME then
    return nil
  end

  return player.selected
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

function anchor_runtime.can_purchase_line(resource, force)
  local definition, flow = defs.get_line_definition(resource)

  if not definition then
    return false, "message.the-square-shop-resource-unknown", nil
  end

  if anchor_runtime.is_resource_unlocked(resource) or defs.is_config_definition_unlocked(definition, flow, force) then
    return true, nil, nil
  end

  if definition.prerequisite_resource and not anchor_runtime.is_resource_unlocked(definition.prerequisite_resource) then
    return false, "message.the-square-shop-prerequisite", definition.prerequisite_resource
  end

  return true, nil, nil
end

function anchor_runtime.sync_anchor_tiers_from_research(force)
  local bootstrap = storage.bootstrap

  if not bootstrap then
    return false
  end

  local target_ingress_tier_level = defs.get_ingress_tier_level_for_force(force or defs.get_player_force())
  local target_egress_tier_level = defs.get_egress_tier_level_for_force(force or defs.get_player_force())
  local changed = false

  if bootstrap.ingress_tier ~= target_ingress_tier_level then
    bootstrap.ingress_tier = target_ingress_tier_level
    changed = true
  end

  if bootstrap.egress_tier ~= target_egress_tier_level then
    bootstrap.egress_tier = target_egress_tier_level
    changed = true
  end

  if not changed then
    return false
  end

  anchor_runtime.ensure_starter_anchors()
  anchor_runtime.ensure_all_planet_starter_anchors()

  return true
end

function anchor_runtime.sync_ingress_tier_from_research(force)
  return anchor_runtime.sync_anchor_tiers_from_research(force)
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

local function grant_managed_line(player, bootstrap, definition, flow, item_name, purchase_message)
  if not (bootstrap and definition and flow and item_name) then
    return false
  end

  storage.starter_anchors = storage.starter_anchors or {
    layout_version = defs.STARTER_ANCHOR_LAYOUT_VERSION,
    anchors = {}
  }
  storage.starter_anchors.anchors[#storage.starter_anchors.anchors + 1] = defs.create_managed_anchor(definition, flow, nil, nil)

  if player and player.valid then
    player_insert_or_spill(player, item_name)

    if purchase_message then
      player.print(purchase_message)
    end
  end

  return true
end

function anchor_runtime.purchase_managed_line_for_resource(player, resource)
  local bootstrap = storage.bootstrap
  local definition, flow = defs.get_line_definition(resource)
  local item_name = get_shop_item_name(resource)

  if not bootstrap or not definition or not item_name then
    return
  end

  local can_purchase, message_key, message_resource = anchor_runtime.can_purchase_line(resource, player and player.force)

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

  grant_managed_line(player, bootstrap, definition, flow, item_name, {
    "message.the-square-shop-purchased-line",
    {"item-name." .. item_name}
  })

  if resource == "uranium-ore" and not anchor_runtime.is_resource_unlocked("sulfuric-acid") then
    local sulfuric_acid_definition = defs.get_output_definition("sulfuric-acid")
    local sulfuric_acid_item_name = defs.get_egress_item_name("sulfuric-acid")

    grant_managed_line(player, bootstrap, sulfuric_acid_definition, "egress", sulfuric_acid_item_name)
  end
end

local function run_anchor_placement_effects(anchor, force, actor, source_label)
  if anchor.flow == "ingress" and anchor.resource == "crude-oil" then
    print_anchor_debug_message(actor, "the-square debug: placed crude oil ingress via " .. source_label)
  end

  if anchor.flow == "ingress" and anchor.resource == "uranium-ore" then
    print_anchor_debug_message(actor, "the-square debug: placed uranium ore ingress via " .. source_label)
  end

  try_unlock_oil_processing(anchor, force, actor)
  try_unlock_uranium_processing(anchor, force, actor)
end

local function get_anchor_placement_rejection_message(reason)
  return reason == "fluid-gap-required" and {"message.the-square-managed-line-fluid-gap-required"}
    or {"message.the-square-managed-line-invalid-edge"}
end

local function consume_player_inventory_item(player, item_name)
  if not (player and player.valid and item_name) then
    return false
  end

  if player.get_item_count and player.get_item_count(item_name) < 1 then
    return false
  end

  if player.remove_item then
    return player.remove_item({name = item_name, count = 1}) == 1
  end

  return false
end

local function can_player_receive_item(player, item_name)
  if not (player and player.valid and item_name) then
    return false
  end

  if player.can_insert then
    return player.can_insert({name = item_name, count = 1})
  end

  return true
end

local function insert_player_inventory_item(player, item_name)
  if not (player and player.valid and item_name and player.insert) then
    return false
  end

  return player.insert({name = item_name, count = 1}) == 1
end

local function destroy_anchor_config_gui(player)
  if not (player and player.valid and player.gui and player.gui.screen) then
    return
  end

  local frame = player.gui.screen[defs.ANCHOR_CONFIG_FRAME_NAME]

  if frame and frame.valid then
    frame.destroy()
  end
end

local function remember_open_anchor_config(player, planet_name, anchor, category, tier_level)
  storage.anchor_config_open = storage.anchor_config_open or {}
  storage.anchor_config_open[player.index or player.player_index or 1] = {
    planet_name = planet_name,
    position_key = anchor.position and defs.get_position_key(anchor.position) or nil,
    category = category or "ingress_item",
    tier_level = tier_level or anchor.tier_level or 1
  }
end

local ANCHOR_CONFIG_CATEGORIES = {
  ingress_item = {
    flow = "ingress",
    kind = "item",
    caption = {"gui.the-square-anchor-config-ingress-item"},
    sprite = "item/underground-belt"
  },
  ingress_fluid = {
    flow = "ingress",
    kind = "fluid",
    caption = {"gui.the-square-anchor-config-ingress-fluid"},
    sprite = "item/offshore-pump"
  },
  egress_fluid = {
    flow = "egress",
    kind = "fluid",
    caption = {"gui.the-square-anchor-config-egress-fluid"},
    sprite = "item/pipe-to-ground"
  },
  egress_item = {
    flow = "egress",
    kind = "item",
    caption = {"gui.the-square-anchor-config-egress-item"},
    sprite = "item/underground-belt"
  }
}

local ANCHOR_CONFIG_CATEGORY_ORDER = {
  "ingress_item",
  "ingress_fluid",
  "egress_fluid",
  "egress_item"
}

local function get_anchor_config_category_for_anchor(anchor)
  if not (anchor and anchor.flow and anchor.kind) then
    return "ingress_item"
  end

  return anchor.flow .. "_" .. anchor.kind
end

local function add_anchor_config_category_tabs(parent, selected_category)
  local tab_flow = parent.add({
    type = "flow",
    direction = "horizontal"
  })

  for _, category_name in ipairs(ANCHOR_CONFIG_CATEGORY_ORDER) do
    local category = ANCHOR_CONFIG_CATEGORIES[category_name]
    local button = tab_flow.add({
      type = "sprite-button",
      name = defs.ANCHOR_CONFIG_BUTTON_PREFIX .. "category__" .. category_name,
      sprite = category.sprite,
      tooltip = category.caption,
      style = "slot_button"
    })

    if button.style then
      button.style.width = 92
      button.style.height = 72
    end

    if category_name == selected_category then
      button.toggled = true
    end
  end
end

local function add_anchor_config_resource_grid(parent, definitions, flow, kind, anchor, force)
  local table_element = parent.add({
    type = "table",
    column_count = 10
  })
  local added = false
  for _, definition in ipairs(definitions) do
    if definition.kind == kind
      and (
        anchor.resource == definition.resource
        or anchor_runtime.is_resource_unlocked(definition.resource)
        or defs.is_config_definition_unlocked(definition, flow, force)
      )
    then
      local selected = anchor.resource == definition.resource and anchor.flow == flow
      local sprite_prefix = definition.kind == "fluid" and "fluid/" or "item/"
      local button = table_element.add({
        type = "sprite-button",
        name = defs.ANCHOR_CONFIG_BUTTON_PREFIX .. "pick__" .. flow .. "__" .. definition.resource,
        sprite = sprite_prefix .. definition.resource,
        tooltip = {(definition.kind == "fluid" and "fluid-name." or "item-name.") .. definition.resource},
        elem_tooltip = {
          type = definition.kind == "fluid" and "fluid" or "item",
          name = definition.resource
        },
        style = "slot_button"
      })

      if button.style then
        button.style.width = 44
        button.style.height = 44
      end

      if selected then
        button.enabled = false
      end

      added = true
    end
  end

  if not added then
    table_element.add({
      type = "label",
      caption = {"gui.the-square-anchor-config-none"}
    })
  end
end

local function add_anchor_config_tier_selector(parent, player, selected_tier_level)
  local tiers = defs.get_researched_managed_line_item_tiers(player and player.force)

  if #tiers <= 1 then
    return
  end

  local flow = parent.add({
    type = "flow",
    direction = "horizontal"
  })

  for _, tier in ipairs(tiers) do
    local button = flow.add({
      type = "button",
      name = defs.ANCHOR_CONFIG_TIER_BUTTON_PREFIX .. tier.key,
      caption = {"the-square-managed-line-tier." .. tier.key}
    })

    if button.style then
      button.style.width = 80
      button.style.height = 32
    end

    if tier.tier_level == selected_tier_level then
      button.enabled = false
    end
  end
end

local function open_anchor_config_gui(player, anchor, planet_name, category_name, tier_level)
  if not (player and player.valid and player.gui and player.gui.screen and anchor and anchor.position) then
    return false
  end

  category_name = category_name or get_anchor_config_category_for_anchor(anchor)
  tier_level = tier_level or anchor.tier_level or 1

  destroy_anchor_config_gui(player)
  remember_open_anchor_config(player, planet_name, anchor, category_name, tier_level)

  local frame = player.gui.screen.add({
    type = "frame",
    name = defs.ANCHOR_CONFIG_FRAME_NAME,
    direction = "vertical",
    caption = {"gui.the-square-anchor-config-title"}
  })

  if frame.force_auto_center then
    frame.force_auto_center()
  end

  add_anchor_config_category_tabs(frame, category_name)

  local category = ANCHOR_CONFIG_CATEGORIES[category_name] or ANCHOR_CONFIG_CATEGORIES.ingress_item
  local definitions = category.flow == "egress"
    and defs.get_output_definitions(planet_name)
    or defs.get_input_definitions(planet_name)

  add_anchor_config_resource_grid(frame, definitions, category.flow, category.kind, anchor, player.force)
  add_anchor_config_tier_selector(frame, player, tier_level)

  player.opened = frame

  return true
end

local function clear_anchor_managed_line(anchor)
  if not anchor then
    return
  end

  if anchor.entity and anchor.entity.valid and anchor.entity.destroy then
    anchor.entity.destroy({raise_destroy = false})
  end

  anchor.resource = nil
  anchor.kind = nil
  anchor.flow = nil
  anchor.direction = nil
  anchor.entity_name = nil
  anchor.item_name = nil
  anchor.item_progress = {0, 0}
  anchor.entity = nil
end

local function configure_anchor_managed_line(anchor, definition, flow, side, tier_level)
  anchor.resource = definition.resource
  anchor.kind = definition.kind
  anchor.flow = flow
  anchor.side = side
  anchor.direction = defs.get_anchor_direction_for_side(flow, definition.kind, side)
  anchor.tier_level = tier_level or anchor.tier_level or 1
  anchor.item_name = defs.get_generic_anchor_item_name_for_tier(anchor.kind, anchor.flow, anchor.tier_level)
  anchor.entity_name = defs.get_anchor_entity_name_for_current_tier(anchor)
  anchor.item_progress = {0, 0}
end

local function find_matching_stashed_configurable_anchor(definition, flow, starter_anchors, tier_level)
  if not (definition and flow and starter_anchors) then
    return nil
  end

  for _, candidate in ipairs(starter_anchors.anchors) do
    if not candidate.position
      and candidate.kind == definition.kind
      and candidate.flow == flow
      and (candidate.tier_level or 1) == (tier_level or 1)
      and (not candidate.resource or candidate.resource == definition.resource)
    then
      return candidate
    end
  end

  return nil
end

local function remove_anchor_from_set(anchor, starter_anchors)
  if not (anchor and starter_anchors) then
    return
  end

  for index, candidate in ipairs(starter_anchors.anchors) do
    if candidate == anchor then
      table.remove(starter_anchors.anchors, index)
      return
    end
  end
end

local function handle_managed_anchor_built(entity, actor, gui_runtime)
  if not (entity and entity.valid) then
    return
  end

  local starter_anchors, planet = get_anchor_state_for_surface(entity.surface)

  if not (starter_anchors and planet) then
    reject_anchor_placement(entity, actor, {"message.the-square-managed-line-invalid-surface"})
    return
  end

  reject_anchor_placement(entity, actor, {"message.the-square-managed-line-use-anchor-slot"})
end

function anchor_runtime.handle_managed_anchor_slot_click(player)
  if not (player and player.valid) then
    return
  end

  local starter_anchors, planet, planet_name = get_anchor_state_for_surface(player.surface)

  if not (starter_anchors and planet) then
    return
  end

  local proxy = get_selected_anchor_slot_proxy(player)

  if not proxy then
    return
  end

  local tile_position = defs.snap_entity_position_to_tile(proxy.position)
  local side = defs.get_anchor_side_for_position(planet:get_square_size(), tile_position)

  if not side then
    player.print({"message.the-square-managed-line-invalid-edge"})
    return
  end

  local anchor = find_anchor_by_position(tile_position, starter_anchors)

  if not anchor then
    anchor = {
      side = side,
      position = tile_position,
      item_progress = {0, 0}
    }
    starter_anchors.anchors[#starter_anchors.anchors + 1] = anchor
  end

  open_anchor_config_gui(player, anchor, planet_name)
end

function anchor_runtime.handle_anchor_mined(entity)
  if not (entity and entity.valid) then
    return
  end

  local starter_anchors, _, planet_name = get_anchor_state_for_surface(entity.surface)
  local anchor = find_anchor_by_entity(entity, starter_anchors)
    or find_anchor_by_entity_name_and_position(entity.name, entity.position, starter_anchors)

  if anchor then
    clear_anchor_managed_line(anchor)

    anchor_runtime.ensure_planet_starter_anchors(planet_name)
  end
end

function anchor_runtime.handle_anchor_gui_opened(entity, player)
  if not (entity and entity.valid and player and player.valid) then
    return false
  end

  local starter_anchors, _, planet_name = get_anchor_state_for_surface(entity.surface)
  local anchor = find_anchor_by_entity(entity, starter_anchors)
    or find_anchor_by_entity_name_and_position(entity.name, entity.position, starter_anchors)

  if not (anchor and anchor.position and entity.surface) then
    return false
  end

  return open_anchor_config_gui(player, anchor, planet_name)
end

function anchor_runtime.handle_anchor_recipe_changed(entity, actor)
  if not (entity and entity.valid and (anchor_identity.is_generic_entity_name(entity.name) or anchor_identity.is_config_proxy_entity_name(entity.name))) then
    return false
  end

  local starter_anchors, planet, planet_name = get_anchor_state_for_surface(entity.surface)
  local anchor = find_anchor_by_entity(entity, starter_anchors)
    or find_anchor_by_entity_name_and_position(entity.name, entity.position, starter_anchors)

  if not anchor then
    return false
  end

  local recipe = entity.get_recipe and entity.get_recipe(entity) or nil
  if not recipe then
    anchor.resource = nil
    anchor.item_progress = {0, 0}
    return true
  end

  local resource, flow = defs.parse_config_recipe_name(recipe.name)
  local definition = defs.get_config_definition(resource, flow, planet_name)

  local is_fresh_slot_configuration = anchor_identity.is_config_proxy_entity_name(entity.name)
    and not anchor.resource

  if not definition
    or (not is_fresh_slot_configuration and (flow ~= anchor.flow or definition.kind ~= anchor.kind))
  then
    if entity.set_recipe then
      entity.set_recipe(anchor.resource and defs.get_config_recipe_name(anchor.resource, anchor.flow) or nil)
    end
    if actor and actor.valid and actor.print then
      actor.print({"message.the-square-managed-line-invalid-configuration"})
    end
    return false
  end

  local placement_anchor = is_fresh_slot_configuration and {
    kind = definition.kind,
    flow = flow
  } or anchor
  local ok, reason, side = anchor_placement.check(
    placement_anchor,
    anchor.position,
    planet and planet:get_square_size() or storage.bootstrap and storage.bootstrap.square_size,
    starter_anchors
  )

  if not ok then
    if entity.set_recipe then
      entity.set_recipe(nil)
    end
    if actor and actor.valid and actor.print then
      actor.print(get_anchor_placement_rejection_message(reason))
    end
    if entity.active ~= nil then
      entity.active = false
    end
    return false
  end

  if is_fresh_slot_configuration then
    local item_name = defs.get_generic_anchor_item_name_for_tier(definition.kind, flow, anchor.tier_level or 1)

    if not consume_player_inventory_item(actor, item_name) then
      if entity.set_recipe then
        entity.set_recipe(nil)
      end
      if actor and actor.valid and actor.print then
        actor.print({"message.the-square-managed-line-missing-inventory", {"item-name." .. item_name}})
      end
      if entity.active ~= nil then
        entity.active = false
      end
      return false
    end

    local stashed_anchor = find_matching_stashed_configurable_anchor(definition, flow, starter_anchors, anchor.tier_level or 1)

    if stashed_anchor and stashed_anchor ~= anchor then
      remove_anchor_from_set(anchor, starter_anchors)
      anchor = stashed_anchor
      anchor.entity = entity
      anchor.position = entity.position and defs.snap_entity_position_to_tile(entity.position) or anchor.position
    end
  end

  anchor.resource = resource
  anchor.kind = definition.kind
  anchor.flow = flow
  anchor.side = side
  anchor.direction = defs.get_anchor_direction_for_side(flow, definition.kind, side)
  anchor.tier_level = anchor.tier_level or 1
  anchor.item_name = defs.get_generic_anchor_item_name_for_tier(anchor.kind, anchor.flow, anchor.tier_level)
  anchor.entity_name = defs.get_anchor_entity_name_for_current_tier(anchor)
  anchor.item_progress = {0, 0}
  if entity.active ~= nil then
    entity.active = false
  end
  try_unlock_oil_processing(anchor, entity.force, actor)
  try_unlock_uranium_processing(anchor, entity.force, actor)

  anchor_runtime.ensure_planet_starter_anchors(planet_name)

  return true
end

local function get_open_anchor_for_player(player)
  if not (player and player.valid and storage.anchor_config_open) then
    return nil, nil, nil, nil
  end

  local open_config = storage.anchor_config_open[player.index or player.player_index or 1]

  if not (open_config and open_config.planet_name and open_config.position_key) then
    return nil, nil, nil, nil
  end

  local starter_anchors = managed_line_state.ensure(open_config.planet_name)

  if not starter_anchors then
    return nil, nil, nil, nil
  end

  for _, anchor in ipairs(starter_anchors.anchors) do
    if anchor.position and defs.get_position_key(anchor.position) == open_config.position_key then
      return anchor, starter_anchors, planet_instance.ensure(open_config.planet_name), open_config.planet_name
    end
  end

  return nil, starter_anchors, planet_instance.ensure(open_config.planet_name), open_config.planet_name
end

local function parse_anchor_config_button_name(name)
  if type(name) ~= "string" then
    return nil, nil, nil
  end

  local category = string.match(name, "^" .. defs.ANCHOR_CONFIG_BUTTON_PREFIX .. "category__(.+)$")

  if category then
    return "category", category, nil
  end

  local tier_key = string.match(name, "^" .. defs.ANCHOR_CONFIG_TIER_BUTTON_PREFIX .. "(.+)$")

  if tier_key then
    return "tier", tier_key, nil
  end

  local flow, resource = string.match(name, "^" .. defs.ANCHOR_CONFIG_BUTTON_PREFIX .. "pick__(%w+)__(.+)$")

  if flow then
    return "pick", flow, resource
  end

  flow, resource = string.match(name, "^" .. defs.ANCHOR_CONFIG_BUTTON_PREFIX .. "(%w+)__(.+)$")

  if flow then
    return "pick", flow, resource
  end

  return nil, nil, nil
end

local function get_open_anchor_config_for_player(player)
  return storage.anchor_config_open and storage.anchor_config_open[player.index or player.player_index or 1] or nil
end

function anchor_runtime.handle_anchor_config_gui_click(player, element)
  if not (player and player.valid and element and element.valid) then
    return false
  end

  local anchor, starter_anchors, planet, planet_name = get_open_anchor_for_player(player)

  if not (anchor and starter_anchors and planet and planet_name) then
    return false
  end

  local action, value, resource = parse_anchor_config_button_name(element.name)
  local open_config = get_open_anchor_config_for_player(player) or {}
  local selected_tier_level = open_config.tier_level or anchor.tier_level or 1

  if action == "category" then
    if ANCHOR_CONFIG_CATEGORIES[value] then
      open_anchor_config_gui(player, anchor, planet_name, value, selected_tier_level)
      return true
    end

    return false
  end

  if action == "tier" then
    local tier = defs.get_managed_line_item_tier_by_key(value)
    local researched_tiers = defs.get_researched_managed_line_item_tiers(player.force)

    for _, researched_tier in ipairs(researched_tiers) do
      if researched_tier.key == tier.key then
        open_anchor_config_gui(player, anchor, planet_name, open_config.category, tier.tier_level)
        return true
      end
    end

    return false
  end

  if action ~= "pick" then
    return false
  end

  local flow = value
  local definition = defs.get_config_definition(resource, flow, planet_name)

  if not definition then
    player.print({"message.the-square-managed-line-invalid-configuration"})
    return true
  end

  local ok, reason, side = anchor_placement.check(
    {
      kind = definition.kind,
      flow = flow
    },
    anchor.position,
    planet:get_square_size(),
    starter_anchors
  )

  if not ok then
    player.print(get_anchor_placement_rejection_message(reason))
    return true
  end

  local is_fresh_anchor_configuration = not anchor.resource
  local previous_item_name = anchor.resource and (anchor.item_name or defs.get_generic_anchor_item_name_for_tier(anchor.kind, anchor.flow, anchor.tier_level)) or nil
  local next_item_name = defs.get_generic_anchor_item_name_for_tier(definition.kind, flow, selected_tier_level)
  local is_line_type_change = anchor.resource and previous_item_name ~= next_item_name

  if is_line_type_change and not can_player_receive_item(player, previous_item_name) then
    player.print({"message.the-square-managed-line-refund-inventory-full", {"item-name." .. previous_item_name}})
    return true
  end

  if is_fresh_anchor_configuration or is_line_type_change then
    if not consume_player_inventory_item(player, next_item_name) then
      player.print({"message.the-square-managed-line-missing-inventory", {"item-name." .. next_item_name}})
      return true
    end
  end

  if is_fresh_anchor_configuration then
    local stashed_anchor = find_matching_stashed_configurable_anchor(definition, flow, starter_anchors, selected_tier_level)

    if stashed_anchor and stashed_anchor ~= anchor then
      local position = anchor.position

      remove_anchor_from_set(anchor, starter_anchors)
      anchor = stashed_anchor
      anchor.position = position
      anchor.side = side
      anchor.entity = nil
    end
  end

  if is_line_type_change and not insert_player_inventory_item(player, previous_item_name) then
    insert_player_inventory_item(player, next_item_name)
    player.print({"message.the-square-managed-line-refund-inventory-full", {"item-name." .. previous_item_name}})
    return true
  end

  if anchor.entity and anchor.entity.valid and anchor.entity.destroy then
    anchor.entity.destroy({raise_destroy = false})
    anchor.entity = nil
  end

  configure_anchor_managed_line(anchor, definition, flow, side, selected_tier_level)
  local force = player.force or game and game.forces and game.forces.player
  try_unlock_oil_processing(anchor, force, player)
  try_unlock_uranium_processing(anchor, force, player)
  anchor_runtime.ensure_planet_starter_anchors(planet_name)
  destroy_anchor_config_gui(player)

  return true
end

function anchor_runtime.handle_anchor_config_gui_closed(player, element)
  if not (player and player.valid and element and element.valid) then
    return false
  end

  if element.name ~= defs.ANCHOR_CONFIG_FRAME_NAME then
    return false
  end

  if storage.anchor_config_open then
    storage.anchor_config_open[player.index or player.player_index or 1] = nil
  end

  if element.destroy then
    element.destroy()
  end

  return true
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
    reject_reserved_ring_placement(entity, actor, {"message.the-square-edge-reserved"})
    return
  end

  if is_forbidden_logistic_container(entity) and not defs.is_logistic_network_automation_enabled() then
    reject_reserved_ring_placement(
      entity,
      actor,
      {"message.the-square-logistic-network-disabled", {"entity-name." .. entity.name}}
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
