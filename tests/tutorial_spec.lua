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
    ["the-square-background-tile"] = {
      value = "grass-1"
    }
  },
  startup = {
    ["the-square-expansion-tiles-per-research"] = {
      value = 9
    }
  }
}

storage = {}

local tutorial = require("lib.tutorial")
local defs = require("lib.runtime_defs")

local function assert_equal(actual, expected, message)
  if actual ~= expected then
    error((message or "values differ") .. "\nexpected: " .. tostring(expected) .. "\nactual: " .. tostring(actual))
  end
end

local function run_test(name, fn)
  local ok, err = xpcall(fn, debug.traceback)

  if not ok then
    io.stderr:write("FAIL " .. name .. "\n" .. err .. "\n")
    os.exit(1)
  end

  io.stdout:write("PASS " .. name .. "\n")
end

local function make_gui_parent()
  local parent = {
    children = {}
  }

  parent.add = function(_, spec)
    spec = spec or _
    local child = make_gui_parent()
    child.valid = true
    child.name = spec.name
    child.type = spec.type
    child.caption = spec.caption
    child.destroy = function()
      child.valid = false

      if child.name then
        parent[child.name] = nil
      end
    end

    if child.name then
      parent[child.name] = child
    end

    parent.children[#parent.children + 1] = child
    return child
  end

  return parent
end

local function build_player(index)
  local item_counts = {}
  local right_anchor_slot_proxy = {
    valid = true,
    name = defs.ANCHOR_SLOT_PROXY_NAME,
    position = {x = 4, y = 0}
  }
  local left_anchor_slot_proxy = {
    valid = true,
    name = defs.ANCHOR_SLOT_PROXY_NAME,
    position = {x = -4, y = 0}
  }
  local goals = {}
  local arrows = {}

  return {
    valid = true,
    index = index or 1,
    surface = {
      name = "nauvis",
      find_entities_filtered = function(filter)
        if filter.name == defs.ANCHOR_SLOT_PROXY_NAME then
          return {right_anchor_slot_proxy, left_anchor_slot_proxy}
        end

        return {}
      end,
      create_entity = function(spec)
        local arrow
        arrow = {
          valid = true,
          name = spec.name,
          position = spec.position,
          destroy = function()
            arrow.valid = false
          end
        }
        arrows[#arrows + 1] = arrow
        return arrow
      end
    },
    gui = {
      screen = make_gui_parent()
    },
    get_item_count = function(item_name)
      return item_counts[item_name] or 0
    end,
    add_item = function(_, item_name, count)
      item_counts[item_name] = (item_counts[item_name] or 0) + (count or 1)
    end,
    set_goal_description = function(goal)
      goals[#goals + 1] = goal
    end,
    get_goals = function()
      return goals
    end,
    get_arrows = function()
      return arrows
    end,
    print = function()
    end
  },
    left_anchor_slot_proxy
end

local function with_message_spy(fn)
  local messages = {}
  game = {
    is_multiplayer = function()
      return false
    end,
    show_message_dialog = function(param)
      messages[#messages + 1] = param
    end
  }

  fn(messages)

  game = nil
end

run_test("world creation tutorial uses native message dialogs for the ingress flow", function()
  with_message_spy(function(messages)
    storage = {}
    local player, anchor_slot_proxy = build_player(7)
    local ingress_entity = {
      valid = true,
      name = "the-square-item-ingress-managed-anchor",
      position = {x = -4, y = 1}
    }
    local anchors = {
      anchors = {}
    }
    local managed_line_runtime = {
      get = function()
        return anchors
      end
    }

    assert_equal(tutorial.show_world_creation(player), true, "first show should create the first message")
    assert_equal(messages[1].text[1], "gui.the-square-tutorial-click-anchor-slot", "tutorial should start by asking for an anchor slot")
    assert_equal(messages[1].point_to.type, "entity", "anchor slot prompt should point to an entity")
    assert_equal(messages[1].point_to.entity, anchor_slot_proxy, "anchor slot prompt should point to an anchor slot")
    assert_equal(player.get_goals()[1][1], "gui.the-square-tutorial-goal-click-anchor-slot", "anchor slot step should set the current objective")
    assert_equal(player.get_arrows()[1].position, anchor_slot_proxy.position, "anchor slot step should create a world arrow on the left anchor slot")

    player.gui.screen.add({
      type = "frame",
      name = defs.ANCHOR_CONFIG_FRAME_NAME
    })

    assert_equal(tutorial.handle_anchor_slot_clicked(player), true, "opening anchor configuration should advance the tutorial")
    assert_equal(player.get_goals()[2][1], "gui.the-square-tutorial-goal-select-ingress", "selection step should update the current objective")
    assert_equal(#messages, 1, "selection step should use the objective instead of a modal message")
    assert_equal(player.get_arrows()[1].valid, false, "selection step should clear the anchor slot arrow")

    anchors.anchors[1] = {
      position = {x = 1, y = 0},
      flow = "ingress",
      kind = "item",
      resource = "iron-ore",
      entity = ingress_entity
    }

    assert_equal(tutorial.handle_anchor_config_changed(player, managed_line_runtime), true, "configured item ingress should advance to pickup")
    assert_equal(player.get_goals()[3][1], "gui.the-square-tutorial-goal-pick-up-resource", "pickup step should update the current objective")
    assert_equal(#messages, 1, "pickup step should use the objective instead of a modal message")
    assert_equal(player.get_arrows()[2].position, ingress_entity.position, "pickup step should point a world arrow at the ingress")

    assert_equal(tutorial.handle_inventory_changed(player), false, "unchanged inventory should not complete the tutorial")
    player:add_item("iron-ore", 1)
    assert_equal(tutorial.handle_inventory_changed(player), true, "picked up ingress resource should complete the tutorial")
    assert_equal(messages[2].text[1], "gui.the-square-tutorial-complete", "tutorial should point to Tips after completion")
    assert_equal(player.get_goals()[4], "", "completion should clear the current objective")
    assert_equal(player.get_arrows()[2].valid, false, "completion should clear the pickup arrow")
  end)
end)

run_test("world creation tutorial ignores fluid ingress for pickup step", function()
  with_message_spy(function(messages)
    storage = {}
    local player = build_player(3)
    local managed_line_runtime = {
      get = function()
        return {
          anchors = {
            {
              position = {x = 1, y = 0},
              flow = "ingress",
              kind = "fluid",
              resource = "water"
            }
          }
        }
      end
    }

    tutorial.show_world_creation(player)
    player.gui.screen.add({
      type = "frame",
      name = defs.ANCHOR_CONFIG_FRAME_NAME
    })
    tutorial.handle_anchor_slot_clicked(player)

    assert_equal(tutorial.handle_anchor_config_changed(player, managed_line_runtime), false, "fluid ingress should not satisfy the item pickup tutorial")
    assert_equal(#messages, 1, "fluid ingress should not show another modal prompt")
  end)
end)
