local pentapod_egg_bootstrap = {}

pentapod_egg_bootstrap.CATEGORY_NAME = "the-square-hand-crafting"
pentapod_egg_bootstrap.RECIPE_NAME = "the-square-pentapod-egg-bootstrap"
pentapod_egg_bootstrap.UNLOCK_TECHNOLOGY_NAME = "biochamber"
pentapod_egg_bootstrap.ENERGY_REQUIRED = 120

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
    name = pentapod_egg_bootstrap.RECIPE_NAME,
    icon = "__space-age__/graphics/icons/pentapod-egg.png",
    category = pentapod_egg_bootstrap.CATEGORY_NAME,
    subgroup = "agriculture-processes",
    order = "d[organic-processing]-a[pentapod-egg]-a[bootstrap]",
    enabled = false,
    auto_recycle = false,
    allow_decomposition = false,
    energy_required = pentapod_egg_bootstrap.ENERGY_REQUIRED,
    ingredients = {
      {type = "item", name = "yumako-mash", amount = 50},
      {type = "item", name = "jelly", amount = 50},
      {type = "item", name = "spoilage", amount = 100}
    },
    results = {
      {type = "item", name = "pentapod-egg", amount = 1}
    },
    reset_freshness_on_craft = true
  }
end

function pentapod_egg_bootstrap.install(data_stage, active_mods)
  if not (active_mods and active_mods["space-age"]) then
    return false
  end

  data_stage:extend({
    {
      type = "recipe-category",
      name = pentapod_egg_bootstrap.CATEGORY_NAME
    },
    build_recipe()
  })

  for _, character in pairs(data_stage.raw.character or {}) do
    character.crafting_categories = character.crafting_categories or {}
    append_unique(character.crafting_categories, pentapod_egg_bootstrap.CATEGORY_NAME)
  end

  local technology = data_stage.raw.technology[pentapod_egg_bootstrap.UNLOCK_TECHNOLOGY_NAME]
  if technology then
    add_recipe_unlock(technology, pentapod_egg_bootstrap.RECIPE_NAME)
  end

  return true
end

return pentapod_egg_bootstrap
