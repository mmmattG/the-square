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
    ["fes-background-tile"] = {
      value = "grass-1"
    }
  }
}

storage = {}
game = {
  players = {
    [1] = {
      valid = true
    }
  }
}

local growth_runtime = require("lib.growth_runtime")
local planet_state = require("lib.planet_state")

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

run_test("planet-local expansion research expands non-nauvis planets", function()
  local printed_message = nil
  local expanded_planet_key = nil
  local refreshed_debug_guis = 0

  local bootstrap_runtime = {
    expand_planet_square = function(planet_key)
      expanded_planet_key = planet_key
      local state = planet_state.ensure_planet(planet_key)
      state.square_size = state.square_size + 2
      return true
    end,
    ensure_bootstrap_state_defaults = function()
      error("non-nauvis expansion should not touch nauvis bootstrap state")
    end
  }

  local gui_runtime = {
    refresh_all_debug_guis = function()
      refreshed_debug_guis = refreshed_debug_guis + 1
    end
  }

  local research = {
    name = "fes-square-expansion-vulcanus-0003",
    valid = true,
    force = {
      print = function(message)
        printed_message = message
      end
    }
  }

  local handled = growth_runtime.handle_expansion_research_finished(research, bootstrap_runtime, gui_runtime, nil)
  local state = planet_state.ensure_planet("vulcanus")

  assert_equal(handled, true, "non-nauvis expansion research should now be handled")
  assert_equal(expanded_planet_key, "vulcanus", "growth runtime should route expansion to the researched planet")
  assert_equal(state.expansion_research_levels, 3, "the researched level should be stored on the planet")
  assert_equal(state.square_size, 9, "the target planet square should grow by one ring")
  assert_equal(refreshed_debug_guis, 1, "the runtime GUIs should refresh after expansion")
  assert_equal(printed_message[1], "message.fes-expansion-research-completed", "the normal completion message should still be used")
  assert_equal(printed_message[2], 3, "the printed message should include the completed level")
  assert_equal(printed_message[3], 9, "the printed message should include the new planet square size")
end)
