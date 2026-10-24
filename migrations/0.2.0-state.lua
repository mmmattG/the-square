-- 0.2.0 trimmed each Planet's stored state down to what cannot be derived, renamed
-- `starter_anchors` to `managed_lines`, and stopped caching the researched Managed
-- Line tier. Self-contained on purpose: migrations must not depend on lib/ modules
-- that later versions are free to change. Safe to run more than once.
local NAUVIS_DEFAULT_SQUARE_SIZE = 7
local MAX_TIER_LEVEL = 5

local DROPPED_PLANET_FIELDS = {
  "name",
  "surface_name",
  "surface_size",
  "floor_tile_name",
  "ingress_tier",
  "egress_tier",
  "expansions_completed",
  "growth_progress",
  "expansion_speed_research_levels"
}

local function clamp_tier_level(tier_level)
  return math.max(1, math.min(MAX_TIER_LEVEL, tier_level or 1))
end

-- Placed lines without their own tier used to take their Anchor entity from the
-- cached researched tier. Give them that tier so the same entity stays in place.
local function migrate_line(anchor, cached_tiers)
  anchor.input_budget_active = nil

  if anchor.tier_level ~= nil or not (anchor.kind and anchor.position and anchor.resource) then
    return
  end

  if anchor.kind == "fluid" then
    anchor.tier_level = 1
  elseif anchor.flow == "egress" then
    anchor.tier_level = clamp_tier_level(cached_tiers.egress or cached_tiers.ingress)
  else
    anchor.tier_level = clamp_tier_level(cached_tiers.ingress)
  end
end

local function migrate_planet(planet_name, planet, cached_tiers, get_starting_square_size)
  planet.managed_lines = planet.managed_lines or planet.starter_anchors
  planet.starter_anchors = nil

  if planet.managed_lines then
    planet.managed_lines.layout_version = nil

    for _, anchor in ipairs(planet.managed_lines.anchors or {}) do
      migrate_line(anchor, cached_tiers)
    end
  end

  planet.expansion_research_levels = planet.expansion_research_levels or planet.expansions_completed or 0
  planet.square_position = planet.square_position or {x = 0, y = 0}
  planet.square_size = planet.square_size or get_starting_square_size(planet_name)

  -- Older versions gave other Planets Nauvis's default size before they had their own.
  if planet_name ~= "nauvis"
    and planet.square_size == NAUVIS_DEFAULT_SQUARE_SIZE
    and planet.expansion_research_levels == 0
  then
    planet.square_size = get_starting_square_size(planet_name)
  end

  for _, field in ipairs(DROPPED_PLANET_FIELDS) do
    planet[field] = nil
  end
end

local function migrate(planets, get_starting_square_size)
  local nauvis = planets.nauvis or {}
  local cached_tiers = {ingress = nauvis.ingress_tier, egress = nauvis.egress_tier}

  for planet_name, planet in pairs(planets) do
    migrate_planet(planet_name, planet, cached_tiers, get_starting_square_size)
  end
end

if storage.planets then
  migrate(storage.planets, function(planet_name)
    return settings.startup["the-square-" .. planet_name .. "-starting-square-size"].value
  end)
end
