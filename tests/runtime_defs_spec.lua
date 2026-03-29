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
      value = "checkerboard"
    }
  }
}

local runtime_defs = require("lib.runtime_defs")

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

run_test("checkerboard alternates lab floor tiles inside the square", function()
  assert_equal(
    runtime_defs.get_managed_tile_name(7, 9, {x = 0, y = 0}),
    "lab-dark-1",
    "even-parity tiles should use the first checkerboard tile"
  )
  assert_equal(
    runtime_defs.get_managed_tile_name(7, 9, {x = 1, y = 0}),
    "lab-dark-2",
    "odd-parity tiles should use the second checkerboard tile"
  )
end)

run_test("checkerboard still keeps the border out of map", function()
  assert_equal(
    runtime_defs.get_managed_tile_name(7, 9, {x = 0, y = -4}),
    "out-of-map",
    "checkerboard should not replace the managed void border"
  )
end)
