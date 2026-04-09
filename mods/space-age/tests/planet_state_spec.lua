package.path = "./?.lua;./?/init.lua;" .. package.path

storage = {}

local planet_state = require("lib.planet_state")

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

run_test("planet state uses the categorized planet config defaults", function()
  local state = planet_state.ensure_planet("nauvis")

  assert_equal(state.square_size, 7, "planet state should use the planet square config")
  assert_equal(state.expansion_points, 0, "planet state should use the configured starting point bank")
end)

run_test("planet state can spend from a planet-local point bank", function()
  local state = planet_state.ensure_planet("vulcanus")
  state.expansion_points = 150

  local spent, remaining = planet_state.try_spend_expansion_points("vulcanus", 100)

  assert_equal(spent, true, "the spend should succeed when the local bank has enough points")
  assert_equal(remaining, 50, "the local bank should return the remaining points")
  assert_equal(state.expansion_points, 50, "the local bank should be decremented in place")
end)
