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
  },
  startup = {
    ["the-square-vulcanus-starting-square-size"] = {value = 11}
  }
}

local planet_config = require("lib.planet_config")
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

run_test("Space Age planet configs default to 17x17 thematic squares", function()
  settings.startup = {}

  local expected_floor_tiles = {
    vulcanus = "volcanic-ash-soil",
    fulgora = "fulgoran-dust",
    gleba = "lowland-cream-cauliflower",
    aquilo = "snow-flat"
  }

  for planet_name, floor_tile_name in pairs(expected_floor_tiles) do
    local config = planet_config.get(planet_name)

    assert_equal(config.square_size, 17, planet_name .. " should default to a 17x17 starting square")
    assert_equal(config.surface_size, 19, planet_name .. " surface should include the managed void ring")
    assert_equal(config.floor_tile_name, floor_tile_name, planet_name .. " should use its fixed thematic floor")
  end

  local nauvis_config = planet_config.get("nauvis")
  assert_equal(nauvis_config.square_size, 9, "Nauvis should keep using the existing compatibility default path")
  assert_equal(nauvis_config.floor_tile_name, nil, "Nauvis should keep using the legacy background tile path")

  settings.startup = {
    ["the-square-vulcanus-starting-square-size"] = {value = 11}
  }
end)

run_test("Space Age Planet Instance initializes independent planet state", function()
  storage = {}

  local vulcanus = planet_instance.ensure("vulcanus")

  assert_equal(vulcanus:get_square_size(), 11, "Space Age planets should use their planet startup square size")
  assert_equal(vulcanus:get_surface_name(), "vulcanus", "Space Age planets should use vanilla planet surfaces")
  assert_equal(vulcanus:get_surface_size(), 13, "planet surface size should include the managed void ring")
  assert_equal(vulcanus:get_floor_tile_name(), "volcanic-ash-soil", "Space Age planets should expose their fixed floor tile")
  assert_equal(storage.planets.vulcanus.square_size, 11, "planet state should be stored independently")
  assert_equal(storage.bootstrap, nil, "initializing another planet should not create Nauvis bootstrap state")
end)

run_test("Nauvis and Space Age Planet Instances share one method set", function()
  storage = {}

  local nauvis = planet_instance.ensure("nauvis")
  local vulcanus = planet_instance.ensure("vulcanus")

  for _, method_name in ipairs({
    "get_square_size",
    "set_square_size",
    "get_surface_name",
    "set_surface_name",
    "get_surface_size",
    "get_floor_tile_name",
    "get_expansion_points",
    "add_expansion_points",
    "get_completed_square_expansion_levels",
    "set_completed_square_expansion_levels",
    "get_managed_lines",
    "get_bootstrap_storage"
  }) do
    assert_equal(type(nauvis[method_name]), "function", "Nauvis should expose " .. method_name)
    assert_equal(nauvis[method_name], vulcanus[method_name], "Planet Instances should share " .. method_name)
  end

  assert_equal(storage.planets.nauvis, storage.bootstrap, "legacy bootstrap handle should alias the Nauvis Planet Instance state")
end)

run_test("Space Age Planet Instance migrates accidental Nauvis-sized planet state", function()
  settings.startup = {}
  storage = {
    planets = {
      fulgora = {
        square_size = 7,
        expansions_completed = 0,
        expansion_research_levels = 0
      }
    }
  }

  local fulgora = planet_instance.ensure("fulgora")

  assert_equal(fulgora:get_square_size(), 17, "Space Age planets should not retain Nauvis catalog default size")
  assert_equal(fulgora:get_surface_size(), 19, "migrated surface size should match the planet square")

  settings.startup = {
    ["the-square-vulcanus-starting-square-size"] = {value = 11}
  }
end)
