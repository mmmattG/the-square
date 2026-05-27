package.path = "./?.lua;./?/init.lua;" .. package.path

defines = {
  direction = {
    south = 1,
    west = 2,
    north = 3,
    east = 4
  }
}

settings = {
  global = {
    ["the-square-background-tile"] = {value = "grass-1"}
  },
  startup = {
    ["the-square-nauvis-starting-square-size"] = {value = 9},
    ["the-square-expansion-tiles-per-research"] = {value = 2}
  }
}

local defs = require("lib.runtime_defs")

local function assert_equal(actual, expected, message)
  if actual ~= expected then
    error((message or "values differ") .. "\nexpected: " .. tostring(expected) .. "\nactual: " .. tostring(actual))
  end
end

local function run_test(name, fn)
  local ok, err = pcall(fn)

  if not ok then
    io.stderr:write("FAIL " .. name .. "\n" .. err .. "\n")
    os.exit(1)
  end

  io.stdout:write("PASS " .. name .. "\n")
end

local function run_migration()
  dofile("migrations/0.1.3.lua")
end

run_test("0.1.3 migration preserves legacy red and blue ingress anchor tiers", function()
  storage = {
    bootstrap = {
      surface_name = "nauvis",
      ingress_tier = 4
    },
    starter_anchors = {
      anchors = {
        {
          resource = "iron-ore",
          kind = "item",
          flow = "ingress",
          side = "north",
          position = {x = -1, y = -5},
          entity_name = "fes-iron-ore-ingress-anchor-red",
          item_name = "fes-iron-ore-ingress",
          item_progress = {0, 0}
        },
        {
          resource = "copper-ore",
          kind = "item",
          flow = "ingress",
          side = "north",
          position = {x = 1, y = -5},
          entity_name = "fes-copper-ore-ingress-anchor-blue",
          item_name = "fes-copper-ore-ingress",
          item_progress = {0, 0}
        }
      }
    }
  }

  run_migration()

  local red_anchor = storage.starter_anchors.anchors[1]
  local blue_anchor = storage.starter_anchors.anchors[2]

  assert_equal(red_anchor.tier_level, 3, "red legacy ingress should become a red Managed Line")
  assert_equal(
    red_anchor.item_name,
    defs.get_generic_anchor_item_name_for_tier("item", "ingress", 3),
    "red legacy ingress should refund/reconfigure as a red generic item ingress"
  )
  assert_equal(
    red_anchor.entity_name,
    defs.get_ingress_entity_name("iron-ore", 3),
    "red legacy ingress should stay hooked to the red resource anchor entity"
  )

  assert_equal(blue_anchor.tier_level, 4, "blue legacy ingress should become a blue Managed Line")
  assert_equal(
    blue_anchor.item_name,
    defs.get_generic_anchor_item_name_for_tier("item", "ingress", 4),
    "blue legacy ingress should refund/reconfigure as a blue generic item ingress"
  )
  assert_equal(
    blue_anchor.entity_name,
    defs.get_ingress_entity_name("copper-ore", 4),
    "blue legacy ingress should stay hooked to the blue resource anchor entity"
  )
end)

run_test("0.1.3 migration falls back to researched ingress tier for legacy item anchors", function()
  storage = {
    bootstrap = {
      surface_name = "nauvis",
      ingress_tier = 3
    },
    starter_anchors = {
      anchors = {
        {
          resource = "coal",
          kind = "item",
          flow = "ingress",
          side = "south",
          position = {x = -1, y = 5},
          entity_name = "the-square-coal-ingress-anchor",
          item_name = "the-square-coal-ingress",
          item_progress = {0, 0}
        }
      }
    }
  }

  run_migration()

  local anchor = storage.starter_anchors.anchors[1]

  assert_equal(anchor.tier_level, 3, "legacy item ingress without a suffix should inherit the save's ingress tier")
  assert_equal(
    anchor.item_name,
    defs.get_generic_anchor_item_name_for_tier("item", "ingress", 3),
    "fallback tier should select the tiered generic item"
  )
  assert_equal(
    anchor.entity_name,
    defs.get_ingress_entity_name("coal", 3),
    "fallback tier should keep the anchor slot connected to the matching tier entity"
  )
end)

