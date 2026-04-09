local expansion_research = require("lib.expansion_research")

local planet_catalog = {}

local ordered_planets = {
  {
    key = "nauvis",
    display_name = "Nauvis",
    surface_name = "nauvis",
    unlock_technology_name = nil,
    starting_square_size = expansion_research.DEFAULT_STARTING_SQUARE_SIZE,
    native_inputs = {"iron-ore", "copper-ore", "coal", "stone", "water", "wood", "crude-oil", "uranium-ore"},
    native_outputs = {"sulfuric-acid"},
    config = {
      square = {
        starting_size = expansion_research.DEFAULT_STARTING_SQUARE_SIZE
      },
      economy = {
        starting_expansion_points = 0
      },
      ingress = {
        inputs = {
          {resource = "iron-ore", kind = "item", starter_side = "north", prerequisite_resource = nil},
          {resource = "copper-ore", kind = "item", starter_side = "north", prerequisite_resource = nil},
          {resource = "coal", kind = "item", starter_side = "south", prerequisite_resource = nil},
          {resource = "stone", kind = "item", starter_side = "south", prerequisite_resource = nil},
          {resource = "water", kind = "fluid", starter_side = "west", prerequisite_resource = nil},
          {resource = "wood", kind = "item", starter_side = "east", prerequisite_resource = nil},
          {
            resource = "crude-oil",
            kind = "fluid",
            starter_side = nil,
            prerequisite_resource = nil,
            trigger_technologies = {"oil-processing"}
          },
          {
            resource = "uranium-ore",
            kind = "item",
            starter_side = nil,
            prerequisite_resource = "crude-oil",
            trigger_technologies = {"uranium-processing"}
          }
        },
        outputs = {
          {resource = "sulfuric-acid", kind = "fluid", starter_side = nil, prerequisite_resource = "uranium-ore"}
        }
      },
      research = {
        expansion_bands = {
          {
            start_level = 1,
            label = "Automation science",
            ingredients = {
              {"automation-science-pack", 1}
            }
          },
          {
            start_level = 11,
            label = "Automation + logistic science",
            ingredients = {
              {"automation-science-pack", 1},
              {"logistic-science-pack", 1}
            }
          },
          {
            start_level = 21,
            label = "Automation + logistic + chemical science",
            ingredients = {
              {"automation-science-pack", 1},
              {"logistic-science-pack", 1},
              {"chemical-science-pack", 1}
            }
          },
          {
            start_level = 31,
            label = "Automation + logistic + chemical + space science",
            ingredients = {
              {"automation-science-pack", 1},
              {"logistic-science-pack", 1},
              {"chemical-science-pack", 1},
              {"space-science-pack", 1}
            }
          },
          {
            start_level = 41,
            label = "Automation + logistic + chemical + space + production + utility science",
            ingredients = {
              {"automation-science-pack", 1},
              {"logistic-science-pack", 1},
              {"chemical-science-pack", 1},
              {"space-science-pack", 1},
              {"production-science-pack", 1},
              {"utility-science-pack", 1}
            }
          }
        }
      }
    },
    expansion_research_bands = {
      {
        start_level = 1,
        label = "Automation science",
        ingredients = {
          {"automation-science-pack", 1}
        }
      },
      {
        start_level = 11,
        label = "Automation + logistic science",
        ingredients = {
          {"automation-science-pack", 1},
          {"logistic-science-pack", 1}
        }
      },
      {
        start_level = 21,
        label = "Automation + logistic + chemical science",
        ingredients = {
          {"automation-science-pack", 1},
          {"logistic-science-pack", 1},
          {"chemical-science-pack", 1}
        }
      },
      {
        start_level = 31,
        label = "Automation + logistic + chemical + space science",
        ingredients = {
          {"automation-science-pack", 1},
          {"logistic-science-pack", 1},
          {"chemical-science-pack", 1},
          {"space-science-pack", 1}
        }
      },
      {
        start_level = 41,
        label = "Automation + logistic + chemical + space + production + utility science",
        ingredients = {
          {"automation-science-pack", 1},
          {"logistic-science-pack", 1},
          {"chemical-science-pack", 1},
          {"space-science-pack", 1},
          {"production-science-pack", 1},
          {"utility-science-pack", 1}
        }
      }
    }
  },
  {
    key = "vulcanus",
    display_name = "Vulcanus",
    surface_name = "vulcanus",
    unlock_technology_name = "planet-discovery-vulcanus",
    starting_square_size = expansion_research.DEFAULT_STARTING_SQUARE_SIZE,
    native_inputs = {},
    native_outputs = {},
    config = {
      square = {
        starting_size = expansion_research.DEFAULT_STARTING_SQUARE_SIZE
      },
      economy = {
        starting_expansion_points = 0
      },
      ingress = {
        inputs = {},
        outputs = {}
      },
      research = {
        expansion_bands = {
          {
            start_level = 1,
            label = "Metallurgic science",
            ingredients = {
              {"metallurgic-science-pack", 1}
            }
          }
        }
      }
    },
    expansion_research_bands = {
      {
        start_level = 1,
        label = "Metallurgic science",
        ingredients = {
          {"metallurgic-science-pack", 1}
        }
      }
    }
  },
  {
    key = "fulgora",
    display_name = "Fulgora",
    surface_name = "fulgora",
    unlock_technology_name = "planet-discovery-fulgora",
    starting_square_size = expansion_research.DEFAULT_STARTING_SQUARE_SIZE,
    native_inputs = {},
    native_outputs = {},
    config = {
      square = {
        starting_size = expansion_research.DEFAULT_STARTING_SQUARE_SIZE
      },
      economy = {
        starting_expansion_points = 0
      },
      ingress = {
        inputs = {},
        outputs = {}
      },
      research = {
        expansion_bands = {
          {
            start_level = 1,
            label = "Electromagnetic science",
            ingredients = {
              {"electromagnetic-science-pack", 1}
            }
          }
        }
      }
    },
    expansion_research_bands = {
      {
        start_level = 1,
        label = "Electromagnetic science",
        ingredients = {
          {"electromagnetic-science-pack", 1}
        }
      }
    }
  },
  {
    key = "gleba",
    display_name = "Gleba",
    surface_name = "gleba",
    unlock_technology_name = "planet-discovery-gleba",
    starting_square_size = expansion_research.DEFAULT_STARTING_SQUARE_SIZE,
    native_inputs = {},
    native_outputs = {},
    config = {
      square = {
        starting_size = expansion_research.DEFAULT_STARTING_SQUARE_SIZE
      },
      economy = {
        starting_expansion_points = 0
      },
      ingress = {
        inputs = {},
        outputs = {}
      },
      research = {
        expansion_bands = {
          {
            start_level = 1,
            label = "Agricultural science",
            ingredients = {
              {"agricultural-science-pack", 1}
            }
          }
        }
      }
    },
    expansion_research_bands = {
      {
        start_level = 1,
        label = "Agricultural science",
        ingredients = {
          {"agricultural-science-pack", 1}
        }
      }
    }
  },
  {
    key = "aquilo",
    display_name = "Aquilo",
    surface_name = "aquilo",
    unlock_technology_name = "planet-discovery-aquilo",
    starting_square_size = expansion_research.DEFAULT_STARTING_SQUARE_SIZE,
    native_inputs = {},
    native_outputs = {},
    config = {
      square = {
        starting_size = expansion_research.DEFAULT_STARTING_SQUARE_SIZE
      },
      economy = {
        starting_expansion_points = 0
      },
      ingress = {
        inputs = {},
        outputs = {}
      },
      research = {
        expansion_bands = {
          {
            start_level = 1,
            label = "Cryogenic science",
            ingredients = {
              {"cryogenic-science-pack", 1}
            }
          }
        }
      }
    },
    expansion_research_bands = {
      {
        start_level = 1,
        label = "Cryogenic science",
        ingredients = {
          {"cryogenic-science-pack", 1}
        }
      }
    }
  }
}

local planets_by_key = {}
local planets_by_surface_name = {}

for index, definition in ipairs(ordered_planets) do
  definition.order = index
  planets_by_key[definition.key] = definition
  planets_by_surface_name[definition.surface_name] = definition
end

function planet_catalog.get_all()
  return ordered_planets
end

function planet_catalog.get_planet(planet_key)
  return planets_by_key[planet_key]
end

function planet_catalog.get_planet_for_surface(surface_name)
  return planets_by_surface_name[surface_name]
end

function planet_catalog.get_starting_planet()
  return ordered_planets[1]
end

function planet_catalog.get_config(planet_key)
  local definition = planet_catalog.get_planet(planet_key)
  return definition and definition.config or nil
end

function planet_catalog.get_input_definitions(planet_key)
  local config = planet_catalog.get_config(planet_key)
  return config and config.ingress and config.ingress.inputs or {}
end

function planet_catalog.get_output_definitions(planet_key)
  local config = planet_catalog.get_config(planet_key)
  return config and config.ingress and config.ingress.outputs or {}
end

function planet_catalog.get_expansion_research_band(planet_key, level)
  local definition = planet_catalog.get_planet(planet_key)
  local bands = definition and definition.config and definition.config.research and definition.config.research.expansion_bands or nil
  local selected_band = bands and bands[1] or nil

  if not selected_band then
    error("Missing expansion research bands for planet " .. tostring(planet_key))
  end

  for _, band in ipairs(bands) do
    if level >= band.start_level then
      selected_band = band
    else
      break
    end
  end

  return selected_band
end

return planet_catalog
