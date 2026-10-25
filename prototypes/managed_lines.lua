-- Managed Line items, recipes and Anchor entities, plus the Anchor slot machinery.
local definitions = require("lib.managed_line_definitions")

local SUBGROUP_ORDER = {
  item_ingress = "b[item-ingress-anchor]",
  item_egress = "c[item-egress-anchor]",
  fluid_ingress = "d[fluid-ingress-anchor]",
  fluid_egress = "e[fluid-egress-anchor]"
}

local FLUID_LINE_ICONS = {
  ingress = "__base__/graphics/icons/offshore-pump.png",
  egress = "__base__/graphics/icons/pipe-to-ground.png"
}

local function is_tier_available(tier)
  return not tier.space_age_only or mods["space-age"] ~= nil
end

local function build_anchor_frame_item()
  return {
    type = "item",
    name = definitions.ANCHOR_FRAME_ITEM_NAME,
    localised_description = {"item-description.the-square-anchor-frame"},
    icons = {
      {icon = "__base__/graphics/icons/steel-plate.png", icon_size = 64, scale = 0.75},
      {icon = "__base__/graphics/icons/iron-gear-wheel.png", icon_size = 64, scale = 0.28, shift = {-10, -10}},
      {icon = "__base__/graphics/icons/iron-gear-wheel.png", icon_size = 64, scale = 0.28, shift = {10, -10}},
      {icon = "__base__/graphics/icons/iron-gear-wheel.png", icon_size = 64, scale = 0.28, shift = {-10, 10}},
      {icon = "__base__/graphics/icons/iron-gear-wheel.png", icon_size = 64, scale = 0.28, shift = {10, 10}}
    },
    subgroup = "intermediate-product",
    order = "z[the-square]-a[anchor-frame]",
    stack_size = 50
  }
end

local function build_anchor_frame_recipe()
  return {
    type = "recipe",
    name = definitions.ANCHOR_FRAME_ITEM_NAME,
    enabled = true,
    energy_required = 10,
    ingredients = {
      {type = "item", name = "steel-plate", amount = 50},
      {type = "item", name = "electronic-circuit", amount = 50},
      {type = "item", name = "iron-gear-wheel", amount = 50}
    },
    results = {{type = "item", name = definitions.ANCHOR_FRAME_ITEM_NAME, amount = 1}}
  }
end

-- Item lines show their underground belt with a tier-coloured square; fluid lines
-- show their pump or pipe with the parametrise badge.
local function build_line_icons(kind, flow, tier)
  if kind == "fluid" then
    return {
      {icon = FLUID_LINE_ICONS[flow], icon_size = 64},
      {icon = "__core__/graphics/icons/parametrise.png", icon_size = 64, scale = 0.35, shift = {8, 8}}
    }
  end

  local belt_item = data.raw.item[tier.underground_belt]

  return {
    {icon = belt_item.icon, icon_size = belt_item.icon_size or 64},
    {icon = "__core__/graphics/white-square.png", icon_size = 10, scale = 2, shift = {12, 12}, tint = tier.square_tint}
  }
end

-- Players see Managed Lines as Ingress and Egress, named like Factorio's belts:
-- "Item Ingress", then "Fast Item Ingress" and so on. Item line descriptions name the
-- belt colour, so searching a menu for "red" still finds them.
local function get_line_localised_name(kind, flow, tier)
  local base_name = {"item-name." .. definitions.get_item_name(kind, flow)}

  if kind == "fluid" or tier.key == "yellow" then
    return base_name
  end

  return {"item-name.the-square-tiered-generic-anchor", {"the-square-managed-line-tier." .. tier.key}, base_name}
end

local function get_line_item_description(kind, flow, tier)
  local flow_description = {"item-description.the-square-" .. flow .. "-line"}

  if kind == "fluid" then
    return flow_description
  end

  return {"item-description.the-square-item-line", {"the-square-belt-colour." .. tier.key}, flow_description}
end

local function build_line_item(kind, flow, tier)
  local order = SUBGROUP_ORDER[kind .. "_" .. flow]

  return {
    type = "item",
    name = definitions.get_item_name(kind, flow, tier.key),
    localised_name = get_line_localised_name(kind, flow, tier),
    localised_description = get_line_item_description(kind, flow, tier),
    icons = build_line_icons(kind, flow, tier),
    subgroup = "energy-pipe-distribution",
    order = "z[the-square]-" .. (tier.key == "yellow" and order or order .. "-" .. tier.key),
    stack_size = 50
  }
end

local function item(name, amount)
  return {type = "item", name = name, amount = amount}
end

-- Yellow lines are built from parts; each higher item tier upgrades the tier below it.
local function get_line_ingredients(kind, flow, tier)
  if tier.previous_key then
    return {
      item(definitions.get_item_name(kind, flow, tier.previous_key), 1),
      item(definitions.ANCHOR_FRAME_ITEM_NAME, tier.anchor_frames),
      item(tier.transport_belt, 50),
      item(tier.underground_belt, 5)
    }
  end

  if kind == "item" then
    return {
      item(definitions.ANCHOR_FRAME_ITEM_NAME, tier.anchor_frames),
      item("transport-belt", 50),
      item("underground-belt", 5)
    }
  end

  return {
    item(definitions.ANCHOR_FRAME_ITEM_NAME, tier.anchor_frames),
    item("pipe", 50),
    flow == "ingress" and item("offshore-pump", 1) or item("pipe-to-ground", 1)
  }
end

local function build_line_recipe(kind, flow, tier)
  local name = definitions.get_item_name(kind, flow, tier.key)

  return {
    type = "recipe",
    name = name,
    -- Higher tiers are unlocked by their Managed Line Upgrade research.
    enabled = tier.key == "yellow",
    energy_required = 5,
    ingredients = get_line_ingredients(kind, flow, tier),
    results = {{type = "item", name = name, amount = 1}}
  }
end

-- Anchors sit on the out-of-map Boundary ring, and Fulgora's lightning must not destroy them.
local function allow_on_out_of_map_and_lightning(entity)
  if entity.collision_mask then
    entity.collision_mask.layers["ground_tile"] = nil
  end

  entity.tile_buildability_rules = nil
  entity.resistances = entity.resistances or {}

  for _, resistance in ipairs(entity.resistances) do
    if resistance.type == "electric" then
      resistance.percent = math.max(resistance.percent or 0, 100)
      return
    end
  end

  entity.resistances[#entity.resistances + 1] = {type = "electric", percent = 100}
end

-- Anchor entities are copies of vanilla entities: item lines are underground belts,
-- fluid ingress is an offshore pump and fluid egress is a pipe-to-ground.
local function get_anchor_source(kind, flow, tier)
  if kind == "item" then
    return data.raw["underground-belt"][tier.underground_belt], data.raw.item[tier.underground_belt].icon
  end

  if flow == "ingress" then
    return data.raw["offshore-pump"]["offshore-pump"], FLUID_LINE_ICONS.ingress
  end

  return data.raw["pipe-to-ground"]["pipe-to-ground"], FLUID_LINE_ICONS.egress
end

local function build_anchor_entity(kind, flow, tier)
  local source, icon = get_anchor_source(kind, flow, tier)
  local entity = table.deepcopy(source)
  local item_name = definitions.get_item_name(kind, flow, tier.key)

  entity.name = definitions.get_entity_name(kind, flow, tier.key)
  entity.localised_name = get_line_localised_name(kind, flow, tier)
  entity.localised_description = {"entity-description.the-square-" .. flow .. "-anchor"}
  entity.icon = icon
  entity.icon_size = 64
  entity.icons = nil
  entity.minable = {mining_time = 0.1, result = item_name}
  entity.placeable_by = {item = item_name, count = 1}
  entity.next_upgrade = nil
  allow_on_out_of_map_and_lightning(entity)

  return entity
end

-- An invisible, selectable marker on every empty Anchor. Clicking it opens
-- Anchor Slot Configuration.
local function build_anchor_slot_proxy()
  return {
    type = "simple-entity-with-owner",
    name = definitions.SLOT_PROXY_NAME,
    icon = "__base__/graphics/icons/info.png",
    icon_size = 64,
    flags = {
      "not-on-map",
      "placeable-off-grid",
      "not-blueprintable",
      "not-deconstructable",
      "not-flammable"
    },
    hidden_in_factoriopedia = true,
    selectable_in_game = true,
    collision_box = {{0, 0}, {0, 0}},
    collision_mask = {layers = {}},
    selection_box = {{-0.5, -0.5}, {0.5, 0.5}},
    max_health = 1,
    resistances = {{type = "electric", percent = 100}},
    render_layer = "object",
    picture = {
      filename = "__core__/graphics/empty.png",
      size = 1
    }
  }
end

-- Clicks on Anchors piggyback on the vanilla build and open-gui controls.
local function build_custom_input(name, linked_game_control)
  return {
    type = "custom-input",
    name = name,
    key_sequence = "",
    linked_game_control = linked_game_control,
    consuming = "none",
    include_selected_prototype = true
  }
end

local prototypes = {
  build_anchor_slot_proxy(),
  build_custom_input(definitions.PLACE_INPUT_NAME, "build"),
  build_custom_input(definitions.OPEN_INPUT_NAME, "open-gui"),
  build_anchor_frame_item(),
  build_anchor_frame_recipe()
}

definitions.each_line_item(function(kind, flow, tier)
  if is_tier_available(tier) then
    prototypes[#prototypes + 1] = build_line_item(kind, flow, tier)
    prototypes[#prototypes + 1] = build_line_recipe(kind, flow, tier)
    prototypes[#prototypes + 1] = build_anchor_entity(kind, flow, tier)
  end
end)

data:extend(prototypes)
