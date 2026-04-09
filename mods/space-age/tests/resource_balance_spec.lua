package.path = "./?.lua;./?/init.lua;" .. package.path

local resource_balance = require("lib.resource_balance")

local function assert_equal(actual, expected, message)
  if actual ~= expected then
    error((message or "values differ") .. "\nexpected: " .. tostring(expected) .. "\nactual: " .. tostring(actual))
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

run_test("uranium stays gated without sulfuric acid egress", function()
  local budget = resource_balance.compute_uranium_budget(0, 0, 0)

  assert_equal(budget.ore_budget, 0, "uranium should stay idle without acid")
  assert_equal(budget.remaining_ore_progress, 0, "no progress should accumulate without acid")
end)

run_test("base sulfuric acid ratio matches vanilla uranium mining", function()
  local budget = resource_balance.compute_uranium_budget(160, 0, 0)

  assert_equal(budget.ore_budget, 160, "base acid throughput should convert 1:1 into uranium ore budget")
  assert_equal(budget.remaining_ore_progress, 0, "whole-acid throughput should not leave fractional carry")
end)

run_test("mining productivity scales uranium budget without changing acid usage", function()
  local budget = resource_balance.compute_uranium_budget(5, 0.1, 0)

  assert_equal(budget.ore_budget, 5, "fractional productivity should only produce whole extra ore once enough progress accrues")
  assert_equal(budget.remaining_ore_progress, 0.5, "fractional productivity should carry forward")

  local next_budget = resource_balance.compute_uranium_budget(5, 0.1, budget.remaining_ore_progress)

  assert_equal(next_budget.ore_budget, 6, "carried progress should eventually produce the extra ore")
  assert_equal(next_budget.remaining_ore_progress, 0, "carried progress should be spent once it reaches a full ore")
end)

run_test("multiple uranium lines share one sulfuric acid budget", function()
  local allocation = resource_balance.allocate_shared_budget(6, {4, 4})

  assert_equal(allocation.allocations[1], 4, "the first anchor should consume only part of the shared pool")
  assert_equal(allocation.allocations[2], 2, "the second anchor should receive only the leftover shared pool")
  assert_equal(allocation.remaining_budget, 0, "the shared pool should be spent once")
end)

run_test("multiple sulfuric acid egress lines combine into one shared allowance", function()
  local sulfuric_acid_total = 80 + 80
  local budget = resource_balance.compute_uranium_budget(sulfuric_acid_total, 0, 0)
  local allocation = resource_balance.allocate_shared_budget(budget.ore_budget, {70, 70, 70})

  assert_equal(budget.ore_budget, 160, "all sulfuric acid egress should sum into one uranium pool")
  assert_equal(allocation.allocations[1], 70, "the first uranium line should draw from the shared pool")
  assert_equal(allocation.allocations[2], 70, "the second uranium line should continue using the same pool")
  assert_equal(allocation.allocations[3], 20, "the final line should receive only the remaining budget")
  assert_equal(allocation.remaining_budget, 0, "the summed sulfuric acid budget should not duplicate")
end)
