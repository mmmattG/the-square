package.path = "./?.lua;./?/init.lua;" .. package.path

defines = {
  direction = {
    south = 1,
    west = 2,
    north = 3,
    east = 4
  }
}

settings = {
  global = {
    ["the-square-screenshot-alt-mode"] = {
      value = true
    },
    ["the-square-screenshot-pixels-per-tile"] = {
      value = 48
    },
    ["the-square-background-tile"] = {
      value = "checkerboard"
    }
  }
}

local runtime_defs = require("lib.runtime_defs")

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

run_test("checkerboard alternates lab floor tiles inside the square", function()
  assert_equal(
    runtime_defs.get_managed_tile_name(7, 9, {x = 0, y = 0}),
    "lab-dark-1",
    "even-parity tiles should use the first checkerboard tile"
  )
  assert_equal(
    runtime_defs.get_managed_tile_name(7, 9, {x = 1, y = 0}),
    "lab-dark-2",
    "odd-parity tiles should use the second checkerboard tile"
  )
end)

run_test("checkerboard still keeps the border out of map", function()
  assert_equal(
    runtime_defs.get_managed_tile_name(7, 9, {x = 0, y = -4}),
    "out-of-map",
    "checkerboard should not replace the managed void border"
  )
end)

run_test("expansion research name detection accepts the finite and infinite prototype name", function()
  assert_equal(
    runtime_defs.is_expansion_research_name("the-square-square-expansion-0007"),
    true,
    "finite chain names should match"
  )
  assert_equal(
    runtime_defs.is_expansion_research_name("the-square-square-expansion-0041"),
    true,
    "the infinite prototype name should still match"
  )
  assert_equal(
    runtime_defs.is_expansion_research_name("logistics"),
    false,
    "other technology names should not match"
  )
end)

run_test("screenshot pixels per tile comes from the runtime-global setting", function()
  assert_equal(
    runtime_defs.get_screenshot_pixels_per_tile(),
    48,
    "screenshot captures should use the configured render density"
  )
end)

run_test("screenshot alt mode defaults to the runtime-global toggle", function()
  assert_equal(
    runtime_defs.is_screenshot_alt_mode_enabled(),
    true,
    "base screenshots should include alt mode info by default"
  )
end)

run_test("item egress entity names follow researched belt tiers", function()
  assert_equal(runtime_defs.get_egress_entity_name("yumako-seed", 1), "the-square-yumako-seed-egress-anchor")
  assert_equal(runtime_defs.get_egress_entity_name("yumako-seed", 3), "the-square-yumako-seed-egress-anchor-red")
  assert_equal(runtime_defs.get_egress_entity_name("yumako-seed", 5), "the-square-yumako-seed-egress-anchor-turbo")
  assert_equal(runtime_defs.get_egress_entity_name("sulfuric-acid", 5), "the-square-sulfuric-acid-egress-anchor")
end)

run_test("Managed Line tier research includes the Space Age-only final tier", function()
  local force = {
    valid = true,
    technologies = {
      ["the-square-ingress-blue"] = {researched = true},
      ["the-square-egress-turbo"] = {researched = true}
    }
  }

  assert_equal(runtime_defs.get_ingress_tier_level_for_force(force), 5)
  assert_equal(runtime_defs.get_egress_tier_level_for_force(force), 5)
  assert_equal(runtime_defs.get_ingress_entity_name("scrap", 5), "the-square-scrap-ingress-anchor-turbo")
end)
