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

local function give_player_item(player, item_name)
  player.item_counts = player.item_counts or {}
  player.item_counts[item_name] = (player.item_counts[item_name] or 0) + 1
end

local function make_gui_parent()
  local parent = {}
  parent.add = function(_, spec)
    spec = spec or _
    local child = make_gui_parent()
    child.valid = true
    child.name = spec.name
    child.destroy = function()
      child.valid = false
      if child.name then
        parent[child.name] = nil
      end
    end
    if child.name then
      parent[child.name] = child
    end
    return child
  end
  return parent
end

run_test("Vulcanus anchor slots open a Managed Line configuration menu using planet-local state", function()
  local created = {}
  local surface = {
    name = "vulcanus",
    find_entities_filtered = function() return {} end,
    create_entity = function(entity)
      created[#created + 1] = entity
      local created_entity
      created_entity = {
        valid = true,
        name = entity.name,
        position = entity.position,
        direction = entity.direction,
        force = entity.force,
        surface = surface,
        active = true,
        destroy = function(self) self.valid = false end,
        get_recipe = function(self) return self.recipe end,
        set_recipe = function(recipe_name) created_entity.recipe = recipe_name and {name = recipe_name} or nil end
      }
      return created_entity
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

  assert_equal(anchor.position.x, 0, "mining a Vulcanus Managed Line should leave the planet-local anchor point in place")
  assert_equal(anchor.resource, nil, "mining a Vulcanus Managed Line should clear the anchor point's Managed Line")

  local player
  local messages = {}
  player = {
    valid = true,
    index = 1,
    surface = surface,
    force = game.forces.player,
    selected = {valid = true, name = runtime_defs.ANCHOR_SLOT_PROXY_NAME, position = {x = 1, y = -9}},
    get_item_count = function(item_name)
      return player.item_counts and player.item_counts[item_name] or 0
    end,
    remove_item = function(stack)
      local available = player.get_item_count(stack.name)
      local removed = math.min(available, stack.count or 1)
      player.item_counts[stack.name] = available - removed
      return removed
    end,
    print = function(message) messages[#messages + 1] = message end,
    gui = {screen = make_gui_parent()}
  }

  give_player_item(player, runtime_defs.get_generic_anchor_item_name("item", "ingress"))
  anchor_runtime.handle_managed_anchor_slot_click(player)
  assert_equal(player.gui.screen[runtime_defs.ANCHOR_CONFIG_FRAME_NAME] ~= nil, true, "slot click should open a configuration menu")
  assert_equal(storage.anchor_config_open[1].position_key, "1:-9", "configuration menu should be owned by the selected Vulcanus anchor slot")
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

    assert_equal(anchor.resource, nil, case.planet .. " " .. case.resource .. " ingress should clear when mined by centered entity position")
    assert_equal(anchor.position.x, 0, case.planet .. " " .. case.resource .. " anchor point should stay in place")
  end
end)
