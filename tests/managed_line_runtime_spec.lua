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

run_test("managed_line_runtime exposes only the deep Managed Line interface", function()
  storage = {}
  game = {surfaces = {}, forces = {player = {technologies = {}}}}

  assert_equal(type(managed_line_runtime.initialize), "function", "Managed Line runtime should expose initialization")
  assert_equal(type(managed_line_runtime.reconcile), "function", "Managed Line runtime should expose event-driven reconciliation")
  assert_equal(type(managed_line_runtime.pump), "function", "Managed Line runtime should expose pump")
  assert_equal(type(managed_line_runtime.sync_tier), "function", "Managed Line runtime should expose sync_tier")
  assert_equal(type(managed_line_runtime.handle_built), "function", "Managed Line runtime should expose explicit event handlers")
end)

run_test("control does not schedule recurring Managed Line reconciliation", function()
  local control_file = assert(io.open("control.lua", "r"))
  local source = control_file:read("*a")
  control_file:close()

  assert_equal(
    source:match("on_nth_tick%s*%(%s*defs%.ITEM_ANCHOR_INTERVAL_TICKS"),
    nil,
    "Managed Line reconciliation should be triggered by lifecycle events, not a recurring tick"
  )
end)
