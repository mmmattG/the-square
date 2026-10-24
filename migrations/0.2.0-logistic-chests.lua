-- 0.2.0 removed the "Enable logistic network automation" map setting.
-- Saves that had it turned off still have these chest recipes disabled by script,
-- so re-enable each one that a researched technology unlocks.
local CHEST_RECIPE_NAMES = {
  ["active-provider-chest"] = true,
  ["buffer-chest"] = true,
  ["requester-chest"] = true,
  ["storage-chest"] = true
}

for _, force in pairs(game.forces) do
  for _, technology in pairs(force.technologies) do
    if technology.researched then
      for _, effect in pairs(technology.prototype.effects) do
        local recipe = effect.type == "unlock-recipe" and CHEST_RECIPE_NAMES[effect.recipe] and force.recipes[effect.recipe]

        if recipe then
          recipe.enabled = true
        end
      end
    end
  end
end
