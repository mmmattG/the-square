local expansion_research = require("lib.expansion_research")

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

local egress_resources = {
  {resource = "sulfuric-acid", kind = "fluid", icon = "__base__/graphics/icons/fluid/sulfuric-acid.png", order = "b[egress]-a[sulfuric-acid]"}
}

local item_ingress_belt_tiers = {
  {key = "yellow", prototype_name = "underground-belt"},
  {key = "red", prototype_name = "fast-underground-belt"},
  {key = "blue", prototype_name = "express-underground-belt"}
}

local square_expansion_research_bands = {
  {
    start_level = 1,
    ingredients = {
      {"automation-science-pack", 1}
    }
  },
  {
    start_level = 11,
    ingredients = {
      {"automation-science-pack", 1},
      {"logistic-science-pack", 1}
    }
  },
  {
    start_level = 21,
    ingredients = {
      {"automation-science-pack", 1},
      {"logistic-science-pack", 1},
      {"chemical-science-pack", 1}
    }
  },
  {
    start_level = 31,
    ingredients = {
      {"automation-science-pack", 1},
      {"logistic-science-pack", 1},
      {"chemical-science-pack", 1},
      {"production-science-pack", 1},
      {"utility-science-pack", 1}
    }
  },
  {
    start_level = 41,
    ingredients = {
      {"automation-science-pack", 1},
      {"logistic-science-pack", 1},
      {"chemical-science-pack", 1},
      {"production-science-pack", 1},
      {"utility-science-pack", 1},
      {"space-science-pack", 1}
    }
  }
}

local ingress_research_definitions = {
  {
    name = "the-square-ingress-dual-lane",
    icon = "__base__/graphics/icons/transport-belt.png",
    prerequisite_technology_name = "logistics",
    previous_ingress_technology_name = nil,
    localised_name = {"technology-name.the-square-ingress-dual-lane"},
    localised_description = {"technology-description.the-square-ingress-dual-lane"},
    effect_description = {"technology-effect.the-square-ingress-dual-lane"}
  },
  {
    name = "the-square-ingress-red",
    icon = "__base__/graphics/icons/fast-transport-belt.png",
    prerequisite_technology_name = "logistics-2",
    previous_ingress_technology_name = "the-square-ingress-dual-lane",
    localised_name = {"technology-name.the-square-ingress-red"},
    localised_description = {"technology-description.the-square-ingress-red"},
    effect_description = {"technology-effect.the-square-ingress-red"}
  },
  {
    name = "the-square-ingress-blue",
    icon = "__base__/graphics/icons/express-transport-belt.png",
    prerequisite_technology_name = "logistics-3",
    previous_ingress_technology_name = "the-square-ingress-red",
    localised_name = {"technology-name.the-square-ingress-blue"},
    localised_description = {"technology-description.the-square-ingress-blue"},
    effect_description = {"technology-effect.the-square-ingress-blue"}
  }
}

local tips_and_tricks_items = {
  {
    name = "the-square-mod",
    order = "a[mod]",
    category = "the-square-rules",
    icon = "__base__/graphics/icons/landfill.png",
    is_title = true
  },
  {
    name = "the-square-overview",
    order = "b[overview]",
    category = "the-square-rules",
    icon = "__base__/graphics/icons/info.png",
    indent = 1
  },
  {
    name = "the-square-expansion-research",
    order = "c[expansion-research]",
    category = "the-square-rules",
    icon = "__base__/graphics/icons/landfill.png",
    indent = 1
  },
  {
    name = "the-square-ingress-lines",
    order = "d[ingress-lines]",
    category = "the-square-rules",
    icon = "__base__/graphics/icons/transport-belt.png",
    indent = 1
  },
  {
    name = "the-square-uranium-egress",
    order = "e[uranium-egress]",
    category = "the-square-rules",
    icon = "__base__/graphics/icons/fluid/sulfuric-acid.png",
    indent = 1
  },
  {
    name = "the-square-research-and-rewards",
    order = "f[research-and-rewards]",
    category = "the-square-rules",
    icon = "__base__/graphics/icons/utility-science-pack.png",
    indent = 1
  },
  {
    name = "the-square-anchor-upgrades",
    order = "g[anchor-upgrades]",
    category = "the-square-rules",
    icon = "__base__/graphics/icons/fast-transport-belt.png",
    indent = 1
  },
  {
    name = "the-square-logistics-rule",
    order = "h[logistics-rule]",
    category = "the-square-rules",
    icon = "__base__/graphics/icons/logistic-robot.png",
    indent = 1
  }
}

local function ingress_item_name(resource)
  return "the-square-" .. resource .. "-ingress"
end

local function egress_item_name(resource)
  return "the-square-" .. resource .. "-egress"
end

local function ingress_entity_name(resource, belt_tier_key)
  if not belt_tier_key or belt_tier_key == "yellow" then
    return "the-square-" .. resource .. "-ingress-anchor"
  end

  return "the-square-" .. resource .. "-ingress-anchor-" .. belt_tier_key
end

local function egress_entity_name(resource)
  return "the-square-" .. resource .. "-egress-anchor"
end

local function build_ingress_item(definition)
  return {
    type = "item",
    name = ingress_item_name(definition.resource),
    localised_description = {"item-description.the-square-ingress-item"},
    icon = definition.icon,
    icon_size = 64,
    subgroup = definition.kind == "fluid" and "energy-pipe-distribution" or "belt",
    order = definition.order,
    stack_size = 50
  }
end

local function remove_collision_layers(collision_mask, layers_to_remove)
  if not collision_mask then
    return collision_mask
  end

  if collision_mask.layers then
    for layer_name in pairs(layers_to_remove) do
      collision_mask.layers[layer_name] = nil
    end

    return collision_mask
  end

  local filtered_mask = {}

  for _, layer_name in ipairs(collision_mask) do
    if not layers_to_remove[layer_name] then
      filtered_mask[#filtered_mask + 1] = layer_name
    end
  end

  return filtered_mask
end

local function allow_anchor_on_out_of_map(source)
  source.collision_mask = remove_collision_layers(source.collision_mask, {
    ["ground-tile"] = true,
    ground_tile = true
  })
  source.tile_buildability_rules = nil
end

local function build_ingress_entity(definition, belt_tier_key, belt_prototype_name)
  local source = definition.kind == "fluid"
    and table.deepcopy(data.raw["offshore-pump"]["offshore-pump"])
    or table.deepcopy(data.raw["underground-belt"][belt_prototype_name or "underground-belt"])
  local item_name = ingress_item_name(definition.resource)

  source.name = ingress_entity_name(definition.resource, belt_tier_key)
  source.localised_description = {"entity-description.the-square-ingress-anchor"}
  source.icon = definition.icon
  source.icon_size = 64
  source.minable = {mining_time = 0.1, result = item_name}
  source.placeable_by = {item = item_name, count = 1}
  source.next_upgrade = nil
  allow_anchor_on_out_of_map(source)

  return source
end

local function build_egress_item(definition)
  return {
    type = "item",
    name = egress_item_name(definition.resource),
    localised_description = {"item-description.the-square-egress-item"},
    icon = definition.icon,
    icon_size = 64,
    subgroup = "energy-pipe-distribution",
    order = definition.order,
    stack_size = 50
  }
end

local function build_anchor_slot_proxy()
  return {
    type = "simple-entity-with-owner",
    name = "the-square-anchor-slot-proxy",
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
    render_layer = "object",
    picture = {
      filename = "__core__/graphics/empty.png",
      size = 1
    }
  }
end

local function build_anchor_place_input()
  return {
    type = "custom-input",
    name = "the-square-place-managed-anchor",
    key_sequence = "",
    linked_game_control = "build",
    consuming = "none",
    include_selected_prototype = true
  }
end

local function build_egress_entity(definition)
  local source = table.deepcopy(data.raw["pipe-to-ground"]["pipe-to-ground"])
  local item_name = egress_item_name(definition.resource)

  source.name = egress_entity_name(definition.resource)
  source.localised_description = {"entity-description.the-square-egress-anchor"}
  source.icon = definition.icon
  source.icon_size = 64
  source.minable = {mining_time = 0.1, result = item_name}
  source.placeable_by = {item = item_name, count = 1}
  source.next_upgrade = nil
  allow_anchor_on_out_of_map(source)

  return source
end

local function build_square_expansion_technology(definition)
  local unit = {
    ingredients = definition.ingredients,
    time = 30
  }

  if definition.count_formula then
    unit.count_formula = definition.count_formula
  else
    unit.count = definition.count
  end

  return {
    type = "technology",
    name = definition.name,
    localised_name = {"technology-name.the-square-square-expansion"},
    localised_description = {"technology-description.the-square-square-expansion"},
    icon = "__base__/graphics/icons/landfill.png",
    icon_size = 64,
    order = definition.order,
    upgrade = true,
    prerequisites = definition.prerequisites,
    max_level = definition.max_level,
    unit = unit,
    effects = {
      {
        type = "nothing",
        effect_description = {"technology-effect.the-square-square-expansion"}
      }
    }
  }
end

local function copy_technology_unit(technology_name)
  local technology = data.raw.technology[technology_name]

  if not technology or not technology.unit then
    error("Missing technology unit for " .. technology_name)
  end

  return table.deepcopy(technology.unit)
end

local function build_ingress_research_technology(definition)
  local prerequisites = {definition.prerequisite_technology_name}

  if definition.previous_ingress_technology_name then
    prerequisites[#prerequisites + 1] = definition.previous_ingress_technology_name
  end

  return {
    type = "technology",
    name = definition.name,
    localised_name = definition.localised_name,
    localised_description = definition.localised_description,
    icon = definition.icon,
    icon_size = definition.icon_size or 64,
    order = "c-b[" .. definition.name .. "]",
    prerequisites = prerequisites,
    unit = copy_technology_unit(definition.prerequisite_technology_name),
    effects = {
      {
        type = "nothing",
        effect_description = definition.effect_description
      }
    }
  }
end

local function get_expansion_research_band(level)
  local selected_band = square_expansion_research_bands[1]

  for _, band in ipairs(square_expansion_research_bands) do
    if level >= band.start_level then
      selected_band = band
    else
      break
    end
  end

  return selected_band
end

local function build_tips_item(definition)
  return {
    type = "tips-and-tricks-item",
    name = definition.name,
    order = definition.order,
    category = definition.category,
    starting_status = "unlocked",
    indent = definition.indent,
    is_title = definition.is_title,
    localised_name = {"tips-and-tricks-item-name." .. definition.name},
    localised_description = {"tips-and-tricks-item-description." .. definition.name},
    icon = definition.icon,
    icon_size = definition.icon_size or 64,
    image = definition.image
  }
end

local prototypes = {}

prototypes[#prototypes + 1] = {
  type = "tips-and-tricks-item-category",
  name = "the-square-rules",
  order = "o[the-square]"
}

prototypes[#prototypes + 1] = build_anchor_slot_proxy()
prototypes[#prototypes + 1] = build_anchor_place_input()

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

for _, definition in ipairs(egress_resources) do
  prototypes[#prototypes + 1] = build_egress_item(definition)
  prototypes[#prototypes + 1] = build_egress_entity(definition)
end

local starting_square_size = expansion_research.DEFAULT_STARTING_SQUARE_SIZE
local tiles_per_research = settings.startup["the-square-expansion-tiles-per-research"].value

for level = 1, expansion_research.FINAL_FINITE_LEVEL do
  local band = get_expansion_research_band(level)

  prototypes[#prototypes + 1] = build_square_expansion_technology({
    name = expansion_research.get_technology_name(level),
    order = string.format("c-a[square-expansion]-%04d", level),
    prerequisites = level > 1 and {expansion_research.get_technology_name(level - 1)} or nil,
    ingredients = band.ingredients,
    count = expansion_research.get_research_unit_count(starting_square_size, tiles_per_research, level)
  })
end

prototypes[#prototypes + 1] = build_square_expansion_technology({
  name = expansion_research.get_technology_name(expansion_research.INFINITE_START_LEVEL),
  order = string.format("c-a[square-expansion]-%04d", expansion_research.INFINITE_START_LEVEL),
  prerequisites = {expansion_research.get_technology_name(expansion_research.INFINITE_START_LEVEL - 1)},
  ingredients = get_expansion_research_band(expansion_research.INFINITE_START_LEVEL).ingredients,
  count_formula = expansion_research.get_infinite_research_unit_formula(starting_square_size, tiles_per_research),
  max_level = "infinite"
})

for _, definition in ipairs(ingress_research_definitions) do
  prototypes[#prototypes + 1] = build_ingress_research_technology(definition)
end

for _, definition in ipairs(tips_and_tricks_items) do
  prototypes[#prototypes + 1] = build_tips_item(definition)
end

data:extend(prototypes)
