local biter_egg_bootstrap = {}

biter_egg_bootstrap.CATEGORY_NAME = "the-square-hand-crafting-biter-egg"
biter_egg_bootstrap.RECIPE_NAME = "the-square-biter-egg-bootstrap"
biter_egg_bootstrap.UNLOCK_TECHNOLOGY_NAME = "captivity"
biter_egg_bootstrap.ENERGY_REQUIRED = 10
biter_egg_bootstrap.NAUVIS_PRESSURE = 1000

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
    name = biter_egg_bootstrap.RECIPE_NAME,
    localised_name = {"recipe-name.the-square-biter-egg-bootstrap"},
    localised_description = {"recipe-description.the-square-biter-egg-bootstrap"},
    icon = "__space-age__/graphics/icons/biter-egg.png",
    category = biter_egg_bootstrap.CATEGORY_NAME,
    subgroup = "agriculture-processes",
    order = "c[eggs]-a[biter-egg]-a[bootstrap]",
    enabled = false,
    auto_recycle = false,
    allow_decomposition = false,
    energy_required = biter_egg_bootstrap.ENERGY_REQUIRED,
    ingredients = {
      {type = "item", name = "bioflux", amount = 1}
    },
    results = {
      {type = "item", name = "biter-egg", amount = 5}
    },
    reset_freshness_on_craft = true,
    surface_conditions = {
      {
        property = "pressure",
        min = biter_egg_bootstrap.NAUVIS_PRESSURE,
        max = biter_egg_bootstrap.NAUVIS_PRESSURE
      }
    }
  }
end

function biter_egg_bootstrap.install(data_stage, active_mods)
  if not (active_mods and active_mods["space-age"]) then
    return false
  end

  data_stage:extend({
    {
      type = "recipe-category",
      name = biter_egg_bootstrap.CATEGORY_NAME
    },
    build_recipe()
  })

  for _, character in pairs(data_stage.raw.character or {}) do
    character.crafting_categories = character.crafting_categories or {}
    append_unique(character.crafting_categories, biter_egg_bootstrap.CATEGORY_NAME)
  end

  local technology = data_stage.raw.technology[biter_egg_bootstrap.UNLOCK_TECHNOLOGY_NAME]
  if technology then
    add_recipe_unlock(technology, biter_egg_bootstrap.RECIPE_NAME)
  end

  local handling_technology = data_stage.raw.technology["biter-egg-handling"]
  if handling_technology then
    handling_technology.research_trigger = {
      type = "craft-item",
      item = "biter-egg",
      count = 5
    }
  end

  return true
end

return biter_egg_bootstrap
