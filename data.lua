local ingress_resources = {
  {resource = "iron-ore", kind = "item", icon = "__base__/graphics/icons/iron-ore.png", order = "a[ingress]-a[iron-ore]"},
  {resource = "copper-ore", kind = "item", icon = "__base__/graphics/icons/copper-ore.png", order = "a[ingress]-b[copper-ore]"},
  {resource = "coal", kind = "item", icon = "__base__/graphics/icons/coal.png", order = "a[ingress]-c[coal]"},
  {resource = "stone", kind = "item", icon = "__base__/graphics/icons/stone.png", order = "a[ingress]-d[stone]"},
  {resource = "water", kind = "fluid", icon = "__base__/graphics/icons/fluid/water.png", order = "a[ingress]-e[water]"},
  {resource = "wood", kind = "item", icon = "__base__/graphics/icons/wood.png", order = "a[ingress]-f[wood]"},
  {resource = "crude-oil", kind = "fluid", icon = "__base__/graphics/icons/fluid/crude-oil.png", order = "a[ingress]-g[crude-oil]"},
  {resource = "uranium-ore", kind = "item", icon = "__base__/graphics/icons/uranium-ore.png", order = "a[ingress]-h[uranium-ore]"}
}

local item_ingress_belt_tiers = {
  {key = "yellow", prototype_name = "transport-belt"},
  {key = "red", prototype_name = "fast-transport-belt"},
  {key = "blue", prototype_name = "express-transport-belt"}
}

local function ingress_item_name(resource)
  return "fes-" .. resource .. "-ingress"
end

local function ingress_entity_name(resource, belt_tier_key)
  if not belt_tier_key or belt_tier_key == "yellow" then
    return "fes-" .. resource .. "-ingress-anchor"
  end

  return "fes-" .. resource .. "-ingress-anchor-" .. belt_tier_key
end

local function build_ingress_item(definition)
  return {
    type = "item",
    name = ingress_item_name(definition.resource),
    localised_description = {"item-description.fes-ingress-item"},
    icon = definition.icon,
    icon_size = 64,
    subgroup = definition.kind == "fluid" and "energy-pipe-distribution" or "belt",
    order = definition.order,
    stack_size = 50,
    place_result = ingress_entity_name(definition.resource, definition.kind == "item" and "yellow" or nil)
  }
end

local function build_ingress_entity(definition, belt_tier_key, belt_prototype_name)
  local source = definition.kind == "fluid"
    and table.deepcopy(data.raw.pipe.pipe)
    or table.deepcopy(data.raw["transport-belt"][belt_prototype_name or "transport-belt"])
  local item_name = ingress_item_name(definition.resource)

  source.name = ingress_entity_name(definition.resource, belt_tier_key)
  source.localised_description = {"entity-description.fes-ingress-anchor"}
  source.icon = definition.icon
  source.icon_size = 64
  source.minable = {mining_time = 0.1, result = item_name}
  source.placeable_by = {item = item_name, count = 1}
  source.next_upgrade = nil

  return source
end

local prototypes = {}

for _, definition in ipairs(ingress_resources) do
  prototypes[#prototypes + 1] = build_ingress_item(definition)

  if definition.kind == "item" then
    for _, belt_tier in ipairs(item_ingress_belt_tiers) do
      prototypes[#prototypes + 1] = build_ingress_entity(
        definition,
        belt_tier.key,
        belt_tier.prototype_name
      )
    end
  else
    prototypes[#prototypes + 1] = build_ingress_entity(definition)
  end
end

data:extend(prototypes)
