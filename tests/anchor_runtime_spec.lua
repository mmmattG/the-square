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
    },
    ["the-square-line-purchase-cost"] = {
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

run_test("placed generic Managed Lines stay unconfigured and operable", function()
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
  assert_equal(anchor.entity_name, runtime_defs.get_generic_anchor_entity_name("fluid", "ingress"), "unconfigured Managed Lines should spawn the matching generic entity")
  assert_equal(anchor.entity.name, runtime_defs.get_generic_anchor_entity_name("fluid", "ingress"), "placement should recreate an unconfigured generic entity")
  assert_equal(anchor.entity.operable, true, "unconfigured generic Managed Lines should stay operable so clicking opens configuration")
end)

run_test("existing generic item Managed Lines do not require underground belt fields", function()
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

  assert_equal(storage.starter_anchors.anchors[1].entity, generic_entity, "existing generic item Managed Line should be reused without underground-belt access")
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

run_test("Managed Line Placement Preview invalid cursor movement does not print placement errors", function()
  rendering.drawn_sprites = {}
  storage.bootstrap = {
    square_size = 12,
    expansion_points = 5000
  }
  storage.planets = nil
  storage.anchor_preview_ghosts = nil
  storage.starter_anchors = {
    layout_version = runtime_defs.STARTER_ANCHOR_LAYOUT_VERSION,
    anchors = {
      runtime_defs.create_managed_anchor(runtime_defs.get_input_definition("iron-ore"), "ingress", nil, nil)
    }
  }

  local player = build_player()
  player.index = 1
  player.valid = true
  player.surface = {name = "nauvis"}
  player.selected = {
    valid = true,
    name = runtime_defs.ANCHOR_SLOT_PROXY_NAME,
    position = {x = 0, y = -6}
  }
  player.cursor_position = {x = 50.2, y = 3.7}
  player.cursor_stack = {
    valid_for_read = true,
    name = runtime_defs.get_ingress_item_name("iron-ore"),
    count = 1
  }

  anchor_runtime.update_player_anchor_preview(player)

  assert_equal(#rendering.drawn_sprites, 1, "invalid cursor movement should still draw a preview")
  assert_equal(#player.get_messages(), 0, "passive preview updates should not print invalid placement errors")
end)

run_test("attempted invalid Managed Line placement still prints placement errors", function()
  storage.bootstrap = {
    square_size = 12,
    expansion_points = 5000,
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
  assert_equal(player.get_messages()[1][1], "message.the-square-managed-line-invalid-edge", "invalid edge attempts should print an error")

  local fluid_gap_entity = {
    valid = true,
    name = runtime_defs.get_ingress_entity_name("crude-oil", 1),
    position = {x = 0, y = -7},
    surface = player.surface,
    destroy = function(self) self.valid = false end
  }

  anchor_runtime.handle_entity_built({entity = fluid_gap_entity, player_index = 1})
  assert_equal(player.get_messages()[2][1], "message.the-square-managed-line-fluid-gap-required", "fluid gap attempts should print an error")
end)

run_test("Managed Line Placement Preview follows cursor and stays visible with invalid tint", function()
  rendering.drawn_sprites = {}
  storage.bootstrap = {
    square_size = 12,
    expansion_points = 5000
  }
  storage.planets = nil
  storage.anchor_preview_ghosts = nil
  storage.starter_anchors = {
    layout_version = runtime_defs.STARTER_ANCHOR_LAYOUT_VERSION,
    anchors = {
      runtime_defs.create_managed_anchor(runtime_defs.get_input_definition("iron-ore"), "ingress", nil, nil)
    }
  }

  local player = build_player()
  player.index = 1
  player.valid = true
  player.surface = {name = "nauvis"}
  player.selected = {
    valid = true,
    name = runtime_defs.ANCHOR_SLOT_PROXY_NAME,
    position = {x = 0, y = -6}
  }
  player.cursor_position = {x = 50.2, y = 3.7}
  player.cursor_stack = {
    valid_for_read = true,
    name = runtime_defs.get_ingress_item_name("iron-ore"),
    count = 1
  }

  anchor_runtime.update_player_anchor_preview(player)

  assert_equal(#rendering.drawn_sprites, 1, "one preview should be drawn")
  local args = rendering.drawn_sprites[1].args

  assert_equal(args.target.x, 50.5, "preview should snap to the cursor tile x")
  assert_equal(args.target.y, 3.5, "preview should snap to the cursor tile y")
  assert_equal(args.tint.r, 1, "invalid preview should be red")
  assert_equal(args.tint.g, 0, "invalid preview should not include green tint")
  assert_equal(args.tint.b, 0, "invalid preview should not include blue tint")
  assert_equal(args.sprite, "entity/" .. runtime_defs.get_ingress_entity_name("iron-ore", 1), "preview should use current-tier sprite")
end)
