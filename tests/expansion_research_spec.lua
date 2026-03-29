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

run_test("level one is fixed at five packs", function()
  assert_equal(expansion_research.get_research_unit_count(7, 7, 1), 5, "level 1 should always cost five")
end)

run_test("early levels round up to the next ten after level one", function()
  assert_equal(expansion_research.get_research_unit_count(7, 7, 2), 10, "40 tiles should round up to 10")
  assert_equal(expansion_research.get_research_unit_count(7, 7, 3), 10, "48 tiles should round up to 10")
end)

run_test("higher tier levels keep rounding up in tens", function()
  assert_equal(expansion_research.get_research_unit_count(7, 7, 7), 20, "19x19 to 21x21 should round up to 20")
  assert_equal(expansion_research.get_research_unit_count(7, 7, 8), 20, "21x21 to 23x23 should stay at 20")
end)

run_test("custom tiles per research changes the count", function()
  assert_equal(expansion_research.get_research_unit_count(7, 8, 2), 10, "40 tiles at 8 tiles per pack should still round up to 10")
  assert_equal(expansion_research.get_research_unit_count(7, 20, 2), 10, "non-first levels keep a minimum of 10")
end)
