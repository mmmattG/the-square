-- Anchor Slot Configuration: clicking an empty Anchor (or a placed line) opens a menu
-- of the resources this Planet allows. Picking one consumes the matching Managed
-- Line item from the player's inventory and places the line.
local anchor_placement = require("lib.anchor_placement")
local anchor_runtime = require("lib.anchor_runtime")
local definitions = require("lib.managed_line_definitions")
local managed_line_state = require("lib.managed_line_state")
local managed_line_tiers = require("lib.managed_line_tiers")
local mod_settings = require("lib.mod_settings")
local planet_catalog = require("lib.planet_catalog")
local planet_state = require("lib.planet_state")
local square_layout = require("lib.square_layout")

local anchor_config_gui = {}

local FRAME_NAME = "the_square_anchor_config_frame"
local CATEGORY_BUTTON_PREFIX = "the_square_anchor_config_category__"
local PICK_BUTTON_PREFIX = "the_square_anchor_config_pick__"
local TIER_BUTTON_PREFIX = "the_square_anchor_config_tier__"

local CATEGORIES = {
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

local CATEGORY_ORDER = {"ingress_item", "ingress_fluid", "egress_fluid", "egress_item"}

-- Placing these ingress lines also researches the technology that processes them,
-- once its prerequisites are done, since the Square has no ore patch to trigger it.
local PLACEMENT_UNLOCKS = {
  ["crude-oil"] = "oil-processing",
  ["uranium-ore"] = "uranium-processing"
}

local function print_debug(player, message)
  if mod_settings.is_dev_mode_enabled(player) then
    player.print("the-square debug: " .. message)
  end
end

local function are_prerequisites_researched(technology)
  for _, prerequisite in pairs(technology.prerequisites) do
    if not prerequisite.researched then
      return false
    end
  end

  return true
end

local function unlock_processing_technology(anchor, player)
  local technology_name = anchor.flow == "ingress" and PLACEMENT_UNLOCKS[anchor.resource]

  if not technology_name then
    return
  end

  local technology = player.force.technologies[technology_name]

  if technology.researched then
    print_debug(player, technology_name .. " already researched")
    return
  end

  if not are_prerequisites_researched(technology) then
    print_debug(player, anchor.resource .. " ingress placed but " .. technology_name .. " prerequisites are not researched")
    return
  end

  technology.researched = true
  player.force.play_sound({path = "utility/research_completed"})
  print_debug(player, "unlocked " .. technology_name .. " from " .. anchor.resource .. " ingress placement")
end

-- A resource is offered once it is unlocked, or while the Planet owns a line for it.
local function is_resource_offered(definition, flow, anchor, managed_lines, force)
  if anchor.resource == definition.resource
    or definition.unlocked_at_start
    or managed_line_state.owns_resource(managed_lines, definition.resource)
  then
    return true
  end

  local technology = definition.unlock_technology and force.technologies[definition.unlock_technology]

  return technology ~= nil and technology.researched
end

local function destroy_frame(player)
  local frame = player.gui.screen[FRAME_NAME]

  if frame then
    frame.destroy()
  end
end

local function add_category_tabs(parent, selected_category)
  local tabs = parent.add({type = "flow", direction = "horizontal"})

  for _, category_name in ipairs(CATEGORY_ORDER) do
    local category = CATEGORIES[category_name]
    local button = tabs.add({
      type = "sprite-button",
      name = CATEGORY_BUTTON_PREFIX .. category_name,
      sprite = category.sprite,
      tooltip = category.caption,
      style = "slot_button",
      toggled = category_name == selected_category
    })

    button.style.width = 92
    button.style.height = 72
  end
end

local function add_resource_grid(parent, category, anchor, managed_lines, planet_name, player, selected_tier_level)
  local grid = parent.add({type = "table", column_count = 10})
  local added = false

  for _, definition in ipairs(planet_catalog.get_resources(planet_name, category.flow)) do
    if definition.kind == category.kind
      and is_resource_offered(definition, category.flow, anchor, managed_lines, player.force)
    then
      local is_current = anchor.resource == definition.resource
        and anchor.flow == category.flow
        and (definition.kind == "fluid" or (anchor.tier_level or 1) == selected_tier_level)
      local button = grid.add({
        type = "sprite-button",
        name = PICK_BUTTON_PREFIX .. category.flow .. "__" .. definition.resource,
        sprite = definition.kind .. "/" .. definition.resource,
        tooltip = {definition.kind .. "-name." .. definition.resource},
        elem_tooltip = {type = definition.kind, name = definition.resource},
        style = "slot_button",
        enabled = not is_current
      })

      button.style.width = 44
      button.style.height = 44
      added = true
    end
  end

  if not added then
    grid.add({type = "label", caption = {"gui.the-square-anchor-config-none"}})
  end
end

local function add_tier_selector(parent, player, selected_tier_level)
  local tiers = managed_line_tiers.get_researched_item_tiers(player.force)

  if #tiers <= 1 then
    return
  end

  local row = parent.add({type = "flow", direction = "horizontal"})

  for _, tier in ipairs(tiers) do
    local button = row.add({
      type = "button",
      name = TIER_BUTTON_PREFIX .. tier.key,
      caption = {"the-square-managed-line-tier." .. tier.key},
      enabled = tier.tier_level ~= selected_tier_level
    })

    button.style.width = 80
    button.style.height = 32
  end
end

local function open(player, anchor, planet_name, category_name, tier_level)
  category_name = category_name or (anchor.flow and anchor.kind and anchor.flow .. "_" .. anchor.kind) or "ingress_item"
  tier_level = tier_level or anchor.tier_level or 1

  local category = CATEGORIES[category_name]
  local managed_lines = managed_line_state.get(planet_name)

  destroy_frame(player)
  storage.anchor_config_open = storage.anchor_config_open or {}
  storage.anchor_config_open[player.index] = {
    planet_name = planet_name,
    position_key = square_layout.get_position_key(anchor.position),
    category = category_name,
    tier_level = tier_level
  }

  local frame = player.gui.screen.add({
    type = "frame",
    name = FRAME_NAME,
    direction = "vertical",
    caption = {"gui.the-square-anchor-config-title"}
  })

  frame.force_auto_center()
  add_category_tabs(frame, category_name)
  add_resource_grid(frame, category, anchor, managed_lines, planet_name, player, tier_level)

  if category.kind == "item" then
    add_tier_selector(frame, player, tier_level)
  end

  player.opened = frame
end

-- The configuration a player has open, with the line it is for.
local function get_open_config(player)
  local open_config = storage.anchor_config_open and storage.anchor_config_open[player.index]

  if not open_config then
    return nil
  end

  local managed_lines = managed_line_state.get(open_config.planet_name)

  if not managed_lines then
    return nil
  end

  for _, anchor in ipairs(managed_lines.anchors) do
    if anchor.position and square_layout.get_position_key(anchor.position) == open_config.position_key then
      return open_config, anchor, managed_lines
    end
  end

  return nil
end

local function get_rejection_message(reason)
  if reason == "fluid-gap-required" then
    return {"message.the-square-managed-line-fluid-gap-required"}
  end

  return {"message.the-square-managed-line-invalid-edge"}
end

-- Places (or reconfigures) the line on the open Anchor. Changing to a different kind
-- of line returns the previous line's item.
local function pick(player, open_config, anchor, managed_lines, flow, resource)
  local planet_name = open_config.planet_name
  local planet = planet_state.get(planet_name)
  local definition = planet_catalog.get_resource(planet_name, flow, resource)

  if not definition then
    player.print({"message.the-square-managed-line-invalid-configuration"})
    return
  end

  local ok, reason, side = anchor_placement.check(
    {kind = definition.kind, flow = flow},
    anchor.position,
    planet:get_square_size(),
    managed_lines,
    planet:get_square_position()
  )

  if not ok then
    player.print(get_rejection_message(reason))
    return
  end

  -- Fluid lines have no item tiers.
  local tier_level = definition.kind == "fluid" and 1 or open_config.tier_level
  local is_new_line = anchor.resource == nil
  local previous_item_name = not is_new_line and anchor.item_name or nil
  local next_item_name = managed_line_state.get_item_name(definition.kind, flow, tier_level)
  local is_line_type_change = previous_item_name ~= nil and previous_item_name ~= next_item_name

  if is_line_type_change and not player.can_insert({name = previous_item_name, count = 1}) then
    player.print({"message.the-square-managed-line-refund-inventory-full", {"item-name." .. previous_item_name}})
    return
  end

  if (is_new_line or is_line_type_change) and player.remove_item({name = next_item_name, count = 1}) < 1 then
    player.print({"message.the-square-managed-line-missing-inventory", {"item-name." .. next_item_name}})
    return
  end

  if is_new_line then
    -- Reuse a stashed line record, so a Planet's owned lines stay one record each.
    local stashed = managed_line_state.find_reusable_stashed_line(managed_lines, definition, flow, tier_level)

    if stashed and stashed ~= anchor then
      managed_line_state.remove(managed_lines, anchor)
      stashed.position = anchor.position
      stashed.side = side
      stashed.entity = nil
      anchor = stashed
    end
  end

  if is_line_type_change and player.insert({name = previous_item_name, count = 1}) < 1 then
    player.insert({name = next_item_name, count = 1})
    player.print({"message.the-square-managed-line-refund-inventory-full", {"item-name." .. previous_item_name}})
    return
  end

  if anchor.entity and anchor.entity.valid then
    anchor.entity.destroy({raise_destroy = false})
  end

  anchor.entity = nil
  managed_line_state.configure(anchor, definition, flow, side, tier_level)
  unlock_processing_technology(anchor, player)
  anchor_runtime.reconcile(planet_name)
  destroy_frame(player)
end

-- Returns true when the click belonged to this menu.
function anchor_config_gui.handle_click(player, element)
  local name = element.name
  local category_name = string.match(name, "^" .. CATEGORY_BUTTON_PREFIX .. "(.+)$")
  local tier_key = string.match(name, "^" .. TIER_BUTTON_PREFIX .. "(.+)$")
  local flow, resource = string.match(name, "^" .. PICK_BUTTON_PREFIX .. "(%w+)__(.+)$")

  if not (category_name or tier_key or flow) then
    return false
  end

  local open_config, anchor, managed_lines = get_open_config(player)

  if not open_config then
    return false
  end

  if category_name then
    if CATEGORIES[category_name] then
      open(player, anchor, open_config.planet_name, category_name, open_config.tier_level)
    end
  elseif tier_key then
    local tier = definitions.get_item_tier(tier_key)

    for _, researched_tier in ipairs(managed_line_tiers.get_researched_item_tiers(player.force)) do
      if researched_tier == tier then
        open(player, anchor, open_config.planet_name, open_config.category, tier.tier_level)
      end
    end
  else
    pick(player, open_config, anchor, managed_lines, flow, resource)
  end

  return true
end

function anchor_config_gui.handle_closed(player, element)
  if element.name ~= FRAME_NAME then
    return false
  end

  storage.anchor_config_open[player.index] = nil
  element.destroy()

  return true
end

-- Clicking an empty Anchor's slot marker (the build control).
function anchor_config_gui.handle_slot_click(player)
  local marker = player.selected

  if not (marker and marker.name == definitions.SLOT_PROXY_NAME) then
    return
  end

  local planet = planet_state.for_surface(player.surface)
  local managed_lines = planet and managed_line_state.get(planet:get_name())

  if not managed_lines then
    return
  end

  local position = square_layout.snap_to_tile(marker.position)
  local side = square_layout.get_anchor_side_for_position(planet:get_square_size(), position, planet:get_square_position())

  if not side then
    player.print({"message.the-square-managed-line-invalid-edge"})
    return
  end

  local anchor = managed_line_state.find_by_position(managed_lines, position)

  if not anchor then
    anchor = {side = side, position = position, item_progress = {0, 0}}
    managed_lines.anchors[#managed_lines.anchors + 1] = anchor
  end

  open(player, anchor, planet:get_name())
end

-- Opening a placed line's Anchor entity reopens its configuration.
function anchor_config_gui.handle_entity_opened(player, entity)
  local planet = planet_state.for_surface(entity.surface)
  local managed_lines = planet and managed_line_state.get(planet:get_name())
  local anchor = managed_lines and managed_line_state.find_by_entity(managed_lines, entity)

  if anchor and anchor.position then
    open(player, anchor, planet:get_name())
  end
end

return anchor_config_gui
