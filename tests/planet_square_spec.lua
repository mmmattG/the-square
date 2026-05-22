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
    ["the-square-starting-square-size"] = {value = 7},
    ["the-square-vulcanus-starting-square-size"] = {value = 5}
  }
}

local planet_square = require("lib.planet_square")
local growth_runtime = require("lib.growth_runtime")

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

local function make_surface(name)
  local surface
  surface = {
    name = name,
    map_gen_settings = {width = 9, height = 9},
    tiles_set = nil,
    created_entities = {},
    request_to_generate_chunks = function() end,
    force_generate_chunk_requests = function() end,
    set_tiles = function(self, tiles)
      self.tiles_set = tiles
    end,
    find_entities_filtered = function()
      return {}
    end,
    create_entity = function(entity)
      surface.created_entities[#surface.created_entities + 1] = entity
      return {valid = true, name = entity.name}
    end
  }

  return surface
end

local function install_game(surfaces)
  game = {
    surfaces = surfaces,
    players = {{valid = true, play_sound = function() end}},
    forces = {
      player = {
        charted_surface = nil,
        chart = function(self, surface)
          self.charted_surface = surface.name
        end
      }
    },
    print = function() end
  }
end

run_test("Planet Square expands Nauvis through one interface and preserves Anchor Shift stubs", function()
  local surface = make_surface("nauvis")
  install_game({nauvis = surface})
  storage = {
    bootstrap = {square_size = 7, surface_size = 9, surface_name = "nauvis", expansion_points = 0, expansion_research_levels = 0},
    starter_anchors = {
      anchors = {{kind = "item", flow = "ingress", side = "north", position = {x = 0, y = -4}, entity_name = "iron-ore-ingress"}}
    }
  }

  local result = planet_square.apply_square_expansion("nauvis")

  assert_equal(result.square_size, 9, "Nauvis should grow by one Ring")
  assert_equal(storage.bootstrap.expansion_points, 32, "Nauvis should receive the Ring reward")
  assert_equal(storage.starter_anchors.anchors[1].position.y, -5, "Managed Lines should shift outward")
  assert_equal(surface.created_entities[1].name, "transport-belt", "Nauvis expansion should leave trailing ingress stubs")
  assert_equal(surface.map_gen_settings.width, 11, "surface dimensions should be resized")
end)

run_test("Planet Square expands a non-Nauvis Planet without touching Nauvis points", function()
  local vulcanus = make_surface("vulcanus")
  install_game({vulcanus = vulcanus})
  storage = {
    bootstrap = {square_size = 7, surface_size = 9, surface_name = "nauvis", expansion_points = 5},
    planets = {
      vulcanus = {square_size = 5, surface_size = 7, surface_name = "vulcanus", floor_tile_name = "volcanic-ash-soil", expansion_points = 1}
    }
  }

  local result = planet_square.apply_square_expansion("vulcanus")

  assert_equal(result.square_size, 7, "Planet-local square should grow by one Ring")
  assert_equal(storage.planets.vulcanus.expansion_points, 25, "Planet should receive only its local Ring reward")
  assert_equal(storage.bootstrap.expansion_points, 5, "Nauvis points should be unchanged")
  assert_equal(vulcanus.created_entities[1], nil, "non-Nauvis expansion should not use Nauvis trailing stubs")
end)

run_test("Square Expansion research routes to the researched Planet", function()
  local vulcanus = make_surface("vulcanus")
  install_game({vulcanus = vulcanus})
  storage = {planets = {vulcanus = {square_size = 5, surface_size = 7, surface_name = "vulcanus"}}}
  local printed_level = nil
  local printed_size = nil
  local research = {
    valid = true,
    name = "the-square-vulcanus-square-expansion",
    force = {
      print = function(message)
        printed_level = message[2]
        printed_size = message[3]
      end
    }
  }

  local handled = growth_runtime.handle_expansion_research_finished(research, require("lib.bootstrap_runtime"), nil, nil)

  assert_equal(handled, true, "planet research should be handled")
  assert_equal(storage.planets.vulcanus.square_size, 7, "researched Planet should expand")
  assert_equal(printed_level, 1, "message should use Planet-local research level")
  assert_equal(printed_size, 7, "message should use Planet-local Square size")
end)
