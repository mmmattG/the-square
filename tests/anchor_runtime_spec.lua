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
    },
    ["fes-line-purchase-cost"] = {
      value = 1000
    }
  }
}

storage = {
  bootstrap = {
    square_size = 12,
    expansion_points = 5000
  }
}

game = {
  surfaces = {},
  players = {}
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

local function build_player()
  local inventory = {}
  local messages = {}

  return {
    valid = true,
    force = {},
    position = {x = 0, y = 0},
    surface = {
      spill_item_stack = function(_, _, _, _, _)
      end
    },
    insert = function(stack)
      inventory[#inventory + 1] = stack.name
      return stack.count
    end,
    print = function(message)
      messages[#messages + 1] = message
    end,
    get_inventory_names = function()
      return inventory
    end,
    get_messages = function()
      return messages
    end
  }
end

local function build_entity_build_stats_recorder()
  local flows = {}

  return {
    valid = true,
    on_flow = function(name, count)
      flows[#flows + 1] = {name = name, count = count}
    end,
    get_flows = function()
      return flows
    end
  }
end

local function build_force_with_entity_build_stats(statistics)
  return {
    valid = true,
    get_entity_build_count_statistics = function(_)
      return statistics
    end
  }
end

run_test("uranium purchase also grants one sulfuric acid egress line", function()
  storage.bootstrap.expansion_points = 5000

  local player = build_player()
  local crude_oil_definition = runtime_defs.get_input_definition("crude-oil")

  storage.starter_anchors = {
    layout_version = runtime_defs.STARTER_ANCHOR_LAYOUT_VERSION,
    anchors = {
      runtime_defs.create_managed_anchor(crude_oil_definition, "ingress", nil, nil)
    }
  }

  anchor_runtime.purchase_managed_line_for_resource(player, "uranium-ore")

  assert_equal(storage.bootstrap.expansion_points, 4000, "uranium purchase should only spend one line cost")
  assert_equal(anchor_runtime.get_owned_line_counts("uranium-ore").owned, 1, "uranium should be owned after purchase")
  assert_equal(
    anchor_runtime.get_owned_line_counts("sulfuric-acid").owned,
    1,
    "first uranium purchase should also grant sulfuric acid egress ownership"
  )

  local inventory = player.get_inventory_names()

  assert_equal(inventory[1], runtime_defs.get_ingress_item_name("uranium-ore"), "player should receive the uranium ingress item")
  assert_equal(
    inventory[2],
    runtime_defs.get_egress_item_name("sulfuric-acid"),
    "player should also receive the sulfuric acid egress item"
  )
end)

run_test("fluid egress faces inward on the managed border", function()
  assert_equal(
    runtime_defs.get_anchor_direction_for_side("egress", "fluid", "north"),
    defines.direction.south,
    "north-side fluid egress should face inward"
  )
  assert_equal(
    runtime_defs.get_anchor_direction_for_side("egress", "fluid", "west"),
    defines.direction.east,
    "west-side fluid egress should face inward"
  )
end)

run_test("placing crude oil ingress counts as mining crude oil each time it is placed", function()
  storage.bootstrap.surface_name = "fes-bootstrap"

  local statistics = build_entity_build_stats_recorder()
  local force = build_force_with_entity_build_stats(statistics)
  local player = build_player()
  player.force = force
  player.surface = {name = "fes-bootstrap"}
  player.selected = {
    valid = true,
    name = runtime_defs.ANCHOR_SLOT_PROXY_NAME,
    position = {x = -6, y = -7}
  }
  local first_cursor_stack = {
    valid_for_read = true,
    name = runtime_defs.get_ingress_item_name("crude-oil"),
    count = 1
  }
  first_cursor_stack.clear = function()
    first_cursor_stack.valid_for_read = false
    first_cursor_stack.name = nil
    first_cursor_stack.count = 0
  end
  player.cursor_stack = first_cursor_stack

  storage.starter_anchors = {
    layout_version = runtime_defs.STARTER_ANCHOR_LAYOUT_VERSION,
    anchors = {
      runtime_defs.create_managed_anchor(runtime_defs.get_input_definition("crude-oil"), "ingress", nil, nil)
    }
  }

  anchor_runtime.handle_managed_anchor_slot_click(player)

  local flows = statistics.get_flows()
  assert_equal(#flows, 1, "first crude oil placement should record one mined-entity event")
  assert_equal(flows[1].name, "crude-oil", "crude oil placement should report the crude-oil entity")
  assert_equal(flows[1].count, -1, "crude oil placement should record a mined count")

  anchor_runtime.handle_anchor_mined({
    valid = true,
    name = runtime_defs.get_ingress_entity_name("crude-oil", 1),
    position = {x = -6, y = -7}
  })

  local second_cursor_stack = {
    valid_for_read = true,
    name = runtime_defs.get_ingress_item_name("crude-oil"),
    count = 1
  }
  second_cursor_stack.clear = function()
    second_cursor_stack.valid_for_read = false
    second_cursor_stack.name = nil
    second_cursor_stack.count = 0
  end
  player.cursor_stack = second_cursor_stack

  anchor_runtime.handle_managed_anchor_slot_click(player)

  flows = statistics.get_flows()
  assert_equal(#flows, 2, "re-placing crude oil ingress should record mining again")
  assert_equal(flows[2].name, "crude-oil", "re-placement should still report crude-oil")
  assert_equal(flows[2].count, -1, "re-placement should record another mined count")
end)

run_test("placing non-crude ingress does not record crude oil mining progress", function()
  storage.bootstrap.surface_name = "fes-bootstrap"

  local statistics = build_entity_build_stats_recorder()
  local force = build_force_with_entity_build_stats(statistics)
  local player = build_player()
  player.force = force
  player.surface = {name = "fes-bootstrap"}
  player.selected = {
    valid = true,
    name = runtime_defs.ANCHOR_SLOT_PROXY_NAME,
    position = {x = -6, y = -7}
  }
  local cursor_stack = {
    valid_for_read = true,
    name = runtime_defs.get_ingress_item_name("iron-ore"),
    count = 1
  }
  cursor_stack.clear = function()
    cursor_stack.valid_for_read = false
    cursor_stack.name = nil
    cursor_stack.count = 0
  end
  player.cursor_stack = cursor_stack

  storage.starter_anchors = {
    layout_version = runtime_defs.STARTER_ANCHOR_LAYOUT_VERSION,
    anchors = {
      runtime_defs.create_managed_anchor(runtime_defs.get_input_definition("iron-ore"), "ingress", nil, nil)
    }
  }

  anchor_runtime.handle_managed_anchor_slot_click(player)

  assert_equal(#statistics.get_flows(), 0, "only crude oil placement should bridge the mining trigger")
end)
