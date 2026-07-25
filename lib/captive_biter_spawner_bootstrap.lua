local captive_biter_spawner_bootstrap = {}

captive_biter_spawner_bootstrap.CATEGORY_NAME = "the-square-hand-crafting-captive-biter-spawner"
captive_biter_spawner_bootstrap.RECIPE_NAME = "the-square-captive-biter-spawner-bootstrap"
captive_biter_spawner_bootstrap.UNLOCK_TECHNOLOGY_NAME = "captivity"
captive_biter_spawner_bootstrap.ENERGY_REQUIRED = 30

local function append_unique(values, value)
  for _, existing_value in ipairs(values) do
    if existing_value == value then
      return
    end
  end

  values[#values + 1] = value
end

local function add_recipe_unlock(technology, recipe_name)
  technology.effects = technology.effects or {}

  for _, effect in ipairs(technology.effects) do
    if effect.type == "unlock-recipe" and effect.recipe == recipe_name then
      return
    end
  end

  technology.effects[#technology.effects + 1] = {
    type = "unlock-recipe",
    recipe = recipe_name
  }
end

local function build_recipe()
  return {
    type = "recipe",
    name = captive_biter_spawner_bootstrap.RECIPE_NAME,
    localised_name = {"recipe-name.the-square-captive-biter-spawner-bootstrap"},
    localised_description = {"recipe-description.the-square-captive-biter-spawner-bootstrap"},
    icon = "__space-age__/graphics/icons/captive-biter-spawner.png",
    category = captive_biter_spawner_bootstrap.CATEGORY_NAME,
    subgroup = "agriculture",
    order = "z[biter-nest]-a[bootstrap]",
    enabled = false,
    auto_recycle = false,
    allow_decomposition = false,
    energy_required = captive_biter_spawner_bootstrap.ENERGY_REQUIRED,
    ingredients = {
      {type = "item", name = "capture-robot-rocket", amount = 1},
      {type = "item", name = "bioflux", amount = 100},
      {type = "item", name = "refined-concrete", amount = 25}
    },
    results = {
      {type = "item", name = "captive-biter-spawner", amount = 1}
    },
    reset_freshness_on_craft = true
  }
end

function captive_biter_spawner_bootstrap.install(data_stage, active_mods)
  if not (active_mods and active_mods["space-age"]) then
    return false
  end

  data_stage:extend({
    {
      type = "recipe-category",
      name = captive_biter_spawner_bootstrap.CATEGORY_NAME
    },
    build_recipe()
  })

  for _, character in pairs(data_stage.raw.character or {}) do
    character.crafting_categories = character.crafting_categories or {}
    append_unique(character.crafting_categories, captive_biter_spawner_bootstrap.CATEGORY_NAME)
  end

  local technology = data_stage.raw.technology[captive_biter_spawner_bootstrap.UNLOCK_TECHNOLOGY_NAME]
  if technology then
    add_recipe_unlock(technology, captive_biter_spawner_bootstrap.RECIPE_NAME)
  end

  local handling_technology = data_stage.raw.technology["biter-egg-handling"]
  if handling_technology then
    handling_technology.research_trigger = {
      type = "craft-item",
      item = "captive-biter-spawner",
      count = 1
    }
  end

  return true
end

return captive_biter_spawner_bootstrap
