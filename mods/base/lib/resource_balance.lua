local resource_balance = {}

resource_balance.URANIUM_ORE_PER_SULFURIC_ACID = 1

local function floor_with_epsilon(value)
  return math.floor(value + 1e-9)
end

function resource_balance.compute_uranium_budget(sulfuric_acid_egressed, mining_productivity_bonus, carried_ore_progress)
  local acid_amount = sulfuric_acid_egressed or 0
  local productivity_bonus = mining_productivity_bonus or 0
  local carry = carried_ore_progress or 0
  local total_ore_progress = carry + (acid_amount * resource_balance.URANIUM_ORE_PER_SULFURIC_ACID * (1 + productivity_bonus))
  local ore_budget = floor_with_epsilon(total_ore_progress)

  return {
    ore_budget = ore_budget,
    remaining_ore_progress = total_ore_progress - ore_budget
  }
end

function resource_balance.allocate_shared_budget(total_budget, capacities)
  local remaining_budget = math.max(0, total_budget or 0)
  local allocations = {}

  for index, capacity in ipairs(capacities or {}) do
    local applied_capacity = math.max(0, capacity or 0)
    local allocation = math.min(applied_capacity, remaining_budget)

    allocations[index] = allocation
    remaining_budget = remaining_budget - allocation
  end

  return {
    allocations = allocations,
    remaining_budget = remaining_budget
  }
end

return resource_balance
