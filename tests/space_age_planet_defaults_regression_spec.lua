package.path = "./?.lua;./?/init.lua;" .. package.path

defines = {direction = {south = 1, west = 2, north = 3, east = 4}}
settings = {global = {}, startup = {}}
storage = {bootstrap = {square_size = 7, surface_name = "nauvis", ingress_tier = 1}}
game = {forces = {player = {valid = true, mining_drill_productivity_bonus = 0}}}

local defs = require("lib.runtime_defs")
local planet_config = require("lib.planet_config")
local bootstrap_runtime = require("lib.bootstrap_runtime")
local ingress_runtime = require("lib.ingress_runtime")
local void_item_runtime = require("lib.void_item_runtime")

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

local function resource_names(definitions)
  local names = {}
  for _, definition in ipairs(definitions) do
    names[#names + 1] = definition.resource
  end
  table.sort(names)
  return table.concat(names, ",")
end

run_test("Space Age planet defaults match the PRD matrix", function()
  local expected = {
    vulcanus = {tile = "volcanic-ash-soil", ingress = "calcite,coal,lava,sulfuric-acid,tungsten-ore", egress = ""},
    fulgora = {tile = "fulgoran-dust", ingress = "heavy-oil,scrap", egress = ""},
    gleba = {tile = "lowland-cream-cauliflower", ingress = "jellynut,stone,water,yumako", egress = "jellynut-seed,yumako-seed"},
    aquilo = {tile = "snow-flat", ingress = "ammoniacal-solution,crude-oil,fluorine,lithium-brine", egress = ""}
  }

  for planet_name, planet_expectation in pairs(expected) do
    local config = planet_config.get(planet_name)
    local anchors = bootstrap_runtime.build_starter_anchor_layout(config.square_size, planet_name)

    assert_equal(config.square_size, 17, planet_name .. " should default to a 17x17 square")
    assert_equal(config.floor_tile_name, planet_expectation.tile, planet_name .. " should use its thematic tile")
    assert_equal(resource_names(defs.get_input_definitions(planet_name)), planet_expectation.ingress, planet_name .. " ingress defaults changed")
    assert_equal(resource_names(defs.get_output_definitions(planet_name)), planet_expectation.egress, planet_name .. " egress defaults changed")
    assert_equal(#anchors, #defs.get_input_definitions(planet_name) + #defs.get_output_definitions(planet_name), planet_name .. " starter anchors should match default lines")
  end
end)

run_test("Nauvis defaults remain on the legacy path", function()
  settings.global = {}
  local config = planet_config.get("nauvis")

  assert_equal(config.square_size, 7, "Nauvis should keep the original default square size")
  assert_equal(config.floor_tile_name, nil, "Nauvis should keep using the configurable legacy floor")
  assert_equal(resource_names(defs.get_input_definitions("nauvis")), "coal,copper-ore,crude-oil,iron-ore,stone,uranium-ore,water,wood")
  assert_equal(resource_names(defs.get_output_definitions("nauvis")), "sulfuric-acid")
end)

run_test("anchor presentation maps item and fluid ingress/egress behavior", function()
  assert_equal(defs.get_anchor_presentation("ingress", "item"), "underground-belt-inward")
  assert_equal(defs.get_anchor_presentation("egress", "item"), "underground-belt-outward")
  assert_equal(defs.get_anchor_presentation("ingress", "fluid"), "offshore-pump")
  assert_equal(defs.get_anchor_presentation("egress", "fluid"), "underground-pipe")
end)

run_test("Gleba ingresses and egresses use normal item-anchor cadence", function()
  local inserted = {}
  local removed = {}
  local function entity()
    return {
      valid = true,
      get_transport_line = function()
        return {
          can_insert_at_back = function() return true end,
          insert_at_back = function(stack) inserted[stack.name] = (inserted[stack.name] or 0) + stack.count end,
          remove_item = function(stack) removed[stack.name] = (removed[stack.name] or 0) + stack.count; return stack.count end
        }
      end
    }
  end

  storage = {
    bootstrap = {square_size = 7, surface_name = "nauvis", ingress_tier = 1},
    planets = {gleba = {square_size = 17, surface_name = "gleba", starter_anchors = {anchors = {
      {resource = "yumako", kind = "item", flow = "ingress", position = {x = 0, y = 9}, entity = entity(), item_progress = {0, 0}},
      {resource = "yumako-seed", kind = "item", flow = "egress", position = {x = 0, y = 9}, entity = entity(), item_progress = {0, 0}}
    }}}}
  }

  for _ = 1, defs.ITEM_ANCHOR_INTERVAL_TICKS do
    ingress_runtime.pump_planet_starter_anchors()
  end

  assert_equal(removed["yumako-seed"], 1, "seed egress should drain once per yellow interval")
  assert_equal(inserted.yumako, 1, "fruit ingress should emit at the configured yellow interval")
end)

run_test("void item destruction applies across supported planets", function()
  for _, planet_name in ipairs({"nauvis", "vulcanus", "fulgora", "gleba", "aquilo"}) do
    storage.bootstrap = {square_size = 7, surface_name = "nauvis", ingress_tier = 1}
    storage.planets = {}
    local destroyed = false
    local entity = {
      valid = true,
      type = "item-entity",
      surface = {name = planet_name, get_tile = function() return {name = "out-of-map"} end},
      position = {x = 20, y = 0},
      destroy = function() destroyed = true end
    }

    assert_equal(void_item_runtime.destroy_if_void_item({entity = entity}), true, planet_name .. " void item should be destroyed")
    assert_equal(destroyed, true, planet_name .. " destroy should be called")
  end
end)
