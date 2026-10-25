-- Tier Upgrade research and the throughput it gives each line.
local definitions = require("lib.managed_line_definitions")

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

function managed_line_tiers.is_upgrade_technology(technology_name)
  for _, upgrade in ipairs(definitions.UPGRADE_TECHNOLOGIES) do
    if upgrade.name == technology_name then
      return true
    end
  end

  return false
end

-- A line's purchased tier sets its throughput, except that yellow lines gain their
-- second lane once the force has researched tier 2 (dual lane) or higher.
function managed_line_tiers.get_throughput(anchor, researched_tier_level)
  local tier_level = anchor.tier_level

  if tier_level == 1 and researched_tier_level >= 2 then
    tier_level = 2
  end

  return definitions.get_throughput(tier_level)
end

return managed_line_tiers
