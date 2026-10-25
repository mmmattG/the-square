-- Square Expansion research for every Planet, and the Tier Upgrade research.
local definitions = require("lib.managed_line_definitions")
local expansion_research = require("lib.expansion_research")
local mod_settings = require("lib.mod_settings")
local planet_catalog = require("lib.planet_catalog")

local function build_square_expansion_technology(options)
  return {
    type = "technology",
    name = options.name,
    localised_name = options.localised_name or {"technology-name.the-square-square-expansion"},
    localised_description = options.localised_description or {"technology-description.the-square-square-expansion"},
    icon = options.icon or "__base__/graphics/icons/landfill.png",
    icon_size = 64,
    order = options.order,
    upgrade = true,
    prerequisites = options.prerequisites,
    max_level = options.max_level,
    unit = {
      ingredients = options.ingredients,
      time = 30,
      count = options.count,
      count_formula = options.count_formula
    },
    effects = {
      {
        type = "nothing",
        effect_description = {"technology-effect.the-square-square-expansion"}
      }
    }
  }
end

-- Nauvis: forty finite levels, then one infinite technology. The costs assume the
-- default starting size, because research is built before any save exists.
local function build_nauvis_expansion_technologies()
  local starting_square_size = expansion_research.DEFAULT_STARTING_SQUARE_SIZE
  local tiles_per_research = mod_settings.get_expansion_tiles_per_research()
  local technologies = {}

  for level = 1, expansion_research.FINAL_FINITE_LEVEL do
    technologies[#technologies + 1] = build_square_expansion_technology({
      name = expansion_research.get_technology_name(level),
      order = string.format("c-a[square-expansion]-%04d", level),
      prerequisites = level > 1 and {expansion_research.get_technology_name(level - 1)} or nil,
      ingredients = expansion_research.get_band(level).ingredients,
      count = expansion_research.get_research_unit_count(starting_square_size, tiles_per_research, level)
    })
  end

  local infinite_level = expansion_research.INFINITE_START_LEVEL

  technologies[#technologies + 1] = build_square_expansion_technology({
    name = expansion_research.get_technology_name(infinite_level),
    order = string.format("c-a[square-expansion]-%04d", infinite_level),
    prerequisites = {expansion_research.get_technology_name(infinite_level - 1)},
    ingredients = expansion_research.get_band(infinite_level).ingredients,
    count_formula = expansion_research.get_infinite_research_unit_formula(starting_square_size, tiles_per_research),
    max_level = "infinite"
  })

  return technologies
end

local function round_to_nearest_50(value)
  return math.max(50, math.floor((value + 25) / 50) * 50)
end

-- Other Planets: one infinite technology paid in that Planet's science pack,
-- costing about ten packs per tile for the first Ring.
local function build_planet_expansion_technology(planet_name)
  local planet = planet_catalog.get(planet_name)
  local science_pack = planet.expansion_research.science_pack
  -- Factorio 2.1 made science packs plain items, but mods can still define tool-type packs.
  -- data.raw.tool is nil when no tool prototypes exist at all.
  local tools = data.raw.tool or {}

  if not (data.raw.item[science_pack] or tools[science_pack]) then
    return nil
  end

  local starting_square_size = mod_settings.get_starting_square_size(planet_name)
  local first_ring_tiles = expansion_research.get_tiles_unlocked_for_level(starting_square_size, 1)
  local approximate_first_cost = round_to_nearest_50(first_ring_tiles * 10)
  local packs_per_tile = math.max(1, math.floor((approximate_first_cost / first_ring_tiles) + 0.5))

  return build_square_expansion_technology({
    name = expansion_research.get_planet_technology_name(planet_name),
    localised_name = {"technology-name.the-square-planet-square-expansion", planet.label},
    localised_description = {"technology-description.the-square-planet-square-expansion", planet.label},
    icon = planet.expansion_research.icon,
    order = planet.expansion_research.order,
    -- Each Space Age science pack is unlocked by a technology of the same name.
    prerequisites = data.raw.technology[science_pack] and {science_pack} or nil,
    ingredients = {{science_pack, 1}},
    count_formula = expansion_research.get_infinite_research_unit_formula(starting_square_size, 1 / packs_per_tile),
    max_level = "infinite"
  })
end

local function build_upgrade_icons(belt_icon)
  return {
    {icon = belt_icon, icon_size = 64, scale = 0.8, shift = {-8, 0}},
    {icon = "__base__/graphics/icons/underground-belt.png", icon_size = 64, scale = 0.45, shift = {14, -12}},
    {icon = "__base__/graphics/icons/underground-belt.png", icon_size = 64, scale = 0.45, shift = {14, 12}}
  }
end

local function build_upgrade_technology(upgrade, previous_upgrade)
  local prerequisite = data.raw.technology[upgrade.prerequisite]

  if not (prerequisite and prerequisite.unit) then
    error("Missing technology unit for " .. upgrade.prerequisite)
  end

  local technology = {
    type = "technology",
    name = upgrade.name,
    localised_name = {"technology-name." .. upgrade.name},
    localised_description = {"technology-description." .. upgrade.name},
    icons = build_upgrade_icons(upgrade.belt_icon),
    order = "c-b[" .. upgrade.name .. "]",
    prerequisites = {upgrade.prerequisite, previous_upgrade and previous_upgrade.name},
    unit = table.deepcopy(prerequisite.unit),
    effects = {
      {
        type = "nothing",
        effect_description = {"technology-effect." .. upgrade.name}
      }
    }
  }

  if upgrade.unlocks_item_tier then
    for _, flow in ipairs(definitions.FLOWS) do
      technology.effects[#technology.effects + 1] = {
        type = "unlock-recipe",
        recipe = definitions.get_item_name("item", flow, upgrade.unlocks_item_tier)
      }
    end
  end

  return technology
end

local technologies = build_nauvis_expansion_technologies()

for _, planet_name in ipairs(planet_catalog.SUPPORTED_PLANETS) do
  if planet_catalog.get(planet_name).expansion_research then
    technologies[#technologies + 1] = build_planet_expansion_technology(planet_name)
  end
end

local previous_upgrade

for _, upgrade in ipairs(definitions.UPGRADE_TECHNOLOGIES) do
  if not upgrade.space_age_only or mods["space-age"] then
    technologies[#technologies + 1] = build_upgrade_technology(upgrade, previous_upgrade)
    previous_upgrade = upgrade
  end
end

data:extend(technologies)
