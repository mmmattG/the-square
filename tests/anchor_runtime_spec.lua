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
