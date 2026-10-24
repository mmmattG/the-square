package.path = "./?.lua;./?/init.lua;" .. package.path

local helper = require("tests.helper")
local assert_equal = helper.assert_equal
local run_test = helper.run_test

defines = {direction = {south = 1, west = 2, north = 3, east = 4}}
settings = {global = {}}
storage = {}

local anchor_placement = require("lib.anchor_placement")

run_test("Managed Line placement check owns Boundary and fluid gap rules", function()
  local anchor = {kind = "fluid", flow = "ingress"}
  local starter_anchors = {
    anchors = {
      anchor,
      {kind = "fluid", flow = "ingress", side = "north", position = {x = -1, y = -7}}
    }
  }

  local ok, reason = anchor_placement.check(anchor, {x = 0, y = -7}, 12, starter_anchors)
  assert_equal(ok, false, "adjacent fluid Managed Line should be rejected")
  assert_equal(reason, "fluid-gap-required", "fluid gap rejection should be explicit")

  ok, reason = anchor_placement.check(anchor, {x = 2, y = -7}, 12, starter_anchors)
  assert_equal(ok, true, "spaced fluid Managed Line should be allowed")
  assert_equal(reason, nil, "allowed placement should have no reason")
end)
