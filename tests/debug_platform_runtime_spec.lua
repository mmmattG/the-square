package.path = "./?.lua;./?/init.lua;" .. package.path

defines = {
  direction = {
    south = 1,
    west = 2,
    north = 3,
    east = 4
  }
}

local debug_platform_runtime = require("lib.debug_platform_runtime")

local function assert_equal(actual, expected, message)
  if actual ~= expected then
    error((message or "values differ") .. "\nexpected: " .. tostring(expected) .. "\nactual: " .. tostring(actual))
  end
end

local function assert_truthy(value, message)
  if not value then
    error(message or "expected truthy value")
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

run_test("space age debug teleport lazily creates one reusable platform per force and planet", function()
  storage = {}

  local created = {}
  local force

  force = {
    name = "player",
    index = 1,
    platforms = {},
    create_space_platform = function(spec)
      local platform = {
        valid = true,
        index = #created + 1,
        name = spec.name,
        force = force,
        planet = spec.planet,
        starter_pack = spec.starter_pack,
        applied = 0,
        apply_starter_pack = function(platform_self)
          platform_self.applied = platform_self.applied + 1
          platform_self.hub = {valid = true, destructible = true}
          return platform_self.hub
        end,
        surface = {
          find_entities_filtered = function()
            return {}
          end
        }
      }

      created[#created + 1] = platform
      force.platforms[platform.index] = platform
      return platform
    end
  }
  local entered = {}
  local player = {
    valid = true,
    force = force,
    enter_space_platform = function(platform)
      entered[#entered + 1] = platform
      return true
    end
  }

  local first = debug_platform_runtime.teleport_player_to_planet_platform(player, "vulcanus")
  local second = debug_platform_runtime.teleport_player_to_planet_platform(player, "vulcanus")

  assert_truthy(first.ok, "first teleport should succeed")
  assert_truthy(second.ok, "second teleport should succeed")
  assert_equal(#created, 1, "same force/planet should reuse the existing debug platform")
  assert_equal(#entered, 2, "player should enter the platform on each click")
  assert_equal(entered[1], created[1], "player should enter the created platform, not receive an implicit self argument")
  assert_equal(created[1].planet, "vulcanus", "platform should be created at the requested planet orbit")
  assert_equal(created[1].starter_pack.name, "space-platform-starter-pack", "platform should use the barebones vanilla starter pack")
  assert_equal(created[1].hub.destructible, false, "starter hub should be made indestructible")
end)
