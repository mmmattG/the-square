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
    ["the-square-starting-square-size"] = {value = 9},
    ["the-square-expansion-tiles-per-research"] = {value = 2},
    ["the-square-background-tile"] = {value = "grass-1"}
  }
}

local planet_instance = require("lib.planet_instance")

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

run_test("Nauvis Planet Instance preserves existing bootstrap defaults", function()
  storage = {
    bootstrap = {
      square_size = 9
    }
  }

  local nauvis = planet_instance.ensure_nauvis()

  assert_equal(nauvis:get_square_size(), 9, "Planet Progression should expose Square size")
  assert_equal(nauvis:get_surface_name(), "nauvis", "Nauvis adapter should use the normal starting surface")
  assert_equal(nauvis:get_surface_size(), 11, "surface size should include the managed void ring")
  assert_equal(nauvis:get_expansion_points(), 0, "Expansion Points should default to zero")
  assert_equal(nauvis:get_completed_square_expansion_levels(), 0, "Square Expansion levels should default to zero")
  assert_equal(storage.bootstrap.growth_progress, nil, "removed legacy growth state should stay cleared")
end)

run_test("Nauvis Planet Instance migrates legacy bootstrap surface saves", function()
  storage = {
    bootstrap = {
      square_size = 9,
      surface_name = "fes-bootstrap"
    },
    starter_anchors = {
      anchors = {
        {entity = {valid = true}}
      }
    }
  }

  local nauvis = planet_instance.ensure_nauvis()

  assert_equal(nauvis:get_surface_name(), "nauvis", "old saves should move their Planet Instance back to Nauvis")
  assert_equal(storage.bootstrap.surface_name, "nauvis", "legacy storage should be migrated in place")
  assert_equal(storage.starter_anchors.anchors[1].entity, nil, "legacy surface entity refs should be rebuilt on Nauvis")
end)

run_test("Nauvis Planet Instance owns local Expansion Points", function()
  storage = {
    bootstrap = {
      square_size = 9,
      expansion_points = 4
    }
  }

  local nauvis = planet_instance.ensure_nauvis()
  nauvis:add_expansion_points(6)

  assert_equal(nauvis:get_expansion_points(), 10, "Expansion Points should be added to the Planet Instance")
  assert_equal(storage.bootstrap.expansion_points, 10, "adapter should keep the existing alpha storage shape updated")
end)
