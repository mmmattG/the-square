-- Hand-grown egg recipes (Space Age only). The Square has no enemy nests to capture
-- biter eggs from and no space on Gleba to start a pentapod egg loop, so the
-- character can grow a first batch of each by hand.
if not mods["space-age"] then
  return
end

local recipes = {
  {
    name = "the-square-biter-egg-bootstrap",
    egg = "biter-egg",
    egg_count = 5,
    ingredients = {{type = "item", name = "bioflux", amount = 1}},
    energy_required = 10,
    order = "c[eggs]-a[biter-egg]-a[bootstrap]",
    pressure = 1000, -- Nauvis only
    unlock_technology = "captivity"
  },
  {
    name = "the-square-pentapod-egg-bootstrap",
    egg = "pentapod-egg",
    egg_count = 1,
    ingredients = {{type = "item", name = "nutrients", amount = 30}},
    energy_required = 15,
    order = "d[organic-processing]-a[pentapod-egg]-a[bootstrap]",
    pressure = 2000, -- Gleba only
    unlock_technology = "biochamber"
  }
}

for _, recipe in ipairs(recipes) do
  data:extend({
    {
      type = "recipe",
      name = recipe.name,
      icon = "__space-age__/graphics/icons/" .. recipe.egg .. ".png",
      -- Only the character has the built-in "hand-crafting" category, so machines cannot make eggs.
      categories = {"hand-crafting"},
      subgroup = "agriculture-processes",
      order = recipe.order,
      enabled = false,
      auto_recycle = false,
      allow_decomposition = false,
      energy_required = recipe.energy_required,
      ingredients = recipe.ingredients,
      results = {
        {type = "item", name = recipe.egg, amount = recipe.egg_count, reset_freshness_on_craft = true}
      },
      surface_conditions = {
        {property = "pressure", min = recipe.pressure, max = recipe.pressure}
      }
    }
  })

  local technology = data.raw.technology[recipe.unlock_technology]
  technology.effects = technology.effects or {}
  table.insert(technology.effects, {type = "unlock-recipe", recipe = recipe.name})
end

-- Biter egg handling is normally triggered by capturing a nest. Trigger it by
-- growing the first eggs instead.
data.raw.technology["biter-egg-handling"].research_trigger = {
  type = "craft-item",
  item = "biter-egg",
  count = 5
}
