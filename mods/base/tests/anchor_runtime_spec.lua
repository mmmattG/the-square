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

local function build_force_with_oil_processing(prerequisites_researched)
  local fluid_handling = {researched = prerequisites_researched}
  local oil_gathering = {researched = prerequisites_researched}
  local played_sounds = {}

  local oil_processing = {
    researched = false,
    prerequisites = {
      ["fluid-handling"] = fluid_handling,
      ["oil-gathering"] = oil_gathering
    }
  }

  return {
    valid = true,
    play_sound = function(sound)
      played_sounds[#played_sounds + 1] = sound
    end,
    get_played_sounds = function()
      return played_sounds
    end,
    technologies = {
      ["fluid-handling"] = fluid_handling,
      ["oil-gathering"] = oil_gathering,
      ["oil-processing"] = oil_processing
    }
  }
end

local function build_force_with_uranium_processing(prerequisites_researched)
  local sulfur_processing = {researched = prerequisites_researched}
  local played_sounds = {}

  local uranium_processing = {
    researched = false,
    prerequisites = {
      ["sulfur-processing"] = sulfur_processing
    }
  }

  return {
    valid = true,
    play_sound = function(sound)
      played_sounds[#played_sounds + 1] = sound
    end,
    get_played_sounds = function()
      return played_sounds
    end,
    technologies = {
      ["sulfur-processing"] = sulfur_processing,
      ["uranium-processing"] = uranium_processing
    }
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

run_test("placing crude oil ingress unlocks oil processing once prerequisites are researched", function()
  storage.bootstrap.surface_name = "fes-bootstrap"

  local force = build_force_with_oil_processing(false)
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

  assert_equal(
    force.technologies["oil-processing"].researched,
    false,
    "oil processing should stay locked until its prerequisites are researched"
  )
  assert_equal(#force.get_played_sounds(), 0, "no research sound should play before prerequisites are met")

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

  force.technologies["fluid-handling"].researched = true
  force.technologies["oil-gathering"].researched = true

  anchor_runtime.handle_managed_anchor_slot_click(player)

  assert_equal(
    force.technologies["oil-processing"].researched,
    true,
    "re-placing crude oil ingress should unlock oil processing once prerequisites are met"
  )
  assert_equal(#force.get_played_sounds(), 1, "unlocking oil processing should play the research-complete sound once")
  assert_equal(
    force.get_played_sounds()[1].path,
    "utility/research_completed",
    "unlocking oil processing should use the normal research-complete sound"
  )
end)

run_test("placing crude oil ingress unlocks oil processing immediately when prerequisites are already researched", function()
  storage.bootstrap.surface_name = "fes-bootstrap"

  local force = build_force_with_oil_processing(true)
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
    name = runtime_defs.get_ingress_item_name("crude-oil"),
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
      runtime_defs.create_managed_anchor(runtime_defs.get_input_definition("crude-oil"), "ingress", nil, nil)
    }
  }

  anchor_runtime.handle_managed_anchor_slot_click(player)

  assert_equal(
    force.technologies["oil-processing"].researched,
    true,
    "crude oil placement should unlock oil processing immediately when prerequisites are already researched"
  )
  assert_equal(#force.get_played_sounds(), 1, "immediate unlock should play the research-complete sound once")
  assert_equal(
    force.get_played_sounds()[1].path,
    "utility/research_completed",
    "immediate unlock should use the normal research-complete sound"
  )
end)

run_test("placing non-crude ingress does not unlock oil processing", function()
  storage.bootstrap.surface_name = "fes-bootstrap"

  local force = build_force_with_oil_processing(true)
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

  assert_equal(force.technologies["oil-processing"].researched, false, "only crude oil placement should unlock oil processing")
  assert_equal(#force.get_played_sounds(), 0, "non-crude placement should not play the research-complete sound")
end)

run_test("placing uranium ore ingress unlocks uranium processing once prerequisites are researched", function()
  storage.bootstrap.surface_name = "fes-bootstrap"

  local force = build_force_with_uranium_processing(false)
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
    name = runtime_defs.get_ingress_item_name("uranium-ore"),
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
      runtime_defs.create_managed_anchor(runtime_defs.get_input_definition("uranium-ore"), "ingress", nil, nil)
    }
  }

  anchor_runtime.handle_managed_anchor_slot_click(player)

  assert_equal(
    force.technologies["uranium-processing"].researched,
    false,
    "uranium processing should stay locked until its prerequisites are researched"
  )
  assert_equal(#force.get_played_sounds(), 0, "no research sound should play before uranium prerequisites are met")

  anchor_runtime.handle_anchor_mined({
    valid = true,
    name = runtime_defs.get_ingress_entity_name("uranium-ore", 1),
    position = {x = -6, y = -7}
  })

  local second_cursor_stack = {
    valid_for_read = true,
    name = runtime_defs.get_ingress_item_name("uranium-ore"),
    count = 1
  }
  second_cursor_stack.clear = function()
    second_cursor_stack.valid_for_read = false
    second_cursor_stack.name = nil
    second_cursor_stack.count = 0
  end
  player.cursor_stack = second_cursor_stack

  force.technologies["sulfur-processing"].researched = true

  anchor_runtime.handle_managed_anchor_slot_click(player)

  assert_equal(
    force.technologies["uranium-processing"].researched,
    true,
    "re-placing uranium ore ingress should unlock uranium processing once prerequisites are met"
  )
  assert_equal(#force.get_played_sounds(), 1, "unlocking uranium processing should play the research-complete sound once")
  assert_equal(
    force.get_played_sounds()[1].path,
    "utility/research_completed",
    "unlocking uranium processing should use the normal research-complete sound"
  )
end)

run_test("placing uranium ore ingress unlocks uranium processing immediately when prerequisites are already researched", function()
  storage.bootstrap.surface_name = "fes-bootstrap"

  local force = build_force_with_uranium_processing(true)
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
    name = runtime_defs.get_ingress_item_name("uranium-ore"),
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
      runtime_defs.create_managed_anchor(runtime_defs.get_input_definition("uranium-ore"), "ingress", nil, nil)
    }
  }

  anchor_runtime.handle_managed_anchor_slot_click(player)

  assert_equal(
    force.technologies["uranium-processing"].researched,
    true,
    "uranium ore placement should unlock uranium processing immediately when prerequisites are already researched"
  )
  assert_equal(#force.get_played_sounds(), 1, "immediate uranium unlock should play the research-complete sound once")
  assert_equal(
    force.get_played_sounds()[1].path,
    "utility/research_completed",
    "immediate uranium unlock should use the normal research-complete sound"
  )
end)

run_test("placing non-uranium ingress does not unlock uranium processing", function()
  storage.bootstrap.surface_name = "fes-bootstrap"

  local force = build_force_with_uranium_processing(true)
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

  assert_equal(
    force.technologies["uranium-processing"].researched,
    false,
    "only uranium ore placement should unlock uranium processing"
  )
  assert_equal(#force.get_played_sounds(), 0, "non-uranium placement should not play the research-complete sound")
end)
