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
    ["the-square-background-tile"] = {value = "grass-1"},
    ["the-square-screenshot-alt-mode"] = {value = true},
    ["the-square-screenshot-pixels-per-tile"] = {value = 48}
  },
  startup = {
    ["the-square-nauvis-starting-square-size"] = {value = 7}
  }
}

local screenshots = {}
local messages = {}

game = {
  tick = 123456,
  surfaces = {},
  take_screenshot = function(spec)
    screenshots[#screenshots + 1] = spec
  end
}

storage = {}

local screenshot_runtime = require("lib.screenshot_runtime")

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

local function make_surface(name)
  local surface = {name = name}
  game.surfaces[name] = surface
  return surface
end

local function make_player(surface, physical_surface)
  return {
    valid = true,
    surface = surface,
    physical_surface = physical_surface or surface,
    print = function(message)
      messages[#messages + 1] = message
    end
  }
end

local function reset_results()
  screenshots = {}
  messages = {}
end

local nauvis = make_surface("nauvis")
local vulcanus = make_surface("vulcanus")
local fulgora = make_surface("fulgora")
local gleba = make_surface("gleba")
local aquilo = make_surface("aquilo")
local platform = make_surface("space-platform-1")

storage = {
  bootstrap = {
    square_size = 9,
    surface_name = "nauvis",
    expansions_completed = 1,
    expansion_research_levels = 1
  },
  planets = {
    vulcanus = {
      square_size = 19,
      surface_name = "vulcanus",
      expansions_completed = 1,
      expansion_research_levels = 1
    },
    fulgora = {
      square_size = 21,
      surface_name = "fulgora",
      expansions_completed = 2,
      expansion_research_levels = 2
    },
    gleba = {
      square_size = 23,
      surface_name = "gleba",
      expansions_completed = 3,
      expansion_research_levels = 3
    },
    aquilo = {
      square_size = 25,
      surface_name = "aquilo",
      expansions_completed = 4,
      expansion_research_levels = 4
    }
  }
}

run_test("supported planets use their current Planet-local square size and filename", function()
  local cases = {
    {surface = nauvis, name = "nauvis", square_size = 9},
    {surface = vulcanus, name = "vulcanus", square_size = 19},
    {surface = fulgora, name = "fulgora", square_size = 21},
    {surface = gleba, name = "gleba", square_size = 23},
    {surface = aquilo, name = "aquilo", square_size = 25}
  }

  for _, case in ipairs(cases) do
    reset_results()

    local result = screenshot_runtime.take_base_screenshot(make_player(case.surface))
    local capture = screenshots[1]

    assert_equal(result, true, case.name .. " capture should succeed")
    assert_equal(#screenshots, 1, case.name .. " should request one screenshot")
    assert_equal(capture.surface, case.surface, case.name .. " should capture its own surface")
    assert_equal(
      capture.path,
      "the-square/" .. case.name .. "-base-" .. case.square_size .. "x" .. case.square_size .. "-tick-123456.png",
      case.name .. " filename should identify the planet and current square size"
    )
    assert_equal(capture.resolution.x, (case.square_size + 4) * 48, case.name .. " framing should use its square size")
    assert_equal(capture.show_entity_info, true, case.name .. " should preserve the alt-mode setting")
    assert_equal(messages[1][2], capture.path, case.name .. " confirmation should include the output path")
    assert_equal(messages[1][3], case.square_size, case.name .. " confirmation should include the square size")
  end
end)

run_test("remote map view uses the viewed planet instead of the physical planet", function()
  reset_results()

  local result = screenshot_runtime.take_base_screenshot(make_player(gleba, nauvis))

  assert_equal(result, true, "map-view capture should succeed")
  assert_equal(screenshots[1].surface, gleba, "capture should use player.surface from the active remote view")
  assert_equal(
    screenshots[1].path,
    "the-square/gleba-base-23x23-tick-123456.png",
    "map-view capture should identify the viewed planet"
  )
end)

run_test("unsupported viewed surfaces do not fall back to Nauvis", function()
  reset_results()

  local result = screenshot_runtime.take_base_screenshot(make_player(platform, nauvis))

  assert_equal(result, false, "unsupported surface capture should be rejected")
  assert_equal(#screenshots, 0, "unsupported surfaces should not request a screenshot")
  assert_equal(
    messages[1][1],
    "message.the-square-screenshot-unsupported-surface",
    "unsupported surfaces should explain why no screenshot was taken"
  )
end)
