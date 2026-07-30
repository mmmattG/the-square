package.path = "./?.lua;./?/init.lua;" .. package.path

defines = {
  direction = {
    south = 1,
    west = 2,
    north = 3,
    east = 4
  }
}

settings = {
  global = {
    ["the-square-background-tile"] = {value = "grass-1"}
  },
  startup = {
    ["the-square-nauvis-starting-square-size"] = {value = 7}
  }
}

local defs = require("lib.runtime_defs")
local gui_runtime = require("lib.gui_runtime")

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

run_test("recurring Square move GUI refreshes do not check directions while the menu is closed", function()
  local checks = 0
  local player = {
    valid = true,
    gui = {
      screen = {}
    }
  }
  game = {
    players = {player}
  }

  gui_runtime.refresh_all_square_move_guis({
    get_options_for_player = function()
      checks = checks + 1
      return {}
    end
  })

  assert_equal(checks, 0, "closed movement menus should not scan any Square edge")
end)

run_test("the movement mode switch is remembered per player", function()
  storage = {}
  local top = {}
  top.add = function(spec)
    local element = {valid = true, name = spec.name}
    top[spec.name] = element
    return element
  end
  local player = {
    index = 7,
    valid = true,
    gui = {
      screen = {},
      top = top
    }
  }
  local element = {
    valid = true,
    name = "the_square_move_mode_switch",
    switch_state = "right"
  }

  gui_runtime.sync_square_move_gui(player)
  assert_equal(
    gui_runtime.get_square_move_mode(player),
    defs.SQUARE_MOVE_MODES.SQUARE,
    "Square movement should be initialized as the default"
  )
  assert_equal(
    gui_runtime.handle_square_move_mode_changed(player, element, {}),
    true,
    "the movement mode switch should be handled"
  )
  assert_equal(
    gui_runtime.get_square_move_mode(player),
    defs.SQUARE_MOVE_MODES.CONTENTS,
    "the selected mode should be remembered"
  )
end)
