-- Managed Line Upgrade research and the throughput it gives each line.
local definitions = require("lib.managed_line_definitions")
local planet_state = require("lib.planet_state")

local managed_line_tiers = {}

-- The highest tier level the force has researched (1 with no upgrades).
function managed_line_tiers.get_researched_tier_level(force)
  local tier_level = 1

  for _, upgrade in ipairs(definitions.UPGRADE_TECHNOLOGIES) do
    local technology = force.technologies[upgrade.name]

    if technology and technology.researched and upgrade.tier_level > tier_level then
      tier_level = upgrade.tier_level
    end
  end

  return tier_level
end

-- The item tiers a player may choose in Anchor Slot Configuration.
function managed_line_tiers.get_researched_item_tiers(force)
  local researched_tier_level = managed_line_tiers.get_researched_tier_level(force)
  local tiers = {}

  for _, tier in ipairs(definitions.ITEM_TIERS) do
    if tier.tier_level <= researched_tier_level then
      tiers[#tiers + 1] = tier
    end
  end

  return tiers
end

local function get_tier_state()
  return planet_state.get("nauvis"):get_state()
end

-- Copies the researched tier into storage and returns true when it changed.
function managed_line_tiers.sync_from_research(force)
  local tier_state = get_tier_state()
  local tier_level = managed_line_tiers.get_researched_tier_level(force)

  if tier_state.ingress_tier == tier_level and tier_state.egress_tier == tier_level then
    return false
  end

  tier_state.ingress_tier = tier_level
  tier_state.egress_tier = tier_level

  return true
end

-- A line's purchased tier sets its throughput, except that yellow lines gain their
-- second lane from the dual-lane research.
function managed_line_tiers.get_throughput(anchor)
  local tier_level = anchor.tier_level or 1

  -- Read storage directly: the pump calls this for every line on every tick.
  if tier_level == 1 and (storage.planets.nauvis.ingress_tier or 1) >= 2 then
    tier_level = 2
  end

  return definitions.get_throughput(tier_level)
end

return managed_line_tiers
