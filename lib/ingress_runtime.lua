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

local function set_anchor_active(anchor, entity, active)
  if anchor then
    anchor.input_budget_active = active and true or false
  end

  if entity and entity.valid and entity.active ~= nil then
    entity.active = active and true or false
  end
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

local function can_insert_item_at_back(entity, lane_index)
  local line = get_anchor_transport_line(entity, lane_index)

  if not line or not line.can_insert_at_back then
    return false
  end

  local ok, can_insert = pcall(line.can_insert_at_back)

  return ok and can_insert == true
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

local function drain_uranium_acid_buffer(starter_anchors, bootstrap)
  if not (starter_anchors and bootstrap) then
    return 0
  end

  local buffer_capacity = throughput_policy.URANIUM_SULFURIC_ACID_BUFFER_CAPACITY
  local buffer = math.min(buffer_capacity, math.max(0, bootstrap.uranium_sulfuric_acid_buffer or 0))

  for _, anchor in ipairs(starter_anchors.anchors) do
    local entity = anchor.position and anchor.entity or nil

    if anchor.flow == "egress"
      and anchor.resource == "sulfuric-acid"
      and entity
      and entity.valid
    then
      local remaining_capacity = buffer_capacity - buffer

      if remaining_capacity <= 0 then
        break
      end

      buffer = buffer + drain_fluid_anchor(
        entity,
        anchor.resource,
        math.min(defs.get_effective_ingress_tier_for_anchor(anchor).fluid_amount_per_interval, remaining_capacity)
      )
    end
  end

  bootstrap.uranium_sulfuric_acid_buffer = buffer
  return buffer
end

local function get_uranium_anchors(ingress_tier, starter_anchors)
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
      local insertable_count = 0

      for lane_index = 1, 2 do
        local requested_count = emission.lane_emissions[lane_index] or 0

        if requested_count > 0 and can_insert_item_at_back(entity, lane_index) then
          insertable_count = insertable_count + requested_count
        end
      end

      anchors[#anchors + 1] = {
        anchor = anchor,
        entity = entity,
        requested_emission = emission,
        capacity = insertable_count
      }
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

  local available_acid = math.max(0, bootstrap.uranium_sulfuric_acid_buffer or 0)
  local sulfuric_acid_to_spend = math.min(available_acid, total_capacity / (
    throughput_policy.URANIUM_ORE_PER_SULFURIC_ACID * (1 + mining_productivity_bonus)
  ))

  local budget = throughput_policy.compute_uranium_budget(
    sulfuric_acid_to_spend,
    mining_productivity_bonus,
    bootstrap.uranium_ore_progress_carry or 0
  )

  bootstrap.uranium_sulfuric_acid_buffer = available_acid - sulfuric_acid_to_spend
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
  starter_anchors.gleba_fruit_budgets = starter_anchors.gleba_fruit_budgets or {}
  local budgets = starter_anchors.gleba_fruit_budgets

  if planet_name ~= "gleba" then
    return budgets
  end

  for _, anchor in ipairs(starter_anchors.anchors) do
    local entity = anchor.position and anchor.entity or nil
    local fruit = throughput_policy.get_gleba_fruit_for_seed_anchor(anchor)

    if fruit and anchor.flow == "egress" and anchor.kind == "item" and entity and entity.valid then
      local emission = get_item_anchor_emissions(anchor, defs.get_effective_ingress_tier_for_anchor(anchor), 1)
      local fruit_buffer_capacity = throughput_policy.GLEBA_SEED_BUFFER_CAPACITY * throughput_policy.GLEBA_FRUIT_PER_SEED
      local available_fruit_capacity = fruit_buffer_capacity - math.min(fruit_buffer_capacity, math.max(0, budgets[fruit] or 0))
      local seed_capacity = math.floor(available_fruit_capacity / throughput_policy.GLEBA_FRUIT_PER_SEED)
      local lane_one_target = math.min(emission.lane_emissions[1] or 0, seed_capacity)
      local drained_seeds = drain_item_anchor(entity, anchor.resource, 1, lane_one_target)
      local remaining_seed_capacity = seed_capacity - drained_seeds
      local lane_two_target = math.min(emission.lane_emissions[2] or 0, remaining_seed_capacity)

      drained_seeds = drained_seeds + drain_item_anchor(entity, anchor.resource, 2, lane_two_target)

      budgets[fruit] = (budgets[fruit] or 0) + drained_seeds * throughput_policy.GLEBA_FRUIT_PER_SEED
    end
  end

  return budgets
end

local function grant_biter_egg_handling_from_ingress(bootstrap, force)
  if not bootstrap or bootstrap.biter_egg_handling_granted_from_ingress then
    return
  end

  if not (force and force.valid ~= false and force.technologies) then
    return
  end

  local technology = force.technologies["biter-egg-handling"]

  if not technology then
    return
  end

  bootstrap.biter_egg_handling_granted_from_ingress = true

  if not technology.researched then
    technology.researched = true
    if type(force.play_sound) == "function" then
      force.play_sound({path = "utility/research_completed"})
    end
  end
end

local function drain_biter_egg_budget(starter_anchors, planet_name)
  if planet_name ~= "nauvis" then
    return 0
  end

  local egg_budget_capacity = throughput_policy.BITER_BIOFLUX_BUFFER_CAPACITY * throughput_policy.BITER_EGGS_PER_BIOFLUX

  starter_anchors.biter_egg_budget = math.min(
    egg_budget_capacity,
    math.max(0, starter_anchors.biter_egg_budget or 0)
  )

  local budget = starter_anchors.biter_egg_budget

  for _, anchor in ipairs(starter_anchors.anchors) do
    local entity = anchor.position and anchor.entity or nil

    if anchor.flow == "egress"
      and anchor.kind == "item"
      and anchor.resource == "bioflux"
      and entity
      and entity.valid
    then
      local available_egg_capacity = egg_budget_capacity - budget
      local bioflux_capacity = math.floor(available_egg_capacity / throughput_policy.BITER_EGGS_PER_BIOFLUX)

      if bioflux_capacity <= 0 then
        break
      end

      local emission = get_item_anchor_emissions(anchor, defs.get_effective_ingress_tier_for_anchor(anchor), 1)
      local lane_one_target = math.min(emission.lane_emissions[1] or 0, bioflux_capacity)
      local drained_bioflux = drain_item_anchor(entity, anchor.resource, 1, lane_one_target)
      local remaining_bioflux_capacity = bioflux_capacity - drained_bioflux
      local lane_two_target = math.min(emission.lane_emissions[2] or 0, remaining_bioflux_capacity)

      drained_bioflux = drained_bioflux + drain_item_anchor(entity, anchor.resource, 2, lane_two_target)
      budget = budget + drained_bioflux * throughput_policy.BITER_EGGS_PER_BIOFLUX
    end
  end

  starter_anchors.biter_egg_budget = budget
  return budget
end

local function pump_anchor_set(starter_anchors, ingress_tier, uranium_context, planet_name)
  if not starter_anchors then
    return
  end

  local gleba_fruit_budgets = drain_gleba_seed_budgets(starter_anchors, ingress_tier, planet_name)
  local biter_egg_budget = drain_biter_egg_budget(starter_anchors, planet_name)
  local bootstrap = planet_name and storage.planets and storage.planets[planet_name] or nil

  for _, anchor in ipairs(starter_anchors.anchors) do
    local entity = anchor.position and anchor.entity or nil

    if entity and entity.valid and anchor.resource then
      if anchor.flow == "ingress" then
        if anchor.kind == "item" then
          if anchor.resource == "uranium-ore" then
            local uranium_anchor = uranium_context and uranium_context.by_anchor and uranium_context.by_anchor[anchor] or nil
            local allocated_budget = uranium_anchor and uranium_anchor.allocation or 0
            local uranium_buffer = uranium_context and uranium_context.sulfuric_acid_buffer or 0

            set_anchor_active(anchor, entity, allocated_budget > 0 or uranium_buffer > 0)
            pump_uranium_ingress_anchor(entity, uranium_anchor and uranium_anchor.requested_emission, allocated_budget)
          elseif throughput_policy.should_gate_gleba_fruit(planet_name, anchor) then
            local available = gleba_fruit_budgets[anchor.resource] or 0
            local emission = get_item_anchor_emissions(anchor, defs.get_effective_ingress_tier_for_anchor(anchor), 1)

            set_anchor_active(anchor, entity, available > 0)
            if available > 0 then
              local lane_one_inserted = pump_item_anchor(entity, anchor.resource, 1, math.min(emission.lane_emissions[1] or 0, available))
              available = available - lane_one_inserted
              local lane_two_inserted = pump_item_anchor(entity, anchor.resource, 2, math.min(emission.lane_emissions[2] or 0, available))
              available = available - lane_two_inserted
            end

            gleba_fruit_budgets[anchor.resource] = available
          elseif throughput_policy.should_gate_biter_egg(planet_name, anchor) then
            local emission = get_item_anchor_emissions(anchor, defs.get_effective_ingress_tier_for_anchor(anchor), 1)

            set_anchor_active(anchor, entity, biter_egg_budget > 0)
            if biter_egg_budget > 0 then
              local lane_one_inserted = pump_item_anchor(entity, anchor.resource, 1, math.min(emission.lane_emissions[1] or 0, biter_egg_budget))
              biter_egg_budget = biter_egg_budget - lane_one_inserted
              local lane_two_inserted = pump_item_anchor(entity, anchor.resource, 2, math.min(emission.lane_emissions[2] or 0, biter_egg_budget))
              biter_egg_budget = biter_egg_budget - lane_two_inserted

              if lane_one_inserted + lane_two_inserted > 0 then
                grant_biter_egg_handling_from_ingress(bootstrap, entity.force or defs.get_player_force())
              end
            end

            starter_anchors.biter_egg_budget = biter_egg_budget
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
  local sulfuric_acid_buffer = drain_uranium_acid_buffer(starter_anchors, bootstrap)
  local uranium_anchors = get_uranium_anchors(ingress_tier, starter_anchors)

  if #uranium_anchors == 0 then
    return {
      anchors = {},
      allocations = {},
      by_anchor = {},
      sulfuric_acid_buffer = sulfuric_acid_buffer
    }
  end

  local uranium_budget = get_active_uranium_budget_per_interval(uranium_anchors, starter_anchors, bootstrap)
  local uranium_capacities = {}

  for index, uranium_anchor in ipairs(uranium_anchors) do
    uranium_capacities[index] = uranium_anchor.capacity
  end

  local allocations = throughput_policy.allocate_shared_budget(uranium_budget, uranium_capacities)
  local by_anchor = {}

  for index, uranium_anchor in ipairs(uranium_anchors) do
    uranium_anchor.allocation = allocations[index] or 0
    by_anchor[uranium_anchor.anchor] = uranium_anchor
  end

  return {
    anchors = uranium_anchors,
    allocations = allocations,
    by_anchor = by_anchor,
    sulfuric_acid_buffer = bootstrap.uranium_sulfuric_acid_buffer or 0
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
