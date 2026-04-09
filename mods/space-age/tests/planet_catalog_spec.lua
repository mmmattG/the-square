package.path = "./?.lua;./?/init.lua;" .. package.path

local planet_catalog = require("lib.planet_catalog")

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

run_test("planet catalog exposes the supported planets in rollout order", function()
  local planets = planet_catalog.get_all()

  assert_equal(#planets, 5, "the Space Age variant should track five supported planets")
  assert_equal(planets[1].key, "nauvis", "Nauvis should stay first")
  assert_equal(planets[2].key, "vulcanus", "Vulcanus should be the first Space Age proof planet")
  assert_equal(planets[5].key, "aquilo", "Aquilo should remain last in the rollout")
end)

run_test("planet catalog can resolve a planet from the surface name", function()
  local planet = planet_catalog.get_planet_for_surface("fulgora")

  assert_equal(planet.key, "fulgora", "surface names should map to the matching planet definition")
  assert_equal(planet.unlock_technology_name, "planet-discovery-fulgora", "the discovery tech should be tracked")
end)

run_test("nauvis expansion science uses space science before production and utility", function()
  local band_31 = planet_catalog.get_expansion_research_band("nauvis", 31)
  local band_41 = planet_catalog.get_expansion_research_band("nauvis", 41)

  assert_equal(band_31.ingredients[4][1], "space-science-pack", "space science should enter at the fourth Nauvis band")
  assert_equal(band_41.ingredients[5][1], "production-science-pack", "production science should move after space science on Nauvis")
  assert_equal(band_41.ingredients[6][1], "utility-science-pack", "utility science should move after space science on Nauvis")
end)

run_test("space age planets use only their own science pack for expansion", function()
  local vulcanus_band = planet_catalog.get_expansion_research_band("vulcanus", 25)
  local aquilo_band = planet_catalog.get_expansion_research_band("aquilo", 41)

  assert_equal(#vulcanus_band.ingredients, 1, "Vulcanus expansion should stay on one science pack")
  assert_equal(vulcanus_band.ingredients[1][1], "metallurgic-science-pack", "Vulcanus should use metallurgic science")
  assert_equal(#aquilo_band.ingredients, 1, "Aquilo expansion should stay on one science pack")
  assert_equal(aquilo_band.ingredients[1][1], "cryogenic-science-pack", "Aquilo should use cryogenic science")
end)

run_test("planet config exposes categorized ingress and economy definitions", function()
  local nauvis_config = planet_catalog.get_config("nauvis")

  assert_equal(nauvis_config.square.starting_size, 7, "Nauvis should keep the existing starting square size")
  assert_equal(nauvis_config.economy.starting_expansion_points, 0, "planets should start with their configured point bank")
  assert_equal(nauvis_config.ingress.inputs[7].trigger_technologies[1], "oil-processing", "crude oil ingress should list its trigger technology")
  assert_equal(nauvis_config.ingress.inputs[8].trigger_technologies[1], "uranium-processing", "uranium ingress should list its trigger technology")
end)
