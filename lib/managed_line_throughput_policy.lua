-- Support Material Dependency rules: which Managed Lines run on a budget, and how
-- big those budgets are. Pure logic; the pump applies it.
local resource_balance = require("lib.resource_balance")

local managed_line_throughput_policy = {}

managed_line_throughput_policy.URANIUM_ORE_PER_SULFURIC_ACID = resource_balance.URANIUM_ORE_PER_SULFURIC_ACID
managed_line_throughput_policy.URANIUM_SULFURIC_ACID_BUFFER_CAPACITY = 1000
managed_line_throughput_policy.GLEBA_FRUIT_PER_SEED = 50
managed_line_throughput_policy.GLEBA_SEED_BUFFER_CAPACITY = 20

local GLEBA_SEED_BY_FRUIT = {
  yumako = "yumako-seed",
  jellynut = "jellynut-seed"
}

local GLEBA_FRUIT_BY_SEED = {}

for fruit, seed in pairs(GLEBA_SEED_BY_FRUIT) do
  GLEBA_FRUIT_BY_SEED[seed] = fruit
end

-- Gleba fruit ingress only runs while seed egress has paid for it.
function managed_line_throughput_policy.should_gate_gleba_fruit(planet_name, anchor)
  return planet_name == "gleba"
    and anchor.flow == "ingress"
    and anchor.kind == "item"
    and GLEBA_SEED_BY_FRUIT[anchor.resource] ~= nil
end

-- The fruit a seed egress line pays for, or nil.
function managed_line_throughput_policy.get_gleba_fruit_for_seed_anchor(anchor)
  if not (anchor.flow == "egress" and anchor.kind == "item") then
    return nil
  end

  return GLEBA_FRUIT_BY_SEED[anchor.resource]
end

-- Egress lines that feed a budget instead of simply venting their resource.
function managed_line_throughput_policy.is_support_material_egress(planet_name, anchor)
  if anchor.resource == "sulfuric-acid" then
    return true
  end

  return planet_name == "gleba" and GLEBA_FRUIT_BY_SEED[anchor.resource] ~= nil
end

function managed_line_throughput_policy.compute_uranium_budget(sulfuric_acid_egressed, mining_productivity_bonus, carry)
  return resource_balance.compute_uranium_budget(sulfuric_acid_egressed, mining_productivity_bonus, carry)
end

function managed_line_throughput_policy.allocate_shared_budget(budget, capacities)
  return resource_balance.allocate_shared_budget(budget, capacities).allocations
end

return managed_line_throughput_policy
