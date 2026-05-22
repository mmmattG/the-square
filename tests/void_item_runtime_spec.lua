package.path = "./?.lua;./?/init.lua;" .. package.path

defines = {direction = {south = 1, west = 2, north = 3, east = 4}}
settings = {global = {}, startup = {}}
storage = {bootstrap = {square_size = 7, surface_name = "nauvis"}}

local void_item_runtime = require("lib.void_item_runtime")

local function assert_equal(actual, expected, message)
  if actual ~= expected then
    error((message or "values differ") .. "\nexpected: " .. tostring(expected) .. "\nactual: " .. tostring(actual))
  end
end

local function make_entity(surface_name, position, tile_name)
  local destroyed = false
  local surface = {
    name = surface_name,
    get_tile = function()
      return {name = tile_name}
    end
  }
  return {
    valid = true,
    type = "item-entity",
    surface = surface,
    position = position,
    destroy = function()
      destroyed = true
    end,
    was_destroyed = function()
      return destroyed
    end
  }
end

local function run_test(name, fn)
  local ok, err = pcall(fn)
  if not ok then
    io.stderr:write("FAIL " .. name .. "\n" .. err .. "\n")
    os.exit(1)
  end
  io.stdout:write("PASS " .. name .. "\n")
end

run_test("items on void outside supported planet square are destroyed", function()
  local entity = make_entity("vulcanus", {x = 20, y = 0}, "out-of-map")
  assert_equal(void_item_runtime.destroy_if_void_item({entity = entity}), true)
  assert_equal(entity.was_destroyed(), true)
end)

run_test("items inside square are not destroyed", function()
  local entity = make_entity("vulcanus", {x = 0, y = 0}, "out-of-map")
  assert_equal(void_item_runtime.destroy_if_void_item({entity = entity}), false)
  assert_equal(entity.was_destroyed(), false)
end)

run_test("items outside square but not on void are not destroyed", function()
  local entity = make_entity("vulcanus", {x = 20, y = 0}, "volcanic-ash-soil")
  assert_equal(void_item_runtime.destroy_if_void_item({entity = entity}), false)
  assert_equal(entity.was_destroyed(), false)
end)
