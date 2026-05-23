package.path = "./?.lua;./?/init.lua;" .. package.path

defines = {direction = {south = 1, west = 2, north = 3, east = 4}}
settings = {global = {}, startup = {}}

local managed_line_runtime = require("lib.managed_line_runtime")

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

run_test("managed_line_runtime exposes the deep Managed Line interface and compatibility seam", function()
  storage = {}
  game = {surfaces = {}, forces = {player = {technologies = {}}}}

  assert_equal(type(managed_line_runtime.ensure), "function", "Managed Line runtime should expose ensure")
  assert_equal(type(managed_line_runtime.pump), "function", "Managed Line runtime should expose pump")
  assert_equal(type(managed_line_runtime.purchase), "function", "Managed Line runtime should expose purchase")
  assert_equal(type(managed_line_runtime.sync_tier), "function", "Managed Line runtime should expose sync_tier")
  assert_equal(type(managed_line_runtime.handle_built), "function", "Managed Line runtime should expose explicit event handlers")

  assert_equal(
    managed_line_runtime.purchase_managed_line_for_resource,
    managed_line_runtime.purchase,
    "legacy purchase export should route through the deep seam"
  )
  assert_equal(
    managed_line_runtime.sync_ingress_tier_from_research,
    managed_line_runtime.sync_tier,
    "legacy tier sync export should route through the deep seam"
  )
end)
