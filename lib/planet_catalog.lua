-- Static Planet Config for every supported Planet: starting size, floor, native
-- resources, opt-in egress resources and starter content.
-- Pure data, shared by the data stage, the control stage and dev/asset-gallery.
local planet_catalog = {}

-- Resource fields:
--   unlocked_at_start  selectable in Anchor Slot Configuration from the start
--   unlock_technology  otherwise selectable once this technology is researched
local planets = {
  {
    name = "nauvis",
    label = "Nauvis",
    default_square_size = 7,
    native_free_resources = {
      {resource = "iron-ore", kind = "item", unlocked_at_start = true},
      {resource = "copper-ore", kind = "item", unlocked_at_start = true},
      {resource = "coal", kind = "item", unlocked_at_start = true},
      {resource = "stone", kind = "item", unlocked_at_start = true},
      {resource = "water", kind = "fluid", unlocked_at_start = true},
      {resource = "wood", kind = "item", unlocked_at_start = true},
      {resource = "crude-oil", kind = "fluid", unlock_technology = "oil-gathering"},
      {resource = "uranium-ore", kind = "item", unlock_technology = "uranium-mining"}
    },
    opt_in_egress_resources = {
      {resource = "sulfuric-acid", kind = "fluid", unlock_technology = "uranium-mining"}
    },
    -- Nauvis is the only Planet that starts with Managed Lines, as stashed items.
    initial_line_items = {
      {kind = "fluid", flow = "ingress"},
      {kind = "item", flow = "ingress"},
      {kind = "item", flow = "ingress"}
    }
  },
  {
    name = "vulcanus",
    label = "Vulcanus",
    default_square_size = 17,
    floor_tile_name = "volcanic-ash-soil",
    native_free_resources = {
      {resource = "coal", kind = "item", unlocked_at_start = true},
      {resource = "calcite", kind = "item", unlocked_at_start = true},
      {resource = "tungsten-ore", kind = "item", unlocked_at_start = true},
      {resource = "sulfuric-acid", kind = "fluid", unlocked_at_start = true},
      {resource = "lava", kind = "fluid", unlocked_at_start = true}
    },
    opt_in_egress_resources = {},
    starter_research = {"calcite-processing", "tungsten-carbide"},
    expansion_research = {
      science_pack = "metallurgic-science-pack",
      icon = "__space-age__/graphics/icons/metallurgic-science-pack.png",
      order = "c-a[planet-square-expansion]-a[vulcanus]"
    }
  },
  {
    name = "fulgora",
    label = "Fulgora",
    default_square_size = 17,
    floor_tile_name = "fulgoran-dust",
    native_free_resources = {
      {resource = "scrap", kind = "item", unlocked_at_start = true},
      {resource = "heavy-oil", kind = "fluid", unlocked_at_start = true}
    },
    opt_in_egress_resources = {},
    starter_research = {"recycling"},
    starter_entities = {
      {name = "recycler", position = {x = 0, y = 0}},
      {name = "lightning-rod", position = {x = -7, y = -7}},
      {name = "lightning-rod", position = {x = 7, y = -7}},
      {name = "lightning-rod", position = {x = -7, y = 7}},
      {name = "lightning-rod", position = {x = 7, y = 7}}
    },
    expansion_research = {
      science_pack = "electromagnetic-science-pack",
      icon = "__space-age__/graphics/icons/electromagnetic-science-pack.png",
      order = "c-a[planet-square-expansion]-b[fulgora]"
    }
  },
  {
    name = "gleba",
    label = "Gleba",
    default_square_size = 17,
    floor_tile_name = "lowland-cream-cauliflower",
    native_free_resources = {
      {resource = "stone", kind = "item", unlocked_at_start = true},
      {resource = "water", kind = "fluid", unlocked_at_start = true},
      {resource = "yumako", kind = "item", unlocked_at_start = true},
      {resource = "jellynut", kind = "item", unlocked_at_start = true}
    },
    opt_in_egress_resources = {
      {resource = "yumako-seed", kind = "item", unlocked_at_start = true},
      {resource = "jellynut-seed", kind = "item", unlocked_at_start = true}
    },
    starter_research = {"heating-tower", "agriculture", "jellynut", "yumako"},
    starter_entities = {
      {
        name = "steel-chest",
        position = {x = 0, y = 0},
        items = {{name = "yumako-seed", count = 50}, {name = "jellynut-seed", count = 50}}
      }
    },
    expansion_research = {
      science_pack = "agricultural-science-pack",
      icon = "__space-age__/graphics/icons/agricultural-science-pack.png",
      order = "c-a[planet-square-expansion]-c[gleba]"
    }
  },
  {
    name = "aquilo",
    label = "Aquilo",
    default_square_size = 17,
    floor_tile_name = "snow-flat",
    native_free_resources = {
      {resource = "crude-oil", kind = "fluid", unlocked_at_start = true},
      {resource = "ammoniacal-solution", kind = "fluid", unlocked_at_start = true},
      {resource = "fluorine", kind = "fluid", unlocked_at_start = true},
      {resource = "lithium-brine", kind = "fluid", unlocked_at_start = true}
    },
    opt_in_egress_resources = {},
    starter_research = {"lithium-processing"},
    expansion_research = {
      science_pack = "cryogenic-science-pack",
      icon = "__space-age__/graphics/icons/cryogenic-science-pack.png",
      order = "c-a[planet-square-expansion]-d[aquilo]"
    }
  }
}

local by_name = {}
planet_catalog.SUPPORTED_PLANETS = {}

for _, planet in ipairs(planets) do
  planet_catalog.SUPPORTED_PLANETS[#planet_catalog.SUPPORTED_PLANETS + 1] = planet.name
  by_name[planet.name] = planet
end

-- Treat the returned table as read-only.
function planet_catalog.get(planet_name)
  return by_name[planet_name]
end

function planet_catalog.is_supported(planet_name)
  return by_name[planet_name] ~= nil
end

-- Ingress lines draw from native free resources; egress lines from opt-in egress resources.
function planet_catalog.get_resources(planet_name, flow)
  local planet = by_name[planet_name]

  if not planet then
    return {}
  end

  return flow == "egress" and planet.opt_in_egress_resources or planet.native_free_resources
end

function planet_catalog.get_resource(planet_name, flow, resource)
  for _, definition in ipairs(planet_catalog.get_resources(planet_name, flow)) do
    if definition.resource == resource then
      return definition
    end
  end

  return nil
end

return planet_catalog
