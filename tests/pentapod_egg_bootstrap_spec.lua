package.path = "./?.lua;./?/init.lua;" .. package.path

local bootstrap = require("lib.pentapod_egg_bootstrap")

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
        biochamber = {effects = {{type = "unlock-recipe", recipe = "biochamber"}}}
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

run_test("bootstrap prototypes are gated behind Space Age", function()
  local data_stage = build_data_stage()

  assert_equal(bootstrap.install(data_stage, {}), false)
  assert_equal(data_stage.raw.recipe, nil, "base-only startup must not define the bootstrap recipe")
  assert_equal(data_stage.raw["recipe-category"], nil, "base-only startup must not define its category")
  assert_equal(contains(data_stage.raw.character.character.crafting_categories, bootstrap.CATEGORY_NAME), false)
  assert_equal(has_unlock(data_stage.raw.technology.biochamber, bootstrap.RECIPE_NAME), false)
end)

run_test("Space Age installs a character-only bootstrap recipe", function()
  local data_stage = build_data_stage()

  assert_equal(bootstrap.install(data_stage, {["space-age"] = "2.0.66"}), true)

  local recipe = data_stage.raw.recipe[bootstrap.RECIPE_NAME]
  assert_true(data_stage.raw["recipe-category"][bootstrap.CATEGORY_NAME], "dedicated recipe category should exist")
  assert_equal(recipe.category, bootstrap.CATEGORY_NAME)
  assert_equal(recipe.enabled, false)
  assert_equal(recipe.energy_required, 15)
  assert_equal(recipe.reset_freshness_on_craft, true)
  assert_equal(#recipe.ingredients, 1)
  assert_equal(recipe.ingredients[1].name, "nutrients")
  assert_equal(recipe.ingredients[1].amount, 30)
  assert_equal(recipe.results[1].name, "pentapod-egg")
  assert_equal(recipe.results[1].amount, 1)
  assert_equal(#recipe.surface_conditions, 1)
  assert_equal(recipe.surface_conditions[1].property, "pressure")
  assert_equal(recipe.surface_conditions[1].min, bootstrap.GLEBA_PRESSURE)
  assert_equal(recipe.surface_conditions[1].max, bootstrap.GLEBA_PRESSURE)

  for _, ingredient in ipairs(recipe.ingredients) do
    assert_equal(ingredient.type, "item", "bootstrap ingredients must remain hand-craftable items")
    assert_true(ingredient.name ~= "pentapod-egg", "bootstrap must not require an existing egg")
  end

  assert_equal(contains(data_stage.raw.character.character.crafting_categories, bootstrap.CATEGORY_NAME), true)
  for machine_name, machine in pairs(data_stage.raw["assembling-machine"]) do
    assert_equal(
      contains(machine.crafting_categories, bootstrap.CATEGORY_NAME),
      false,
      machine_name .. " must not support the hand-crafting category"
    )
  end
  assert_equal(has_unlock(data_stage.raw.technology.biochamber, bootstrap.RECIPE_NAME), true)
end)
