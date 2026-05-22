local expansion_research = {}

expansion_research.DEFAULT_STARTING_SQUARE_SIZE = 7
expansion_research.FINAL_FINITE_LEVEL = 40
expansion_research.INFINITE_START_LEVEL = 41

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
  return string.match(technology_name or "", "^the%-square%-(%a+)%-square%-expansion$")
end

function expansion_research.get_level_from_technology_name(technology_name)
  return tonumber(string.match(technology_name or "", "^the%-square%-square%-expansion%-(%d%d%d%d)$"))
    or tonumber(string.match(technology_name or "", "^fes%-square%-expansion%-(%d%d%d%d)$"))
end

function expansion_research.is_expansion_technology_name(technology_name)
  return expansion_research.get_level_from_technology_name(technology_name) ~= nil
    or expansion_research.get_planet_from_technology_name(technology_name) ~= nil
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
