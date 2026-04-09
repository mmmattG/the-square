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

local function normalize_planet_and_level(planet_key, level)
  if level == nil then
    return "nauvis", planet_key
  end

  return planet_key, level
end

function expansion_research.get_technology_name(planet_key, level)
  local normalized_planet_key, normalized_level = normalize_planet_and_level(planet_key, level)
  return string.format("fes-square-expansion-%s-%04d", normalized_planet_key, normalized_level)
end

function expansion_research.get_definition_from_technology_name(technology_name)
  local planet_key, level = string.match(technology_name or "", "^fes%-square%-expansion%-([a-z0-9%-]+)%-(%d%d%d%d)$")

  if planet_key and level then
    return {
      planet_key = planet_key,
      level = tonumber(level)
    }
  end

  local legacy_level = tonumber(string.match(technology_name or "", "^fes%-square%-expansion%-(%d%d%d%d)$"))

  if legacy_level then
    return {
      planet_key = "nauvis",
      level = legacy_level
    }
  end

  return nil
end

function expansion_research.get_level_from_technology_name(technology_name)
  local definition = expansion_research.get_definition_from_technology_name(technology_name)
  return definition and definition.level or nil
end

function expansion_research.get_planet_key_from_technology_name(technology_name)
  local definition = expansion_research.get_definition_from_technology_name(technology_name)
  return definition and definition.planet_key or nil
end

function expansion_research.is_expansion_technology_name(technology_name)
  return expansion_research.get_definition_from_technology_name(technology_name) ~= nil
end

function expansion_research.get_infinite_research_unit_formula(starting_square_size, tiles_per_research)
  local safe_tiles_per_research = math.max(tiles_per_research, 1)
  local numerator_constant = (4 * starting_square_size) - 4

  return string.format(
    "max(1, ((8 * L) + %d) / %d)",
    numerator_constant,
    safe_tiles_per_research
  )
end

return expansion_research
