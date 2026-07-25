local resource_balance = require("lib.resource_balance")

local managed_line_throughput_policy = {}

managed_line_throughput_policy.URANIUM_ORE_PER_SULFURIC_ACID = resource_balance.URANIUM_ORE_PER_SULFURIC_ACID
managed_line_throughput_policy.URANIUM_SULFURIC_ACID_BUFFER_CAPACITY = 1000
managed_line_throughput_policy.GLEBA_FRUIT_PER_SEED = 50
managed_line_throughput_policy.GLEBA_SEED_BUFFER_CAPACITY = 20
managed_line_throughput_policy.gleba_seed_by_fruit = {
  yumako = "yumako-seed",
  jellynut = "jellynut-seed"
}

function managed_line_throughput_policy.should_gate_gleba_fruit(planet_name, anchor)
  return planet_name == "gleba"
    and anchor.flow == "ingress"
    and anchor.kind == "item"
    and managed_line_throughput_policy.gleba_seed_by_fruit[anchor.resource] ~= nil
end

function managed_line_throughput_policy.get_gleba_fruit_for_seed_anchor(anchor)
  if not (anchor and anchor.flow == "egress" and anchor.kind == "item") then
    return nil
  end

  if anchor.resource == "yumako-seed" then
    return "yumako"
  end

  if anchor.resource == "jellynut-seed" then
    return "jellynut"
  end

  return nil
end

function managed_line_throughput_policy.should_skip_regular_egress(planet_name, anchor, uranium_context)
  if anchor.resource == "sulfuric-acid" then
    return true
  end

  return planet_name == "gleba" and (
    anchor.resource == "yumako-seed" or anchor.resource == "jellynut-seed"
  )
end

function managed_line_throughput_policy.compute_uranium_budget(sulfuric_acid_egressed, mining_productivity_bonus, carry)
  return resource_balance.compute_uranium_budget(sulfuric_acid_egressed, mining_productivity_bonus, carry)
end

function managed_line_throughput_policy.allocate_shared_budget(budget, capacities)
  return resource_balance.allocate_shared_budget(budget, capacities).allocations
end

return managed_line_throughput_policy
