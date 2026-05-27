package.path = "./?.lua;./?/init.lua;" .. package.path

defines = {direction = {south = 1, west = 2, north = 3, east = 4}}
settings = {global = {}, startup = {}}

local defs = require("lib.runtime_defs")
local bootstrap_runtime = require("lib.bootstrap_runtime")

local function assert_equal(actual, expected, message)
  if actual ~= expected then
    error((message or "values differ") .. "\nexpected: " .. tostring(expected) .. "\nactual: " .. tostring(actual))
  end
end

local function names(definitions)
  local result = {}
  for _, definition in ipairs(definitions) do
    result[#result + 1] = definition.resource
  end
  table.sort(result)
  return table.concat(result, ",")
end

local function run_test(name, fn)
  local ok, err = pcall(fn)
  if not ok then
    io.stderr:write("FAIL " .. name .. "\n" .. err .. "\n")
    os.exit(1)
  end
  io.stdout:write("PASS " .. name .. "\n")
end

run_test("planet starter resource matrix is planet-local", function()
  assert_equal(names(defs.get_input_definitions("nauvis")), "biter-egg,coal,copper-ore,crude-oil,iron-ore,stone,uranium-ore,water,wood")
  assert_equal(names(defs.get_output_definitions("nauvis")), "bioflux,sulfuric-acid")
  assert_equal(names(defs.get_input_definitions("vulcanus")), "calcite,coal,lava,sulfuric-acid,tungsten-ore")
  assert_equal(names(defs.get_output_definitions("vulcanus")), "")
  assert_equal(names(defs.get_input_definitions("fulgora")), "heavy-oil,scrap")
  assert_equal(names(defs.get_output_definitions("fulgora")), "")
  assert_equal(names(defs.get_input_definitions("gleba")), "jellynut,stone,water,yumako")
  assert_equal(names(defs.get_output_definitions("gleba")), "jellynut-seed,yumako-seed")
  assert_equal(names(defs.get_input_definitions("aquilo")), "ammoniacal-solution,crude-oil,fluorine,lithium-brine")
  assert_equal(names(defs.get_output_definitions("aquilo")), "")
  assert_equal(defs.get_input_definition("stone", "gleba").starter_side ~= nil, true)
  assert_equal(defs.get_input_definition("stone", "nauvis").starter_side, "south")
end)

run_test("overlapping resource names keep Planet-local behavior", function()
  local gleba_stone = defs.get_input_definition("stone", "gleba")
  local nauvis_stone = defs.get_input_definition("stone", "nauvis")

  assert_equal(gleba_stone.resource, nauvis_stone.resource)
  assert_equal(gleba_stone == nauvis_stone, false, "shared resource names should not share definition tables")

  gleba_stone.prerequisite_resource = "gleba-local-test"
  assert_equal(nauvis_stone.prerequisite_resource, nil, "mutating Gleba stone must not change Nauvis stone")
  gleba_stone.prerequisite_resource = nil
end)

run_test("starter config includes Fulgora placed entities and Gleba seed chest", function()
  local planet_config = require("lib.planet_config")
  local fulgora_entities = planet_config.get_starter_entities("fulgora")
  local gleba_entities = planet_config.get_starter_entities("gleba")

  assert_equal(#fulgora_entities, 5, "Fulgora should have one recycler and four rods")
  assert_equal(fulgora_entities[1].name, "recycler", "Fulgora should spawn a recycler")
  assert_equal(fulgora_entities[2].name, "lightning-rod", "Fulgora should spawn lightning rods")
  assert_equal(#gleba_entities, 1, "Gleba should have one starter chest")
  assert_equal(gleba_entities[1].inventory.articles[1].name, "yumako-seed", "Gleba chest should contain yumako seeds")
  assert_equal(gleba_entities[1].inventory.articles[1].count, 50, "Gleba chest should contain 50 yumako seeds")
  assert_equal(gleba_entities[1].inventory.articles[2].name, "jellynut-seed", "Gleba chest should contain jellynut seeds")
  assert_equal(gleba_entities[1].inventory.articles[2].count, 50, "Gleba chest should contain 50 jellynut seeds")
  assert_equal(#planet_config.get_starter_entities("nauvis"), 0, "Nauvis should not receive Space Age starter entities")
end)

run_test("starter layout includes planet-local Gleba seed egresses", function()
  local anchors = bootstrap_runtime.build_starter_anchor_layout(17, "gleba")
  local seen = {}
  for _, anchor in ipairs(anchors) do
    seen[anchor.flow .. ":" .. anchor.resource] = true
  end
  assert_equal(seen["ingress:yumako"], true)
  assert_equal(seen["ingress:jellynut"], true)
  assert_equal(seen["egress:yumako-seed"], true)
  assert_equal(seen["egress:jellynut-seed"], true)
end)
