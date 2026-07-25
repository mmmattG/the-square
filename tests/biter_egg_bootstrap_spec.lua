package.path = "./?.lua;./?/init.lua;" .. package.path

local bootstrap = require("lib.biter_egg_bootstrap")

local function assert_equal(actual, expected, message)
  if actual ~= expected then
    error((message or "values differ") .. "\nexpected: " .. tostring(expected) .. "\nactual: " .. tostring(actual))
  end
end

local function assert_true(value, message)
  if not value then
    error(message or "expected a truthy value")
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

local function build_data_stage()
  local data_stage = {
    raw = {
      character = {
        character = {crafting_categories = {"crafting"}}
      },
      ["assembling-machine"] = {
        ["assembling-machine-1"] = {crafting_categories = {"crafting"}},
        biochamber = {crafting_categories = {"organic"}}
      },
      technology = {
        captivity = {effects = {{type = "unlock-recipe", recipe = "capture-robot-rocket"}}},
        ["biter-egg-handling"] = {research_trigger = {type = "capture-spawner"}}
      }
    }
  }

  function data_stage:extend(prototypes)
    for _, prototype in ipairs(prototypes) do
      self.raw[prototype.type] = self.raw[prototype.type] or {}
      self.raw[prototype.type][prototype.name] = prototype
    end
  end

  return data_stage
end

local function contains(values, expected)
  for _, value in ipairs(values or {}) do
    if value == expected then
      return true
    end
  end

  return false
end

local function has_unlock(technology, recipe_name)
  for _, effect in ipairs(technology.effects or {}) do
    if effect.type == "unlock-recipe" and effect.recipe == recipe_name then
      return true
    end
  end

  return false
end

run_test("biter egg bootstrap prototypes are gated behind Space Age", function()
  local data_stage = build_data_stage()

  assert_equal(bootstrap.install(data_stage, {}), false)
  assert_equal(data_stage.raw.recipe, nil)
  assert_equal(data_stage.raw["recipe-category"], nil)
  assert_equal(data_stage.raw.technology["biter-egg-handling"].research_trigger.type, "capture-spawner")
end)

run_test("Space Age installs a Nauvis-only character biter egg recipe at Captivity", function()
  local data_stage = build_data_stage()

  assert_equal(bootstrap.install(data_stage, {["space-age"] = "2.0.66"}), true)

  local recipe = data_stage.raw.recipe[bootstrap.RECIPE_NAME]
  assert_equal(recipe.category, bootstrap.CATEGORY_NAME)
  assert_equal(recipe.enabled, false)
  assert_equal(recipe.energy_required, 10)
  assert_equal(recipe.reset_freshness_on_craft, true)
  assert_equal(#recipe.ingredients, 1)
  assert_equal(recipe.ingredients[1].name, "bioflux")
  assert_equal(recipe.ingredients[1].amount, 1)
  assert_equal(recipe.results[1].name, "biter-egg")
  assert_equal(recipe.results[1].amount, 5)
  assert_equal(#recipe.surface_conditions, 1)
  assert_equal(recipe.surface_conditions[1].property, "pressure")
  assert_equal(recipe.surface_conditions[1].min, 1000)
  assert_equal(recipe.surface_conditions[1].max, 1000)
  assert_equal(contains(data_stage.raw.character.character.crafting_categories, bootstrap.CATEGORY_NAME), true)

  for machine_name, machine in pairs(data_stage.raw["assembling-machine"]) do
    assert_equal(
      contains(machine.crafting_categories, bootstrap.CATEGORY_NAME),
      false,
      machine_name .. " must not support the hand-crafting category"
    )
  end

  assert_equal(has_unlock(data_stage.raw.technology.captivity, bootstrap.RECIPE_NAME), true)
  assert_equal(data_stage.raw.technology["biter-egg-handling"].research_trigger.type, "craft-item")
  assert_equal(data_stage.raw.technology["biter-egg-handling"].research_trigger.item, "biter-egg")
  assert_equal(data_stage.raw.technology["biter-egg-handling"].research_trigger.count, 5)
end)
