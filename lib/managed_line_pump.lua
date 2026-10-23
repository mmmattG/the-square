-- Moves resources through placed Managed Lines every tick: ingress lines insert
-- items or fluid into their Anchor, egress lines remove them.
--
-- Two Support Material Dependencies change the plain flow:
--   Nauvis uranium ore only flows while sulfuric acid egress builds a budget.
--   Gleba fruit only flows while matching seed egress builds a budget.
local item_ingress = require("lib.item_ingress")
local definitions = require("lib.managed_line_definitions")
local managed_line_tiers = require("lib.managed_line_tiers")
local planet_catalog = require("lib.planet_catalog")
local throughput_policy = require("lib.managed_line_throughput_policy")

local managed_line_pump = {}

-- Items each lane should move this tick, carrying fractions between ticks.
local function advance_item_emissions(anchor, throughput)
  return item_ingress.advance_lane_progress(
    throughput.item_lane_counts,
    definitions.ITEM_INTERVAL_TICKS,
    anchor.item_progress,
    1
  )
end

local function insert_items(entity, resource, lane_index, item_count)
  local line = entity.get_transport_line(lane_index)
  local inserted = 0

  while inserted < item_count and line.can_insert_at_back() do
    line.insert_at_back({name = resource, count = 1})
    inserted = inserted + 1
  end

  return inserted
end

local function remove_items(entity, resource, lane_index, item_count)
  if item_count <= 0 then
    return 0
  end

  return entity.get_transport_line(lane_index).remove_item({name = resource, count = item_count})
end

local function extract_fluid(entity, resource, amount)
  if amount <= 0 then
    return 0
  end

  return entity.extract_fluid({name = resource, amount = amount})
end

-- Fills lane one first, then lane two, without going over the budget.
local function insert_items_within_budget(entity, resource, lane_one_count, lane_two_count, budget)
  local inserted = insert_items(entity, resource, 1, math.min(budget, lane_one_count))

  return inserted + insert_items(entity, resource, 2, math.min(budget - inserted, lane_two_count))
end

local function placed_entity(anchor)
  local entity = anchor.position and anchor.entity

  return entity and entity.valid and entity or nil
end

-- Sulfuric acid egress fills a capped buffer that uranium ore ingress spends.
local function drain_uranium_acid_buffer(managed_lines, planet)
  local buffer_capacity = throughput_policy.URANIUM_SULFURIC_ACID_BUFFER_CAPACITY
  local buffer = math.min(buffer_capacity, math.max(0, planet.uranium_sulfuric_acid_buffer or 0))

  for _, anchor in ipairs(managed_lines.anchors) do
    local entity = placed_entity(anchor)

    if entity and anchor.flow == "egress" and anchor.resource == "sulfuric-acid" then
      local remaining_capacity = buffer_capacity - buffer

      if remaining_capacity <= 0 then
        break
      end

      local amount = math.min(managed_line_tiers.get_throughput(anchor).fluid_amount_per_tick, remaining_capacity)
      buffer = buffer + extract_fluid(entity, anchor.resource, amount)
    end
  end

  planet.uranium_sulfuric_acid_buffer = buffer
end

-- How much uranium ore each placed uranium line wants this tick, and how much of
-- that its belt can take.
local function collect_uranium_lines(managed_lines)
  local lines = {}

  for _, anchor in ipairs(managed_lines.anchors) do
    local entity = placed_entity(anchor)

    if entity and anchor.flow == "ingress" and anchor.resource == "uranium-ore" then
      local lane_one_count, lane_two_count = advance_item_emissions(anchor, managed_line_tiers.get_throughput(anchor))
      local capacity = 0

      if lane_one_count > 0 and entity.get_transport_line(1).can_insert_at_back() then
        capacity = capacity + lane_one_count
      end

      if lane_two_count > 0 and entity.get_transport_line(2).can_insert_at_back() then
        capacity = capacity + lane_two_count
      end

      lines[#lines + 1] = {
        anchor = anchor,
        lane_one_count = lane_one_count,
        lane_two_count = lane_two_count,
        capacity = capacity
      }
    end
  end

  return lines
end

-- Spends buffered acid on as much ore as the uranium lines can take this tick.
local function spend_uranium_budget(uranium_lines, planet)
  local total_capacity = 0

  for _, line in ipairs(uranium_lines) do
    total_capacity = total_capacity + line.capacity
  end

  if total_capacity <= 0 then
    return 0
  end

  local mining_productivity_bonus = game.forces.player.mining_drill_productivity_bonus
  local available_acid = math.max(0, planet.uranium_sulfuric_acid_buffer or 0)
  local acid_to_spend = math.min(available_acid, total_capacity / (
    throughput_policy.URANIUM_ORE_PER_SULFURIC_ACID * (1 + mining_productivity_bonus)
  ))
  local budget = throughput_policy.compute_uranium_budget(
    acid_to_spend,
    mining_productivity_bonus,
    planet.uranium_ore_progress_carry or 0
  )

  planet.uranium_sulfuric_acid_buffer = available_acid - acid_to_spend
  planet.uranium_ore_progress_carry = budget.remaining_ore_progress

  return budget.ore_budget
end

-- Returns each uranium line's share of this tick's ore budget, keyed by anchor.
local function plan_uranium(managed_lines, planet)
  drain_uranium_acid_buffer(managed_lines, planet)

  local uranium_lines = collect_uranium_lines(managed_lines)

  if #uranium_lines == 0 then
    return {}
  end

  local capacities = {}

  for index, line in ipairs(uranium_lines) do
    capacities[index] = line.capacity
  end

  local allocations = throughput_policy.allocate_shared_budget(spend_uranium_budget(uranium_lines, planet), capacities)
  local plan = {}

  for index, line in ipairs(uranium_lines) do
    line.allocation = allocations[index] or 0
    plan[line.anchor] = line
  end

  return plan
end

-- Seed egress on Gleba adds fruit to a capped budget per fruit.
local function drain_gleba_seeds(managed_lines)
  managed_lines.gleba_fruit_budgets = managed_lines.gleba_fruit_budgets or {}
  local budgets = managed_lines.gleba_fruit_budgets
  local fruit_capacity = throughput_policy.GLEBA_SEED_BUFFER_CAPACITY * throughput_policy.GLEBA_FRUIT_PER_SEED

  for _, anchor in ipairs(managed_lines.anchors) do
    local entity = placed_entity(anchor)
    local fruit = throughput_policy.get_gleba_fruit_for_seed_anchor(anchor)

    if entity and fruit then
      local lane_one_count, lane_two_count = advance_item_emissions(anchor, managed_line_tiers.get_throughput(anchor))
      local free_fruit_capacity = fruit_capacity - math.min(fruit_capacity, math.max(0, budgets[fruit] or 0))
      local seed_capacity = math.floor(free_fruit_capacity / throughput_policy.GLEBA_FRUIT_PER_SEED)
      local seeds = remove_items(entity, anchor.resource, 1, math.min(lane_one_count, seed_capacity))

      seeds = seeds + remove_items(entity, anchor.resource, 2, math.min(lane_two_count, seed_capacity - seeds))
      budgets[fruit] = (budgets[fruit] or 0) + seeds * throughput_policy.GLEBA_FRUIT_PER_SEED
    end
  end

  return budgets
end

local function pump_uranium_ingress(anchor, entity, uranium_plan)
  local line = uranium_plan[anchor]
  local allocation = line and line.allocation or 0

  if allocation > 0 then
    insert_items_within_budget(entity, "uranium-ore", line.lane_one_count, line.lane_two_count, allocation)
  end
end

local function pump_gleba_fruit_ingress(anchor, entity, fruit_budgets)
  local available = fruit_budgets[anchor.resource] or 0
  local lane_one_count, lane_two_count = advance_item_emissions(anchor, managed_line_tiers.get_throughput(anchor))

  if available > 0 then
    available = available - insert_items_within_budget(entity, anchor.resource, lane_one_count, lane_two_count, available)
  end

  fruit_budgets[anchor.resource] = available
end

local function pump_line(anchor, entity, planet_name, context)
  local throughput = managed_line_tiers.get_throughput(anchor)

  if anchor.flow == "ingress" then
    if anchor.kind == "fluid" then
      entity.insert_fluid({name = anchor.resource, amount = throughput.fluid_amount_per_tick})
    elseif anchor.resource == "uranium-ore" then
      pump_uranium_ingress(anchor, entity, context.uranium_plan)
    elseif throughput_policy.should_gate_gleba_fruit(planet_name, anchor) then
      pump_gleba_fruit_ingress(anchor, entity, context.fruit_budgets)
    else
      local lane_one_count, lane_two_count = advance_item_emissions(anchor, throughput)

      insert_items(entity, anchor.resource, 1, lane_one_count)
      insert_items(entity, anchor.resource, 2, lane_two_count)
    end

    return
  end

  -- Support material egress was already drained into its budget above.
  if throughput_policy.is_support_material_egress(planet_name, anchor) then
    return
  end

  if anchor.kind == "fluid" then
    extract_fluid(entity, anchor.resource, throughput.fluid_amount_per_tick)
  else
    local lane_one_count, lane_two_count = advance_item_emissions(anchor, throughput)

    remove_items(entity, anchor.resource, 1, lane_one_count)
    remove_items(entity, anchor.resource, 2, lane_two_count)
  end
end

function managed_line_pump.pump_planet(planet_name)
  local planet = storage.planets and storage.planets[planet_name]
  local managed_lines = planet and planet.starter_anchors

  if not managed_lines then
    return
  end

  local context = {
    uranium_plan = planet_name == "nauvis" and plan_uranium(managed_lines, planet) or {},
    fruit_budgets = planet_name == "gleba" and drain_gleba_seeds(managed_lines) or {}
  }

  for _, anchor in ipairs(managed_lines.anchors) do
    local entity = placed_entity(anchor)

    if entity and anchor.resource then
      pump_line(anchor, entity, planet_name, context)
    end
  end
end

function managed_line_pump.pump_all()
  for _, planet_name in ipairs(planet_catalog.SUPPORTED_PLANETS) do
    managed_line_pump.pump_planet(planet_name)
  end
end

return managed_line_pump
