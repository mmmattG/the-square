package.path = "./?.lua;./?/init.lua;" .. package.path

local bootstrap_layout = require("lib.bootstrap_layout")

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

run_test("anchor ring tiles stay walkable floor", function()
  local square_size = 12
  local surface_size = bootstrap_layout.get_surface_size(square_size, 2)

  assert_equal(
    bootstrap_layout.get_managed_tile_name(square_size, surface_size, "grass-1", "out-of-map", {x = 0, y = -7}),
    "grass-1",
    "north anchor ring should remain floor"
  )
  assert_equal(
    bootstrap_layout.get_managed_tile_name(square_size, surface_size, "grass-1", "out-of-map", {x = 6, y = 0}),
    "grass-1",
    "east anchor ring should remain floor"
  )
end)

run_test("occupied anchor tiles switch back to out-of-map", function()
  local square_size = 12

  assert_equal(
    bootstrap_layout.get_anchor_occupied_tile_name(square_size, "out-of-map", {x = 0, y = -7}, true),
    "out-of-map",
    "occupied north anchor tiles should not keep grass behind the anchor"
  )
  assert_equal(
    bootstrap_layout.get_anchor_occupied_tile_name(square_size, "out-of-map", {x = 0, y = -6}, true),
    nil,
    "playable edge tiles should not be affected by the occupied-anchor overlay"
  )
end)

run_test("playable square stays walkable floor", function()
  local square_size = 12
  local surface_size = bootstrap_layout.get_surface_size(square_size, 2)

  assert_equal(
    bootstrap_layout.get_managed_tile_name(square_size, surface_size, "grass-1", "out-of-map", {x = 0, y = 0}),
    "grass-1",
    "the playable square should keep floor tiles"
  )
end)

run_test("outer perimeter outside the anchor ring stays out-of-map", function()
  local square_size = 12
  local surface_size = bootstrap_layout.get_surface_size(square_size, 2)

  assert_equal(
    bootstrap_layout.get_managed_tile_name(square_size, surface_size, "grass-1", "out-of-map", {x = 0, y = -8}),
    "out-of-map",
    "the outer perimeter should remain void"
  )
end)

run_test("anchor side detection still targets the ingress ring", function()
  local square_size = 12

  assert_equal(
    bootstrap_layout.get_anchor_side_for_position(square_size, {x = 0, y = -7}),
    "north",
    "starter anchors should still snap to the north ring"
  )
  assert_equal(
    bootstrap_layout.get_anchor_side_for_position(square_size, {x = 6, y = 0}),
    "east",
    "starter anchors should still snap to the east ring"
  )
end)

run_test("playable edge detection resolves the inner placement strip", function()
  local square_size = 12

  assert_equal(
    bootstrap_layout.get_playable_edge_side_for_position(square_size, {x = 0, y = -6}),
    "north",
    "players should place north anchors from the inner edge"
  )
  assert_equal(
    bootstrap_layout.get_playable_edge_side_for_position(square_size, {x = 5, y = 0}),
    "east",
    "players should place east anchors from the inner edge"
  )
end)
