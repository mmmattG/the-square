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

local expansion_speed_research_bands = {
  {
    name = "fes-expansion-speed-1",
    localised_name = {"technology-name.fes-expansion-speed"},
    icon = "__base__/graphics/icons/lab.png",
    order = "c-a[expansion-speed]-a[automation]",
    count_formula = "50*(L)",
    start_level = 1,
    max_level = 5,
    ingredients = {
      {"automation-science-pack", 1}
    }
  },
  {
    name = "fes-expansion-speed-2",
    localised_name = {"technology-name.fes-expansion-speed"},
    icon = "__base__/graphics/icons/lab.png",
    order = "c-a[expansion-speed]-b[logistic]",
    count_formula = "75*(L-5)",
    start_level = 6,
    max_level = 10,
    prerequisites = {"fes-expansion-speed-1"},
    ingredients = {
      {"automation-science-pack", 1},
      {"logistic-science-pack", 1}
    }
  },
  {
    name = "fes-expansion-speed-3",
    localised_name = {"technology-name.fes-expansion-speed"},
    icon = "__base__/graphics/icons/lab.png",
    order = "c-a[expansion-speed]-c[chemical]",
    count_formula = "125*(L-10)",
    start_level = 11,
    max_level = 15,
    prerequisites = {"fes-expansion-speed-2"},
    ingredients = {
      {"automation-science-pack", 1},
      {"logistic-science-pack", 1},
      {"chemical-science-pack", 1}
    }
  },
  {
    name = "fes-expansion-speed-4",
    localised_name = {"technology-name.fes-expansion-speed"},
    icon = "__base__/graphics/icons/lab.png",
    order = "c-a[expansion-speed]-d[production-utility]",
    count_formula = "200*(L-15)",
    start_level = 16,
    max_level = 20,
    prerequisites = {"fes-expansion-speed-3"},
    ingredients = {
      {"automation-science-pack", 1},
      {"logistic-science-pack", 1},
      {"chemical-science-pack", 1},
      {"production-science-pack", 1},
      {"utility-science-pack", 1}
    }
  },
  {
    name = "fes-expansion-speed-5",
    localised_name = {"technology-name.fes-expansion-speed"},
    icon = "__base__/graphics/icons/lab.png",
    order = "c-a[expansion-speed]-e[space]",
    count_formula = "300*(L-20)",
    start_level = 21,
    max_level = "infinite",
    prerequisites = {"fes-expansion-speed-4"},
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

local dummy_research_definitions = {
  {
    name = "fes-dummy-research-red",
    icon = "__base__/graphics/icons/automation-science-pack.png",
    order = "c-b[dummy-research]-a[automation]",
    count_formula = "30*(L)",
    ingredients = {
      {"automation-science-pack", 1}
    }
  },
  {
    name = "fes-dummy-research-green",
    icon = "__base__/graphics/icons/logistic-science-pack.png",
    order = "c-b[dummy-research]-b[logistic]",
    count_formula = "45*(L)",
    ingredients = {
      {"automation-science-pack", 1},
      {"logistic-science-pack", 1}
    }
  },
  {
    name = "fes-dummy-research-blue",
    icon = "__base__/graphics/icons/chemical-science-pack.png",
    order = "c-b[dummy-research]-c[chemical]",
    count_formula = "75*(L)",
    ingredients = {
      {"automation-science-pack", 1},
      {"logistic-science-pack", 1},
      {"chemical-science-pack", 1}
    }
  },
  {
    name = "fes-dummy-research-production-utility",
    icon = "__base__/graphics/icons/production-science-pack.png",
    order = "c-b[dummy-research]-d[production-utility]",
    count_formula = "125*(L)",
    ingredients = {
      {"automation-science-pack", 1},
      {"logistic-science-pack", 1},
      {"chemical-science-pack", 1},
      {"production-science-pack", 1},
      {"utility-science-pack", 1}
    }
  },
  {
    name = "fes-dummy-research-space",
    icon = "__base__/graphics/icons/space-science-pack.png",
    order = "c-b[dummy-research]-e[space]",
    count_formula = "200*(L)",
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

local function build_expansion_speed_technology(definition)
  return {
    type = "technology",
    name = definition.name,
    localised_name = definition.localised_name,
    localised_description = {"technology-description.fes-expansion-speed"},
    icon = definition.icon,
    icon_size = 64,
    order = definition.order,
    upgrade = true,
    max_level = definition.max_level,
    level = definition.start_level,
    prerequisites = definition.prerequisites,
    unit = {
      count_formula = definition.count_formula,
      ingredients = definition.ingredients,
      time = 30
    },
    effects = {
      {
        type = "nothing",
        effect_description = {"technology-effect.fes-expansion-speed"}
      }
    }
  }
end

local function build_dummy_research(definition)
  return {
    type = "technology",
    name = definition.name,
    localised_description = {"technology-description." .. definition.name},
    icon = definition.icon,
    icon_size = 64,
    order = definition.order,
    max_level = "infinite",
    unit = {
      count_formula = definition.count_formula,
      ingredients = definition.ingredients,
      time = 30
    },
    effects = {
      {
        type = "nothing",
        effect_description = {"technology-effect.fes-dummy-research"}
      }
    }
  }
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

for _, definition in ipairs(expansion_speed_research_bands) do
  prototypes[#prototypes + 1] = build_expansion_speed_technology(definition)
end

for _, definition in ipairs(dummy_research_definitions) do
  prototypes[#prototypes + 1] = build_dummy_research(definition)
end

data:extend(prototypes)
