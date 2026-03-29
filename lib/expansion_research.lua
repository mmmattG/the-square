local expansion_research = {}

expansion_research.MAX_LEVEL = 1000

local function round_up_to_nearest_10(value)
  return math.ceil(value / 10) * 10
end

function expansion_research.get_starting_square_size(current_square_size, completed_levels)
  return current_square_size - (completed_levels * 2)
end

function expansion_research.get_square_size_before_level(starting_square_size, level)
  return starting_square_size + ((level - 1) * 2)
end

function expansion_research.get_tiles_unlocked_for_level(starting_square_size, level)
  local square_size = expansion_research.get_square_size_before_level(starting_square_size, level)
  local next_square_size = square_size + 2

  return (next_square_size * next_square_size) - (square_size * square_size)
end

function expansion_research.get_research_unit_count(starting_square_size, tiles_per_research, level)
  local unlocked_tiles = expansion_research.get_tiles_unlocked_for_level(starting_square_size, level)
  local raw_count = unlocked_tiles / math.max(tiles_per_research, 1)

  if level == 1 then
    return 5
  end

  return math.max(10, round_up_to_nearest_10(raw_count))
end

function expansion_research.get_technology_name(level)
  return string.format("fes-square-expansion-%04d", level)
end

return expansion_research
