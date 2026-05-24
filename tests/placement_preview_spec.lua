package.path = "./?.lua;./?/init.lua;" .. package.path

defines = {direction = {south = 1, west = 2, north = 3, east = 4}}
settings = {global = {}}
storage = {}

local placement_preview = require("lib.placement_preview")

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

local function assert_inference(position, expected_side, expected_direction, message)
  local side, direction = placement_preview.infer_side_and_direction(position)

  assert_equal(side, expected_side, message .. " side")
  assert_equal(direction, expected_direction, message .. " direction")
end

run_test("Placement Preview infers cardinal side and inward-facing direction", function()
  assert_inference({x = 0, y = -5}, "north", defines.direction.south, "north region should face down")
  assert_inference({x = 5, y = 0}, "east", defines.direction.west, "east region should face left")
  assert_inference({x = 0, y = 5}, "south", defines.direction.north, "south region should face up")
  assert_inference({x = -5, y = 0}, "west", defines.direction.east, "west region should face right")
end)

run_test("Placement Preview infers stable center default and anti-clockwise diagonal ties", function()
  assert_inference({x = 0, y = 0}, "north", defines.direction.south, "center should default north")
  assert_inference({x = 4, y = -4}, "north", defines.direction.south, "northeast tie should resolve north")
  assert_inference({x = -4, y = -4}, "west", defines.direction.east, "northwest tie should resolve west")
  assert_inference({x = -4, y = 4}, "south", defines.direction.north, "southwest tie should resolve south")
  assert_inference({x = 4, y = 4}, "east", defines.direction.west, "southeast tie should resolve east")
end)
