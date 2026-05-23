package.path = "./?.lua;./?/init.lua;" .. package.path

defines = {direction = {south = 1, west = 2, north = 3, east = 4}}
settings = {global = {}}
storage = {}

local anchor_placement = require("lib.anchor_placement")

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

run_test("Anchor placement check owns Boundary and fluid gap rules", function()
  local anchor = {kind = "fluid", flow = "ingress"}
  local starter_anchors = {
    anchors = {
      anchor,
      {kind = "fluid", flow = "ingress", side = "north", position = {x = -1, y = -7}}
    }
  }

  local ok, reason = anchor_placement.check(anchor, {x = 0, y = -7}, 12, starter_anchors)
  assert_equal(ok, false, "adjacent fluid Anchor should be rejected")
  assert_equal(reason, "fluid-gap-required", "fluid gap rejection should be explicit")

  ok, reason = anchor_placement.check(anchor, {x = 2, y = -7}, 12, starter_anchors)
  assert_equal(ok, true, "spaced fluid Anchor should be allowed")
  assert_equal(reason, nil, "allowed placement should have no reason")
end)
