package.path = "./?.lua;./?/init.lua;" .. package.path

defines = {direction = {south = 1, west = 2, north = 3, east = 4}}
settings = {
  global = {["the-square-background-tile"] = {value = "grass-1"}},
  startup = {
    ["the-square-starting-square-size"] = {value = 7},
    ["the-square-vulcanus-starting-square-size"] = {value = 5}
  }
}

local planet_square_runtime = require("lib.planet_square_runtime")

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
    map_gen_settings = {width = 7, height = 7},
    request_to_generate_chunks = function() end,
    force_generate_chunk_requests = function() end,
    set_tiles = function() end,
    find_entities_filtered = function() return {} end,
    create_entity = function(entity) return {valid = true, name = entity.name} end
  }
  return surface
end

local function install_game(surface)
  game = {
    surfaces = {[surface.name] = surface},
    players = {{valid = true, play_sound = function() end}},
    forces = {player = {chart = function() end}},
    print = function(message) game.printed = message end
  }
end

run_test("Planet Square runtime expands one Planet-local Square through one interface", function()
  local surface = make_surface("vulcanus")
  install_game(surface)
  storage = {
    planets = {
      vulcanus = {
        square_size = 5,
        surface_size = 7,
        surface_name = "vulcanus",
        floor_tile_name = "volcanic-ash-soil",
        starter_anchors = {anchors = {}}
      }
    }
  }
  local refreshed = false
  local ensured_planet = nil
  local gui_runtime = {refresh_all_debug_guis = function() refreshed = true end}
  local managed_line_runtime = {ensure = function(planet_name) ensured_planet = planet_name end}

  local result = planet_square_runtime.expand("vulcanus", {
    gui_runtime = gui_runtime,
    managed_line_runtime = managed_line_runtime
  })

  assert_equal(result.square_size, 7, "runtime should grow the Planet Square")
  assert_equal(storage.planets.vulcanus.expansion_research_levels, 1, "runtime should advance Planet Progression")
  assert_equal(refreshed, true, "runtime should own expansion GUI refresh")
  assert_equal(ensured_planet, "vulcanus", "runtime should pass Managed Line adapter through for Anchor Shift repair")
end)

run_test("Planet Square runtime handles Square Expansion research without bootstrap_runtime", function()
  local surface = make_surface("vulcanus")
  install_game(surface)
  storage = {planets = {vulcanus = {square_size = 5, surface_size = 7, surface_name = "vulcanus", starter_anchors = {anchors = {}}}}}
  local printed_level = nil
  local printed_size = nil
  local research = {
    valid = true,
    name = "the-square-vulcanus-square-expansion",
    force = {print = function(message) printed_level = message[2]; printed_size = message[3] end}
  }

  local handled = planet_square_runtime.expand_after_research(research)

  assert_equal(handled, true, "runtime should handle expansion research")
  assert_equal(printed_level, 1, "research message should use Planet-local level")
  assert_equal(printed_size, 7, "research message should use Planet-local Square size")
end)
