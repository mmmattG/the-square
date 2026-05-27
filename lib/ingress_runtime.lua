local item_ingress = require("lib.item_ingress")
local throughput_policy = require("lib.managed_line_throughput_policy")
local defs = require("lib.runtime_defs")
local planet_config = require("lib.planet_config")
local planet_instance = require("lib.planet_instance")

local ingress_runtime = {}

local function get_item_anchor_emissions(anchor, ingress_tier, elapsed_ticks)
  if not anchor then
    return {
      lane_emissions = {0, 0},
      carried_progress = {0, 0}
    }
  end

  local emission = item_ingress.compute_lane_emissions(
    ingress_tier.item_lane_counts or {0, 0},
    defs.ITEM_ANCHOR_INTERVAL_TICKS,
    anchor.item_progress or {0, 0},
    elapsed_ticks
  )

  anchor.item_progress = emission.carried_progress
  return emission
end

local function get_anchor_transport_line(entity, lane_index)
  if not (entity and entity.valid and entity.get_transport_line) then
    return nil
  end

  local ok, line = pcall(entity.get_transport_line, lane_index)

  if not ok then
    return nil
  end

  return line
end

local function pump_item_anchor(entity, resource, lane_index, item_count)
  if item_count <= 0 then
    return 0
  end

  local line = get_anchor_transport_line(entity, lane_index)

  if not line then
    return 0
  end

  local inserted = 0

  for _ = 1, item_count do
    if not line.can_insert_at_back() then
      return inserted
    end

    line.insert_at_back({name = resource, count = 1})
    inserted = inserted + 1
  end

  return inserted
end

local function drain_item_anchor(entity, resource, lane_index, item_count)
  if item_count <= 0 then
    return 0
  end

  local line = get_anchor_transport_line(entity, lane_index)

  if not line then
    return 0
  end

  local removed = line.remove_item({name = resource, count = item_count})
  return removed or 0
end

local function drain_fluid_anchor(entity, resource, amount)
  if not (entity and entity.valid) or amount <= 0 then
    return 0
  end

  if not entity.remove_fluid then
    return 0
  end

  local ok, removed = pcall(entity.remove_fluid, {
    name = resource,
    amount = amount
  })

  if not ok then
    return 0
  end

  return removed or 0
end

local function get_mining_productivity_bonus()
  local player_force = defs.get_player_force()

  if not (player_force and player_force.valid) then
    return 0
  end

  return player_force.mining_drill_productivity_bonus or 0
end

local function get_active_uranium_anchors(ingress_tier, starter_anchors)
  local anchors = {}

  if not starter_anchors then
    return anchors
  end

  for _, anchor in ipairs(starter_anchors.anchors) do
    local entity = anchor.position and anchor.entity or nil

    if anchor.flow == "ingress"
      and anchor.resource == "uranium-ore"
      and entity
      and entity.valid
    then
      local emission = get_item_anchor_emissions(anchor, defs.get_effective_ingress_tier_for_anchor(anchor), 1)
      local requested_count = (emission.lane_emissions[1] or 0) + (emission.lane_emissions[2] or 0)

      if requested_count > 0 then
        anchors[#anchors + 1] = {
          anchor = anchor,
          entity = entity,
          requested_emission = emission,
          capacity = requested_count
        }
      end
    end
  end

  return anchors
end

local function get_active_uranium_budget_per_interval(uranium_anchors, starter_anchors, bootstrap)
  if not bootstrap or not starter_anchors or #uranium_anchors == 0 then
    return 0
  end

  local mining_productivity_bonus = get_mining_productivity_bonus()
  local total_capacity = 0

  for _, uranium_anchor in ipairs(uranium_anchors) do
    total_capacity = total_capacity + uranium_anchor.capacity
  end

  if total_capacity <= 0 then
    return 0
  end

  local sulfuric_acid_needed = total_capacity / (
    throughput_policy.URANIUM_ORE_PER_SULFURIC_ACID * (1 + mining_productivity_bonus)
  )
  local sulfuric_acid_egressed = 0

  for _, anchor in ipairs(starter_anchors.anchors) do
    local entity = anchor.position and anchor.entity or nil

    if anchor.flow == "egress"
      and anchor.resource == "sulfuric-acid"
      and entity
      and entity.valid
    then
      local remaining_needed = sulfuric_acid_needed - sulfuric_acid_egressed

      if remaining_needed <= 0 then
        break
      end

      sulfuric_acid_egressed = sulfuric_acid_egressed + drain_fluid_anchor(
        entity,
        anchor.resource,
        math.min(defs.get_effective_ingress_tier_for_anchor(anchor).fluid_amount_per_interval, remaining_needed)
      )
    end
  end

  local budget = throughput_policy.compute_uranium_budget(
    sulfuric_acid_egressed,
    mining_productivity_bonus,
    bootstrap.uranium_ore_progress_carry or 0
  )

  bootstrap.uranium_ore_progress_carry = budget.remaining_ore_progress
  return budget.ore_budget
end

local function pump_uranium_ingress_anchor(entity, requested_emission, shared_budget)
  if shared_budget <= 0 then
    return 0
  end

  local lane_emissions = requested_emission and requested_emission.lane_emissions or {0, 0}
  local lane_one_target = math.min(shared_budget, lane_emissions[1] or 0)
  local inserted = pump_item_anchor(entity, "uranium-ore", 1, lane_one_target)
  local remaining_budget = shared_budget - inserted
  local lane_two_target = math.min(remaining_budget, lane_emissions[2] or 0)

  inserted = inserted + pump_item_anchor(entity, "uranium-ore", 2, lane_two_target)
  return inserted
end

local function drain_gleba_seed_budgets(starter_anchors, ingress_tier, planet_name)
  local budgets = {}

  if planet_name ~= "gleba" then
    return budgets
  end

  for _, anchor in ipairs(starter_anchors.anchors) do
    local entity = anchor.position and anchor.entity or nil
    local fruit = throughput_policy.get_gleba_fruit_for_seed_anchor(anchor)

    if fruit and anchor.flow == "egress" and anchor.kind == "item" and entity and entity.valid then
      local emission = get_item_anchor_emissions(anchor, defs.get_effective_ingress_tier_for_anchor(anchor), 1)
      local drained_seeds = drain_item_anchor(entity, anchor.resource, 1, emission.lane_emissions[1] or 0)
        + drain_item_anchor(entity, anchor.resource, 2, emission.lane_emissions[2] or 0)

      budgets[fruit] = (budgets[fruit] or 0) + drained_seeds * throughput_policy.GLEBA_FRUIT_PER_SEED
    end
  end

  return budgets
end

local function pump_anchor_set(starter_anchors, ingress_tier, uranium_context, planet_name)
  if not starter_anchors then
    return
  end

  local uranium_anchor_index = 1
  local gleba_fruit_budgets = drain_gleba_seed_budgets(starter_anchors, ingress_tier, planet_name)

  for _, anchor in ipairs(starter_anchors.anchors) do
    local entity = anchor.position and anchor.entity or nil

    if entity and entity.valid and anchor.resource then
      if anchor.flow == "ingress" then
        if anchor.kind == "item" then
          if uranium_context and anchor.resource == "uranium-ore" then
            local allocated_budget = uranium_context.allocations[uranium_anchor_index] or 0
            local uranium_anchor = uranium_context.anchors[uranium_anchor_index]

            pump_uranium_ingress_anchor(entity, uranium_anchor and uranium_anchor.requested_emission, allocated_budget)
            uranium_anchor_index = uranium_anchor_index + 1
          elseif throughput_policy.should_gate_gleba_fruit(planet_name, anchor) then
            local available = (anchor.gleba_fruit_budget or 0) + (gleba_fruit_budgets[anchor.resource] or 0)
            local emission = get_item_anchor_emissions(anchor, defs.get_effective_ingress_tier_for_anchor(anchor), 1)

            if available > 0 then
              local lane_one_inserted = pump_item_anchor(entity, anchor.resource, 1, math.min(emission.lane_emissions[1] or 0, available))
              available = available - lane_one_inserted
              local lane_two_inserted = pump_item_anchor(entity, anchor.resource, 2, math.min(emission.lane_emissions[2] or 0, available))
              available = available - lane_two_inserted
            end

            anchor.gleba_fruit_budget = available
          else
            local emission = get_item_anchor_emissions(anchor, defs.get_effective_ingress_tier_for_anchor(anchor), 1)

            pump_item_anchor(entity, anchor.resource, 1, emission.lane_emissions[1] or 0)
            pump_item_anchor(entity, anchor.resource, 2, emission.lane_emissions[2] or 0)
          end
        else
          if entity.insert_fluid then
            pcall(entity.insert_fluid, {
              name = anchor.resource,
              amount = defs.get_effective_ingress_tier_for_anchor(anchor).fluid_amount_per_interval
            })
          end
        end
      elseif anchor.flow == "egress" then
        if anchor.kind == "item" then
          if not throughput_policy.should_skip_regular_egress(planet_name, anchor, uranium_context) then
            local emission = get_item_anchor_emissions(anchor, defs.get_effective_ingress_tier_for_anchor(anchor), 1)

            drain_item_anchor(entity, anchor.resource, 1, emission.lane_emissions[1] or 0)
            drain_item_anchor(entity, anchor.resource, 2, emission.lane_emissions[2] or 0)
          end
        elseif not throughput_policy.should_skip_regular_egress(planet_name, anchor, uranium_context) then
          drain_fluid_anchor(entity, anchor.resource, defs.get_effective_ingress_tier_for_anchor(anchor).fluid_amount_per_interval)
        end
      end
    end
  end
end

local function get_uranium_context(ingress_tier, starter_anchors, bootstrap)
  local uranium_anchors = get_active_uranium_anchors(ingress_tier, starter_anchors)

  if #uranium_anchors == 0 then
    return nil
  end

  local uranium_budget = get_active_uranium_budget_per_interval(uranium_anchors, starter_anchors, bootstrap)
  local uranium_capacities = {}

  for index, uranium_anchor in ipairs(uranium_anchors) do
    uranium_capacities[index] = uranium_anchor.capacity
  end

  return {
    anchors = uranium_anchors,
    allocations = throughput_policy.allocate_shared_budget(uranium_budget, uranium_capacities)
  }
end

function ingress_runtime.pump_planet_anchors(planet_name)
  local planet = storage.planets and storage.planets[planet_name] and planet_instance.ensure(planet_name) or nil
  local starter_anchors = planet and planet:get_bootstrap_storage().starter_anchors or nil

  if not starter_anchors then
    return
  end

  local ingress_tier = defs.get_current_ingress_tier()
  pump_anchor_set(starter_anchors, ingress_tier, get_uranium_context(ingress_tier, starter_anchors, planet:get_bootstrap_storage()), planet_name)
end

function ingress_runtime.pump_starter_anchors()
  ingress_runtime.pump_planet_anchors("nauvis")
end

function ingress_runtime.pump_planet_starter_anchors()
  for _, planet_name in ipairs(planet_config.SUPPORTED_PLANETS) do
    ingress_runtime.pump_planet_anchors(planet_name)
  end
end

return ingress_runtime
