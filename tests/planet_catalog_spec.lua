package.path = "./?.lua;./?/init.lua;" .. package.path

local helper = require("tests.helper")
local assert_equal = helper.assert_equal
local run_test = helper.run_test

local planet_catalog = require("lib.planet_catalog")

run_test("every resource can be chosen somehow", function()
  for _, planet_name in ipairs(planet_catalog.SUPPORTED_PLANETS) do
    for _, flow in ipairs({"ingress", "egress"}) do
      for _, definition in ipairs(planet_catalog.get_resources(planet_name, flow)) do
        local label = planet_name .. " " .. flow .. " " .. definition.resource
        assert_equal(definition.kind == "item" or definition.kind == "fluid", true, label .. " has a kind")
        assert_equal(definition.unlocked_at_start == true or type(definition.unlock_technology) == "string", true, label .. " is unlocked somehow")
      end
    end
  end
end)

run_test("Support Material Dependencies have both of their lines", function()
  assert_equal(planet_catalog.get_resource("nauvis", "ingress", "uranium-ore").kind, "item", "Nauvis uranium ingress")
  assert_equal(planet_catalog.get_resource("nauvis", "egress", "sulfuric-acid").kind, "fluid", "Nauvis acid egress pays for uranium")

  for _, fruit in ipairs({"yumako", "jellynut"}) do
    assert_equal(planet_catalog.get_resource("gleba", "ingress", fruit).kind, "item", "Gleba " .. fruit .. " ingress")
    assert_equal(planet_catalog.get_resource("gleba", "egress", fruit .. "-seed").kind, "item", "Gleba " .. fruit .. " seed egress")
  end
end)

run_test("only Nauvis starts with Managed Lines, and only other Planets have their own expansion research", function()
  for _, planet_name in ipairs(planet_catalog.SUPPORTED_PLANETS) do
    local planet = planet_catalog.get(planet_name)
    assert_equal(planet.initial_line_items ~= nil, planet_name == "nauvis", planet_name .. " initial lines")
    assert_equal(planet.expansion_research ~= nil, planet_name ~= "nauvis", planet_name .. " expansion research")
    assert_equal(planet.floor_tile_name ~= nil, planet_name ~= "nauvis", planet_name .. " floor (Nauvis uses the Background tile setting)")
  end
end)

run_test("unknown Planets have no resources", function()
  assert_equal(planet_catalog.is_supported("nauvis"), true, "Nauvis is supported")
  assert_equal(planet_catalog.is_supported("harness-nauvis"), false, "other surfaces are not Planets")
  assert_equal(#planet_catalog.get_resources("space-platform", "ingress"), 0, "no resources for unknown names")
end)
