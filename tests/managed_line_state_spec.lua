package.path = "./?.lua;./?/init.lua;" .. package.path

defines = {direction = {south = 1, west = 2, north = 3, east = 4}}
settings = {global = {}, startup = {}}

local managed_line_state = require("lib.managed_line_state")

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

run_test("same Managed Line state seam ensures and reads Nauvis and Proof Planet lines", function()
  storage = {bootstrap = {square_size = 7, surface_name = "nauvis"}}

  local nauvis_lines = managed_line_state.ensure("nauvis")
  local vulcanus_lines = managed_line_state.ensure("vulcanus")

  assert_equal(managed_line_state.get("nauvis"), nauvis_lines, "Nauvis lines should be readable through the seam")
  assert_equal(managed_line_state.get("vulcanus"), vulcanus_lines, "Proof Planet lines should be readable through the seam")
  assert_equal(#nauvis_lines.anchors, 3, "Nauvis should start with three stashed Managed Lines")
  assert_equal(#vulcanus_lines.anchors, 0, "Proof Planet should not start with free Managed Lines")
  assert_equal(nauvis_lines.anchors[1].position, nil, "Nauvis starter Managed Lines should not be placed")
end)

run_test("seam returns nil for unsupported planets without creating Managed Lines", function()
  storage = {}

  assert_equal(managed_line_state.ensure("not-a-planet"), nil, "unsupported Planet should not have Managed Lines")
  assert_equal(managed_line_state.get("not-a-planet"), nil, "unsupported Planet should not read Managed Lines")
end)
