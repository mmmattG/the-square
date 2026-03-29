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
  {key = "yellow", prototype_name = "transport-belt"},
  {key = "red", prototype_name = "fast-transport-belt"},
  {key = "blue", prototype_name = "express-transport-belt"}
}

local expansion_speed_research_bands = {
  {
    name = "fes-expansion-speed-automation",
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
    name = "fes-expansion-speed-logistic",
    localised_name = {"technology-name.fes-expansion-speed"},
    icon = "__base__/graphics/icons/lab.png",
    order = "c-a[expansion-speed]-b[logistic]",
    count_formula = "75*(L-5)",
    start_level = 6,
    max_level = 10,
    prerequisites = {"fes-expansion-speed-automation"},
    ingredients = {
      {"automation-science-pack", 1},
      {"logistic-science-pack", 1}
    }
  },
  {
    name = "fes-expansion-speed-chemical",
    localised_name = {"technology-name.fes-expansion-speed"},
    icon = "__base__/graphics/icons/lab.png",
    order = "c-a[expansion-speed]-c[chemical]",
    count_formula = "125*(L-10)",
    start_level = 11,
    max_level = 15,
    prerequisites = {"fes-expansion-speed-logistic"},
    ingredients = {
      {"automation-science-pack", 1},
      {"logistic-science-pack", 1},
      {"chemical-science-pack", 1}
    }
  },
  {
    name = "fes-expansion-speed-production-utility",
    localised_name = {"technology-name.fes-expansion-speed"},
    icon = "__base__/graphics/icons/lab.png",
    order = "c-a[expansion-speed]-d[production-utility]",
    count_formula = "200*(L-15)",
    start_level = 16,
    max_level = 20,
    prerequisites = {"fes-expansion-speed-chemical"},
    ingredients = {
      {"automation-science-pack", 1},
      {"logistic-science-pack", 1},
      {"chemical-science-pack", 1},
      {"production-science-pack", 1},
      {"utility-science-pack", 1}
    }
  },
  {
    name = "fes-expansion-speed-space",
    localised_name = {"technology-name.fes-expansion-speed"},
    icon = "__base__/graphics/icons/lab.png",
    order = "c-a[expansion-speed]-e[space]",
    count_formula = "300*(L-20)",
    start_level = 21,
    max_level = "infinite",
    prerequisites = {"fes-expansion-speed-production-utility"},
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

local tips_and_tricks_items = {
  {
    name = "fes-mod",
    order = "a[mod]",
    category = "fes-rules",
    icon = "__base__/graphics/icons/info.png",
    is_title = true
  },
  {
    name = "fes-overview",
    order = "b[overview]",
    category = "fes-rules",
    icon = "__base__/graphics/icons/info.png",
    indent = 1
  },
  {
    name = "fes-utilization-and-growth",
    order = "c[utilization-and-growth]",
    category = "fes-rules",
    icon = "__base__/graphics/icons/lab.png",
    indent = 1
  },
  {
    name = "fes-ingress-lines",
    order = "d[ingress-lines]",
    category = "fes-rules",
    icon = "__base__/graphics/icons/transport-belt.png",
    indent = 1
  },
  {
    name = "fes-uranium-egress",
    order = "e[uranium-egress]",
    category = "fes-rules",
    icon = "__base__/graphics/icons/fluid/sulfuric-acid.png",
    indent = 1
  },
  {
    name = "fes-research-and-rewards",
    order = "f[research-and-rewards]",
    category = "fes-rules",
    icon = "__base__/graphics/icons/utility-science-pack.png",
    indent = 1
  },
  {
    name = "fes-logistics-rule",
    order = "g[logistics-rule]",
    category = "fes-rules",
    icon = "__base__/graphics/icons/logistic-robot.png",
    indent = 1
  }
}

local function ingress_item_name(resource)
  return "fes-" .. resource .. "-ingress"
end

local function egress_item_name(resource)
  return "fes-" .. resource .. "-egress"
end

local function ingress_entity_name(resource, belt_tier_key)
  if not belt_tier_key or belt_tier_key == "yellow" then
    return "fes-" .. resource .. "-ingress-anchor"
  end

  return "fes-" .. resource .. "-ingress-anchor-" .. belt_tier_key
end

local function egress_entity_name(resource)
  return "fes-" .. resource .. "-egress-anchor"
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
  allow_anchor_on_out_of_map(source)

  return source
end

local function build_egress_item(definition)
  return {
    type = "item",
    name = egress_item_name(definition.resource),
    localised_description = {"item-description.fes-egress-item"},
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
    name = "fes-anchor-slot-proxy",
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
    selection_box = {{-0.45, -0.45}, {0.45, 0.45}},
    max_health = 1,
    render_layer = "object",
    picture = {
      filename = "__base__/graphics/icons/info.png",
      size = 64,
      scale = 0.35,
      tint = {r = 0.85, g = 0.85, b = 0.85, a = 0.35}
    }
  }
end

local function build_anchor_place_input()
  return {
    type = "custom-input",
    name = "fes-place-managed-anchor",
    key_sequence = "",
    linked_game_control = "build",
    consuming = "none",
    include_selected_prototype = true
  }
end

local function build_egress_entity(definition)
  local source = table.deepcopy(data.raw.pipe.pipe)
  local item_name = egress_item_name(definition.resource)

  source.name = egress_entity_name(definition.resource)
  source.localised_description = {"entity-description.fes-egress-anchor"}
  source.icon = definition.icon
  source.icon_size = 64
  source.minable = {mining_time = 0.1, result = item_name}
  source.placeable_by = {item = item_name, count = 1}
  source.next_upgrade = nil
  allow_anchor_on_out_of_map(source)

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
    icon_size = 64
  }
end

local prototypes = {}

prototypes[#prototypes + 1] = {
  type = "tips-and-tricks-item-category",
  name = "fes-rules",
  order = "o[factorio-expanding-square]"
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

for _, definition in ipairs(expansion_speed_research_bands) do
  prototypes[#prototypes + 1] = build_expansion_speed_technology(definition)
end

for _, definition in ipairs(dummy_research_definitions) do
  prototypes[#prototypes + 1] = build_dummy_research(definition)
end

for _, definition in ipairs(tips_and_tricks_items) do
  prototypes[#prototypes + 1] = build_tips_item(definition)
end

data:extend(prototypes)
