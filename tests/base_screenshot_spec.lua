package.path = "./?.lua;./?/init.lua;" .. package.path

local base_screenshot = require("lib.base_screenshot")

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

run_test("starting square framing includes two void tiles on each side", function()
  local spec = base_screenshot.build_capture_spec(7, 2)

  assert_equal(spec.position.x, 0.5, "odd-width captures should stay centered on the square")
  assert_equal(spec.position.y, 0.5, "odd-width captures should stay centered on the square")
  assert_equal(spec.tile_span, 11, "a 7x7 square with a two-tile margin should span 11 tiles")
  assert_equal(spec.resolution.x, 352, "resolution should use 32 pixels per tile")
  assert_equal(spec.resolution.y, 352, "resolution should use 32 pixels per tile")
  assert_equal(spec.zoom, 1, "captures should use Factorio's default zoom")
end)

run_test("expanded squares keep the same deterministic two-tile margin", function()
  local spec = base_screenshot.build_capture_spec(13, 2)

  assert_equal(spec.position.x, 0.5, "expanded odd-width squares should stay centered")
  assert_equal(spec.position.y, 0.5, "expanded odd-width squares should stay centered")
  assert_equal(spec.tile_span, 17, "the image should grow with the square while keeping the same margin")
  assert_equal(spec.resolution.x, 544, "resolution should keep the same 32 pixels per tile scale")
  assert_equal(spec.resolution.y, 544, "resolution should keep the same 32 pixels per tile scale")
end)
