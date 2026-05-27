local expansion_research = require("lib.expansion_research")
local planet_config = require("lib.planet_config")

local function space_age_icon(path, fallback)
  if mods and mods["space-age"] then
    return "__space-age__/graphics/icons/" .. path
  end

  return fallback
end

local ingress_resources = {
  {resource = "iron-ore", kind = "item", icon = "__base__/graphics/icons/iron-ore.png", order = "a[ingress]-a[iron-ore]"},
  {resource = "copper-ore", kind = "item", icon = "__base__/graphics/icons/copper-ore.png", order = "a[ingress]-b[copper-ore]"},
  {resource = "coal", kind = "item", icon = "__base__/graphics/icons/coal.png", order = "a[ingress]-c[coal]"},
  {resource = "stone", kind = "item", icon = "__base__/graphics/icons/stone.png", order = "a[ingress]-d[stone]"},
  {resource = "water", kind = "fluid", icon = "__base__/graphics/icons/fluid/water.png", order = "a[ingress]-e[water]"},
  {resource = "wood", kind = "item", icon = "__base__/graphics/icons/wood.png", order = "a[ingress]-f[wood]"},
  {resource = "crude-oil", kind = "fluid", icon = "__base__/graphics/icons/fluid/crude-oil.png", order = "a[ingress]-g[crude-oil]"},
  {resource = "uranium-ore", kind = "item", icon = "__base__/graphics/icons/uranium-ore.png", order = "a[ingress]-h[uranium-ore]"},
  {resource = "calcite", kind = "item", icon = space_age_icon("calcite.png", "__base__/graphics/icons/stone.png"), order = "a[ingress]-i[calcite]"},
  {resource = "tungsten-ore", kind = "item", icon = space_age_icon("tungsten-ore.png", "__base__/graphics/icons/stone.png"), order = "a[ingress]-j[tungsten-ore]"},
  {resource = "sulfuric-acid", kind = "fluid", icon = "__base__/graphics/icons/fluid/sulfuric-acid.png", order = "a[ingress]-k[sulfuric-acid]"},
  {resource = "lava", kind = "fluid", icon = space_age_icon("fluid/lava.png", "__base__/graphics/icons/fluid/crude-oil.png"), order = "a[ingress]-l[lava]"},
  {resource = "scrap", kind = "item", icon = space_age_icon("scrap.png", "__base__/graphics/icons/iron-stick.png"), order = "a[ingress]-m[scrap]"},
  {resource = "heavy-oil", kind = "fluid", icon = "__base__/graphics/icons/fluid/heavy-oil.png", order = "a[ingress]-n[heavy-oil]"},
  {resource = "yumako", kind = "item", icon = space_age_icon("yumako.png", "__base__/graphics/icons/wood.png"), order = "a[ingress]-o[yumako]"},
  {resource = "jellynut", kind = "item", icon = space_age_icon("jellynut.png", "__base__/graphics/icons/wood.png"), order = "a[ingress]-p[jellynut]"},
  {resource = "ammoniacal-solution", kind = "fluid", icon = space_age_icon("fluid/ammoniacal-solution.png", "__base__/graphics/icons/fluid/water.png"), order = "a[ingress]-q[ammoniacal-solution]"},
  {resource = "fluorine", kind = "fluid", icon = space_age_icon("fluid/fluorine.png", "__base__/graphics/icons/fluid/water.png"), order = "a[ingress]-r[fluorine]"},
  {resource = "lithium-brine", kind = "fluid", icon = space_age_icon("fluid/lithium-brine.png", "__base__/graphics/icons/fluid/water.png"), order = "a[ingress]-s[lithium-brine]"}
}

local egress_resources = {
  {resource = "sulfuric-acid", kind = "fluid", icon = "__base__/graphics/icons/fluid/sulfuric-acid.png", order = "b[egress]-a[sulfuric-acid]"},
  {resource = "yumako-seed", kind = "item", icon = space_age_icon("yumako-seed.png", "__base__/graphics/icons/wood.png"), order = "b[egress]-b[yumako-seed]"},
  {resource = "jellynut-seed", kind = "item", icon = space_age_icon("jellynut-seed.png", "__base__/graphics/icons/wood.png"), order = "b[egress]-c[jellynut-seed]"}
}

local item_ingress_belt_tiers = {
  {key = "yellow", prototype_name = "underground-belt"},
  {key = "red", prototype_name = "fast-underground-belt"},
  {key = "blue", prototype_name = "express-underground-belt"}
}

local item_egress_belt_tiers = {
  {key = "yellow", prototype_name = "underground-belt"},
  {key = "red", prototype_name = "fast-underground-belt"},
  {key = "blue", prototype_name = "express-underground-belt"}
}

if mods and mods["space-age"] and data.raw["underground-belt"]["turbo-underground-belt"] then
  item_ingress_belt_tiers[#item_ingress_belt_tiers + 1] = {key = "turbo", prototype_name = "turbo-underground-belt"}
  item_egress_belt_tiers[#item_egress_belt_tiers + 1] = {key = "turbo", prototype_name = "turbo-underground-belt"}
end

local managed_line_item_tiers = {
  {key = "yellow", label = "Yellow", tier_level = 1, anchor_frames = 1, item_belt = "transport-belt", underground_belt = "underground-belt", square_tint = {r = 1, g = 0.83, b = 0.22, a = 1}},
  {key = "red", label = "Red", tier_level = 3, anchor_frames = 5, previous_key = "yellow", item_belt = "fast-transport-belt", underground_belt = "fast-underground-belt", prerequisite_technology = "the-square-ingress-red", square_tint = {r = 0.95, g = 0.12, b = 0.08, a = 1}},
  {key = "blue", label = "Blue", tier_level = 4, anchor_frames = 10, previous_key = "red", item_belt = "express-transport-belt", underground_belt = "express-underground-belt", prerequisite_technology = "the-square-ingress-blue", square_tint = {r = 0.12, g = 0.42, b = 1, a = 1}},
  {key = "turbo", label = "Green", tier_level = 5, anchor_frames = 20, previous_key = "blue", item_belt = "turbo-transport-belt", underground_belt = "turbo-underground-belt", prerequisite_technology = "the-square-egress-turbo", space_age_only = true, square_tint = {r = 0.1, g = 0.9, b = 0.25, a = 1}}
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

local planet_expansion_research_definitions = {
  vulcanus = {
    science_pack = "metallurgic-science-pack",
    icon = "__space-age__/graphics/icons/metallurgic-science-pack.png",
    prerequisite = "metallurgic-science-pack",
    order = "c-a[planet-square-expansion]-a[vulcanus]"
  },
  fulgora = {
    science_pack = "electromagnetic-science-pack",
    icon = "__space-age__/graphics/icons/electromagnetic-science-pack.png",
    prerequisite = "electromagnetic-science-pack",
    order = "c-a[planet-square-expansion]-b[fulgora]"
  },
  gleba = {
    science_pack = "agricultural-science-pack",
    icon = "__space-age__/graphics/icons/agricultural-science-pack.png",
    prerequisite = "agricultural-science-pack",
    order = "c-a[planet-square-expansion]-c[gleba]"
  },
  aquilo = {
    science_pack = "cryogenic-science-pack",
    icon = "__space-age__/graphics/icons/cryogenic-science-pack.png",
    prerequisite = "cryogenic-science-pack",
    order = "c-a[planet-square-expansion]-d[aquilo]"
  }
}

local function build_anchor_upgrade_icons(belt_icon)
  return {
    {icon = belt_icon, icon_size = 64, scale = 0.8, shift = {-8, 0}},
    {icon = "__base__/graphics/icons/underground-belt.png", icon_size = 64, scale = 0.45, shift = {14, -12}},
    {icon = "__base__/graphics/icons/underground-belt.png", icon_size = 64, scale = 0.45, shift = {14, 12}}
  }
end

local function get_managed_line_tier_recipe_names(tier_key)
  local names = {}

  for _, kind in ipairs({"item", "fluid"}) do
    for _, flow in ipairs({"ingress", "egress"}) do
      local base_name = "the-square-" .. kind .. "-" .. flow .. "-anchor"
      names[#names + 1] = tier_key == "yellow" and base_name or base_name .. "-" .. tier_key
    end
  end

  return names
end

local ingress_research_definitions = {
  {
    name = "the-square-ingress-dual-lane",
    icons = build_anchor_upgrade_icons("__base__/graphics/icons/transport-belt.png"),
    prerequisite_technology_name = "logistics",
    previous_ingress_technology_name = nil,
    localised_name = {"technology-name.the-square-ingress-dual-lane"},
    localised_description = {"technology-description.the-square-ingress-dual-lane"},
    effect_description = {"technology-effect.the-square-ingress-dual-lane"}
  },
  {
    name = "the-square-ingress-red",
    icons = build_anchor_upgrade_icons("__base__/graphics/icons/fast-transport-belt.png"),
    prerequisite_technology_name = "logistics-2",
    previous_ingress_technology_name = "the-square-ingress-dual-lane",
    localised_name = {"technology-name.the-square-ingress-red"},
    localised_description = {"technology-description.the-square-ingress-red"},
    effect_description = {"technology-effect.the-square-ingress-red"},
    unlock_recipes = get_managed_line_tier_recipe_names("red")
  },
  {
    name = "the-square-ingress-blue",
    icons = build_anchor_upgrade_icons("__base__/graphics/icons/express-transport-belt.png"),
    prerequisite_technology_name = "logistics-3",
    previous_ingress_technology_name = "the-square-ingress-red",
    localised_name = {"technology-name.the-square-ingress-blue"},
    localised_description = {"technology-description.the-square-ingress-blue"},
    effect_description = {"technology-effect.the-square-ingress-blue"},
    unlock_recipes = get_managed_line_tier_recipe_names("blue")
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

local function ingress_entity_name(resource, belt_tier_key)
  if not belt_tier_key or belt_tier_key == "yellow" then
    return "the-square-" .. resource .. "-ingress-anchor"
  end

  return "the-square-" .. resource .. "-ingress-anchor-" .. belt_tier_key
end

local function egress_entity_name(resource, belt_tier_key)
  if not belt_tier_key or belt_tier_key == "yellow" then
    return "the-square-" .. resource .. "-egress-anchor"
  end

  return "the-square-" .. resource .. "-egress-anchor-" .. belt_tier_key
end

local function generic_anchor_item_name(kind, flow)
  return "the-square-" .. kind .. "-" .. flow .. "-anchor"
end

local function generic_anchor_item_name_for_tier(kind, flow, tier)
  local base_name = generic_anchor_item_name(kind, flow)

  if not tier or tier.key == "yellow" then
    return base_name
  end

  return base_name .. "-" .. tier.key
end

local function generic_anchor_entity_name(kind, flow)
  return "the-square-generic-" .. kind .. "-" .. flow .. "-anchor"
end

local function build_anchor_frame_item()
  return {
    type = "item",
    name = "the-square-anchor-frame",
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

local function build_parameterised_anchor_icons(icon)
  return {
    {icon = icon, icon_size = 64},
    {icon = "__core__/graphics/icons/parametrise.png", icon_size = 64, scale = 0.35, shift = {8, 8}}
  }
end

local function build_tiered_managed_line_icons(tier, kind, flow, fallback_icon)
  local icon = fallback_icon
  local icon_size = 64

  if kind == "item" then
    local belt_item = data.raw.item[tier.underground_belt] or data.raw.item["underground-belt"]

    if belt_item then
      icon = belt_item.icon
      icon_size = belt_item.icon_size or 64
    end
  end

  return {
    {icon = icon, icon_size = icon_size},
    {
      icon = "__core__/graphics/white-square.png",
      icon_size = 10,
      scale = 2,
      shift = {12, 12},
      tint = tier.square_tint
    }
  }
end

local function build_generic_anchor_item(name, icon, order, place_result, tier, kind, flow)
  return {
    type = "item",
    name = name,
    localised_name = tier
      and {"item-name.the-square-tiered-generic-anchor", {"the-square-managed-line-tier." .. tier.key}, {"item-name." .. generic_anchor_item_name(kind, flow)}}
      or nil,
    localised_description = {"item-description.the-square-generic-anchor"},
    icons = build_tiered_managed_line_icons(tier, kind, flow, icon),
    subgroup = "energy-pipe-distribution",
    order = order,
    place_result = place_result,
    stack_size = 50
  }
end

local allow_anchor_on_out_of_map

local function build_generic_anchor_animation(anchor_source, kind, flow)
  if kind == "item" and anchor_source.structure then
    local direction_key = flow == "egress" and "direction_out" or "direction_in"
    local structure = anchor_source.structure[direction_key] or anchor_source.structure.direction_in

    if structure and structure.sheet then
      local sheet = table.deepcopy(structure.sheet)
      sheet.direction_count = sheet.direction_count or 4
      return sheet
    end
  end

  if kind == "fluid" and flow == "ingress" and anchor_source.graphics_set and anchor_source.graphics_set.animation then
    return table.deepcopy(anchor_source.graphics_set.animation)
  end

  return {
    layers = {
      {
        filename = anchor_source.icon,
        size = 64,
        scale = 0.5,
        shift = {0, 0}
      },
      {
        filename = "__core__/graphics/icons/parametrise.png",
        size = 64,
        scale = 0.175,
        shift = {0.125, 0.125}
      }
    }
  }
end

local function build_generic_anchor_entity(name, item_name, kind, flow)
  local anchor_source

  if kind == "fluid" and flow == "ingress" then
    anchor_source = table.deepcopy(data.raw["offshore-pump"]["offshore-pump"])
  elseif kind == "fluid" then
    anchor_source = table.deepcopy(data.raw["pipe-to-ground"]["pipe-to-ground"])
  else
    anchor_source = table.deepcopy(data.raw["underground-belt"]["underground-belt"])
  end

  local source = table.deepcopy(data.raw["assembling-machine"]["assembling-machine-1"])
  source.name = name
  source.localised_description = {"entity-description.the-square-generic-anchor"}
  source.icons = build_parameterised_anchor_icons(anchor_source.icon)
  source.icon = nil
  source.minable = {mining_time = 0.1, result = item_name}
  source.placeable_by = {item = item_name, count = 1}
  source.next_upgrade = nil
  source.crafting_categories = {"the-square-anchor-configuration"}
  source.crafting_speed = 1
  source.energy_source = {type = "void"}
  source.energy_usage = "1W"
  source.allowed_effects = {}
  source.module_slots = 0
  source.graphics_set = {
    animation = build_generic_anchor_animation(anchor_source, kind, flow)
  }
  source.collision_box = {{0, 0}, {0, 0}}
  source.selection_box = {{-0.5, -0.5}, {0.5, 0.5}}
  source.collision_mask = {layers = {}}
  source.tile_width = nil
  source.tile_height = nil
  allow_anchor_on_out_of_map(source)

  return source
end

local function build_recipe(name, result, ingredients, energy_required)
  return {
    type = "recipe",
    name = name,
    enabled = true,
    energy_required = energy_required or 1,
    ingredients = ingredients,
    results = {{type = "item", name = result, amount = 1}}
  }
end

local function is_managed_line_item_tier_available(tier)
  if not tier then
    return true
  end

  if tier.space_age_only and not (mods and mods["space-age"]) then
    return false
  end

  if tier.underground_belt and not data.raw["underground-belt"][tier.underground_belt] then
    return false
  end

  if tier.item_belt and not data.raw.item[tier.item_belt] then
    return false
  end

  return true
end

local function config_recipe_name(resource, flow)
  return "the-square-configure-" .. resource .. "-" .. flow
end

local function build_config_recipe(definition, flow, planet_name)
  return {
    type = "recipe",
    name = config_recipe_name(definition.resource, flow),
    localised_name = {"recipe-name.the-square-configure-anchor", {"the-square-resource-name." .. definition.resource}},
    icon = definition.icon,
    icon_size = 64,
    category = "the-square-anchor-configuration",
    enabled = true,
    hidden = false,
    hidden_in_factoriopedia = true,
    allow_productivity = false,
    allow_quality = false,
    energy_required = 1,
    ingredients = {},
    results = {},
    order = "z[the-square-configure]-" .. planet_name .. "-" .. flow .. "-" .. definition.resource
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

local function make_anchor_lightning_safe(source)
  source.resistances = source.resistances or {}

  for _, resistance in ipairs(source.resistances) do
    if resistance.type == "electric" then
      resistance.percent = math.max(resistance.percent or 0, 100)
      return
    end
  end

  source.resistances[#source.resistances + 1] = {type = "electric", percent = 100}
end

allow_anchor_on_out_of_map = function(source)
  source.collision_mask = remove_collision_layers(source.collision_mask, {
    ["ground-tile"] = true,
    ground_tile = true
  })
  source.tile_buildability_rules = nil
  make_anchor_lightning_safe(source)
end

local function build_ingress_entity(definition, belt_tier_key, belt_prototype_name)
  local source = definition.kind == "fluid"
    and table.deepcopy(data.raw["offshore-pump"]["offshore-pump"])
    or table.deepcopy(data.raw["underground-belt"][belt_prototype_name or "underground-belt"])
  local item_name = generic_anchor_item_name(definition.kind, "ingress")

  source.name = ingress_entity_name(definition.resource, belt_tier_key)
  source.localised_name = {"entity-name." .. generic_anchor_entity_name(definition.kind, "ingress")}
  source.localised_description = {"entity-description.the-square-ingress-anchor"}
  source.icon = definition.icon
  source.icon_size = 64
  source.minable = {mining_time = 0.1, result = generic_anchor_item_name(definition.kind, "ingress")}
  source.placeable_by = {item = item_name, count = 1}
  source.next_upgrade = nil
  allow_anchor_on_out_of_map(source)

  return source
end

local function anchor_config_proxy_name(kind, flow)
  return "the-square-anchor-config-proxy-" .. kind .. "-" .. flow
end

local function build_anchor_config_proxy(kind, flow)
  local source = table.deepcopy(data.raw["assembling-machine"]["assembling-machine-1"])
  source.name = anchor_config_proxy_name(kind, flow)
  source.localised_name = {"entity-name.the-square-generic-" .. kind .. "-" .. flow .. "-anchor"}
  source.localised_description = {"entity-description.the-square-generic-anchor"}
  source.icon = "__core__/graphics/icons/parametrise.png"
  source.icon_size = 64
  source.flags = {
    "not-on-map",
    "placeable-off-grid",
    "not-blueprintable",
    "not-deconstructable",
    "not-flammable"
  }
  source.minable = nil
  source.placeable_by = nil
  source.next_upgrade = nil
  source.crafting_categories = {"the-square-anchor-configuration"}
  source.crafting_speed = 1
  source.energy_source = {type = "void"}
  source.energy_usage = "1W"
  source.allowed_effects = {}
  source.module_slots = 0
  source.graphics_set = {
    animation = {
      filename = "__core__/graphics/empty.png",
      size = 1
    }
  }
  source.collision_box = {{0, 0}, {0, 0}}
  source.selection_box = {{-0.49, -0.49}, {0.49, 0.49}}
  source.collision_mask = {layers = {}}
  source.tile_width = nil
  source.tile_height = nil
  allow_anchor_on_out_of_map(source)

  return source
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
    resistances = {{type = "electric", percent = 100}},
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

local function build_anchor_open_input()
  return {
    type = "custom-input",
    name = "the-square-open-managed-anchor",
    key_sequence = "",
    linked_game_control = "open-gui",
    consuming = "none",
    include_selected_prototype = true
  }
end

local function build_egress_entity(definition, belt_tier_key, belt_prototype_name)
  local source = definition.kind == "item"
    and table.deepcopy(data.raw["underground-belt"][belt_prototype_name or "underground-belt"])
    or table.deepcopy(data.raw["pipe-to-ground"]["pipe-to-ground"])
  local item_name = generic_anchor_item_name(definition.kind, "egress")

  source.name = egress_entity_name(definition.resource, belt_tier_key)
  source.localised_name = {"entity-name." .. generic_anchor_entity_name(definition.kind, "egress")}
  source.localised_description = {"entity-description.the-square-egress-anchor"}
  source.icon = definition.icon
  source.icon_size = 64
  source.minable = {mining_time = 0.1, result = generic_anchor_item_name(definition.kind, "egress")}
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
    localised_name = definition.localised_name or {"technology-name.the-square-square-expansion"},
    localised_description = definition.localised_description or {"technology-description.the-square-square-expansion"},
    icon = definition.icon or "__base__/graphics/icons/landfill.png",
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

local function round_to_nearest_50(value)
  return math.max(50, math.floor((value + 25) / 50) * 50)
end

local function build_planet_expansion_technology(planet_name, definition)
  if not (data.raw.tool and data.raw.tool[definition.science_pack]) then
    return nil
  end

  local config = planet_config.get(planet_name)
  local starting_square_size = config.square_size
  local first_ring_tiles = expansion_research.get_tiles_unlocked_for_level(starting_square_size, 1)
  local approximate_first_cost = round_to_nearest_50(first_ring_tiles * 10)
  local formula_multiplier = math.max(1, math.floor((approximate_first_cost / first_ring_tiles) + 0.5))

  return build_square_expansion_technology({
    name = expansion_research.get_planet_technology_name(planet_name),
    localised_name = {"technology-name.the-square-planet-square-expansion", config.label},
    localised_description = {"technology-description.the-square-planet-square-expansion", config.label},
    icon = definition.icon,
    order = definition.order,
    prerequisites = data.raw.technology[definition.prerequisite] and {definition.prerequisite} or nil,
    ingredients = {{definition.science_pack, 1}},
    count_formula = expansion_research.get_infinite_research_unit_formula(starting_square_size, 1 / formula_multiplier),
    max_level = "infinite"
  })
end

local function build_ingress_research_technology(definition)
  local prerequisites = {definition.prerequisite_technology_name}

  if definition.previous_ingress_technology_name then
    prerequisites[#prerequisites + 1] = definition.previous_ingress_technology_name
  end

  local technology = {
    type = "technology",
    name = definition.name,
    localised_name = definition.localised_name,
    localised_description = definition.localised_description,
    icon = definition.icon,
    icons = definition.icons,
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

  if definition.unlock_recipes then
    for _, recipe_name in ipairs(definition.unlock_recipes) do
      technology.effects[#technology.effects + 1] = {
        type = "unlock-recipe",
        recipe = recipe_name
      }
    end
  end

  return technology
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

local function add_recipe_unlock_to_technology(technology_name, recipe_name)
  local technology = data.raw.technology[technology_name]

  if not technology or not data.raw.recipe[recipe_name] then
    return
  end

  technology.effects = technology.effects or {}
  for _, effect in ipairs(technology.effects) do
    if effect.type == "unlock-recipe" and effect.recipe == recipe_name then
      return
    end
  end

  technology.effects[#technology.effects + 1] = {
    type = "unlock-recipe",
    recipe = recipe_name
  }
end

local function add_resource_configuration_unlocks()
  add_recipe_unlock_to_technology("oil-processing", config_recipe_name("crude-oil", "ingress"))
  add_recipe_unlock_to_technology("uranium-mining", config_recipe_name("uranium-ore", "ingress"))
  add_recipe_unlock_to_technology("uranium-mining", config_recipe_name("sulfuric-acid", "ingress"))
  add_recipe_unlock_to_technology("uranium-mining", config_recipe_name("sulfuric-acid", "egress"))
end

local prototypes = {}

prototypes[#prototypes + 1] = {
  type = "tips-and-tricks-item-category",
  name = "the-square-rules",
  order = "o[the-square]"
}

prototypes[#prototypes + 1] = {
  type = "recipe-category",
  name = "the-square-anchor-configuration"
}

prototypes[#prototypes + 1] = build_anchor_config_proxy("item", "ingress")
prototypes[#prototypes + 1] = build_anchor_config_proxy("item", "egress")
prototypes[#prototypes + 1] = build_anchor_config_proxy("fluid", "ingress")
prototypes[#prototypes + 1] = build_anchor_config_proxy("fluid", "egress")
prototypes[#prototypes + 1] = build_anchor_slot_proxy()
prototypes[#prototypes + 1] = build_anchor_place_input()
prototypes[#prototypes + 1] = build_anchor_open_input()
prototypes[#prototypes + 1] = build_anchor_frame_item()
local generic_anchor_item_definitions = {
  {kind = "item", flow = "ingress", icon = "__base__/graphics/icons/underground-belt.png", order = "b[item-ingress-anchor]", place_result = "the-square-generic-item-ingress-anchor"},
  {kind = "item", flow = "egress", icon = "__base__/graphics/icons/underground-belt.png", order = "c[item-egress-anchor]", place_result = "the-square-generic-item-egress-anchor"},
  {kind = "fluid", flow = "ingress", icon = "__base__/graphics/icons/offshore-pump.png", order = "d[fluid-ingress-anchor]", place_result = "the-square-generic-fluid-ingress-anchor"},
  {kind = "fluid", flow = "egress", icon = "__base__/graphics/icons/pipe-to-ground.png", order = "e[fluid-egress-anchor]", place_result = "the-square-generic-fluid-egress-anchor"}
}

for _, tier in ipairs(managed_line_item_tiers) do
  if is_managed_line_item_tier_available(tier) then
    for _, definition in ipairs(generic_anchor_item_definitions) do
      local item_name = generic_anchor_item_name_for_tier(definition.kind, definition.flow, tier)
      local order_suffix = tier.key == "yellow" and definition.order or definition.order .. "-" .. tier.key

      prototypes[#prototypes + 1] = build_generic_anchor_item(
        item_name,
        definition.icon,
        "z[the-square]-" .. order_suffix,
        tier.key == "yellow" and definition.place_result or nil,
        tier,
        definition.kind,
        definition.flow
      )
    end
  end
end
prototypes[#prototypes + 1] = build_generic_anchor_entity("the-square-generic-item-ingress-anchor", "the-square-item-ingress-anchor", "item", "ingress")
prototypes[#prototypes + 1] = build_generic_anchor_entity("the-square-generic-item-egress-anchor", "the-square-item-egress-anchor", "item", "egress")
prototypes[#prototypes + 1] = build_generic_anchor_entity("the-square-generic-fluid-ingress-anchor", "the-square-fluid-ingress-anchor", "fluid", "ingress")
prototypes[#prototypes + 1] = build_generic_anchor_entity("the-square-generic-fluid-egress-anchor", "the-square-fluid-egress-anchor", "fluid", "egress")
prototypes[#prototypes + 1] = build_recipe("the-square-anchor-frame", "the-square-anchor-frame", {
  {type = "item", name = "steel-plate", amount = 50},
  {type = "item", name = "electronic-circuit", amount = 50},
  {type = "item", name = "iron-gear-wheel", amount = 50}
}, 10)
for _, tier in ipairs(managed_line_item_tiers) do
  if is_managed_line_item_tier_available(tier) then
    for _, definition in ipairs(generic_anchor_item_definitions) do
      local item_name = generic_anchor_item_name_for_tier(definition.kind, definition.flow, tier)
      local ingredients

      if tier.key == "yellow" then
        if definition.kind == "item" then
          ingredients = {
            {type = "item", name = "the-square-anchor-frame", amount = tier.anchor_frames},
            {type = "item", name = "transport-belt", amount = 50},
            {type = "item", name = "underground-belt", amount = 5}
          }
        elseif definition.flow == "ingress" then
          ingredients = {
            {type = "item", name = "the-square-anchor-frame", amount = tier.anchor_frames},
            {type = "item", name = "pipe", amount = 50},
            {type = "item", name = "offshore-pump", amount = 1}
          }
        else
          ingredients = {
            {type = "item", name = "the-square-anchor-frame", amount = tier.anchor_frames},
            {type = "item", name = "pipe", amount = 50},
            {type = "item", name = "pipe-to-ground", amount = 1}
          }
        end
      else
        ingredients = {
          {type = "item", name = generic_anchor_item_name_for_tier(definition.kind, definition.flow, {key = tier.previous_key}), amount = 1},
          {type = "item", name = "the-square-anchor-frame", amount = tier.anchor_frames}
        }

        ingredients[#ingredients + 1] = {type = "item", name = tier.item_belt, amount = 50}
        ingredients[#ingredients + 1] = {type = "item", name = tier.underground_belt, amount = 5}

        if definition.kind ~= "item" and definition.flow == "ingress" then
          ingredients[#ingredients + 1] = {type = "item", name = "pipe", amount = 50}
          ingredients[#ingredients + 1] = {type = "item", name = "pump", amount = 1}
        elseif definition.kind ~= "item" then
          ingredients[#ingredients + 1] = {type = "item", name = "pipe", amount = 50}
          ingredients[#ingredients + 1] = {type = "item", name = "pipe-to-ground", amount = 5}
        end
      end

      local recipe = build_recipe(item_name, item_name, ingredients, 5)
      recipe.enabled = tier.key == "yellow"
      prototypes[#prototypes + 1] = recipe
    end
  end
end

for _, definition in ipairs(ingress_resources) do
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
  if definition.kind == "item" then
    for _, belt_tier in ipairs(item_egress_belt_tiers) do
      prototypes[#prototypes + 1] = build_egress_entity(
        definition,
        belt_tier.key,
        belt_tier.prototype_name
      )
    end
  else
    prototypes[#prototypes + 1] = build_egress_entity(definition)
  end
end

for _, definition in ipairs(ingress_resources) do
  prototypes[#prototypes + 1] = build_config_recipe(definition, "ingress", "all")
end

for _, definition in ipairs(egress_resources) do
  prototypes[#prototypes + 1] = build_config_recipe(definition, "egress", "all")
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

for _, planet_name in ipairs(planet_config.SUPPORTED_PLANETS) do
  local definition = planet_expansion_research_definitions[planet_name]

  if definition then
    local technology = build_planet_expansion_technology(planet_name, definition)

    if technology then
      prototypes[#prototypes + 1] = technology
    end
  end
end

for _, definition in ipairs(ingress_research_definitions) do
  prototypes[#prototypes + 1] = build_ingress_research_technology(definition)
end

if mods and mods["space-age"] and data.raw.technology["turbo-transport-belt"] then
  prototypes[#prototypes + 1] = build_ingress_research_technology({
    name = "the-square-egress-turbo",
    icons = build_anchor_upgrade_icons("__space-age__/graphics/icons/turbo-transport-belt.png"),
    prerequisite_technology_name = "turbo-transport-belt",
    previous_ingress_technology_name = "the-square-ingress-blue",
    localised_name = {"technology-name.the-square-egress-turbo"},
    localised_description = {"technology-description.the-square-egress-turbo"},
    effect_description = {"technology-effect.the-square-egress-turbo"},
    unlock_recipes = get_managed_line_tier_recipe_names("turbo")
  })
end

for _, definition in ipairs(tips_and_tricks_items) do
  prototypes[#prototypes + 1] = build_tips_item(definition)
end

data:extend(prototypes)
add_resource_configuration_unlocks()
