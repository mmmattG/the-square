-- Managed Line names, tiers and throughput, shared by the data stage (prototypes)
-- and the control stage (runtime) so the two can never drift apart.
-- Keep this module free of `game`, `defines` and `storage`.
local definitions = {}

definitions.KINDS = {"item", "fluid"}
definitions.FLOWS = {"ingress", "egress"}

definitions.SLOT_PROXY_NAME = "the-square-anchor-slot-proxy"
definitions.PLACE_INPUT_NAME = "the-square-place-managed-anchor"
definitions.OPEN_INPUT_NAME = "the-square-open-managed-anchor"
definitions.ANCHOR_FRAME_ITEM_NAME = "the-square-anchor-frame"

-- Item lanes advance one item per lane count every ITEM_INTERVAL_TICKS, so a
-- lane count of 1 matches one lane of a yellow belt.
definitions.ITEM_INTERVAL_TICKS = 8

-- Purchasable item Managed Line tiers. Fluid Managed Lines only come in yellow.
-- tier_level indexes THROUGHPUT_BY_TIER_LEVEL. Level 2 is not purchasable: it is
-- a yellow line after the dual-lane research.
definitions.ITEM_TIERS = {
  {
    key = "yellow",
    tier_level = 1,
    anchor_frames = 1,
    transport_belt = "transport-belt",
    underground_belt = "underground-belt",
    square_tint = {r = 1, g = 0.83, b = 0.22, a = 1}
  },
  {
    key = "red",
    tier_level = 3,
    anchor_frames = 5,
    previous_key = "yellow",
    transport_belt = "fast-transport-belt",
    underground_belt = "fast-underground-belt",
    square_tint = {r = 0.95, g = 0.12, b = 0.08, a = 1}
  },
  {
    key = "blue",
    tier_level = 4,
    anchor_frames = 10,
    previous_key = "red",
    transport_belt = "express-transport-belt",
    underground_belt = "express-underground-belt",
    square_tint = {r = 0.12, g = 0.42, b = 1, a = 1}
  },
  {
    key = "turbo",
    tier_level = 5,
    anchor_frames = 20,
    previous_key = "blue",
    transport_belt = "turbo-transport-belt",
    underground_belt = "turbo-underground-belt",
    space_age_only = true,
    square_tint = {r = 0.1, g = 0.9, b = 0.25, a = 1}
  }
}

-- Throughput of one Managed Line. The pump runs every tick: item lanes follow
-- ITEM_INTERVAL_TICKS, and fluid lines move up to fluid_amount_per_tick each tick.
definitions.THROUGHPUT_BY_TIER_LEVEL = {
  [1] = {item_lane_counts = {1, 0}, fluid_amount_per_tick = 160},
  [2] = {item_lane_counts = {1, 1}, fluid_amount_per_tick = 320},
  [3] = {item_lane_counts = {2, 2}, fluid_amount_per_tick = 640},
  [4] = {item_lane_counts = {3, 3}, fluid_amount_per_tick = 960},
  [5] = {item_lane_counts = {4, 4}, fluid_amount_per_tick = 1280}
}

-- Tier Upgrade research, in order. Each one copies the science cost of its
-- vanilla prerequisite. Researching it raises the force's tier to tier_level; every
-- upgrade after dual-lane also unlocks the recipes for its item tier.
-- The names predate egress lines and are kept so existing saves keep their research.
definitions.DUAL_LANE_TECHNOLOGY_NAME = "the-square-ingress-dual-lane"
definitions.UPGRADE_TECHNOLOGIES = {
  {
    name = definitions.DUAL_LANE_TECHNOLOGY_NAME,
    tier_level = 2,
    prerequisite = "logistics",
    belt_icon = "__base__/graphics/icons/transport-belt.png"
  },
  {
    name = "the-square-ingress-red",
    tier_level = 3,
    prerequisite = "logistics-2",
    unlocks_item_tier = "red",
    belt_icon = "__base__/graphics/icons/fast-transport-belt.png"
  },
  {
    name = "the-square-ingress-blue",
    tier_level = 4,
    prerequisite = "logistics-3",
    unlocks_item_tier = "blue",
    belt_icon = "__base__/graphics/icons/express-transport-belt.png"
  },
  {
    name = "the-square-egress-turbo",
    tier_level = 5,
    prerequisite = "turbo-transport-belt",
    unlocks_item_tier = "turbo",
    space_age_only = true,
    belt_icon = "__space-age__/graphics/icons/turbo-transport-belt.png"
  }
}

local item_tiers_by_key = {}
local item_tiers_by_level = {}

for _, tier in ipairs(definitions.ITEM_TIERS) do
  item_tiers_by_key[tier.key] = tier
  item_tiers_by_level[tier.tier_level] = tier
end

function definitions.get_item_tier(tier_key)
  return item_tiers_by_key[tier_key]
end

-- Tier levels without their own item tier (level 2) use the yellow item.
function definitions.get_item_tier_for_level(tier_level)
  return item_tiers_by_level[tier_level] or item_tiers_by_key.yellow
end

function definitions.get_throughput(tier_level)
  return definitions.THROUGHPUT_BY_TIER_LEVEL[tier_level] or definitions.THROUGHPUT_BY_TIER_LEVEL[1]
end

local function get_tier_suffix(kind, tier_key)
  if kind == "fluid" or tier_key == nil or tier_key == "yellow" then
    return ""
  end

  return "-" .. tier_key
end

-- The inventory item (and recipe) for a Managed Line, e.g. "the-square-item-ingress-anchor-red".
function definitions.get_item_name(kind, flow, tier_key)
  return "the-square-" .. kind .. "-" .. flow .. "-anchor" .. get_tier_suffix(kind, tier_key)
end

-- The entity placed in an Anchor, e.g. "the-square-item-ingress-managed-anchor-red".
function definitions.get_entity_name(kind, flow, tier_key)
  return "the-square-" .. kind .. "-" .. flow .. "-managed-anchor" .. get_tier_suffix(kind, tier_key)
end

-- Calls fn(kind, flow, tier) once for every Managed Line item that exists.
function definitions.each_line_item(fn)
  for _, tier in ipairs(definitions.ITEM_TIERS) do
    for _, kind in ipairs(definitions.KINDS) do
      for _, flow in ipairs(definitions.FLOWS) do
        if kind == "item" or tier.key == "yellow" then
          fn(kind, flow, tier)
        end
      end
    end
  end
end

local managed_entity_names = {[definitions.SLOT_PROXY_NAME] = true}

definitions.each_line_item(function(kind, flow, tier)
  managed_entity_names[definitions.get_entity_name(kind, flow, tier.key)] = true
end)

-- True for every entity this mod places in or around Anchors.
function definitions.is_managed_entity_name(entity_name)
  return managed_entity_names[entity_name] == true
end

return definitions
