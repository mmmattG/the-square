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
  }
}

storage = {
  bootstrap = {
    square_size = 12
  }
}

game = {
  surfaces = {},
  players = {}
}

rendering = {
  drawn_sprites = {},
  draw_sprite = function(args)
    local sprite = {
      valid = true,
      args = args,
      destroy = function(self)
        self.valid = false
      end
    }

    rendering.drawn_sprites[#rendering.drawn_sprites + 1] = sprite

    return sprite
  end
}

local anchor_runtime = require("lib.anchor_runtime")
local runtime_defs = require("lib.runtime_defs")

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

local function build_player()
  local inventory = {}
  local item_counts = {}
  local messages = {}
  local player
  local function make_gui_parent()
    local parent = {}
    parent.add = function(_, spec)
      spec = spec or _
      local child = make_gui_parent()
      child.valid = true
      child.name = spec.name
      child.type = spec.type
      child.caption = spec.caption
      child.enabled = true
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
  local function create_entity(_, spec)
    spec = spec or _
    local entity
    entity = {
      valid = true,
      name = spec.name,
      position = spec.position,
      direction = spec.direction,
      force = spec.force,
      active = true,
      surface = player.surface,
      destroy = function(self)
        self.valid = false
      end,
      get_recipe = function(self)
        return self.recipe
      end,
      set_recipe = function(recipe_name)
        entity.recipe = recipe_name and {name = recipe_name} or nil
      end
    }
    return entity
  end

  player = {
    valid = true,
    index = 1,
    force = {},
    position = {x = 0, y = 0},
    surface = {
      name = "fes-bootstrap",
      create_entity = create_entity,
      find_entities_filtered = function()
        return {}
      end,
      spill_item_stack = function(_, _, _, _, _)
      end
    },
    insert = function(stack)
      inventory[#inventory + 1] = stack.name
      item_counts[stack.name] = (item_counts[stack.name] or 0) + (stack.count or 1)
      return stack.count
    end,
    can_insert = function()
      return true
    end,
    get_item_count = function(item_name)
      return item_counts[item_name] or 0
    end,
    remove_item = function(stack)
      local available = item_counts[stack.name] or 0
      local removed = math.min(available, stack.count or 1)
      item_counts[stack.name] = available - removed
      return removed
    end,
    print = function(message)
      messages[#messages + 1] = message
    end,
    get_inventory_names = function()
      return inventory
    end,
    get_messages = function()
      return messages
    end,
    gui = {
      screen = make_gui_parent()
    }
  }

  return player
end

local function configure_selected_slot(player, resource, flow)
  storage.bootstrap.square_size = storage.bootstrap.square_size or 12
  local definition = flow == "egress" and runtime_defs.get_output_definition(resource) or runtime_defs.get_input_definition(resource)
  player.insert({name = runtime_defs.get_generic_anchor_item_name(definition.kind, flow), count = 1})
  player.surface.create_entity = player.surface.create_entity or function(_, spec)
    spec = spec or _
    local entity
    entity = {
      valid = true,
      name = spec.name,
      position = spec.position,
      direction = spec.direction,
      force = spec.force,
      surface = player.surface,
      active = true,
      recipe = nil,
      destroy = function(self) self.valid = false end,
      get_recipe = function(self) return self.recipe end,
      set_recipe = function(recipe_name) entity.recipe = recipe_name and {name = recipe_name} or nil end
    }
    return entity
  end
  player.surface.find_entities_filtered = player.surface.find_entities_filtered or function()
    return {}
  end
  anchor_runtime.handle_managed_anchor_slot_click(player)
  assert_equal(player.gui.screen[runtime_defs.ANCHOR_CONFIG_FRAME_NAME] ~= nil, true, "slot click should open an anchor configuration menu")
  assert_equal(player.opened, player.gui.screen[runtime_defs.ANCHOR_CONFIG_FRAME_NAME], "anchor configuration should be the player's opened GUI")
  local configured = anchor_runtime.handle_anchor_config_gui_click(player, {
    valid = true,
    name = runtime_defs.ANCHOR_CONFIG_BUTTON_PREFIX .. flow .. "__" .. resource
  })
  local message = player.get_messages()[#player.get_messages()]
  assert_equal(configured, true, "recipe selection should configure the selected anchor slot: " .. tostring(message and message[1] or message))
  return configured
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
  local player = build_player()
  local crude_oil_definition = runtime_defs.get_input_definition("crude-oil")

  storage.starter_anchors = {
    layout_version = runtime_defs.STARTER_ANCHOR_LAYOUT_VERSION,
    anchors = {
      runtime_defs.create_managed_anchor(crude_oil_definition, "ingress", nil, nil)
    }
  }

  anchor_runtime.purchase_managed_line_for_resource(player, "uranium-ore")

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

run_test("swapping anchor line type refunds the previous Managed Line item", function()
  storage.bootstrap = {square_size = 12, surface_name = "fes-bootstrap"}
  storage.planets = nil
  storage.starter_anchors = {
    layout_version = runtime_defs.STARTER_ANCHOR_LAYOUT_VERSION,
    anchors = {
      runtime_defs.create_managed_anchor(runtime_defs.get_input_definition("iron-ore"), "ingress", "north", {x = -6, y = -7})
    }
  }

  local player = build_player()
  player.surface = {name = "fes-bootstrap"}

  player.insert({name = runtime_defs.get_generic_anchor_item_name("fluid", "ingress"), count = 1})
  anchor_runtime.handle_anchor_gui_opened({
    valid = true,
    name = runtime_defs.get_ingress_entity_name("iron-ore", 1),
    position = {x = -6, y = -7},
    surface = player.surface
  }, player)

  assert_equal(anchor_runtime.handle_anchor_config_gui_click(player, {
    valid = true,
    name = runtime_defs.ANCHOR_CONFIG_BUTTON_PREFIX .. "pick__ingress__water"
  }), true, "swap click should be handled")

  local anchor = storage.starter_anchors.anchors[1]
  assert_equal(anchor.resource, "water", "anchor should switch to the selected fluid ingress")
  assert_equal(player.get_item_count(runtime_defs.get_generic_anchor_item_name("fluid", "ingress")), 0, "new fluid line item should be consumed")
  assert_equal(player.get_item_count(runtime_defs.get_generic_anchor_item_name("item", "ingress")), 1, "previous item line should be refunded")
end)

run_test("swapping anchor line type is cancelled when previous Managed Line cannot be refunded", function()
  storage.bootstrap = {square_size = 12, surface_name = "fes-bootstrap"}
  storage.planets = nil
  storage.starter_anchors = {
    layout_version = runtime_defs.STARTER_ANCHOR_LAYOUT_VERSION,
    anchors = {
      runtime_defs.create_managed_anchor(runtime_defs.get_input_definition("iron-ore"), "ingress", "north", {x = -6, y = -7})
    }
  }

  local player = build_player()
  player.surface = {name = "fes-bootstrap"}
  player.can_insert = function()
    return false
  end

  player.insert({name = runtime_defs.get_generic_anchor_item_name("fluid", "ingress"), count = 1})
  anchor_runtime.handle_anchor_gui_opened({
    valid = true,
    name = runtime_defs.get_ingress_entity_name("iron-ore", 1),
    position = {x = -6, y = -7},
    surface = player.surface
  }, player)

  assert_equal(anchor_runtime.handle_anchor_config_gui_click(player, {
    valid = true,
    name = runtime_defs.ANCHOR_CONFIG_BUTTON_PREFIX .. "pick__ingress__water"
  }), true, "failed swap click should still be handled")

  local anchor = storage.starter_anchors.anchors[1]
  assert_equal(anchor.resource, "iron-ore", "anchor should keep the previous item ingress")
  assert_equal(player.get_item_count(runtime_defs.get_generic_anchor_item_name("fluid", "ingress")), 1, "new fluid line item should not be consumed")
  assert_equal(player.get_messages()[1][1], "message.the-square-managed-line-refund-inventory-full", "player should see the full-inventory refund error")
end)

run_test("closing the anchor configuration GUI destroys the screen frame", function()
  storage.bootstrap.surface_name = "fes-bootstrap"
  storage.starter_anchors = {
    layout_version = runtime_defs.STARTER_ANCHOR_LAYOUT_VERSION,
    anchors = {}
  }

  local player = build_player()
  player.surface = {name = "fes-bootstrap"}
  player.selected = {
    valid = true,
    name = runtime_defs.ANCHOR_SLOT_PROXY_NAME,
    position = {x = -6, y = -7}
  }

  anchor_runtime.handle_managed_anchor_slot_click(player)

  local frame = player.gui.screen[runtime_defs.ANCHOR_CONFIG_FRAME_NAME]
  assert_equal(frame ~= nil, true, "slot click should create the anchor configuration frame")
  assert_equal(anchor_runtime.handle_anchor_config_gui_closed(player, frame), true, "closed screen frame should be handled")
  assert_equal(frame.valid, false, "closed frame should be destroyed")
  assert_equal(player.gui.screen[runtime_defs.ANCHOR_CONFIG_FRAME_NAME], nil, "destroyed frame should be removed from screen GUI")
  assert_equal(storage.anchor_config_open[player.index], nil, "closed frame should clear per-player open anchor state")
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

  player.opened = nil

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

  player.opened = nil

  assert_equal(
    force.technologies["oil-processing"].researched,
    false,
    "mined Managed Lines should be unconfigured and not unlock oil processing until reconfigured"
  )
  assert_equal(#force.get_played_sounds(), 0, "unconfigured replacement should not play the research-complete sound")
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

  configure_selected_slot(player, "crude-oil", "ingress")

  assert_equal(
    force.technologies["oil-processing"].researched,
    true,
    "crude oil placement should unlock oil processing immediately when prerequisites are already researched"
  )
  assert_equal(anchor_runtime.get_owned_line_counts("crude-oil").owned, 1, "placing a purchased line should not duplicate ownership")
  assert_equal(anchor_runtime.get_owned_line_counts("crude-oil").placed, 1, "placing a purchased line should move the stashed ownership record")
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

  configure_selected_slot(player, "iron-ore", "ingress")

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

  player.opened = nil

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

  player.opened = nil

  assert_equal(
    force.technologies["uranium-processing"].researched,
    false,
    "mined Managed Lines should be unconfigured and not unlock uranium processing until reconfigured"
  )
  assert_equal(#force.get_played_sounds(), 0, "unconfigured replacement should not play the research-complete sound")
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

  configure_selected_slot(player, "uranium-ore", "ingress")

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

  configure_selected_slot(player, "iron-ore", "ingress")

  assert_equal(
    force.technologies["uranium-processing"].researched,
    false,
    "only uranium ore placement should unlock uranium processing"
  )
  assert_equal(#force.get_played_sounds(), 0, "non-uranium placement should not play the research-complete sound")
end)

run_test("unconfigured anchor points stay empty and keep their slot proxy", function()
  local player_force = {valid = true, technologies = {}}
  local created_entities = {}
  local surface = {
    name = "fes-bootstrap",
    find_entities_filtered = function()
      return {}
    end,
    create_entity = function(_, spec)
      spec = spec or _
      local entity = {
        valid = true,
        name = spec.name,
        position = spec.position,
        direction = spec.direction,
        force = spec.force,
        belt_to_ground_type = spec.type
      }
      created_entities[#created_entities + 1] = entity
      return entity
    end
  }
  game = {
    forces = {player = player_force},
    surfaces = {["fes-bootstrap"] = surface},
    players = {}
  }
  storage = {
    bootstrap = {square_size = 12, surface_name = "fes-bootstrap", ingress_tier = 1},
    starter_anchors = {layout_version = runtime_defs.STARTER_ANCHOR_LAYOUT_VERSION, anchors = {
      {
        kind = "fluid",
        flow = "ingress",
        side = "north",
        position = {x = -6, y = -7},
        direction = defines.direction.north,
        entity_name = runtime_defs.get_generic_anchor_entity_name("fluid", "ingress"),
        item_name = runtime_defs.get_generic_anchor_item_name("fluid", "ingress"),
        item_progress = {0, 0}
      }
    }}
  }

  anchor_runtime.ensure_starter_anchors()

  local anchor = storage.starter_anchors.anchors[1]
  assert_equal(anchor.resource, nil, "new generic Managed Lines should not configure a resource during placement")
  assert_equal(anchor.entity, nil, "unconfigured anchor points should not spawn a Managed Line entity")
  assert_equal(created_entities[1].name, runtime_defs.ANCHOR_SLOT_PROXY_NAME, "unconfigured anchor points should keep an anchor slot proxy")
end)

run_test("existing generic item Managed Lines collapse back to anchor slot proxies", function()
  local player_force = {valid = true, technologies = {}}
  local generic_entity = setmetatable({
    valid = true,
    name = runtime_defs.get_generic_anchor_entity_name("item", "ingress"),
    position = {x = -6, y = -7},
    force = player_force
  }, {
    __index = function(_, key)
      if key == "belt_to_ground_type" then
        error("Entity is not underground-belt.")
      end
    end
  })
  local surface = {
    name = "fes-bootstrap",
    find_entities_filtered = function(_, filter)
      filter = filter or _
      if filter and filter.name == generic_entity.name and filter.position then
        return {generic_entity}
      end
      return {}
    end,
    create_entity = function(_, spec)
      spec = spec or _
      assert_equal(spec.name, runtime_defs.ANCHOR_SLOT_PROXY_NAME, "only anchor slot proxies should be created")
      return {valid = true, name = spec.name, position = spec.position}
    end
  }
  game = {
    forces = {player = player_force},
    surfaces = {["fes-bootstrap"] = surface},
    players = {}
  }
  storage = {
    bootstrap = {square_size = 12, surface_name = "fes-bootstrap", ingress_tier = 1},
    starter_anchors = {layout_version = runtime_defs.STARTER_ANCHOR_LAYOUT_VERSION, anchors = {
      {
        kind = "item",
        flow = "ingress",
        side = "north",
        position = {x = -6, y = -7},
        direction = defines.direction.south,
        entity = generic_entity,
        entity_name = runtime_defs.get_generic_anchor_entity_name("item", "ingress"),
        item_name = runtime_defs.get_generic_anchor_item_name("item", "ingress"),
        item_progress = {0, 0}
      }
    }}
  }

  anchor_runtime.ensure_starter_anchors()

  assert_equal(storage.starter_anchors.anchors[1].entity, nil, "existing generic item Managed Line state should no longer own a visible generic entity")
end)

run_test("choosing a Managed Line recipe configures the Managed Line for its minable base entity", function()
  local player_force = {valid = true, technologies = {}}
  local created_entities = {}
  local generic_entity
  local surface = {
    name = "fes-bootstrap",
    find_entities_filtered = function(_, filter)
      filter = filter or _
      if filter and filter.position and generic_entity and generic_entity.valid then
        return {generic_entity}
      end

      return {}
    end,
    create_entity = function(_, spec)
      spec = spec or _
      local entity = {
        valid = true,
        name = spec.name,
        position = spec.position,
        direction = spec.direction,
        force = spec.force,
        belt_to_ground_type = spec.type,
        destroy = function(self)
          self.valid = false
        end
      }
      created_entities[#created_entities + 1] = entity
      return entity
    end
  }
  generic_entity = {
    valid = true,
    name = runtime_defs.get_generic_anchor_entity_name("item", "ingress"),
    position = {x = -6, y = -7},
    surface = surface,
    force = player_force,
    active = true,
    get_recipe = function()
      return {name = runtime_defs.get_config_recipe_name("iron-ore", "ingress")}
    end,
    destroy = function()
      generic_entity.valid = false
    end
  }

  game = {
    forces = {player = player_force},
    surfaces = {["fes-bootstrap"] = surface},
    players = {}
  }
  storage = {
    bootstrap = {square_size = 12, surface_name = "fes-bootstrap", ingress_tier = 1},
    starter_anchors = {layout_version = runtime_defs.STARTER_ANCHOR_LAYOUT_VERSION, anchors = {
      {
        kind = "item",
        flow = "ingress",
        side = "north",
        position = {x = -6, y = -7},
        direction = defines.direction.south,
        entity = generic_entity,
        entity_name = runtime_defs.get_generic_anchor_entity_name("item", "ingress"),
        item_progress = {0, 0}
      }
    }}
  }

  assert_equal(anchor_runtime.handle_anchor_recipe_changed(generic_entity), true, "recipe selection should be accepted")

  local anchor = storage.starter_anchors.anchors[1]
  assert_equal(anchor.resource, "iron-ore", "selected recipe should configure the resource")
  assert_equal(anchor.entity_name, runtime_defs.get_ingress_entity_name("iron-ore", 1), "configured Managed Lines should use the minable base entity instead of a top overlay")
  assert_equal(generic_entity.active, false, "selected recipes should stop crafting before the generic Managed Line is replaced")
end)

run_test("anchor slot configuration fails when matching Managed Line item is missing", function()
  storage.bootstrap = {square_size = 12, surface_name = "fes-bootstrap"}
  storage.planets = nil
  storage.starter_anchors = {
    layout_version = runtime_defs.STARTER_ANCHOR_LAYOUT_VERSION,
    anchors = {}
  }

  local player = build_player()
  player.surface = {name = "fes-bootstrap"}
  player.selected = {
    valid = true,
    name = runtime_defs.ANCHOR_SLOT_PROXY_NAME,
    position = {x = -6, y = -7}
  }
  player.surface.create_entity = function(_, spec)
    spec = spec or _
    local entity
    entity = {
      valid = true,
      name = spec.name,
      position = spec.position,
      direction = spec.direction,
      force = spec.force,
      surface = player.surface,
      active = true,
      recipe = nil,
      destroy = function(self) self.valid = false end,
      get_recipe = function(self) return self.recipe end,
      set_recipe = function(recipe_name) entity.recipe = recipe_name and {name = recipe_name} or nil end
    }
    return entity
  end
  player.surface.find_entities_filtered = function()
    return {}
  end

  anchor_runtime.handle_managed_anchor_slot_click(player)
  assert_equal(anchor_runtime.handle_anchor_config_gui_click(player, {
    valid = true,
    name = runtime_defs.ANCHOR_CONFIG_BUTTON_PREFIX .. "ingress__iron-ore"
  }), true, "missing inventory should be handled by the anchor configuration menu")
  assert_equal(player.get_messages()[1][1], "message.the-square-managed-line-missing-inventory", "missing inventory should explain the failure")
  assert_equal(anchor_runtime.get_owned_line_counts("iron-ore").owned, 0, "failed placement should not create owned lines")
end)

run_test("ingress tier research sync keeps planet starter Managed Lines as minable base entities", function()
  local player_force = {
    valid = true,
    technologies = {
      ["the-square-ingress-red"] = {researched = true},
      ["the-square-ingress-blue"] = {researched = false}
    }
  }
  local destroyed_yellow = false
  local created_entities = {}
  local yellow_anchor = {
    valid = true,
    name = runtime_defs.get_ingress_entity_name("scrap", 1),
    force = player_force,
    destroy = function(self)
      self.valid = false
      destroyed_yellow = true
    end
  }
  local surface = {
    name = "fulgora",
    find_entities_filtered = function(_, filter)
      filter = filter or _
      if filter.name == runtime_defs.get_ingress_entity_name("scrap", 1) and yellow_anchor.valid then
        return {yellow_anchor}
      end

      return {}
    end,
    create_entity = function(_, spec)
      spec = spec or _
      local entity = {
        valid = true,
        name = spec.name,
        position = spec.position,
        direction = spec.direction,
        force = spec.force,
        belt_to_ground_type = spec.type
      }
      created_entities[#created_entities + 1] = entity
      return entity
    end
  }

  game = {
    forces = {player = player_force},
    surfaces = {
      fulgora = surface
    },
    players = {}
  }
  storage = {
    bootstrap = {square_size = 7, surface_name = "nauvis", ingress_tier = 1},
    starter_anchors = nil,
    planets = {
      fulgora = {
        square_size = 17,
        surface_name = "fulgora",
        starter_anchors = {anchors = {
          {
            resource = "scrap",
            kind = "item",
            flow = "ingress",
            side = "north",
            position = {x = 0, y = -9},
            direction = defines.direction.south,
            entity = yellow_anchor,
            entity_name = runtime_defs.get_ingress_entity_name("scrap", 1)
          }
        }}
      }
    }
  }

  assert_equal(anchor_runtime.sync_ingress_tier_from_research(player_force), true, "research sync should update the stored tier")
  assert_equal(storage.bootstrap.ingress_tier, 3, "red ingress research should set tier 3")
  assert_equal(destroyed_yellow, true, "legacy planet ingress Managed Line should be destroyed")
  assert_equal(created_entities[1].name, runtime_defs.get_ingress_entity_name("scrap", 3), "planet ingress Managed Line should be recreated as the upgraded minable base entity")
  assert_equal(storage.planets.fulgora.starter_anchors.anchors[1].entity, created_entities[1], "planet Managed Line state should point at the upgraded entity")
end)

run_test("direct Managed Line placement tells players to use anchor slots", function()
  storage.bootstrap = {
    square_size = 12,
    surface_name = "nauvis"
  }
  storage.planets = nil
  storage.starter_anchors = {
    layout_version = runtime_defs.STARTER_ANCHOR_LAYOUT_VERSION,
    anchors = {
      runtime_defs.create_managed_anchor(runtime_defs.get_input_definition("iron-ore"), "ingress", nil, nil),
      runtime_defs.create_managed_anchor(runtime_defs.get_input_definition("crude-oil"), "ingress", nil, nil),
      runtime_defs.create_managed_anchor(runtime_defs.get_input_definition("crude-oil"), "ingress", "north", {x = -1, y = -7})
    }
  }

  local player = build_player()
  player.index = 1
  player.valid = true
  player.object_name = "LuaPlayer"
  player.surface = {name = "nauvis"}

  local invalid_edge_entity = {
    valid = true,
    name = runtime_defs.get_ingress_entity_name("iron-ore", 1),
    position = {x = 0, y = 0},
    surface = player.surface,
    destroy = function(self) self.valid = false end
  }
  game.get_player = function() return player end

  anchor_runtime.handle_entity_built({entity = invalid_edge_entity, player_index = 1})
  assert_equal(player.get_messages()[1][1], "message.the-square-managed-line-use-anchor-slot", "direct placement attempts should point players at anchor slots")

  local fluid_gap_entity = {
    valid = true,
    name = runtime_defs.get_ingress_entity_name("crude-oil", 1),
    position = {x = 0, y = -7},
    surface = player.surface,
    destroy = function(self) self.valid = false end
  }

  anchor_runtime.handle_entity_built({entity = fluid_gap_entity, player_index = 1})
  assert_equal(player.get_messages()[2][1], "message.the-square-managed-line-use-anchor-slot", "all direct Managed Line placement should be rejected")
end)
