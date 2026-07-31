package.path = "./?.lua;./?/init.lua;" .. package.path

defines = {direction = {south = 1, west = 2, north = 3, east = 4}}
settings = {global = {}}
storage = {}

local anchor_identity = require("lib.anchor_identity")
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

run_test("Managed Line identity matches tiered entities", function()
  assert_equal(
    anchor_identity.is_managed_entity_name(defs.get_ingress_entity_name("iron-ore", 2)),
    true,
    "tiered ingress entities should be Managed Line entities"
  )

  assert_equal(
    anchor_identity.does_anchor_match_entity_name(
      {kind = "item", flow = "ingress", resource = "iron-ore"},
      defs.get_ingress_entity_name("iron-ore", 3)
    ),
    true,
    "tiered ingress entity should match its Managed Line"
  )
end)
