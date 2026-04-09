package.path = "./?.lua;./?/init.lua;" .. package.path

local expansion_research = require("lib.expansion_research")

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

run_test("research unit count scales linearly with unlocked tiles", function()
  assert_equal(expansion_research.get_research_unit_count(7, 7, 1), 32 / 7, "level 1 should use the raw tile ratio")
  assert_equal(expansion_research.get_research_unit_count(7, 7, 2), 40 / 7, "level 2 should use the next ring tile ratio")
  assert_equal(expansion_research.get_research_unit_count(7, 7, 8), 88 / 7, "later levels should keep scaling linearly")
end)

run_test("custom tiles per research changes the count", function()
  assert_equal(expansion_research.get_research_unit_count(7, 8, 2), 5, "40 tiles at 8 tiles per pack should cost 5")
  assert_equal(expansion_research.get_research_unit_count(7, 100, 2), 1, "the infinite line keeps a minimum count of 1")
end)

run_test("finite bands end before the infinite continuation starts", function()
  assert_equal(expansion_research.FINAL_FINITE_LEVEL, 40, "the finite chain should stop at level 40")
  assert_equal(expansion_research.INFINITE_START_LEVEL, 41, "the infinite continuation should begin at level 41")
end)

run_test("expansion technology names can be parsed back into levels", function()
  assert_equal(expansion_research.get_level_from_technology_name("fes-square-expansion-0001"), 1, "level 1 should parse")
  assert_equal(expansion_research.get_level_from_technology_name("fes-square-expansion-0041"), 41, "level 41 should parse")
  assert_equal(expansion_research.get_level_from_technology_name("automation"), nil, "non-expansion research should not parse")
end)

run_test("infinite research formula keeps the same linear scaling", function()
  assert_equal(
    expansion_research.get_infinite_research_unit_formula(7, 7),
    "max(1, ((8 * L) + 24) / 7)",
    "the infinite formula should scale with the ring size implied by L"
  )
end)
