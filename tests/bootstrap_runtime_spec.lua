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
    ["fes-background-tile"] = {
      value = "grass-1"
    }
  },
  startup = {
    ["fes-expansion-tiles-per-research"] = {
      value = 9
    }
  }
}

local bootstrap_runtime = require("lib.bootstrap_runtime")

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
