package.path = "./?.lua;./?/init.lua;" .. package.path

local item_ingress = require("lib.item_ingress")

local function assert_equal(actual, expected, message)
  if actual ~= expected then
    error((message or "values differ") .. "\nexpected: " .. tostring(expected) .. "\nactual: " .. tostring(actual))
  end
end

local function assert_at_most(actual, expected, message)
  if actual > expected then
    error((message or "value exceeded maximum") .. "\nmaximum: " .. tostring(expected) .. "\nactual: " .. tostring(actual))
  end
end

local function run_test(name, fn)
  local ok, err = pcall(fn)

  if not ok then
    io.stderr:write("FAIL " .. name .. "\n" .. err .. "\n")
    os.exit(1)
  end

  io.stdout:write("PASS " .. name .. "\n")
end

local function simulate_ticks(item_lane_counts, tick_count)
  local carried_progress = {0, 0}
  local totals = {0, 0}
  local per_tick_emissions = {}

  for tick = 1, tick_count do
    local emission = item_ingress.compute_lane_emissions(item_lane_counts, 8, carried_progress, 1)

    carried_progress = emission.carried_progress
    per_tick_emissions[tick] = emission.lane_emissions
    totals[1] = totals[1] + emission.lane_emissions[1]
    totals[2] = totals[2] + emission.lane_emissions[2]
  end

  return {
    totals = totals,
    per_tick_emissions = per_tick_emissions,
    carried_progress = carried_progress
  }
end

run_test("yellow single lane still emits one item every eight ticks", function()
  local simulation = simulate_ticks({1, 0}, 8)

  assert_equal(simulation.totals[1], 1, "yellow single lane should keep its existing eight-tick throughput")
  assert_equal(simulation.totals[2], 0, "the second lane should stay unused at yellow single")
  assert_equal(simulation.carried_progress[1], 0, "yellow single should not leave excess progress after a full window")
end)

run_test("red double lane distributes output across ticks instead of same-tick bursts", function()
  local simulation = simulate_ticks({2, 2}, 8)

  assert_equal(simulation.totals[1], 2, "the first lane should emit two items across eight ticks")
  assert_equal(simulation.totals[2], 2, "the second lane should emit two items across eight ticks")

  for tick = 1, 8 do
    assert_at_most(
      simulation.per_tick_emissions[tick][1],
      1,
      "red belts should not require two same-tick inserts into one lane"
    )
    assert_at_most(
      simulation.per_tick_emissions[tick][2],
      1,
      "red belts should not require two same-tick inserts into one lane"
    )
  end
end)

run_test("blue double lane sustains full throughput over longer runs", function()
  local simulation = simulate_ticks({3, 3}, 16)

  assert_equal(simulation.totals[1], 6, "the first lane should sustain blue-belt cadence")
  assert_equal(simulation.totals[2], 6, "the second lane should sustain blue-belt cadence")

  for tick = 1, 16 do
    assert_at_most(
      simulation.per_tick_emissions[tick][1],
      1,
      "blue belts should pace inserts rather than depend on same-tick stacking"
    )
    assert_at_most(
      simulation.per_tick_emissions[tick][2],
      1,
      "blue belts should pace inserts rather than depend on same-tick stacking"
    )
  end
end)
