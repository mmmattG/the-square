local expansion_research = {}

expansion_research.DEFAULT_STARTING_SQUARE_SIZE = 7
expansion_research.FINAL_FINITE_LEVEL = 40
expansion_research.INFINITE_START_LEVEL = 41

-- Science packs for Nauvis Square Expansion, in blocks of ten levels. The last band
-- covers the infinite research from INFINITE_START_LEVEL onward.
expansion_research.BANDS = {
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
    label = "Automation + logistic + chemical + production + utility science",
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
    label = "All science through space",
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

function expansion_research.get_band(level)
  local selected_band = expansion_research.BANDS[1]

  for _, band in ipairs(expansion_research.BANDS) do
    if level >= band.start_level then
      selected_band = band
    end
  end

  return selected_band
end

local function get_unlocked_tiles_for_level(starting_square_size, level)
  local square_size = expansion_research.get_square_size_before_level(starting_square_size, level)
  local next_square_size = square_size + 2

  return (next_square_size * next_square_size) - (square_size * square_size)
end

function expansion_research.get_starting_square_size(current_square_size, completed_levels)
  return current_square_size - (completed_levels * 2)
end

function expansion_research.get_square_size_before_level(starting_square_size, level)
  return starting_square_size + ((level - 1) * 2)
end

function expansion_research.get_tiles_unlocked_for_level(starting_square_size, level)
  return get_unlocked_tiles_for_level(starting_square_size, level)
end

function expansion_research.get_research_unit_count(starting_square_size, tiles_per_research, level)
  local unlocked_tiles = get_unlocked_tiles_for_level(starting_square_size, level)
  local raw_count = unlocked_tiles / math.max(tiles_per_research, 1)
  return math.max(1, raw_count)
end

function expansion_research.get_technology_name(level)
  return string.format("the-square-square-expansion-%04d", level)
end

function expansion_research.get_planet_technology_name(planet_name)
  return "the-square-" .. planet_name .. "-square-expansion"
end

function expansion_research.get_planet_from_technology_name(technology_name)
  return string.match(technology_name, "^the%-square%-(%a+)%-square%-expansion$")
end

function expansion_research.get_level_from_technology_name(technology_name)
  return tonumber(string.match(technology_name, "^the%-square%-square%-expansion%-(%d%d%d%d)$"))
end

-- The Planet whose Square a Square Expansion technology grows, or nil for other technologies.
function expansion_research.get_planet_for_technology_name(technology_name)
  if expansion_research.get_level_from_technology_name(technology_name) then
    return "nauvis"
  end

  return expansion_research.get_planet_from_technology_name(technology_name)
end

function expansion_research.get_infinite_research_unit_formula(starting_square_size, tiles_per_research)
  local safe_tiles_per_research = math.max(tiles_per_research, 1)
  local numerator_constant = (4 * starting_square_size) - 4

  return string.format(
    "max(1, ((8 * L) + %d) / %.10g)",
    numerator_constant,
    safe_tiles_per_research
  )
end

return expansion_research
