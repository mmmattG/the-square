package.path = "./?.lua;./?/init.lua;" .. package.path

defines = {
  direction = {
    south = 1,
    west = 2,
    north = 3,
    east = 4
  }
}

settings = {global = {}, startup = {}}
storage = {}

game = {
  surfaces = {},
  players = {},
  forces = {player = {}}
}

local anchor_runtime = require("lib.anchor_runtime")
local runtime_defs = require("lib.runtime_defs")

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

local function make_clearable_stack(name)
  local stack = {valid_for_read = true, name = name, count = 1}
  stack.clear = function()
    stack.valid_for_read = false
    stack.name = nil
    stack.count = 0
  end
  return stack
end

run_test("Vulcanus anchors can be picked up and placed using planet-local state", function()
  local created = {}
  local surface = {
    name = "vulcanus",
    find_entities_filtered = function() return {} end,
    create_entity = function(entity)
      created[#created + 1] = entity
      return {valid = true, name = entity.name, position = entity.position, surface = surface}
    end
  }
  game.surfaces.vulcanus = surface
  storage = {
    bootstrap = {square_size = 7, surface_name = "nauvis"},
    planets = {
      vulcanus = {
        square_size = 17,
        surface_size = 19,
        surface_name = "vulcanus",
        starter_anchors = {
          anchors = {
            runtime_defs.create_managed_anchor(
              runtime_defs.get_input_definition("coal", "vulcanus"),
              "ingress",
              "north",
              {x = 0, y = -9}
            )
          }
        }
      }
    }
  }

  local anchor = storage.planets.vulcanus.starter_anchors.anchors[1]
  anchor.entity = {valid = true, name = anchor.entity_name, position = anchor.position, surface = surface}

  anchor_runtime.handle_anchor_mined(anchor.entity)

  assert_equal(anchor.position, nil, "mining a Vulcanus anchor should stash the planet-local anchor")

  local player = {
    valid = true,
    surface = surface,
    force = game.forces.player,
    selected = {valid = true, name = runtime_defs.ANCHOR_SLOT_PROXY_NAME, position = {x = 1, y = -9}},
    cursor_stack = make_clearable_stack(anchor.item_name),
    print = function() end
  }

  anchor_runtime.handle_managed_anchor_slot_click(player)

  assert_equal(anchor.position.x, 1, "placing should assign the Vulcanus anchor to the selected slot")
  assert_equal(anchor.position.y, -9, "placing should use the Vulcanus square bounds")
  assert_equal(player.cursor_stack.valid_for_read, false, "placing should consume the cursor item")
end)

run_test("Space Age item ingress mining matches centered entity positions after reload", function()
  local planet_cases = {
    {planet = "vulcanus", resource = "calcite"},
    {planet = "vulcanus", resource = "tungsten-ore"},
    {planet = "fulgora", resource = "scrap"},
    {planet = "gleba", resource = "yumako"},
    {planet = "gleba", resource = "jellynut"}
  }

  for _, case in ipairs(planet_cases) do
    local surface = {
      name = case.planet,
      find_entities_filtered = function() return {} end,
      create_entity = function(entity)
        return {valid = true, name = entity.name, position = entity.position, surface = surface}
      end
    }
    game.surfaces[case.planet] = surface
    storage = {
      bootstrap = {square_size = 7, surface_name = "nauvis"},
      planets = {}
    }
    storage.planets[case.planet] = {
      square_size = 17,
      surface_size = 19,
      surface_name = case.planet,
      starter_anchors = {
        anchors = {
          runtime_defs.create_managed_anchor(
            runtime_defs.get_input_definition(case.resource, case.planet),
            "ingress",
            "north",
            {x = 0, y = -9}
          )
        }
      }
    }

    local anchor = storage.planets[case.planet].starter_anchors.anchors[1]
    anchor.entity = nil

    anchor_runtime.handle_anchor_mined({
      valid = true,
      name = anchor.entity_name,
      position = {x = 0.5, y = -8.5},
      surface = surface
    })

    assert_equal(anchor.position, nil, case.planet .. " " .. case.resource .. " ingress should stash when mined by centered entity position")
  end
end)
