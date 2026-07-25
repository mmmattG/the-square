package.path = "./?.lua;./?/init.lua;" .. package.path

defines = {direction = {south = 1, west = 2, north = 3, east = 4}}
settings = {global = {}, startup = {}}

local migration = require("lib.biter_managed_line_migration")
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

run_test("obsolete placed biter lines become generic stashed lines and clear their budget", function()
  local destroyed = 0
  local anchor_set = {
    biter_egg_budget = 450,
    anchors = {
      {
        resource = "biter-egg",
        kind = "item",
        flow = "ingress",
        tier_level = 3,
        side = "north",
        position = {x = 0, y = -5},
        entity = {
          valid = true,
          destroy = function()
            destroyed = destroyed + 1
          end
        }
      },
      {
        resource = "bioflux",
        kind = "item",
        flow = "egress",
        tier_level = 1
      },
      {
        resource = "iron-ore",
        kind = "item",
        flow = "ingress",
        tier_level = 1,
        side = "south",
        position = {x = 0, y = 5}
      }
    }
  }

  local refunds = migration.migrate_anchor_set(anchor_set)

  assert_equal(#refunds, 1, "only the placed obsolete line needs a new inventory item")
  assert_equal(refunds[1], defs.get_generic_anchor_item_name_for_tier("item", "ingress", 3))
  assert_equal(destroyed, 1)
  assert_equal(anchor_set.biter_egg_budget, nil)

  local egg_line = anchor_set.anchors[1]
  assert_equal(egg_line.resource, nil)
  assert_equal(egg_line.position, nil)
  assert_equal(egg_line.side, nil)
  assert_equal(egg_line.item_name, defs.get_generic_anchor_item_name_for_tier("item", "ingress", 3))

  local bioflux_line = anchor_set.anchors[2]
  assert_equal(bioflux_line.resource, nil)
  assert_equal(bioflux_line.position, nil)
  assert_equal(bioflux_line.item_name, defs.get_generic_anchor_item_name_for_tier("item", "egress", 1))

  assert_equal(anchor_set.anchors[3].resource, "iron-ore", "unrelated Managed Lines must be preserved")
  assert_equal(anchor_set.anchors[3].position.y, 5)
end)

run_test("migration removes a placed line from the surface when its saved entity reference is stale", function()
  local destroyed = 0
  local anchor_set = {
    anchors = {
      {
        resource = "bioflux",
        kind = "item",
        flow = "egress",
        tier_level = 1,
        side = "south",
        position = {x = 0, y = 5}
      }
    }
  }
  local surface = {
    find_entities_filtered = function(options)
      assert_equal(options.position.y, 5)
      return {
        {
          valid = true,
          name = defs.get_egress_entity_name("bioflux", 1),
          destroy = function()
            destroyed = destroyed + 1
          end
        }
      }
    end
  }

  migration.migrate_anchor_set(anchor_set, surface)

  assert_equal(destroyed, 1)
  assert_equal(anchor_set.anchors[1].position, nil)
end)

run_test("storage migration refunds placed lines once and preserves completed research", function()
  local inserted = {}
  local anchor_set = {
    biter_egg_budget = 900,
    anchors = {
      {
        resource = "biter-egg",
        kind = "item",
        flow = "ingress",
        tier_level = 1,
        side = "north",
        position = {x = 0, y = -5}
      }
    }
  }

  storage = {
    bootstrap = {
      starter_anchors = anchor_set,
      biter_egg_handling_granted_from_ingress = true
    }
  }
  game = {
    forces = {
      player = {
        technologies = {
          ["biter-egg-handling"] = {researched = true}
        }
      }
    },
    players = {
      {
        valid = true,
        insert = function(stack)
          inserted[stack.name] = (inserted[stack.name] or 0) + stack.count
          return stack.count
        end
      }
    },
    surfaces = {
      nauvis = {
        find_entities_filtered = function()
          return {}
        end
      }
    }
  }

  assert_equal(migration.migrate_storage(), 1)
  assert_equal(inserted[defs.get_generic_anchor_item_name_for_tier("item", "ingress", 1)], 1)
  assert_equal(storage.bootstrap.biter_egg_handling_granted_from_ingress, nil)
  assert_equal(storage.biter_managed_line_migration_version, migration.VERSION)
  assert_equal(game.forces.player.technologies["biter-egg-handling"].researched, true)

  assert_equal(migration.migrate_storage(), 0, "migration should be idempotent")
  assert_equal(inserted[defs.get_generic_anchor_item_name_for_tier("item", "ingress", 1)], 1)
end)
