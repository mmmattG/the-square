local planet_catalog = {}

local planets = {
  {
    name = "nauvis",
    label = "Nauvis",
    default_square_size = 7,
    floor_tile_name = nil,
    native_free_resources = {
      {resource = "iron-ore", kind = "item", starter_side = "north", prerequisite_resource = nil},
      {resource = "copper-ore", kind = "item", starter_side = "north", prerequisite_resource = nil},
      {resource = "coal", kind = "item", starter_side = "south", prerequisite_resource = nil},
      {resource = "stone", kind = "item", starter_side = "south", prerequisite_resource = nil},
      {resource = "water", kind = "fluid", starter_side = "west", prerequisite_resource = nil},
      {resource = "wood", kind = "item", starter_side = "east", prerequisite_resource = nil},
      {resource = "crude-oil", kind = "fluid", starter_side = nil, prerequisite_resource = nil},
      {resource = "uranium-ore", kind = "item", starter_side = nil, prerequisite_resource = "crude-oil"}
    },
    opt_in_egress_resources = {
      {resource = "sulfuric-acid", kind = "fluid", starter_side = nil, prerequisite_resource = "uranium-ore"}
    }
  },
  {
    name = "vulcanus",
    label = "Vulcanus",
    default_square_size = 17,
    floor_tile_name = "volcanic-ash-soil",
    native_free_resources = {
      {resource = "coal", kind = "item", starter_side = "north", prerequisite_resource = nil},
      {resource = "calcite", kind = "item", starter_side = "east", prerequisite_resource = nil},
      {resource = "tungsten-ore", kind = "item", starter_side = "south", prerequisite_resource = nil},
      {resource = "sulfuric-acid", kind = "fluid", starter_side = "west", prerequisite_resource = nil},
      {resource = "lava", kind = "fluid", starter_side = "west", prerequisite_resource = nil}
    },
    opt_in_egress_resources = {},
    bootstrap_research = {"calcite-processing", "tungsten-carbide"}
  },
  {
    name = "fulgora",
    label = "Fulgora",
    default_square_size = 17,
    floor_tile_name = "fulgoran-dust",
    native_free_resources = {
      {resource = "scrap", kind = "item", starter_side = "north", prerequisite_resource = nil},
      {resource = "heavy-oil", kind = "fluid", starter_side = "west", prerequisite_resource = nil}
    },
    opt_in_egress_resources = {},
    bootstrap_research = {"recycling"},
    starter_entities = {
      {name = "recycler", position = {x = 0, y = 0}},
      {name = "lightning-rod", position = {x = -7, y = -7}},
      {name = "lightning-rod", position = {x = 7, y = -7}},
      {name = "lightning-rod", position = {x = -7, y = 7}},
      {name = "lightning-rod", position = {x = 7, y = 7}}
    }
  },
  {
    name = "gleba",
    label = "Gleba",
    default_square_size = 17,
    floor_tile_name = "lowland-cream-cauliflower",
    native_free_resources = {
      {resource = "stone", kind = "item", starter_side = "north", prerequisite_resource = nil},
      {resource = "water", kind = "fluid", starter_side = "west", prerequisite_resource = nil},
      {resource = "yumako", kind = "item", starter_side = "south", prerequisite_resource = nil},
      {resource = "jellynut", kind = "item", starter_side = "east", prerequisite_resource = nil}
    },
    opt_in_egress_resources = {
      {resource = "yumako-seed", kind = "item", starter_side = "south", prerequisite_resource = nil},
      {resource = "jellynut-seed", kind = "item", starter_side = "east", prerequisite_resource = nil}
    },
    bootstrap_research = {"heating-tower", "agriculture", "jellynut", "yumako"},
    starter_entities = {
      {name = "steel-chest", position = {x = 0, y = 0}, inventory = {articles = {{name = "yumako-seed", count = 50}, {name = "jellynut-seed", count = 50}}}}
    }
  },
  {
    name = "aquilo",
    label = "Aquilo",
    default_square_size = 17,
    floor_tile_name = "snow-flat",
    native_free_resources = {
      {resource = "crude-oil", kind = "fluid", starter_side = "north", prerequisite_resource = nil},
      {resource = "ammoniacal-solution", kind = "fluid", starter_side = "east", prerequisite_resource = nil},
      {resource = "fluorine", kind = "fluid", starter_side = "south", prerequisite_resource = nil},
      {resource = "lithium-brine", kind = "fluid", starter_side = "west", prerequisite_resource = nil}
    },
    opt_in_egress_resources = {},
    bootstrap_research = {"lithium-processing"}
  }
}

local by_name = {}
planet_catalog.SUPPORTED_PLANETS = {}

for _, planet in ipairs(planets) do
  planet_catalog.SUPPORTED_PLANETS[#planet_catalog.SUPPORTED_PLANETS + 1] = planet.name
  by_name[planet.name] = planet
end

local function copy_definition(definition)
  return {
    resource = definition.resource,
    kind = definition.kind,
    starter_side = definition.starter_side,
    prerequisite_resource = definition.prerequisite_resource
  }
end

local function copy_definitions(definitions)
  local result = {}

  for _, definition in ipairs(definitions or {}) do
    result[#result + 1] = copy_definition(definition)
  end

  return result
end

function planet_catalog.get(planet_name)
  return by_name[planet_name]
end

function planet_catalog.get_native_free_resources(planet_name)
  local planet = planet_catalog.get(planet_name)
  return planet and copy_definitions(planet.native_free_resources) or nil
end

function planet_catalog.get_opt_in_egress_resources(planet_name)
  local planet = planet_catalog.get(planet_name)
  return planet and copy_definitions(planet.opt_in_egress_resources) or nil
end

function planet_catalog.get_bootstrap_research(planet_name)
  local planet = planet_catalog.get(planet_name)
  local result = {}

  for _, technology_name in ipairs(planet and planet.bootstrap_research or {}) do
    result[#result + 1] = technology_name
  end

  return result
end

function planet_catalog.get_starter_entities(planet_name)
  local planet = planet_catalog.get(planet_name)
  local result = {}

  for _, entity in ipairs(planet and planet.starter_entities or {}) do
    result[#result + 1] = entity
  end

  return result
end

function planet_catalog.build_native_free_resources_by_planet()
  local result = {}

  for _, planet_name in ipairs(planet_catalog.SUPPORTED_PLANETS) do
    result[planet_name] = planet_catalog.get_native_free_resources(planet_name)
  end

  return result
end

function planet_catalog.build_opt_in_egress_resources_by_planet()
  local result = {}

  for _, planet_name in ipairs(planet_catalog.SUPPORTED_PLANETS) do
    result[planet_name] = planet_catalog.get_opt_in_egress_resources(planet_name)
  end

  return result
end

return planet_catalog
