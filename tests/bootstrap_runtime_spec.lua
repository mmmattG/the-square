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

local bootstrap_runtime = require("lib.bootstrap_runtime")
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
  local tiles = bootstrap_runtime.build_generated_chunk_tiles(7, 9, {
    left_top = {x = 64, y = 64},
    right_bottom = {x = 66, y = 66}
  })

  assert_equal(#tiles, 4, "every generated tile in the chunk area should be painted")

  for _, tile in ipairs(tiles) do
    assert_equal(tile.name, "out-of-map", "outside managed area should be void")
  end
end)

run_test("new worlds start with stashed Nauvis Managed Lines only", function()
  local nauvis_lines = bootstrap_runtime.build_initial_managed_line_state("nauvis")
  local vulcanus_lines = bootstrap_runtime.build_initial_managed_line_state("vulcanus")

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

  bootstrap_runtime.grant_initial_managed_line_inventory(player)
  bootstrap_runtime.grant_initial_managed_line_inventory(player)

  assert_equal(inserted[defs.get_generic_anchor_item_name("fluid", "ingress")], 1, "player should receive one fluid ingress")
  assert_equal(inserted[defs.get_generic_anchor_item_name("item", "ingress")], 2, "player should receive two item ingresses")
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

  local handled = bootstrap_runtime.refresh_generated_chunk_for_planet_surface(surface, {
    left_top = {x = 0, y = 0},
    right_bottom = {x = 1, y = 1}
  })

  assert_equal(handled, true, "supported planet surfaces should be handled")
  assert_equal(storage.planets.vulcanus.square_size, 5, "chunk routing should initialize planet state")
  assert_equal(painted_tiles[1].name, "volcanic-ash-soil", "Space Age planet squares should use their fixed thematic floor")
end)

run_test("generated chunks on Nauvis keep using the legacy background tile setting", function()
  storage = {
    bootstrap = {
      square_size = 7,
      surface_name = "nauvis"
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

  local handled = bootstrap_runtime.refresh_generated_chunk_for_planet_surface(surface, {
    left_top = {x = 0, y = 0},
    right_bottom = {x = 1, y = 1}
  })

  assert_equal(handled, true, "Nauvis should still be routed through compatibility storage")
  assert_equal(painted_tiles[1].name, "sand-3", "Nauvis should keep honoring the legacy global background tile")
  settings.global["the-square-background-tile"] = {value = "grass-1"}
end)
