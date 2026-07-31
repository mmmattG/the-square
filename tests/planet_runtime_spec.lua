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
    ["the-square-background-tile"] = {
      value = "grass-1"
    }
  },
  startup = {
    ["the-square-expansion-tiles-per-research"] = {
      value = 9
    },
    ["the-square-vulcanus-starting-square-size"] = {
      value = 5
    }
  }
}

local planet_runtime = require("lib.planet_runtime")
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

run_test("generated chunks outside managed surface are painted void", function()
  local tiles = planet_runtime.build_generated_chunk_tiles(7, 9, {
    left_top = {x = 64, y = 64},
    right_bottom = {x = 66, y = 66}
  })

  assert_equal(#tiles, 4, "every generated tile in the chunk area should be painted")

  for _, tile in ipairs(tiles) do
    assert_equal(tile.name, "out-of-map", "outside managed area should be void")
  end
end)

run_test("generated chunks follow a moved Square position", function()
  local tiles = planet_runtime.build_generated_chunk_tiles(7, 9, {
    left_top = {x = -4, y = -4},
    right_bottom = {x = 6, y = 5}
  }, "grass-1", {x = 1, y = 0})
  local by_position = {}

  for _, tile in ipairs(tiles) do
    by_position[tile.position.x .. ":" .. tile.position.y] = tile.name
  end

  assert_equal(by_position["-3:0"], "out-of-map", "the old west edge should become the moved Boundary")
  assert_equal(by_position["4:0"], "grass-1", "the newly included east tile should become playable")
end)

run_test("new worlds start with stashed Nauvis Managed Lines only", function()
  local nauvis_lines = planet_runtime.build_initial_managed_line_state("nauvis")
  local vulcanus_lines = planet_runtime.build_initial_managed_line_state("vulcanus")

  assert_equal(#nauvis_lines.anchors, 3, "Nauvis should start with three owned Managed Lines")
  assert_equal(#vulcanus_lines.anchors, 0, "other planets should not start with owned Managed Lines")
  assert_equal(nauvis_lines.anchors[1].position, nil, "initial Managed Lines should start stashed")
  assert_equal(nauvis_lines.anchors[1].item_name, defs.get_generic_anchor_item_name("fluid", "ingress"), "first starter item should be a fluid ingress")
  assert_equal(nauvis_lines.anchors[2].item_name, defs.get_generic_anchor_item_name("item", "ingress"), "second starter item should be an item ingress")
end)

run_test("initial Managed Line inventory is granted once", function()
  storage = {}
  local inserted = {}
  local player = {
    valid = true,
    insert = function(stack)
      inserted[stack.name] = (inserted[stack.name] or 0) + stack.count
      return stack.count
    end
  }

  planet_runtime.grant_initial_managed_line_inventory(player, "nauvis")
  planet_runtime.grant_initial_managed_line_inventory(player, "nauvis")

  assert_equal(inserted[defs.get_generic_anchor_item_name("fluid", "ingress")], 1, "player should receive one fluid ingress")
  assert_equal(inserted[defs.get_generic_anchor_item_name("item", "ingress")], 2, "player should receive two item ingresses")
end)

run_test("freeplay starting items omit the burner mining drill", function()
  local created_items = {
    ["burner-mining-drill"] = 1,
    ["stone-furnace"] = 1
  }

  remote = {
    interfaces = {
      freeplay = {
        get_created_items = true,
        set_created_items = true,
        set_disable_crashsite = true,
        set_skip_intro = true
      }
    },
    call = function(_, interface_name, value)
      if interface_name == "get_created_items" then
        return created_items
      end

      if interface_name == "set_created_items" then
        created_items = value
      end
    end
  }

  planet_runtime.configure_freeplay()

  assert_equal(created_items["burner-mining-drill"], nil, "new players should not receive an unusable mining drill")
  assert_equal(created_items["stone-furnace"], 1, "other freeplay starting items should remain unchanged")
end)

run_test("generated chunks on supported Space Age planet surfaces are routed through planet state", function()
  storage = {}
  local painted_tiles = nil
  local surface = {
    name = "vulcanus",
    set_tiles = function(tiles)
      painted_tiles = tiles
    end
  }

  local handled = planet_runtime.refresh_generated_chunk_for_planet_surface(surface, {
    left_top = {x = 0, y = 0},
    right_bottom = {x = 1, y = 1}
  })

  assert_equal(handled, true, "supported planet surfaces should be handled")
  assert_equal(storage.planets.vulcanus.square_size, 5, "chunk routing should initialize planet state")
  assert_equal(painted_tiles[1].name, "volcanic-ash-soil", "Space Age planet squares should use their fixed thematic floor")
end)

run_test("generated chunks on Nauvis keep using the legacy background tile setting", function()
  storage = {
    planets = {
      nauvis = {
        square_size = 7,
        surface_name = "nauvis"
      }
    }
  }
  settings.global["the-square-background-tile"] = {value = "sand-3"}
  local painted_tiles = nil
  local surface = {
    name = "nauvis",
    set_tiles = function(tiles)
      painted_tiles = tiles
    end
  }

  local handled = planet_runtime.refresh_generated_chunk_for_planet_surface(surface, {
    left_top = {x = 0, y = 0},
    right_bottom = {x = 1, y = 1}
  })

  assert_equal(handled, true, "Nauvis should be routed through planet state")
  assert_equal(painted_tiles[1].name, "sand-3", "Nauvis should keep honoring the legacy global background tile")
  settings.global["the-square-background-tile"] = {value = "grass-1"}
end)
