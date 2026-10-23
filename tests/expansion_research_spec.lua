package.path = "./?.lua;./?/init.lua;" .. package.path

local helper = require("tests.helper")
local assert_equal = helper.assert_equal
local run_test = helper.run_test

local expansion_research = require("lib.expansion_research")

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
  assert_equal(expansion_research.get_level_from_technology_name("the-square-square-expansion-0001"), 1, "level 1 should parse")
  assert_equal(expansion_research.get_level_from_technology_name("the-square-square-expansion-0041"), 41, "level 41 should parse")
  assert_equal(expansion_research.get_level_from_technology_name("automation"), nil, "non-expansion research should not parse")
end)

run_test("planet expansion technology names can be parsed", function()
  assert_equal(expansion_research.get_planet_technology_name("vulcanus"), "the-square-vulcanus-square-expansion", "planet technology name should include planet")
  assert_equal(expansion_research.get_planet_from_technology_name("the-square-vulcanus-square-expansion"), "vulcanus", "planet should parse")
end)

run_test("every Square Expansion technology maps to the Planet it grows", function()
  assert_equal(expansion_research.get_planet_for_technology_name("the-square-square-expansion-0007"), "nauvis", "numbered levels grow Nauvis")
  assert_equal(expansion_research.get_planet_for_technology_name("the-square-gleba-square-expansion"), "gleba", "planet research grows that planet")
  assert_equal(expansion_research.get_planet_for_technology_name("the-square-ingress-red"), nil, "other mod research grows nothing")
  assert_equal(expansion_research.get_planet_for_technology_name("automation"), nil, "vanilla research grows nothing")
end)

run_test("science bands step up every ten levels and cover infinite research", function()
  assert_equal(expansion_research.get_band(1).start_level, 1, "level 1 uses the first band")
  assert_equal(expansion_research.get_band(10).start_level, 1, "level 10 is still the first band")
  assert_equal(expansion_research.get_band(11).start_level, 11, "level 11 adds logistic science")
  assert_equal(expansion_research.get_band(expansion_research.INFINITE_START_LEVEL).start_level, 41, "infinite research uses the last band")
  assert_equal(expansion_research.get_band(500).start_level, 41, "high levels stay in the last band")
end)

run_test("infinite research formula keeps the same linear scaling", function()
  assert_equal(
    expansion_research.get_infinite_research_unit_formula(7, 7),
    "max(1, ((8 * L) + 24) / 7)",
    "the infinite formula should scale with the ring size implied by L"
  )
end)
