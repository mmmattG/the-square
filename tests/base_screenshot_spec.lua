package.path = "./?.lua;./?/init.lua;" .. package.path

local helper = require("tests.helper")
local assert_equal = helper.assert_equal
local run_test = helper.run_test

local base_screenshot = require("lib.base_screenshot")

run_test("starting square framing includes two void tiles on each side", function()
  local spec = base_screenshot.build_capture_spec(7, 2, 32)

  assert_equal(spec.position.x, 0.5, "odd-width captures should stay centered on the square")
  assert_equal(spec.position.y, 0.5, "odd-width captures should stay centered on the square")
  assert_equal(spec.tile_span, 11, "a 7x7 square with a two-tile margin should span 11 tiles")
  assert_equal(spec.resolution.x, 352, "resolution should use 32 pixels per tile")
  assert_equal(spec.resolution.y, 352, "resolution should use 32 pixels per tile")
  assert_equal(spec.zoom, 1, "32 pixels per tile should map to Factorio's default zoom")
end)

run_test("expanded squares keep the same deterministic two-tile margin", function()
  local spec = base_screenshot.build_capture_spec(13, 2, 48)

  assert_equal(spec.position.x, 0.5, "expanded odd-width squares should stay centered")
  assert_equal(spec.position.y, 0.5, "expanded odd-width squares should stay centered")
  assert_equal(spec.tile_span, 17, "the image should grow with the square while keeping the same margin")
  assert_equal(spec.resolution.x, 816, "resolution should scale directly with the configured pixels per tile")
  assert_equal(spec.resolution.y, 816, "resolution should scale directly with the configured pixels per tile")
  assert_equal(spec.zoom, 1.5, "zoom should scale with render density so the same tiles stay in frame")
end)

run_test("screenshots follow the Planet-local Square position", function()
  local spec = base_screenshot.build_capture_spec(7, 2, 32, {x = 3, y = -2})

  assert_equal(spec.position.x, 3.5, "the screenshot center should follow a moved Square on x")
  assert_equal(spec.position.y, -1.5, "the screenshot center should follow a moved Square on y")
end)
