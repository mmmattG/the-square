package.path = "./?.lua;./?/init.lua;" .. package.path

local helper = require("tests.helper")
local assert_equal = helper.assert_equal
local run_test = helper.run_test

local definitions = require("lib.managed_line_definitions")

run_test("item and entity names follow one pattern for every tier", function()
  assert_equal(definitions.get_item_name("item", "ingress", "yellow"), "the-square-item-ingress-anchor", "yellow items have no suffix")
  assert_equal(definitions.get_item_name("item", "egress", "red"), "the-square-item-egress-anchor-red", "higher tiers add their key")
  assert_equal(definitions.get_item_name("fluid", "ingress", "red"), "the-square-fluid-ingress-anchor", "fluid lines have no tiers")
  assert_equal(definitions.get_entity_name("item", "ingress", "turbo"), "the-square-item-ingress-managed-anchor-turbo", "entities use the managed-anchor name")
  assert_equal(definitions.get_entity_name("fluid", "egress", "yellow"), "the-square-fluid-egress-managed-anchor", "fluid entity name")
end)

run_test("every placed Anchor entity counts as managed, and nothing else does", function()
  local count = 0

  definitions.each_line_item(function(kind, flow, tier)
    count = count + 1
    assert_equal(definitions.is_managed_entity_name(definitions.get_entity_name(kind, flow, tier.key)), true, kind .. " " .. flow .. " " .. tier.key)
  end)

  assert_equal(count, 10, "four item tiers for two flows, plus yellow fluid ingress and egress")
  assert_equal(definitions.is_managed_entity_name(definitions.SLOT_PROXY_NAME), true, "slot markers are managed")
  assert_equal(definitions.is_managed_entity_name("underground-belt"), false, "vanilla entities are not managed")
  assert_equal(definitions.is_managed_entity_name("the-square-item-ingress-anchor"), false, "item names are not entity names")
end)

run_test("tier levels without their own item use yellow, and throughput rises with tier", function()
  assert_equal(definitions.get_item_tier_for_level(1).key, "yellow", "level 1 is yellow")
  assert_equal(definitions.get_item_tier_for_level(2).key, "yellow", "level 2 is a dual-lane yellow line")
  assert_equal(definitions.get_item_tier_for_level(3).key, "red", "level 3 is red")
  assert_equal(definitions.get_throughput(1).item_lane_counts[2], 0, "a plain yellow line uses one lane")
  assert_equal(definitions.get_throughput(2).item_lane_counts[2], 1, "dual-lane yellow uses both lanes")

  local previous = 0

  for tier_level = 1, 5 do
    local throughput = definitions.get_throughput(tier_level)
    assert_equal(throughput.fluid_amount_per_tick > previous, true, "fluid throughput rises at level " .. tier_level)
    previous = throughput.fluid_amount_per_tick
  end
end)

run_test("each upgrade unlocks an existing item tier and raises the tier level", function()
  local previous_level = 1

  for _, upgrade in ipairs(definitions.UPGRADE_TECHNOLOGIES) do
    assert_equal(upgrade.tier_level > previous_level, true, upgrade.name .. " raises the tier")
    previous_level = upgrade.tier_level

    if upgrade.unlocks_item_tier then
      assert_equal(definitions.get_item_tier(upgrade.unlocks_item_tier).tier_level, upgrade.tier_level, upgrade.name .. " unlocks its own tier")
    end
  end
end)
