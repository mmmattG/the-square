package.path = "./?.lua;./?/init.lua;" .. package.path

defines = {direction = {south = 1, west = 2, north = 3, east = 4}}
settings = {global = {}, startup = {}}

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

run_test("0.1.4 removes obsolete biter Managed Lines and their runtime state", function()
  local destroyed = 0
  local anchor_set = {
    biter_egg_budget = 900,
    anchors = {
      {
        resource = "biter-egg",
        kind = "item",
        flow = "ingress",
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
        side = "south",
        position = {x = 0, y = 5}
      },
      {
        resource = "iron-ore",
        kind = "item",
        flow = "ingress",
        side = "east",
        position = {x = 5, y = 0}
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
    surfaces = {
      nauvis = {
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
    }
  }

  dofile("migrations/0.1.4.lua")

  assert_equal(destroyed, 2)
  assert_equal(#anchor_set.anchors, 1)
  assert_equal(anchor_set.anchors[1].resource, "iron-ore")
  assert_equal(anchor_set.biter_egg_budget, nil)
  assert_equal(storage.bootstrap.biter_egg_handling_granted_from_ingress, nil)
end)

run_test("0.1.4 is safe when the mod has no existing state", function()
  storage = {}
  game = {surfaces = {}}

  dofile("migrations/0.1.4.lua")

  assert_equal(next(storage), nil)
end)
